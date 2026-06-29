import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_scoreboard/providers/api_providers.dart';
import 'package:football_scoreboard/services/api_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
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
