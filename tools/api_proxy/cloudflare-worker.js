/**
 * Cloudflare Worker — public API proxy for the GitHub Pages web demo.
 *
 * football-data.org only allows the browser Origin `http://localhost`, so the
 * deployed web app (https://bekdemirbek.github.io) cannot call it directly.
 * This Worker calls the APIs server-side (no CORS there) with the token kept
 * in a Worker Secret, and returns the response with permissive CORS headers.
 *
 * Setup (Cloudflare dashboard, free, no card):
 *   1. Workers & Pages → Create → Worker → deploy the default.
 *   2. Edit code → paste this file → Deploy.
 *   3. Settings → Variables and Secrets → add Secret:
 *        FOOTBALL_DATA_API_KEY = <your football-data.org token>   (required)
 *        API_FOOTBALL_KEY      = <your api-football key>          (optional)
 *   4. Copy the *.workers.dev URL → set it as the repo Actions Variable
 *      API_PROXY_URL (see .github/workflows/deploy.yml).
 *
 * Requests:
 *   /api-football/<path>  → https://v3.football.api-sports.io/<path>  (x-apisports-key)
 *   /<anything-else>      → https://api.football-data.org/v4/<path>   (X-Auth-Token)
 */

const FOOTBALL_DATA_BASE = 'https://api.football-data.org/v4';
const API_FOOTBALL_BASE = 'https://v3.football.api-sports.io';

// Only these origins may use the proxy (keeps it from being an open relay).
const ALLOWED_ORIGINS = [
  'https://bekdemirbek.github.io',
  'http://localhost',
  'http://localhost:8787',
];

export default {
  async fetch(request, env) {
    const origin = request.headers.get('Origin') || '';
    const allowOrigin = ALLOWED_ORIGINS.includes(origin)
      ? origin
      : ALLOWED_ORIGINS[0];

    const cors = {
      'access-control-allow-origin': allowOrigin,
      'access-control-allow-methods': 'GET,OPTIONS',
      'access-control-allow-headers': 'content-type',
      vary: 'Origin',
    };

    if (request.method === 'OPTIONS') {
      return new Response(null, { status: 204, headers: cors });
    }

    const url = new URL(request.url);
    const isApiFootball = url.pathname.startsWith('/api-football/');

    let target;
    let headers;
    if (isApiFootball) {
      if (!env.API_FOOTBALL_KEY) {
        return json({ error: 'API_FOOTBALL_KEY not configured' }, 500, cors);
      }
      target =
        API_FOOTBALL_BASE +
        url.pathname.slice('/api-football'.length) +
        url.search;
      headers = { 'x-apisports-key': env.API_FOOTBALL_KEY };
    } else {
      if (!env.FOOTBALL_DATA_API_KEY) {
        return json({ error: 'FOOTBALL_DATA_API_KEY not configured' }, 500, cors);
      }
      target = FOOTBALL_DATA_BASE + url.pathname + url.search;
      headers = { 'X-Auth-Token': env.FOOTBALL_DATA_API_KEY };
    }

    try {
      const upstream = await fetch(target, { headers });
      const body = await upstream.text();
      return new Response(body, {
        status: upstream.status,
        headers: {
          ...cors,
          'content-type':
            upstream.headers.get('content-type') || 'application/json',
        },
      });
    } catch (err) {
      return json({ error: 'Proxy request failed', detail: String(err) }, 502, cors);
    }
  },
};

function json(obj, status, cors) {
  return new Response(JSON.stringify(obj), {
    status,
    headers: { ...cors, 'content-type': 'application/json' },
  });
}
