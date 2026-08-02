const http = require('http');
const https = require('https');
const fs = require('fs');
const path = require('path');

const PORT = process.env.PORT || 8080;
const HOST = process.env.HOST || '127.0.0.1';
const ROOT = path.join(__dirname, 'build', 'web');
const ANTHROPIC_API_KEY = process.env.ANTHROPIC_API_KEY;
const CLAUDE_MODEL = process.env.CLAUDE_MODEL || 'claude-3-5-sonnet-20241022';
const CLAUDE_MAX_TOKENS = Number(process.env.CLAUDE_MAX_TOKENS || 1024);
const GEMINI_API_KEY = process.env.GEMINI_API_KEY;
const GEMINI_MODEL = process.env.GEMINI_MODEL || 'gemini-2.0-flash';
const GEMINI_MAX_TOKENS = Number(process.env.GEMINI_MAX_TOKENS || 1024);
const LLM_PROVIDER = GEMINI_API_KEY ? 'gemini' : (ANTHROPIC_API_KEY ? 'anthropic' : null);
const GOOGLE_MAPS_API_KEY =
  process.env.GOOGLE_MAPS_API_KEY || process.env.GOOGLE_PLACES_API_KEY || '';

if (!LLM_PROVIDER) {
  console.warn(
    'Warning: no LLM provider configured. Set GEMINI_API_KEY or ANTHROPIC_API_KEY. /api/claude/* routes will return 503.',
  );
} else {
  console.log(`LLM provider: ${LLM_PROVIDER}`);
}

if (!GOOGLE_MAPS_API_KEY) {
  console.warn(
    'Warning: GOOGLE_MAPS_API_KEY not set. /api/places/* routes will return 503.',
  );
} else {
  console.log('Google Places: enabled');
}

const mimeTypes = {
  '.html': 'text/html',
  '.js': 'application/javascript',
  '.css': 'text/css',
  '.json': 'application/json',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.gif': 'image/gif',
  '.svg': 'image/svg+xml',
  '.ico': 'image/x-icon',
  '.ttf': 'font/ttf',
  '.otf': 'font/otf',
  '.woff': 'font/woff',
  '.woff2': 'font/woff2',
  '.wasm': 'application/wasm',
};

function readJsonBody(req) {
  return new Promise((resolve, reject) => {
    const chunks = [];
    req.on('data', (chunk) => chunks.push(chunk));
    req.on('end', () => {
      try {
        const raw = Buffer.concat(chunks).toString('utf8');
        resolve(raw ? JSON.parse(raw) : {});
      } catch (error) {
        reject(error);
      }
    });
    req.on('error', reject);
  });
}

function corsHeaders() {
  return {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type',
  };
}

function sendJson(res, statusCode, payload, extraHeaders = {}) {
  res.writeHead(statusCode, {
    'Content-Type': 'application/json',
    ...corsHeaders(),
    ...extraHeaders,
  });
  res.end(JSON.stringify(payload));
}

function httpsGetJson(url) {
  return new Promise((resolve, reject) => {
    https
      .get(url, (response) => {
        const chunks = [];
        response.on('data', (chunk) => chunks.push(chunk));
        response.on('end', () => {
          const body = Buffer.concat(chunks).toString('utf8');
          try {
            resolve({
              statusCode: response.statusCode || 500,
              data: JSON.parse(body),
            });
          } catch (error) {
            reject(error);
          }
        });
      })
      .on('error', reject);
  });
}

