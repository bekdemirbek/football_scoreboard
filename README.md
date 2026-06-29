# ⚽ Maçkart — Football Scoreboard

A Flutter app for live football scores, league standings, and detailed match
info — lineups on a real pitch diagram, goal scorers, and head-to-head
statistics — built with Riverpod and two free public football APIs.

[![CI](https://github.com/bekdemirbek/football_scoreboard/actions/workflows/ci.yml/badge.svg)](https://github.com/bekdemirbek/football_scoreboard/actions/workflows/ci.yml)
[![Deploy Web Demo](https://github.com/bekdemirbek/football_scoreboard/actions/workflows/deploy.yml/badge.svg)](https://github.com/bekdemirbek/football_scoreboard/actions/workflows/deploy.yml)

**🔗 Live demo:** https://bekdemirbek.github.io/football_scoreboard/

> The public demo runs without the API-Football key (see [Known limitations](#known-limitations)
> below), so the Matches and Standings tabs show live data while the match-detail
> lineup/stats tabs show a friendly "no data" notice. Run it locally with your own
> key to see the full feature set.

## Screenshots

| Matches | Standings (grouped) | Match detail — lineup pitch |
|---|---|---|
| ![Matches](docs/screenshots/matches.png) | ![Standings](docs/screenshots/standings.png) | ![Match detail](docs/screenshots/match_detail.png) |

*(Add your own screenshots to `docs/screenshots/` — see the filenames above.)*

## Features

- **Maçlar (Matches)** — browse fixtures by date and league, live-match pulse
  indicator, favorite-team markers.
- **Puan Tablosu (Standings)** — league table with promotion/relegation zone
  colors; tournaments with multiple groups (e.g. the World Cup) render each
  group as its own table, plus a knockout-bracket section (Last 32 → Final)
  once the group stage is over.
- **Match detail** — a tabbed view per match:
  - **Maç** — full event timeline (goals with scorer + assist, cards,
    substitutions)
  - **Kadro** — both starting XIs drawn on an actual pitch diagram, positioned
    from the API's formation grid, plus substitutes and the coach
  - **İstatistik** — possession, shots, cards, etc. as home-vs-away bars
- **Favoriler** — persisted favorite teams (SharedPreferences).
- **Dark / light theme** with a custom `ThemeExtension` for the app's
  football-specific palette (live red, gold, zone colors).

## Architecture

Riverpod-based, feature-first layout:

```
lib/
├── core/            # Theming (ThemeData + custom AppColors extension)
├── models/          # Plain data classes, defensive multi-shape JSON parsing
├── services/         # HTTP clients (football-data.org, API-Football)
├── providers/        # Riverpod Notifiers — the "ViewModel" layer
└── features/
    ├── home/        # Bottom-nav shell
    ├── matches/      # Match list + match detail (events/lineups/stats tabs)
    └── standings/    # League table + knockout bracket
```

- **State management:** `flutter_riverpod` — `AsyncNotifierProvider` for
  remote collections (`matchesProvider`, `standingsProvider`,
  `knockoutMatchesProvider`), `FutureProvider.family` for per-match detail
  (`matchDetailProvider`), plain `NotifierProvider` for UI selection state.
- **Two independent data sources**, each behind its own service class:
  [football-data.org](https://www.football-data.org/) for fixtures/standings,
  [API-Football](https://www.api-football.com/) for lineups/events/statistics
  (cross-referenced by date + fuzzy team-name matching, since the two APIs use
  unrelated IDs).
- **Graceful degradation everywhere:** every async section has an explicit
  loading / empty / error state — a missing or rate-limited API response never
  crashes a screen, it falls back to an inline notice.

## Tech stack

| | |
|---|---|
| Framework | Flutter (Dart ^3.9) |
| State management | `flutter_riverpod` 3.x |
| HTTP | `dio` |
| Persistence | `shared_preferences` |
| Testing | `flutter_test` — unit, widget, and golden tests |
| CI/CD | GitHub Actions — analyze/format/test on every push, automatic web deploy to GitHub Pages |

## Known limitations

- **API-Football free plan** only allows fixture lookups within a 3-day
  rolling window (yesterday/today/tomorrow) and a 100 requests/day cap. Match
  detail (lineups/events/stats) is therefore only available for matches inside
  that window — older or future fixtures show a "no data" notice by design,
  not as a bug.
- The public web demo intentionally **does not embed the API-Football key**
  (see `.github/workflows/deploy.yml`) to avoid a single visitor exhausting the
  shared daily quota. The Matches/Standings tabs still use a real
  football-data.org key and work normally.
- Local development against both APIs from Flutter Web requires the small
  Node proxy in `tools/api_proxy/` (CORS workaround); native/mobile builds can
  call the APIs directly.

## Getting started

```bash
flutter pub get

cp .env.example .env
# fill in FOOTBALL_DATA_API_KEY (free: https://www.football-data.org/client/register)
# and API_FOOTBALL_KEY (free: https://dashboard.api-football.com/register)

# Mobile / desktop — reads .env via --dart-define-from-file
flutter run --dart-define-from-file=.env

# Web — needs the local proxy for CORS
node tools/api_proxy/server.mjs &
flutter run -d chrome --dart-define=API_PROXY_URL=http://localhost:8787
```

## Testing

```bash
flutter analyze
dart format --output=none --set-exit-if-changed .
flutter test                 # unit + widget + golden tests
flutter test --update-goldens  # regenerate golden images after an intentional UI change
```

Tests cover the Riverpod providers (with a fake `Dio` adapter, no real network
calls), the match-detail page's loading/empty/data states, and golden
(pixel-diff) regression tests for key widgets.

## Roadmap

- [ ] Full **Favoriler** tab: live/recent/upcoming matches for favorited teams
- [ ] **Gol Kralları** (top scorers) page
- [ ] Local caching for offline support
