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

if (!ANTHROPIC_API_KEY) {
  console.warn(
    'Warning: ANTHROPIC_API_KEY is not set. /api/claude/* routes will return 503.',
  );
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

function sendJson(res, statusCode, payload, extraHeaders = {}) {
  res.writeHead(statusCode, {
    'Content-Type': 'application/json',
    ...extraHeaders,
  });
  res.end(JSON.stringify(payload));
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
  if (!ANTHROPIC_API_KEY) {
    sendJson(res, 503, {
      success: false,
      error: 'Claude proxy is not configured. Set ANTHROPIC_API_KEY.',
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

      const result = await anthropicText(parseEventSystemPrompt(), userText);
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
      const result = await anthropicText(null, prompt);
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

      const result = await anthropicText(systemPrompt, question);
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
      const result = await anthropicText(null, prompt);
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

  if (pathname.startsWith('/api/claude/')) {
    await handleClaudeRoute(req, res, pathname);
    return;
  }

  serveStatic(req, res);
});

server.listen(PORT, HOST, () => {
  console.log(`DayBrief server running at http://${HOST}:${PORT}`);
  if (!ANTHROPIC_API_KEY) {
    console.log('Set ANTHROPIC_API_KEY before starting to enable AI routes.');
  }
});