async function handlePlacesRoute(req, res, pathname) {
  if (!GOOGLE_MAPS_API_KEY) {
    sendJson(res, 503, {
      success: false,
      error:
        'Places proxy is not configured. Set GOOGLE_MAPS_API_KEY (Places API enabled).',
    });
    return;
  }

  if (req.method !== 'GET') {
    sendJson(res, 405, { success: false, error: 'Method not allowed' });
    return;
  }

  try {
    if (pathname === '/api/places/autocomplete') {
      const url = new URL(req.url, `http://${HOST}:${PORT}`);
      const input = (url.searchParams.get('input') || '').trim();
      if (input.length < 2) {
        sendJson(res, 200, { success: true, predictions: [] });
        return;
      }

      const endpoint = new URL(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json',
      );
      endpoint.searchParams.set('input', input);
      endpoint.searchParams.set('key', GOOGLE_MAPS_API_KEY);
      const language = url.searchParams.get('language');
      if (language) endpoint.searchParams.set('language', language);

      const result = await httpsGetJson(endpoint.toString());
      if (result.data.status && result.data.status !== 'OK' && result.data.status !== 'ZERO_RESULTS') {
        sendJson(res, 502, {
          success: false,
          error: result.data.error_message || result.data.status || 'Places request failed',
        });
        return;
      }

      const predictions = (result.data.predictions || []).map((p) => ({
        placeId: p.place_id,
        description: p.description,
        mainText: p.structured_formatting?.main_text || p.description,
        secondaryText: p.structured_formatting?.secondary_text || '',
      }));

      sendJson(res, 200, { success: true, predictions });
      return;
    }

    sendJson(res, 404, { success: false, error: 'Unknown Places route' });
  } catch (error) {
    sendJson(res, 500, { success: false, error: String(error) });
  }
}

function forwardAnthropicRateLimitHeaders(upstreamHeaders, targetHeaders) {
  for (const [key, value] of Object.entries(upstreamHeaders)) {
    const lower = key.toLowerCase();
    if (
      lower === 'retry-after' ||
      lower === 'request-id' ||
      lower.startsWith('anthropic-ratelimit-')
    ) {
      targetHeaders[key] = value;
    }
  }
}

function callAnthropic({ systemPrompt, userPrompt }) {
  return new Promise((resolve, reject) => {
    const payload = JSON.stringify({
      model: CLAUDE_MODEL,
      max_tokens: CLAUDE_MAX_TOKENS,
      ...(systemPrompt ? { system: systemPrompt } : {}),
      messages: [{ role: 'user', content: userPrompt }],
    });

    const request = https.request(
      {
        hostname: 'api.anthropic.com',
        path: '/v1/messages',
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Content-Length': Buffer.byteLength(payload),
          'x-api-key': ANTHROPIC_API_KEY,
          'anthropic-version': '2023-06-01',
        },
      },
      (response) => {
        const chunks = [];
        response.on('data', (chunk) => chunks.push(chunk));
        response.on('end', () => {
          const body = Buffer.concat(chunks).toString('utf8');
          resolve({
            statusCode: response.statusCode,
            headers: response.headers,
            body,
          });
        });
      },
    );

    request.on('error', reject);
    request.write(payload);
    request.end();
  });
}

async function anthropicText(systemPrompt, userPrompt) {
  const upstream = await callAnthropic({ systemPrompt, userPrompt });
  const responseHeaders = {};
  forwardAnthropicRateLimitHeaders(upstream.headers, responseHeaders);

  if (upstream.statusCode !== 200) {
    return {
      ok: false,
      statusCode: upstream.statusCode,
      headers: responseHeaders,
      error: `API Error: ${upstream.statusCode} - ${upstream.body}`,
    };
  }

  const data = JSON.parse(upstream.body);
  return {
    ok: true,
    statusCode: 200,
    headers: responseHeaders,
    text: data.content?.[0]?.text ?? '',
  };
}

function callGemini({ systemPrompt, userPrompt }) {
  return new Promise((resolve, reject) => {
    const payload = JSON.stringify({
      ...(systemPrompt
        ? { system_instruction: { parts: [{ text: systemPrompt }] } }
        : {}),
      contents: [{ role: 'user', parts: [{ text: userPrompt }] }],
      generationConfig: { maxOutputTokens: GEMINI_MAX_TOKENS },
    });

    const request = https.request(
      {
        hostname: 'generativelanguage.googleapis.com',
        path: `/v1beta/models/${encodeURIComponent(GEMINI_MODEL)}:generateContent?key=${encodeURIComponent(GEMINI_API_KEY)}`,
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Content-Length': Buffer.byteLength(payload),
        },
      },
      (response) => {
        const chunks = [];
        response.on('data', (chunk) => chunks.push(chunk));
        response.on('end', () => {
          resolve({
            statusCode: response.statusCode,
            headers: response.headers,
            body: Buffer.concat(chunks).toString('utf8'),
          });
        });
      },
    );

    request.on('error', reject);
    request.write(payload);
    request.end();
  });
}

