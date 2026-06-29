import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_scoreboard/models/favorite_team.dart';
import 'package:football_scoreboard/providers/api_providers.dart';
import 'package:football_scoreboard/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  // ── FavoriteTeam model ─────────────────────────────────────────────────────

  group('FavoriteTeam', () {
    test('serialises and deserialises correctly', () {
      const team = FavoriteTeam(id: '57', name: 'Arsenal FC', crestUrl: 'https://example.test/crest.png');
      final json = team.toJson();
      final roundTripped = FavoriteTeam.fromJson(json);

      expect(roundTripped.id, '57');
      expect(roundTripped.name, 'Arsenal FC');
      expect(roundTripped.crestUrl, 'https://example.test/crest.png');
    });

    test('equality is by id when id is non-empty', () {
      const a = FavoriteTeam(id: '57', name: 'Arsenal FC');
      const b = FavoriteTeam(id: '57', name: 'Arsenal'); // same id, different name
      expect(a, equals(b));
    });

    test('equality falls back to name when id is empty', () {
      const a = FavoriteTeam(id: '', name: 'Arsenal FC');
      const b = FavoriteTeam(id: '', name: 'Arsenal FC');
      const c = FavoriteTeam(id: '', name: 'Chelsea FC');
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    test('listFromPrefs handles legacy plain-string entries', () {
      final teams = FavoriteTeam.listFromPrefs(['Arsenal FC', 'Chelsea FC']);
      expect(teams, hasLength(2));
      expect(teams.first.name, 'Arsenal FC');
      expect(teams.first.id, '');
    });

    test('listFromPrefs handles JSON entries', () {
      final raw = [
        jsonEncode({'id': '57', 'name': 'Arsenal FC'}),
        jsonEncode({'id': '61', 'name': 'Chelsea FC', 'crestUrl': 'https://x.test'}),
      ];
      final teams = FavoriteTeam.listFromPrefs(raw);
      expect(teams.first.id, '57');
      expect(teams.last.crestUrl, 'https://x.test');
    });
  });

  // ── favoriteTeamsProvider ──────────────────────────────────────────────────

  group('favoriteTeamsProvider', () {
    test('starts empty', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final teams = await container.read(favoriteTeamsProvider.future);
      expect(teams, isEmpty);
    });

    test('toggle adds a team', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(favoriteTeamsProvider.future);
      await container.read(favoriteTeamsProvider.notifier).toggle(
        const FavoriteTeam(id: '57', name: 'Arsenal FC'),
      );

      expect(container.read(favoriteTeamsProvider).value, hasLength(1));
      expect(container.read(favoriteTeamsProvider).value!.first.name, 'Arsenal FC');
    });

    test('toggle removes a team that is already in the list', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(favoriteTeamsProvider.future);
      const arsenal = FavoriteTeam(id: '57', name: 'Arsenal FC');
      await container.read(favoriteTeamsProvider.notifier).toggle(arsenal);
      await container.read(favoriteTeamsProvider.notifier).toggle(arsenal);

      expect(container.read(favoriteTeamsProvider).value, isEmpty);
    });

    test('isFavorite returns true for a stored team', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(favoriteTeamsProvider.future);
      const team = FavoriteTeam(id: '57', name: 'Arsenal FC');
      await container.read(favoriteTeamsProvider.notifier).toggle(team);

      expect(container.read(favoriteTeamsProvider.notifier).isFavorite(team), isTrue);
    });

    test('isFavoriteByName matches by name', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(favoriteTeamsProvider.future);
      await container.read(favoriteTeamsProvider.notifier).toggle(
        const FavoriteTeam(id: '57', name: 'Arsenal FC'),
      );

      expect(
        container.read(favoriteTeamsProvider.notifier).isFavoriteByName('Arsenal FC'),
        isTrue,
      );
      expect(
        container.read(favoriteTeamsProvider.notifier).isFavoriteByName('Chelsea FC'),
        isFalse,
      );
    });

    test('persists across container recreations via SharedPreferences', () async {
      final container1 = ProviderContainer();
      await container1.read(favoriteTeamsProvider.future);
      await container1.read(favoriteTeamsProvider.notifier).toggle(
        const FavoriteTeam(id: '57', name: 'Arsenal FC'),
      );
      container1.dispose();

      final container2 = ProviderContainer();
      addTearDown(container2.dispose);
      final teams = await container2.read(favoriteTeamsProvider.future);

      expect(teams, hasLength(1));
      expect(teams.first.name, 'Arsenal FC');
    });
  });

  // ── teamMatchesProvider ────────────────────────────────────────────────────

  group('teamMatchesProvider', () {
    test('returns matches for the given team id', () async {
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
                      'utcDate': '2026-06-20T18:00:00Z',
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

      final matches = await container.read(teamMatchesProvider('57').future);

      expect(matches, hasLength(1));
      expect(matches.first.homeTeam, 'Arsenal FC');
      expect(matches.first.homeScore, 2);
    });

    test('returns empty list when API returns no matches', () async {
      final container = ProviderContainer(
        overrides: [
          apiServiceProvider.overrideWithValue(
            ApiService(
              apiKey: 'test',
              dio: Dio(BaseOptions(baseUrl: 'https://example.test'))
                ..httpClientAdapter = _FakeAdapter({'matches': []}),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final matches = await container.read(teamMatchesProvider('57').future);
      expect(matches, isEmpty);
    });
  });
}

// ─── Helpers ───────────────────────────────────────────────────────────────────

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
