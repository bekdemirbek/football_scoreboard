import 'dart:async';

import 'package:dio/dio.dart';

import '../models/football_league.dart';
import '../models/match.dart';
import '../models/scorer.dart';
import '../models/standing.dart';
import '../models/team.dart';

class ApiService {
  ApiService({
    Dio? dio,
    required String apiKey,
    String baseUrl = 'https://api.football-data.org/v4',
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
           );

  final Dio _dio;

  static String _baseUrl({required String baseUrl, String? proxyUrl}) {
    final normalizedProxy = proxyUrl?.trim();
    if (normalizedProxy != null && normalizedProxy.isNotEmpty) {
      return _trimTrailingSlash(normalizedProxy);
    }

    return _trimTrailingSlash(baseUrl);
  }

  static Map<String, String> _headers({
    required String apiKey,
    String? proxyUrl,
  }) {
    final hasProxy = proxyUrl != null && proxyUrl.trim().isNotEmpty;
    if (hasProxy) return const {};

    if (apiKey.trim().isEmpty) {
      throw StateError(
        'FOOTBALL_DATA_API_KEY yok. Web icin proxy baslatip API_PROXY_URL ile calistir.',
      );
    }

    return {'X-Auth-Token': apiKey};
  }

  Future<List<Match>> fetchMatches({
    required DateTime date,
    required FootballLeague league,
  }) async {
    final code = _competitionCode(league.id);
    final day = _formatDate(date);

    final response =
        await _get(
          '/competitions/$code/matches',
          queryParameters: {'dateFrom': day, 'dateTo': day},
        ).timeout(
          const Duration(seconds: 12),
          onTimeout: () =>
              throw TimeoutException('API istegi zaman asimina ugradi.'),
        );

    final matches = _readList(
      response.data,
      preferredKeys: const ['matches'],
    ).map(Match.fromJson).toList(growable: false);

    matches.sort((a, b) {
      final aDate = a.date ?? DateTime(0);
      final bDate = b.date ?? DateTime(0);
      return aDate.compareTo(bDate);
    });

    return matches;
  }

  Future<List<Team>> fetchTeams({
    String endpoint = '/competitions/PL/teams',
    String query = 'Arsenal',
  }) async {
    final response = await _get(endpoint);
    return _readList(
      response.data,
      preferredKeys: const ['teams'],
    ).map(Team.fromJson).toList(growable: false);
  }

  Future<List<Standing>> fetchStandings({String? leagueId}) async {
    final code = _competitionCode(leagueId);
    final response = await _get('/competitions/$code/standings');
    final standingsRoot = response.data?['standings'];

    if (standingsRoot is! List) return const <Standing>[];

    var entries = standingsRoot
        .whereType<Map<String, dynamic>>()
        .where((item) => item['type'] == 'TOTAL')
        .toList(growable: false);
    if (entries.isEmpty) {
      entries = standingsRoot.whereType<Map<String, dynamic>>().toList(
        growable: false,
      );
    }

    final standings = <Standing>[];
    for (final entry in entries) {
      final table = entry['table'];
      if (table is! List) continue;
      final group = entry['group']?.toString();
      standings.addAll(
        table.whereType<Map<String, dynamic>>().map(
          (row) => Standing.fromJson(row, group: group),
        ),
      );
    }
    return standings;
  }

  Future<List<Scorer>> fetchScorers({String? leagueId, int limit = 20}) async {
    final code = _competitionCode(leagueId);
    final response = await _get(
      '/competitions/$code/scorers',
      queryParameters: {'limit': limit},
    ).timeout(
      const Duration(seconds: 12),
      onTimeout: () =>
          throw TimeoutException('API istegi zaman asimina ugradi.'),
    );

    final raw = _readList(
      response.data,
      preferredKeys: const ['scorers'],
    );

    return raw
        .asMap()
        .entries
        .map((e) => Scorer.fromJson(e.value, rank: e.key + 1))
        .toList(growable: false);
  }

  Future<List<Match>> fetchTeamMatches(
    String teamId, {
    int pastDays = 45,
    int futureDays = 45,
  }) async {
    final now = DateTime.now();
    final from = _formatDate(now.subtract(Duration(days: pastDays)));
    final to = _formatDate(now.add(Duration(days: futureDays)));

    final response = await _get(
      '/teams/$teamId/matches',
      queryParameters: {'dateFrom': from, 'dateTo': to},
    ).timeout(
      const Duration(seconds: 12),
      onTimeout: () =>
          throw TimeoutException('API istegi zaman asimina ugradi.'),
    );

    final matches = _readList(response.data, preferredKeys: const ['matches'])
        .map(Match.fromJson)
        .toList(growable: false);

    matches.sort((a, b) {
      final aDate = a.date ?? DateTime(0);
      final bDate = b.date ?? DateTime(0);
      return aDate.compareTo(bDate);
    });

    return matches;
  }

  Future<List<Match>> fetchKnockoutMatches({String? leagueId}) async {
    final code = _competitionCode(leagueId);
    final response = await _get('/competitions/$code/matches');

    final matches = _readList(
      response.data,
      preferredKeys: const ['matches'],
    ).map(Match.fromJson).where((m) => Match.isKnockoutStage(m.stage)).toList();

    matches.sort((a, b) {
      final aDate = a.date ?? DateTime(0);
      final bDate = b.date ?? DateTime(0);
      return aDate.compareTo(bDate);
    });

    return matches;
  }

  Future<Map<String, dynamic>> fetchRawSample({
    String endpoint = '/competitions/PL/matches',
    String search = '',
  }) async {
    final now = DateTime.now();
    final day = _formatDate(now);
    final response = await _get(
      endpoint,
      queryParameters: {'dateFrom': day, 'dateTo': day},
    );

    return response.data ?? <String, dynamic>{};
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
      final statusCode = error.response?.statusCode;
      final message = _apiMessage(error.response?.data);

      if (statusCode == 403) {
        throw StateError(
          message ??
              'football-data.org bu lige/endpoint\'e free planda izin vermiyor veya token gecersiz.',
        );
      }
      if (statusCode == 429) {
        throw StateError(
          'football-data.org dakika limiti doldu. Biraz bekleyip tekrar dene.',
        );
      }

      throw StateError(
        message ?? 'API istegi basarisiz oldu. HTTP durum kodu: $statusCode',
      );
    }
  }