async function geminiText(systemPrompt, userPrompt) {
  const upstream = await callGemini({ systemPrompt, userPrompt });
  const responseHeaders = {};
  if (upstream.headers['retry-after']) {
    responseHeaders['retry-after'] = upstream.headers['retry-after'];
  }

  if (upstream.statusCode !== 200) {
    return {
      ok: false,
      statusCode: upstream.statusCode,
      headers: responseHeaders,
      error: `Gemini API Error: ${upstream.statusCode} - ${upstream.body}`,
    };
  }

  const data = JSON.parse(upstream.body);
  const text = data.candidates?.[0]?.content?.parts?.[0]?.text ?? '';
  return {
    ok: true,
    statusCode: 200,
    headers: responseHeaders,
    text,
  };
}

async function llmText(systemPrompt, userPrompt) {
  if (LLM_PROVIDER === 'gemini') {
    return geminiText(systemPrompt, userPrompt);
  }
  return anthropicText(systemPrompt, userPrompt);
}

function parseEventSystemPrompt() {
  return `You are a calendar assistant. Parse the user's message into a JSON event.
Current date/time: ${new Date().toISOString()}
Respond ONLY with valid JSON, no markdown, no explanation.

Format:
{
  "title": "short event title",
  "description": "optional description or null",
  "dateTime": "YYYY-MM-DDTHH:mm:00",
  "category": "Work|Personal|Health|Social|Shopping|Other",
  "location": "optional location or null"
}

If you can't parse it, respond with: {"error": "reason"}`;
}

function formatEventsForSummary(events) {
  return events
    .map((event) => {
      const date = new Date(event.dateTime);
      const hours = date.getHours();
      const minutes = String(date.getMinutes()).padStart(2, '0');
      const suffix = event.description ? ` (${event.description})` : '';
      return `- ${event.title} at ${hours}:${minutes}${suffix}`;
    })
    .join('\n');
}

function formatEventsForQuestion(events) {
  return events
    .map((event) => {
      const category = event.category ? ` (${event.category})` : '';
      return `${event.title} - ${event.dateTime}${category}`;
    })
    .join('\n');
}

function formatEventsForSuggestions(events) {
  return events
    .map((event) => {
      const category = event.category || 'uncategorized';
      return `${event.title} - ${event.dateTime} (${category})`;
    })
    .join('\n');
}

function cleanJsonText(text) {
  return text.replace(/```json/g, '').replace(/```/g, '').trim();
}

