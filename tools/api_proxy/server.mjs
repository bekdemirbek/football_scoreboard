import { createServer } from 'node:http';
import { readFileSync, existsSync } from 'node:fs';

const env = readEnv();
const footballDataKey = env.FOOTBALL_DATA_API_KEY;
const footballDataBaseUrl = env.FOOTBALL_DATA_BASE_URL || 'https://api.football-data.org/v4';
const apiFootballKey = env.API_FOOTBALL_KEY;
const apiFootballBaseUrl = 'https://v3.football.api-sports.io';
const port = Number(env.API_PROXY_PORT || 8787);

if (!footballDataKey) {
  console.error('FOOTBALL_DATA_API_KEY .env dosyasinda yok.');
  process.exit(1);
}

const server = createServer(async (req, res) => {
  setCorsHeaders(res);

  if (req.method === 'OPTIONS') {
    res.writeHead(204);
    res.end();
    return;
  }

  try {
    const requestUrl = new URL(req.url || '/', `http://localhost:${port}`);
    const isApiFootball = requestUrl.pathname.startsWith('/api-football/');

    if (isApiFootball && !apiFootballKey) {
      res.writeHead(500, { 'content-type': 'application/json' });
      res.end(JSON.stringify({ error: 'API_FOOTBALL_KEY .env dosyasinda yok.' }));
      return;
    }

    const targetBase = isApiFootball ? apiFootballBaseUrl : trimTrailingSlash(footballDataBaseUrl);
    const targetPath = isApiFootball
      ? requestUrl.pathname.slice('/api-football'.length)
      : requestUrl.pathname;
    const targetUrl = new URL(`${targetBase}${targetPath}`);
    targetUrl.search = requestUrl.search;

    const upstream = await fetch(targetUrl, {
      signal: AbortSignal.timeout(10000),
      headers: isApiFootball
        ? { 'x-apisports-key': apiFootballKey }
        : { 'X-Auth-Token': footballDataKey },
    });

    const body = await upstream.text();
    res.writeHead(upstream.status, {
      'content-type': upstream.headers.get('content-type') || 'application/json',
    });
    res.end(body);
  } catch (error) {
    res.writeHead(500, { 'content-type': 'application/json' });
    res.end(JSON.stringify({ error: 'Proxy request failed or timed out', detail: String(error) }));
  }
});

server.listen(port, () => {
  console.log(`API proxy hazir: http://localhost:${port} (football-data.org + api-football)`);
});

function setCorsHeaders(res) {
  res.setHeader('access-control-allow-origin', '*');
  res.setHeader('access-control-allow-methods', 'GET,OPTIONS');
  res.setHeader('access-control-allow-headers', 'content-type');
}

function trimTrailingSlash(value) {
  return value.endsWith('/') ? value.slice(0, -1) : value;
}

function readEnv() {
  if (!existsSync('.env')) return process.env;

  const values = { ...process.env };
  const content = readFileSync('.env', 'utf8');
  for (const line of content.split(/\r?\n/)) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith('#')) continue;

    const separatorIndex = trimmed.indexOf('=');
    if (separatorIndex === -1) continue;

    const key = trimmed.slice(0, separatorIndex).trim();
    const value = trimmed.slice(separatorIndex + 1).trim();
    values[key] = value;
  }

  return values;
}
