import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_scoreboard/models/football_league.dart';
import 'package:football_scoreboard/models/scorer.dart';
import 'package:football_scoreboard/providers/api_providers.dart';
import 'package:football_scoreboard/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  // ── Scorer model ───────────────────────────────────────────────────────────

  group('Scorer.fromJson', () {
    test('parses standard football-data.org scorers response', () {
      final json = {
        'player': {
          'name': 'Erling Haaland',
          'nationality': 'Norway',
          'position': 'Centre-Forward',
        },
        'team': {'name': 'Manchester City FC', 'shortName': 'Man City'},
        'goals': 27,
        'assists': 5,
        'penalties': 3,
        'playedMatches': 35,
      };

      final scorer = Scorer.fromJson(json, rank: 1);

      expect(scorer.rank, 1);
      expect(scorer.playerName, 'Erling Haaland');
      expect(scorer.teamName, 'Manchester City FC');
      expect(scorer.goals, 27);
      expect(scorer.assists, 5);
      expect(scorer.penalties, 3);
      expect(scorer.playedMatches, 35);
      expect(scorer.nationality, 'Norway');
    });

    test('rank is assigned from the parameter, not JSON', () {
      final scorer = Scorer.fromJson({
        'player': {},
        'team': {},
        'goals': 10,
      }, rank: 4);
      expect(scorer.rank, 4);
    });

    test('defaults missing numeric fields to 0', () {
      final scorer = Scorer.fromJson({
        'player': {'name': 'Test Player'},
        'team': {'name': 'FC Test'},
      }, rank: 1);
      expect(scorer.goals, 0);
      expect(scorer.assists, 0);
      expect(scorer.penalties, 0);
    });

    test('falls back to generic name when player map is empty', () {
      final scorer = Scorer.fromJson({'goals': 5}, rank: 1);
      expect(scorer.playerName, 'Bilinmeyen Oyuncu');
    });
  });

  // ── selectedScorersLeagueProvider ─────────────────────────────────────────

  group('selectedScorersLeagueProvider', () {
    test('defaults to Premier League', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(selectedScorersLeagueProvider).id, 'PL');
    });

    test('selectLeague updates the state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final bundesliga = footballLeagues.firstWhere((l) => l.id == 'BL1');
      container
          .read(selectedScorersLeagueProvider.notifier)
          .selectLeague(bundesliga);

      expect(container.read(selectedScorersLeagueProvider).id, 'BL1');
    });

    test('selectLeague ignores leagues with null id', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      const nullLeague = FootballLeague(id: null, name: 'Unknown');
      container
          .read(selectedScorersLeagueProvider.notifier)
          .selectLeague(nullLeague);

      // Should still be PL (default), not the null-id league
      expect(container.read(selectedScorersLeagueProvider).id, 'PL');
    });
  });

  // ── scorersProvider ────────────────────────────────────────────────────────

  group('scorersProvider', () {
    test('returns parsed scorers list', () async {
      final container = ProviderContainer(
        overrides: [
          apiServiceProvider.overrideWithValue(
            ApiService(
              apiKey: 'test',
              dio: Dio(BaseOptions(baseUrl: 'https://example.test'))
                ..httpClientAdapter = _FakeAdapter({
                  'scorers': [
                    {
                      'player': {
                        'name': 'Erling Haaland',
                        'nationality': 'Norway',
                      },
                      'team': {'name': 'Manchester City FC'},
                      'goals': 27,
                      'assists': 5,
                      'penalties': 3,
                      'playedMatches': 35,
                    },
                    {
                      'player': {
                        'name': 'Mohamed Salah',
                        'nationality': 'Egypt',
                      },
                      'team': {'name': 'Liverpool FC'},
                      'goals': 22,
                      'assists': 13,
                      'penalties': 2,
                      'playedMatches': 35,
                    },
                  ],
                }),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final scorers = await container.read(scorersProvider.future);

      expect(scorers, hasLength(2));
      expect(scorers[0].rank, 1);
      expect(scorers[0].playerName, 'Erling Haaland');
      expect(scorers[0].goals, 27);
      expect(scorers[1].rank, 2);
      expect(scorers[1].playerName, 'Mohamed Salah');
    });

    test('returns empty list when API returns no scorers', () async {
      final container = ProviderContainer(
        overrides: [
          apiServiceProvider.overrideWithValue(
            ApiService(
              apiKey: 'test',
              dio: Dio(BaseOptions(baseUrl: 'https://example.test'))
                ..httpClientAdapter = _FakeAdapter({'scorers': []}),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final scorers = await container.read(scorersProvider.future);
      expect(scorers, isEmpty);
    });

    test('reacts to league change and refetches', () async {
      var requestedCode = '';

      final container = ProviderContainer(
        overrides: [
          apiServiceProvider.overrideWithValue(
            ApiService(
              apiKey: 'test',
              dio: Dio(BaseOptions(baseUrl: 'https://example.test'))
                ..httpClientAdapter = _RecordingAdapter({
                  'scorers': [],
                }, onRequest: (path) => requestedCode = path),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(scorersProvider.future);
      expect(requestedCode, contains('PL'));

      final laliga = footballLeagues.firstWhere((l) => l.id == 'PD');
      container
          .read(selectedScorersLeagueProvider.notifier)
          .selectLeague(laliga);

      await container.read(scorersProvider.future);
      expect(requestedCode, contains('PD'));
    });
  });
}

// ─── Fake adapters ─────────────────────────────────────────────────────────────

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

class _RecordingAdapter implements HttpClientAdapter {
  _RecordingAdapter(this.body, {required this.onRequest});
  final Map<String, dynamic> body;
  final void Function(String path) onRequest;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    onRequest(options.uri.path);
    return ResponseBody.fromString(
      jsonEncode(body),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}
