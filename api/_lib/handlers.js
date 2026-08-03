'use strict';

const https = require('https');

const ANTHROPIC_API_KEY = process.env.ANTHROPIC_API_KEY;
const CLAUDE_MODEL = process.env.CLAUDE_MODEL || 'claude-3-5-sonnet-20241022';
const CLAUDE_MAX_TOKENS = Number(process.env.CLAUDE_MAX_TOKENS || 1024);
const GEMINI_API_KEY = process.env.GEMINI_API_KEY;
const GEMINI_MODEL = process.env.GEMINI_MODEL || 'gemini-2.0-flash';
const GEMINI_MAX_TOKENS = Number(process.env.GEMINI_MAX_TOKENS || 1024);
const LLM_PROVIDER = GEMINI_API_KEY
  ? 'gemini'
  : ANTHROPIC_API_KEY
    ? 'anthropic'
    : null;
const GOOGLE_MAPS_API_KEY =
  process.env.GOOGLE_MAPS_API_KEY || process.env.GOOGLE_PLACES_API_KEY || '';

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

function handleOptions(req, res) {
  if (req.method === 'OPTIONS') {
    res.writeHead(204, corsHeaders());
    res.end();
    return true;
  }
  return false;
}

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

function httpsGetJson(url) {
  return new Promise((resolve, reject) => {
    https
      .get(url, (response) => {
        const chunks = [];
        response.on('data', (chunk) => chunks.push(chunk));
        response.on('end', () => {
          try {
            const body = Buffer.concat(chunks).toString('utf8');
            resolve({
              statusCode: response.statusCode,
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

async function anthropicText(systemPrompt, userPrompt) {
  const upstream = await callAnthropic({ systemPrompt, userPrompt });
  if (upstream.statusCode !== 200) {
    return {
      ok: false,
      statusCode: upstream.statusCode,
      headers: {},
      error: `API Error: ${upstream.statusCode} - ${upstream.body}`,
    };
  }
  const data = JSON.parse(upstream.body);
  return {
    ok: true,
    statusCode: 200,
    headers: {},
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
  if (upstream.statusCode !== 200) {
    return {
      ok: false,
      statusCode: upstream.statusCode,
      headers: {},
      error: `Gemini API Error: ${upstream.statusCode} - ${upstream.body}`,
    };
  }
  const data = JSON.parse(upstream.body);
  return {
    ok: true,
    statusCode: 200,
    headers: {},
    text: data.candidates?.[0]?.content?.parts?.[0]?.text ?? '',
  };
}

async function llmText(systemPrompt, userPrompt) {
  if (LLM_PROVIDER === 'gemini') return geminiText(systemPrompt, userPrompt);
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

function requireLlm(res) {
  if (!LLM_PROVIDER) {
    sendJson(res, 503, {
      success: false,
      error:
        'AI proxy is not configured. Set GEMINI_API_KEY or ANTHROPIC_API_KEY.',
    });
    return false;
  }
  return true;
}

async function parseEvent(req, res) {
  if (handleOptions(req, res)) return;
  if (!requireLlm(res)) return;
  if (req.method !== 'POST') {
    sendJson(res, 405, { success: false, error: 'Method not allowed' });
    return;
  }

  let body;
  try {
    body = await readJsonBody(req);
  } catch (_) {
    sendJson(res, 400, { success: false, error: 'Invalid JSON body' });
    return;
  }

  const userText = body.userText;
  const userId = body.userId || '';
  if (!userText || typeof userText !== 'string') {
    sendJson(res, 400, { success: false, error: 'userText is required' });
    return;
  }

  const result = await llmText(parseEventSystemPrompt(), userText);
  if (!result.ok) {
    sendJson(res, result.statusCode === 429 ? 429 : 502, {
      success: false,
      error: result.error,
    });
    return;
  }

  const json = JSON.parse(cleanJsonText(result.text));
  if (json.error) {
    sendJson(res, 200, { success: false, error: json.error });
    return;
  }

  sendJson(res, 200, {
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
  });
}

async function dailySummary(req, res) {
  if (handleOptions(req, res)) return;
  if (!requireLlm(res)) return;
  if (req.method !== 'POST') {
    sendJson(res, 405, { success: false, error: 'Method not allowed' });
    return;
  }

  let body;
  try {
    body = await readJsonBody(req);
  } catch (_) {
    sendJson(res, 400, { success: false, error: 'Invalid JSON body' });
    return;
  }

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
    sendJson(res, result.statusCode === 429 ? 429 : 502, {
      success: false,
      text: 'Unable to generate summary',
      error: result.error,
    });
    return;
  }
  sendJson(res, 200, { success: true, text: result.text });
}

async function answerQuestion(req, res) {
  if (handleOptions(req, res)) return;
  if (!requireLlm(res)) return;
  if (req.method !== 'POST') {
    sendJson(res, 405, { success: false, error: 'Method not allowed' });
    return;
  }

  let body;
  try {
    body = await readJsonBody(req);
  } catch (_) {
    sendJson(res, 400, { success: false, error: 'Invalid JSON body' });
    return;
  }

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
    sendJson(res, result.statusCode === 429 ? 429 : 502, {
      success: false,
      text: 'Unable to answer right now',
      error: result.error,
    });
    return;
  }
  sendJson(res, 200, { success: true, text: result.text });
}

async function smartSuggestions(req, res) {
  if (handleOptions(req, res)) return;
  if (!requireLlm(res)) return;
  if (req.method !== 'POST') {
    sendJson(res, 405, { success: false, error: 'Method not allowed' });
    return;
  }

  let body;
  try {
    body = await readJsonBody(req);
  } catch (_) {
    sendJson(res, 400, { success: false, error: 'Invalid JSON body' });
    return;
  }

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
    sendJson(res, result.statusCode === 429 ? 429 : 502, {
      success: false,
      text: 'No suggestions available',
      error: result.error,
    });
    return;
  }
  sendJson(res, 200, { success: true, text: result.text });
}

async function placesAutocomplete(req, res) {
  if (handleOptions(req, res)) return;
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

  const url = new URL(req.url, 'http://localhost');
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
  if (
    result.data.status &&
    result.data.status !== 'OK' &&
    result.data.status !== 'ZERO_RESULTS'
  ) {
    sendJson(res, 502, {
      success: false,
      error:
        result.data.error_message ||
        result.data.status ||
        'Places request failed',
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
}

module.exports = {
  parseEvent,
  dailySummary,
  answerQuestion,
  smartSuggestions,
  placesAutocomplete,
};
