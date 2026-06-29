# Local API Proxy

Flutter Web tarayicida API token'ini direkt kullanmak CORS ve token gorunurlugu problemi yaratir. Bu proxy `.env` icindeki football-data.org token'ini server tarafinda tutar.

## Calistirma

```bash
node tools/api_proxy/server.mjs
```

Flutter Web'i proxy ile baslat:

```bash
flutter run -d chrome --dart-define=API_PROXY_URL=http://localhost:8787
```

`.env` icinde su degerler olmali:

```env
FOOTBALL_DATA_API_KEY=...
FOOTBALL_DATA_BASE_URL=https://api.football-data.org/v4
API_FOOTBALL_KEY=...
API_PROXY_PORT=8787
```

Proxy, `/api-football/...` ile baslayan istekleri `v3.football.api-sports.io`'ya
(`x-apisports-key` header'i ile), digerlerini football-data.org'a yonlendirir.