  List<Map<String, dynamic>> _readList(
    Map<String, dynamic>? json, {
    List<String> preferredKeys = const [
      'matches',
      'standings',
      'teams',
      'table',
      'results',
      'data',
      'response',
    ],
  }) {
    if (json == null) return const [];
    final found = _findFirstList(json, preferredKeys);
    return found?.whereType<Map<String, dynamic>>().toList(growable: false) ??
        const [];
  }

  List<dynamic>? _findFirstList(Object? value, List<String> preferredKeys) {
    if (value is List) return value;
    if (value is! Map<String, dynamic>) return null;

    for (final key in preferredKeys) {
      final child = value[key];
      final list = _findFirstList(child, preferredKeys);
      if (list != null) return list;
    }

    for (final child in value.values) {
      final list = _findFirstList(child, preferredKeys);
      if (list != null) return list;
    }

    return null;
  }

  String _competitionCode(String? leagueId) {
    if (leagueId == null || leagueId.trim().isEmpty) return 'PL';
    return leagueId.trim();
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    final year = local.year.toString().padLeft(4, '0');
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  static String _trimTrailingSlash(String value) {
    return value.endsWith('/') ? value.substring(0, value.length - 1) : value;
  }

  String? _apiMessage(Object? data) {
    if (data is Map<String, dynamic>) {
      final message = data['message'] ?? data['error'];
      if (message != null && message.toString().trim().isNotEmpty) {
        return message.toString();
      }
    }
    return null;
  }
}
