import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_scoreboard/models/football_league.dart';
import 'package:football_scoreboard/providers/api_providers.dart';
import 'package:football_scoreboard/services/api_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('selectedMatchDateProvider normalizes to date-only and updates', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container
        .read(selectedMatchDateProvider.notifier)
        .selectDate(DateTime(2026, 6, 29, 14, 30));

    final value = container.read(selectedMatchDateProvider);
    expect(value, DateTime(2026, 6, 29));
  });

  test('selectedLeagueProvider switches league on demand', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final bundesliga = footballLeagues.firstWhere((l) => l.id == 'BL1');
    container.read(selectedLeagueProvider.notifier).selectLeague(bundesliga);

    expect(container.read(selectedLeagueProvider).id, 'BL1');
  });

  test('favoriteTeamsProvider toggles and persists team names', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container.read(favoriteTeamsProvider.future);
    await container.read(favoriteTeamsProvider.notifier).toggle('Arsenal FC');

    expect(container.read(favoriteTeamsProvider).value, {'Arsenal FC'});

    await container.read(favoriteTeamsProvider.notifier).toggle('Arsenal FC');

    expect(container.read(favoriteTeamsProvider).value, isEmpty);
  });

  test(
    'knockoutMatchesProvider skips the extra request for single-group standings',
    () async {
      var matchesRequested = false;
      final container = ProviderContainer(
        overrides: [
          apiServiceProvider.overrideWithValue(
            ApiService(
              apiKey: 'test',
              dio: Dio(BaseOptions(baseUrl: 'https://example.test'))
                ..httpClientAdapter = _RoutedFakeAdapter(
                  {
                    '/competitions/PL/standings': {
                      'standings': [
                        {
                          'type': 'TOTAL',
                          'table': [
                            {
                              'position': 1,
                              'team': {'id': 57, 'name': 'Arsenal FC'},
                              'playedGames': 1,
                              'won': 1,
                              'draw': 0,
                              'lost': 0,
                              'points': 3,
                            },
                          ],
                        },
                      ],
                    },
                  },
                  onRequest: (path) {
                    if (path.contains('/matches')) matchesRequested = true;
                  },
                ),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final knockout = await container.read(knockoutMatchesProvider.future);

      expect(knockout, isEmpty);
      expect(matchesRequested, isFalse);
    },
  );

  test(
    'knockoutMatchesProvider fetches and sorts knockout-stage matches for multi-group tournaments',
    () async {
      final container = ProviderContainer(
        overrides: [
          selectedStandingsLeagueProvider.overrideWith(
            () => _FixedLeagueNotifier(
              footballLeagues.firstWhere((l) => l.id == 'WC'),
            ),
          ),
          apiServiceProvider.overrideWithValue(
            ApiService(
              apiKey: 'test',
              dio: Dio(BaseOptions(baseUrl: 'https://example.test'))
                ..httpClientAdapter = _RoutedFakeAdapter({
                  '/competitions/WC/standings': {
                    'standings': [
                      {
                        'type': 'TOTAL',
                        'group': 'Group A',
                        'table': [
                          {
                            'position': 1,
                            'team': {'id': 1, 'name': 'Mexico'},
                            'playedGames': 3,
                            'won': 3,
                            'draw': 0,
                            'lost': 0,
                            'points': 9,
                          },
                        ],
                      },
                      {
                        'type': 'TOTAL',
                        'group': 'Group B',
                        'table': [
                          {
                            'position': 1,
                            'team': {'id': 2, 'name': 'Brazil'},
                            'playedGames': 3,
                            'won': 2,
                            'draw': 1,
                            'lost': 0,
                            'points': 7,
                          },
                        ],
                      },
                    ],
                  },
                  '/competitions/WC/matches': {
                    'matches': [
                      {
                        'id': 2,
                        'utcDate': '2026-07-05T18:00:00Z',
                        'stage': 'FINAL',
                        'homeTeam': {'name': 'Brazil'},
                        'awayTeam': {'name': 'Mexico'},
                      },
                      {
                        'id': 1,
                        'utcDate': '2026-06-29T18:00:00Z',
                        'stage': 'LAST_32',
                        'homeTeam': {'name': 'Brazil'},
                        'awayTeam': {'name': 'Japan'},
                      },
                      {
                        'id': 3,
                        'utcDate': '2026-06-20T18:00:00Z',
                        'stage': 'GROUP_STAGE',
                        'homeTeam': {'name': 'Brazil'},
                        'awayTeam': {'name': 'Serbia'},
                      },
                    ],
                  },
                }),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final knockout = await container.read(knockoutMatchesProvider.future);

      expect(knockout, hasLength(2));
      expect(knockout.first.stage, 'LAST_32');
      expect(knockout.last.stage, 'FINAL');
    },
  );
  test('teamsProvider exposes loaded teams', () async {
    final container = ProviderContainer(
      overrides: [
        apiServiceProvider.overrideWithValue(
          ApiService(
            apiKey: 'test',
            dio: Dio(BaseOptions(baseUrl: 'https://example.test'))
              ..httpClientAdapter = _FakeAdapter({
                'teams': [
                  {
                    'id': 57,
                    'name': 'Arsenal FC',
                    'crest': 'https://example.test/arsenal.png',
                    'area': {'name': 'England'},
                  },
                ],
              }),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    final teams = await container.read(teamsProvider.future);

    expect(teams, hasLength(1));
    expect(teams.first.name, 'Arsenal FC');
  });

  test('matchesProvider exposes loaded matches', () async {
    final container = ProviderContainer(
      overrides: [
        apiServiceProvider.overrideWithValue(
          ApiService(
            apiKey: 'test',
            dio: Dio(BaseOptions(baseUrl: 'https://example.test'))
              ..httpClientAdapter = _FakeAdapter({
                'matches': [
                  {
                    'id': 1,
                    'utcDate': '2026-06-29T18:00:00Z',
                    'status': 'FINISHED',
                    'competition': {'code': 'PL', 'name': 'Premier League'},
                    'homeTeam': {'id': 57, 'name': 'Arsenal FC'},
                    'awayTeam': {'id': 61, 'name': 'Chelsea FC'},
                    'score': {
                      'fullTime': {'home': 2, 'away': 1},
                    },
                  },
                ],
              }),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    final matches = await container.read(matchesProvider.future);

    expect(matches, hasLength(1));
    expect(matches.first.homeScore, 2);
    expect(matches.first.homeTeam, 'Arsenal FC');
  });

  test('standingsProvider exposes loaded standings', () async {
    final container = ProviderContainer(
      overrides: [
        apiServiceProvider.overrideWithValue(
          ApiService(
            apiKey: 'test',
            dio: Dio(BaseOptions(baseUrl: 'https://example.test'))
              ..httpClientAdapter = _FakeAdapter({
                'standings': [
                  {
                    'type': 'TOTAL',
                    'table': [
                      {
                        'position': 1,
                        'team': {'id': 57, 'name': 'Arsenal FC'},
                        'playedGames': 38,
                        'won': 28,
                        'draw': 6,
                        'lost': 4,
                        'points': 90,
                      },
                    ],
                  },
                ],
              }),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    final standings = await container.read(standingsProvider.future);

    expect(standings, hasLength(1));
    expect(standings.first.points, 90);
    expect(standings.first.teamName, 'Arsenal FC');
  });
}

class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.body);

  final Map<String, dynamic> body;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      jsonEncode(body),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}

class _RoutedFakeAdapter implements HttpClientAdapter {
  _RoutedFakeAdapter(this.responses, {this.onRequest});

  final Map<String, dynamic> responses;
  final void Function(String path)? onRequest;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    onRequest?.call(options.uri.path);
    final body = responses[options.uri.path] ?? const {};
    return ResponseBody.fromString(
      jsonEncode(body),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}

class _FixedLeagueNotifier extends SelectedStandingsLeagueNotifier {
  _FixedLeagueNotifier(this._league);
  final FootballLeague _league;

  @override
  FootballLeague build() => _league;
}