async function handleClaudeRoute(req, res, pathname) {
  if (!LLM_PROVIDER) {
    sendJson(res, 503, {
      success: false,
      error: 'AI proxy is not configured. Set GEMINI_API_KEY or ANTHROPIC_API_KEY.',
    });
    return;
  }

  if (req.method !== 'POST') {
    sendJson(res, 405, { success: false, error: 'Method not allowed' });
    return;
  }

  let body;
  try {
    body = await readJsonBody(req);
  } catch (error) {
    sendJson(res, 400, { success: false, error: 'Invalid JSON body' });
    return;
  }

  try {
    if (pathname === '/api/claude/parse-event') {
      const userText = body.userText;
      const userId = body.userId || '';
      if (!userText || typeof userText !== 'string') {
        sendJson(res, 400, { success: false, error: 'userText is required' });
        return;
      }

      const result = await llmText(parseEventSystemPrompt(), userText);
      if (!result.ok) {
        sendJson(
          res,
          result.statusCode === 429 ? 429 : 502,
          { success: false, error: result.error },
          result.headers,
        );
        return;
      }

      const json = JSON.parse(cleanJsonText(result.text));
      if (json.error) {
        sendJson(res, 200, { success: false, error: json.error }, result.headers);
        return;
      }

      sendJson(
        res,
        200,
        {
          success: true,
          event: {
            id: String(Date.now()),
            title: json.title || 'New Event',
            dateTime: json.dateTime,
            description: json.description ?? null,
            category: json.category || 'Other',
            location: json.location ?? null,
            userId,
          },
        },
        result.headers,
      );
      return;
    }

    if (pathname === '/api/claude/daily-summary') {
      const events = Array.isArray(body.events) ? body.events : [];
      if (events.length === 0) {
        sendJson(res, 200, {
          success: true,
          text: 'You have no events scheduled for today. Enjoy your free day!',
        });
        return;
      }

      const prompt = `Give me a brief, friendly daily briefing for these events. Keep it under 3 sentences, warm and encouraging:\n\n${formatEventsForSummary(events)}`;
      const result = await llmText(null, prompt);
      if (!result.ok) {
        sendJson(
          res,
          result.statusCode === 429 ? 429 : 502,
          { success: false, text: 'Unable to generate summary', error: result.error },
          result.headers,
        );
        return;
      }

      sendJson(res, 200, { success: true, text: result.text }, result.headers);
      return;
    }

    if (pathname === '/api/claude/answer-question') {
      const question = body.question;
      const events = Array.isArray(body.events) ? body.events : [];
      if (!question || typeof question !== 'string') {
        sendJson(res, 400, { success: false, error: 'question is required' });
        return;
      }

      const systemPrompt = `You are a calendar assistant. The user will ask questions about their schedule.
Current date/time: ${new Date().toISOString()}

Their events:
${formatEventsForQuestion(events)}

Answer concisely and conversationally.`;

      const result = await llmText(systemPrompt, question);
      if (!result.ok) {
        sendJson(
          res,
          result.statusCode === 429 ? 429 : 502,
          { success: false, text: 'Unable to answer right now', error: result.error },
          result.headers,
        );
        return;
      }

      sendJson(res, 200, { success: true, text: result.text }, result.headers);
      return;
    }

    if (pathname === '/api/claude/smart-suggestions') {
      const events = Array.isArray(body.events) ? body.events : [];
      if (events.length < 3) {
        sendJson(res, 200, {
          success: true,
          text: 'Add more events to get personalized suggestions',
        });
        return;
      }

      const prompt = `Looking at these events, suggest 1-2 helpful insights or patterns in 2 sentences:\n\n${formatEventsForSuggestions(events)}`;
      const result = await llmText(null, prompt);
      if (!result.ok) {
        sendJson(
          res,
          result.statusCode === 429 ? 429 : 502,
          { success: false, text: 'No suggestions available', error: result.error },
          result.headers,
        );
        return;
      }

      sendJson(res, 200, { success: true, text: result.text }, result.headers);
      return;
    }

    sendJson(res, 404, { success: false, error: 'Unknown Claude route' });
  } catch (error) {
    sendJson(res, 500, { success: false, error: String(error) });
  }
}

function serveStatic(req, res) {
  let urlPath = req.url === '/' ? '/index.html' : req.url.split('?')[0];
  let filePath = path.join(ROOT, urlPath);
  const normalizedRoot = path.normalize(ROOT + path.sep);
  const normalizedFile = path.normalize(filePath);

  if (!normalizedFile.startsWith(normalizedRoot)) {
    res.writeHead(403);
    res.end('Forbidden');
    return;
  }

  if (!fs.existsSync(filePath) || fs.statSync(filePath).isDirectory()) {
    filePath = path.join(ROOT, 'index.html');
  }

  fs.readFile(filePath, (err, data) => {
    if (err) {
      res.writeHead(404);
      res.end('Not Found');
      return;
    }
    const ext = path.extname(filePath);
    const mimeType = mimeTypes[ext] || 'application/octet-stream';
    res.writeHead(200, {
      'Content-Type': mimeType,
      'Cross-Origin-Opener-Policy': 'same-origin',
      'Cross-Origin-Embedder-Policy': 'require-corp',
      'Cache-Control': 'no-cache',
    });
    res.end(data);
  });
}

const server = http.createServer(async (req, res) => {
  const pathname = req.url.split('?')[0];

  if (pathname.startsWith('/api/') && req.method === 'OPTIONS') {
    res.writeHead(204, corsHeaders());
    res.end();
    return;
  }

  if (pathname.startsWith('/api/claude/')) {
    await handleClaudeRoute(req, res, pathname);
    return;
  }

  if (pathname.startsWith('/api/places/')) {
    await handlePlacesRoute(req, res, pathname);
    return;
  }

  serveStatic(req, res);
});

server.listen(PORT, HOST, () => {
  console.log(`DayBrief server running at http://${HOST}:${PORT}`);
  if (!LLM_PROVIDER) {
    console.log('Set GEMINI_API_KEY (recommended) or ANTHROPIC_API_KEY before starting to enable AI routes.');
  }
  if (!GOOGLE_MAPS_API_KEY) {
    console.log('Set GOOGLE_MAPS_API_KEY to enable Google Places location suggestions.');
  }
});
