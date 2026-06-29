import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_scoreboard/core/app_theme.dart';
import 'package:football_scoreboard/features/matches/match_detail_page.dart';
import 'package:football_scoreboard/models/match.dart';
import 'package:football_scoreboard/providers/api_providers.dart';
import 'package:football_scoreboard/services/api_football_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  final match = Match(
    id: '1',
    homeTeam: 'Brazil',
    awayTeam: 'Japan',
    date: DateTime.utc(2026, 6, 29),
    status: 'FINISHED',
  );

  testWidgets(
    'match detail page renders events, lineups and statistics sections',
    (tester) async {
      final apiFootball = ApiFootballService(
        apiKey: 'test',
        dio: Dio(BaseOptions(baseUrl: 'https://example.test'))
          ..httpClientAdapter = _RoutedFakeAdapter({
            '/fixtures': {
              'response': [
                {
                  'fixture': {'id': 999},
                  'teams': {
                    'home': {'id': 6, 'name': 'Brazil'},
                    'away': {'id': 12, 'name': 'Japan'},
                  },
                },
              ],
            },
            '/fixtures/events': {
              'response': [
                {
                  'time': {'elapsed': 56, 'extra': null},
                  'team': {'id': 6, 'name': 'Brazil'},
                  'player': {'id': 1, 'name': 'Casemiro'},
                  'assist': {'id': 2, 'name': 'Gabriel'},
                  'type': 'Goal',
                  'detail': 'Normal Goal',
                },
              ],
            },
            '/fixtures/lineups': {
              'response': [
                {
                  'team': {'id': 6, 'name': 'Brazil'},
                  'formation': '4-3-3',
                  'startXI': [
                    {
                      'player': {
                        'id': 10,
                        'name': 'Alisson',
                        'number': 1,
                        'pos': 'G',
                      },
                    },
                  ],
                  'substitutes': [],
                  'coach': {'name': 'Carlo Ancelotti'},
                },
                {
                  'team': {'id': 12, 'name': 'Japan'},
                  'formation': '3-4-2-1',
                  'startXI': [
                    {
                      'player': {
                        'id': 20,
                        'name': 'Zion Suzuki',
                        'number': 1,
                        'pos': 'G',
                      },
                    },
                  ],
                  'substitutes': [],
                  'coach': {'name': 'Moriyasu'},
                },
              ],
            },
            '/fixtures/statistics': {
              'response': [
                {
                  'team': {'id': 6, 'name': 'Brazil'},
                  'statistics': [
                    {'type': 'Ball Possession', 'value': '67%'},
                  ],
                },
                {
                  'team': {'id': 12, 'name': 'Japan'},
                  'statistics': [
                    {'type': 'Ball Possession', 'value': '33%'},
                  ],
                },
              ],
            },
          }),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiFootballServiceProvider.overrideWithValue(apiFootball),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: MatchDetailPage(match: match),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Maç'), findsOneWidget);
      expect(find.textContaining('Casemiro'), findsWidgets);
      expect(find.text('Kadro'), findsOneWidget);
      expect(find.text('İstatistik'), findsOneWidget);
    },
  );

  testWidgets(
    'match detail page shows a graceful notice when no fixture is found',
    (tester) async {
      final apiFootball = ApiFootballService(
        apiKey: 'test',
        dio: Dio(BaseOptions(baseUrl: 'https://example.test'))
          ..httpClientAdapter = _RoutedFakeAdapter({
            '/fixtures': {'response': []},
          }),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiFootballServiceProvider.overrideWithValue(apiFootball),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: MatchDetailPage(match: match),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.textContaining('detay verisi bulunamadı'), findsOneWidget);
    },
  );
}

class _RoutedFakeAdapter implements HttpClientAdapter {
  _RoutedFakeAdapter(this.responses);

  final Map<String, Map<String, dynamic>> responses;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final body = responses[options.uri.path] ?? const {'response': []};
    return ResponseBody.fromString(
      jsonEncode(body),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}
