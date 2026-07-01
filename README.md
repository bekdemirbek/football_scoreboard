# ⚽ Maçkart — Football Scoreboard

A Flutter app for **live football scores, standings, top scorers/assists, match
detail (lineups on a real pitch, stats, events), team squads**, plus two
**prediction mini-games** and a **100-question football quiz** — built with
Riverpod on top of two real public football APIs.

[![CI](https://github.com/bekdemirbek/football_scoreboard/actions/workflows/ci.yml/badge.svg)](https://github.com/bekdemirbek/football_scoreboard/actions/workflows/ci.yml)
[![Deploy Web Demo](https://github.com/bekdemirbek/football_scoreboard/actions/workflows/deploy.yml/badge.svg)](https://github.com/bekdemirbek/football_scoreboard/actions/workflows/deploy.yml)

**🔗 Live demo:** https://bekdemirbek.github.io/football_scoreboard/

> Dark-only, fully Turkish UI. Design language: near-black + emerald green + gold,
> team **abbreviations instead of logos**, gradient-bordered cards, skeleton
> loaders, and an explicit loading / error / empty state on every async screen.

<!-- Screenshots / demo GIF — add later:
     capture the app, drop files in docs/, then restore this section, e.g.
     ![Demo](docs/demo.gif)
     | Canlı Skorlar | Puan Durumu | Gol/Asist Krallığı | Futbol Quiz |
     |---|---|---|---|
     | ![](docs/screenshots/matches.png) | ![](docs/screenshots/standings.png) | ![](docs/screenshots/scorers.png) | ![](docs/screenshots/quiz.png) |
-->

## Features

**Bottom navigation — 5 tabs**

- **Canlı Skorlar (Matches)** — fixtures by day (Dün/Bugün/Yarın) + league filter
  incl. a **"Tüm Ligler"** option that merges every configured league into one
  list, grouped per league; live-match cards with a gradient border + pulse;
  in-header team search.
- **Puan Durumu (Standings)** — league table with European/relegation zone
  colors; group-stage tournaments render one table per group plus a knockout
  bracket; **tap a team → squad screen**; in-header search.
- **Gol / Asist Krallığı (Top Scorers)** — a Goals⇄Assists toggle re-ranks the
  same dataset; clean gradient-ranked rows; search.
- **Oyunlar (Games)** — three sub-games:
  - **Sıralama Tahmini** — drag teams (shuffled alphabetically so the answer
    isn't given away) into your predicted final order, then score it against the
    live table (exact = 3, ±1 = 2, ±2 = 1).
  - **Gol Kralı Tahmini** — pick the future top scorer; goal counts & ranks are
    hidden so it's a real guess; instant "currently #N" feedback.
  - **Futbol Quiz** — 10 random questions from a 100-question / 8-category local
    pool, timed, with a persistent leaderboard.
- **Favoriler (Favorites)** — persisted favorite teams + per-team match history.

**Match detail** (pushed) — tabbed: event timeline · both starting XIs on a real
pitch diagram · possession/shots/etc. as home-vs-away bars.

## Architecture

Layered, feature-first. The data flows in one direction:

```
┌──────────────┐   ref.watch/read    ┌──────────────┐   calls    ┌──────────────┐   parses   ┌──────────────┐
│   Widget     │ ─────────────────▶  │   Provider   │ ─────────▶ │   Service    │ ─────────▶ │    Model     │
│ (features/)  │ ◀─────────────────  │ (Riverpod    │ ◀───────── │ (Dio / asset)│ ◀───────── │ (fromJson)   │
└──────────────┘   AsyncValue<T>     │  Notifier)   │   Future<T>└──────────────┘            └──────────────┘
      UI                             └──────────────┘
   no HTTP,                          the "ViewModel":              HTTP clients +             plain data,
   no parsing                        state + orchestration         asset loading              defensive parsing
```

- **Widget** never touches HTTP or JSON — it only watches a provider and renders
  `AsyncValue.when(loading / error / data)`.
- **Provider (Riverpod Notifier)** is the ViewModel: holds UI/selection state,
  orchestrates calls, exposes `AsyncValue`. All providers live in
  [`lib/providers/api_providers.dart`](lib/providers/api_providers.dart).
- **Service** is the only layer that does I/O — two HTTP clients + one asset
  loader. Concrete classes, injected into providers (so they're swapped for
  fakes in tests).
- **Model** is a plain immutable class with a defensive `fromJson` (the two APIs
  return different shapes, so parsing tolerates multiple key names).

### Why a Service layer but no Repository?

A Repository indirection earns its keep when you have **multiple/​switchable data
sources behind one domain interface**, offline caching to merge, or you need to
mock at the domain boundary. Here:

- Each screen maps to **one** endpoint on one API; there's no "same data from DB
  or network" decision to hide.
- Services are already **injectable and faked in tests** (see below), so a
  `Repository` wouldn't add testability — only a passthrough layer.
- Riverpod's Notifier *is* the orchestration/ViewModel layer, which is where
  a Repository's coordination logic would otherwise sit.

So `Service` is the boundary. If a second source with caching/merging were added
(e.g. a Hive offline cache fronting the network), **that** is when I'd introduce
a Repository to hide the source decision — and the current Notifier→Service call
sites are the exact seam where it would slot in.

### State management (Riverpod)

- `AsyncNotifierProvider` for remote collections: `matchesProvider`,
  `standingsProvider`, `scorersProvider`, `knockoutMatchesProvider`, plus the
  persisted `favoriteTeamsProvider`, `predictionsProvider`, `quizLeaderboardProvider`.
- `FutureProvider.family` for per-key fetches: `matchDetailProvider(match)`,
  `teamSquadProvider(teamId)`.
- Plain `NotifierProvider` for selection/UI state (selected date, per-tab league,
  goals/assists mode, search queries, active quiz).
- No code-gen, no `StateNotifier` — the whole codebase uses the modern
  `Notifier` / `AsyncNotifier` API consistently.

## Data sources & rate-limit handling

Two independent APIs, each behind its own service:

| Source | Used for | Client |
|---|---|---|
| [football-data.org](https://www.football-data.org/) | fixtures, standings, scorers, **team squad** | `ApiService` |
| [API-Football](https://www.api-football.com/) | match detail: lineups / events / statistics | `ApiFootballService` |

The two APIs use unrelated IDs, so match detail is **cross-referenced by date +
fuzzy team-name matching** (normalized, FC/CF/AC suffixes stripped).

**Rate-limit / failure handling** ([`lib/services/api_service.dart`](lib/services/api_service.dart)):

- `429` → a clear "minute limit reached, try again" `StateError` (surfaced as an
  in-screen retry notice, never a crash).
- `403` → "restricted on the free plan / invalid token" message.
- Per-request **12s timeout** wrapping the Dio call.
- **"Tüm Ligler"** fans out across ~10 leagues in **batches of 3**, and each
  league's fetch is wrapped in try/catch so a single rate-limited league is
  skipped while the rest still render (`fetchMatchesAllLeagues`).
- Every provider is `AsyncValue`, so loading/empty/error are explicit UI states.

### CORS & the hosted proxy (why the live demo needs one)

football-data.org's browser CORS policy only allows the Origin `http://localhost`
(its preflight returns `Access-Control-Allow-Origin: http://localhost`). So a
static GitHub Pages site (`https://bekdemirbek.github.io`) **cannot call the API
directly from the browser** — it's blocked, regardless of the key.

The fix is a tiny **proxy that calls the API server-side** (no CORS there) and
returns permissive CORS headers, with the token kept in the proxy's env — never
in the web bundle. Two forms ship in [`tools/api_proxy/`](tools/api_proxy/):

- `server.mjs` — Node proxy for **local** web dev.
- `cloudflare-worker.js` — a deploy-ready **Cloudflare Worker** for the hosted
  demo. The CI build reads the repo Actions Variable `API_PROXY_URL` and points
  the web app at it; the key lives only in the Worker's secret.

## Security — API keys

- Keys come from `--dart-define` (`String.fromEnvironment`) — **nothing is
  hardcoded** in source.
- **`.env` is git-ignored** (`.gitignore` allows only `.env.example`); no secret
  is ever committed. Verified: `git ls-files` shows only `.env.example`.
- ⚠️ **Caveat (honest):** `String.fromEnvironment` is a *compile-time* constant,
  so if you build a mobile **APK/IPA with `--dart-define=KEY=...`, the key is
  baked into the binary** and is recoverable by decompiling. For a real release
  the correct pattern is to **not ship the key in the client at all** and route
  through a backend/proxy — which this project does for web (Node proxy locally,
  a hosted **Cloudflare Worker** for the live demo; both keep the token
  server-side and fix CORS — see [`tools/api_proxy/`](tools/api_proxy/)). For
  production mobile you'd point the app at that same proxy/backend.

## Tech stack

| | |
|---|---|
| Framework | Flutter (Dart ^3.9), dark-only |
| State management | `flutter_riverpod` 3.x (`Notifier` / `AsyncNotifier`, no codegen) |
| HTTP | `dio` |
| Persistence | `shared_preferences` (favorites, predictions, quiz leaderboard) |
| Testing | `flutter_test` — service unit tests (faked `Dio`), provider tests, widget + golden |
| CI/CD | GitHub Actions — analyze/format/test on push, web deploy to Pages |

## Getting started

```bash
flutter pub get

cp .env.example .env
# fill FOOTBALL_DATA_API_KEY (free: https://www.football-data.org/client/register)
# and    API_FOOTBALL_KEY   (free: https://dashboard.api-football.com/register)
```

**Web** (keys stay server-side in the proxy — recommended):

```bash
node tools/api_proxy/server.mjs          # terminal 1 — reads .env, serves :8787
flutter run -d chrome --dart-define=API_PROXY_URL=http://localhost:8787   # terminal 2
```

**Mobile / desktop** (dev only — note the binary-embedding caveat above):

```bash
flutter run --dart-define-from-file=.env
# or route it through the same proxy: --dart-define=API_PROXY_URL=http://<host>:8787
```

## Testing

```bash
flutter analyze
dart format --output=none --set-exit-if-changed .
flutter test                    # unit + provider + widget + golden
flutter test --update-goldens   # regenerate goldens after an intentional UI change
```

Coverage highlights (priority: **Service > Provider > Widget**):

- **Service** — `ApiService` error handling with a faked `Dio` adapter (no real
  network): `429`/`403`/custom-message paths, standings parsing, and the
  "Tüm Ligler" batch **tolerance** (one league fails → others still return).
- **Provider** — `QuizLeaderboardNotifier` ordering rule (score desc, tie → time
  asc) and `shared_preferences` persistence across containers.
- **Logic/Widget** — quiz option-shuffle correctness, match-detail
  loading/empty/data states, and golden regression for match cards.

## Project structure

```
lib/
├── core/app_theme.dart          # design system: colors, gradients, text, LiveMatchCard, StatBar
├── models/                      # plain data + fromJson (match, standing, scorer, team_squad, quiz_*, …)
├── services/                    # ApiService, ApiFootballService, QuizService (I/O boundary)
├── providers/api_providers.dart # every Riverpod provider / Notifier (the ViewModel layer)
├── features/                    # feature-first UI
│   ├── home/ matches/ standings/ scorers/ favorites/ games/ quiz/ team/
└── widgets/                     # shared: screen_header (ScreenHeader + SegmentedTabs), team_badge, shimmer, …
assets/data/quiz_questions.json  # 100 questions, 8 categories
tools/api_proxy/server.mjs       # Node proxy for web (CORS + server-side token)
```

## Scalability note

The flat `features/<x>/` layout is comfortable at the current ~8 features. Beyond
~20 it would grow along two axes: (1) split `widgets/` and `core/` into a real
**shared/ design-system module** and lift cross-feature models into a `domain/`
layer; (2) if features start depending on each other, introduce a light **DI/
service-locator** seam (or per-feature provider files instead of one global
`api_providers.dart`) so wiring stays explicit. The Notifier→Service boundary is
already the natural place to slot a Repository + cache when a second data source
appears.

## Roadmap

- [x] Full **Favoriler** tab + per-team history
- [x] **Gol/Asist Krallığı**, **Tüm Ligler**, **team squad**, prediction games, **Futbol Quiz**
- [ ] Offline cache (Hive TTL) → would introduce a Repository layer
- [ ] Route mobile through the proxy by default (drop client-side keys entirely)
```
