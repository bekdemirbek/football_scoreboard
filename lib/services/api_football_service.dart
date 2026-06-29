import 'package:dio/dio.dart';

import '../models/match.dart';
import '../models/match_detail.dart';
import '../models/match_event.dart';
import '../models/match_lineup.dart';
import '../models/match_statistic.dart';

class ApiFootballService {
  ApiFootballService({
    Dio? dio,
    required String apiKey,
    String baseUrl = 'https://v3.football.api-sports.io',
    String? proxyUrl,
  }) : _dio =
           dio ??
           Dio(
             BaseOptions(
               baseUrl: _baseUrl(baseUrl: baseUrl, proxyUrl: proxyUrl),
               connectTimeout: const Duration(seconds: 10),
               receiveTimeout: const Duration(seconds: 10),
               headers: _headers(apiKey: apiKey, proxyUrl: proxyUrl),
             ),
           ),
       _hasCredentials =
           (proxyUrl != null && proxyUrl.trim().isNotEmpty) ||
           apiKey.trim().isNotEmpty;

  final Dio _dio;
  final bool _hasCredentials;

  static String _baseUrl({required String baseUrl, String? proxyUrl}) {
    final normalizedProxy = proxyUrl?.trim();
    if (normalizedProxy != null && normalizedProxy.isNotEmpty) {
      return '${_trimTrailingSlash(normalizedProxy)}/api-football';
    }
    return _trimTrailingSlash(baseUrl);
  }

  static Map<String, String> _headers({
    required String apiKey,
    String? proxyUrl,
  }) {
    final hasProxy = proxyUrl != null && proxyUrl.trim().isNotEmpty;
    if (hasProxy || apiKey.trim().isEmpty) return const {};
    return {'x-apisports-key': apiKey};
  }

  Future<MatchDetail> fetchMatchDetail({required Match match}) async {
    if (!_hasCredentials) {
      return MatchDetail.unavailable('API-Football anahtarı tanımlı değil.');
    }

    final matchDate = match.date;
    if (matchDate == null) {
      return MatchDetail.unavailable('Maç tarihi bilinmiyor.');
    }

    Map<String, dynamic>? fixture;
    try {
      fixture = await _findFixture(match: match, date: matchDate);
    } on StateError catch (error) {
      return MatchDetail.unavailable(error.message);
    } catch (_) {
      return MatchDetail.unavailable('Detay verisine ulaşılamadı.');
    }

    if (fixture == null) {
      return MatchDetail.unavailable(
        'Bu maç için detay verisi bulunamadı. Ücretsiz API planında yalnızca '
        'güncel tarihli maçlar desteklenir.',
      );
    }

    final fixtureId = (fixture['fixture']?['id'] as num?)?.toInt();
    if (fixtureId == null) {
      return MatchDetail.unavailable('Maç kimliği bulunamadı.');
    }

    final teams = fixture['teams'] as Map<String, dynamic>? ?? const {};
    final homeTeamId = (teams['home']?['id'] as num?)?.toInt();
    final awayTeamId = (teams['away']?['id'] as num?)?.toInt();

    final results = await Future.wait([
      _fetchEvents(fixtureId),
      _fetchLineups(fixtureId),
      _fetchStatistics(fixtureId),
    ]);

    final events = results[0] as List<MatchEvent>;
    final lineups = results[1] as List<TeamLineup>;
    final statRows = results[2] as List<MatchStatRow>;

    TeamLineup? homeLineup;
    TeamLineup? awayLineup;
    for (final lineup in lineups) {
      if (lineup.teamId == homeTeamId) {
        homeLineup = lineup;
      } else if (lineup.teamId == awayTeamId) {
        awayLineup = lineup;
      }
    }

    return MatchDetail(
      available: true,
      events: events,
      homeLineup: homeLineup,
      awayLineup: awayLineup,
      statRows: statRows,
      apiHomeTeamId: homeTeamId,
      apiAwayTeamId: awayTeamId,
    );
  }

  Future<Map<String, dynamic>?> _findFixture({
    required Match match,
    required DateTime date,
  }) async {
    final day = _formatDate(date.toUtc());
    final response = await _get('/fixtures', queryParameters: {'date': day});
    final list = (response.data?['response'] as List? ?? const [])
        .whereType<Map<String, dynamic>>();

    final homeKey = _normalizeTeamName(match.homeTeam);
    final awayKey = _normalizeTeamName(match.awayTeam);

    for (final item in list) {
      final teams = item['teams'] as Map<String, dynamic>? ?? const {};
      final homeName = _normalizeTeamName(
        teams['home']?['name']?.toString() ?? '',
      );
      final awayName = _normalizeTeamName(
        teams['away']?['name']?.toString() ?? '',
      );

      final homeMatches =
          homeName.isNotEmpty &&
          (homeName == homeKey ||
              homeName.contains(homeKey) ||
              homeKey.contains(homeName));
      final awayMatches =
          awayName.isNotEmpty &&
          (awayName == awayKey ||
              awayName.contains(awayKey) ||
              awayKey.contains(awayName));

      if (homeMatches && awayMatches) return item;
    }
    return null;
  }

  Future<List<MatchEvent>> _fetchEvents(int fixtureId) async {
    try {
      final response = await _get(
        '/fixtures/events',
        queryParameters: {'fixture': fixtureId},
      );
      final list = (response.data?['response'] as List? ?? const [])
          .whereType<Map<String, dynamic>>();
      final events = list.map(MatchEvent.fromJson).toList(growable: false);
      events.sort((a, b) => a.minute.compareTo(b.minute));
      return events;
    } catch (_) {
      return const [];
    }
  }

  Future<List<TeamLineup>> _fetchLineups(int fixtureId) async {
    try {
      final response = await _get(
        '/fixtures/lineups',
        queryParameters: {'fixture': fixtureId},
      );
      final list = (response.data?['response'] as List? ?? const [])
          .whereType<Map<String, dynamic>>();
      return list.map(TeamLineup.fromJson).toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  Future<List<MatchStatRow>> _fetchStatistics(int fixtureId) async {
    try {
      final response = await _get(
        '/fixtures/statistics',
        queryParameters: {'fixture': fixtureId},
      );
      final list = (response.data?['response'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .toList();
      if (list.length < 2) return const [];

      final homeStats = (list[0]['statistics'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .toList();
      final awayStats = (list[1]['statistics'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .toList();
      return MatchStatRow.buildRows(homeStats: homeStats, awayStats: awayStats);
    } catch (_) {
      return const [];
    }
  }

  Future<Response<Map<String, dynamic>>> _get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.get<Map<String, dynamic>>(
        path,
        queryParameters: queryParameters,
      );
    } on DioException catch (error) {
      final message = _apiMessage(error.response?.data);
      throw StateError(message ?? 'API-Football isteği başarısız oldu.');
    }
  }

  String? _apiMessage(Object? data) {
    if (data is Map<String, dynamic>) {
      final errors = data['errors'];
      if (errors is Map && errors.isNotEmpty) {
        return errors.values.first.toString();
      }
      if (errors is List && errors.isNotEmpty) {
        return errors.first.toString();
      }
    }
    return null;
  }

  String _normalizeTeamName(String name) {
    var n = name.toLowerCase();
    n = n.replaceAll(RegExp(r'\b(fc|cf|afc|sc|ac|cd|ud|rc|sad)\b'), '');
    n = n.replaceAll(RegExp(r'[^a-z0-9]'), '');
    return n;
  }

  String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  static String _trimTrailingSlash(String value) {
    return value.endsWith('/') ? value.substring(0, value.length - 1) : value;
  }
}
