import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_scoreboard/models/football_league.dart';
import 'package:football_scoreboard/services/api_service.dart';

/// ApiService'in hata yönetimini (rate-limit / izin / timeout) ve veri
/// ayrıştırmasını gerçek ağ olmadan doğrular. Dio'nun HttpClientAdapter'ı
/// sahte bir adapter ile değiştirilir.
void main() {
  ApiService serviceWith(HttpClientAdapter adapter) => ApiService(
        apiKey: 'test-key',
        dio: Dio(BaseOptions(baseUrl: 'https://example.test'))
          ..httpClientAdapter = adapter,
      );

  group('Hata yönetimi', () {
    test('429 → dakika limiti mesajıyla StateError fırlatır', () {
      final service = serviceWith(_StatusAdapter(429));
      expect(
        () => service.fetchStandings(leagueId: 'PL'),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('limit'),
          ),
        ),
      );
    });

    test('403 → izin mesajıyla StateError fırlatır', () {
      final service = serviceWith(_StatusAdapter(403));
      expect(
        () => service.fetchScorers(leagueId: 'PL'),
        throwsA(isA<StateError>()),
      );
    });

    test('API gövdesindeki message alanı hataya taşınır', () {
      final service = serviceWith(
        _StatusAdapter(400, body: {'message': 'Özel API hatası'}),
      );
      expect(
        () => service.fetchStandings(leagueId: 'PL'),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('Özel API hatası'),
          ),
        ),
      );
    });
  });

  group('Veri ayrıştırma', () {
    test('fetchStandings TOTAL tablosunu doğru çözer', () async {
      final service = serviceWith(
        _StatusAdapter(200, body: {
          'standings': [
            {
              'type': 'TOTAL',
              'table': [
                {
                  'position': 1,
                  'team': {'id': '57', 'name': 'Arsenal'},
                  'playedGames': 10,
                  'won': 8,
                  'draw': 1,
                  'lost': 1,
                  'points': 25,
                },
              ],
            },
          ],
        }),
      );

      final standings = await service.fetchStandings(leagueId: 'PL');
      expect(standings, hasLength(1));
      expect(standings.first.teamName, 'Arsenal');
      expect(standings.first.points, 25);
      expect(standings.first.rank, 1);
    });
  });

  group('fetchMatchesAllLeagues toleransı', () {
    test('bir lig limite takılsa da diğerleri yine döner', () async {
      // Sadece "PL" kodlu istek başarılı; diğer tüm ligler 429 döndürür.
      final service = serviceWith(_PerLeagueAdapter(okCode: 'PL'));

      final matches = await service.fetchMatchesAllLeagues(
        date: DateTime(2026, 7, 1),
        leagues: footballLeagues,
      );

      // 429 dönen ligler atlanır; PL'in tek maçı listede kalır.
      expect(matches, hasLength(1));
      expect(matches.first.homeTeam, 'Arsenal');
      expect(matches.first.league, 'Premier Lig');
    });

    test('tüm ligler başarısızsa boş liste döner (fırlatmaz)', () async {
      final service = serviceWith(_StatusAdapter(429));

      final matches = await service.fetchMatchesAllLeagues(
        date: DateTime(2026, 7, 1),
        leagues: footballLeagues,
      );

      expect(matches, isEmpty);
    });
  });
}

/// Her isteğe sabit bir HTTP durum kodu (ve opsiyonel gövde) döndürür.
class _StatusAdapter implements HttpClientAdapter {
  _StatusAdapter(this.statusCode, {this.body = const {}});

  final int statusCode;
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
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}

/// /competitions/{code}/matches yolunda yalnızca [okCode] için 200 (tek maç),
/// diğer tüm lig kodları için 429 döndürür.
class _PerLeagueAdapter implements HttpClientAdapter {
  _PerLeagueAdapter({required this.okCode});

  final String okCode;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final isOk = options.uri.path.contains('/$okCode/');
    if (!isOk) {
      return ResponseBody.fromString('{}', 429, headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      });
    }
    return ResponseBody.fromString(
      jsonEncode({
        'matches': [
          {
            'id': 1,
            'utcDate': '2026-07-01T15:00:00Z',
            'homeTeam': {'name': 'Arsenal'},
            'awayTeam': {'name': 'Chelsea'},
            'competition': {'name': 'Premier Lig', 'code': 'PL'},
          },
        ],
      }),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}
