class Match {
  const Match({
    required this.id,
    required this.homeTeam,
    required this.awayTeam,
    this.homeTeamId,
    this.awayTeamId,
    this.homeScore,
    this.awayScore,
    this.date,
    this.time,
    this.league,
    this.leagueId,
    this.status,
    this.venue,
    this.stage,
  });

  final String id;
  final String homeTeam;
  final String awayTeam;
  final String? homeTeamId;
  final String? awayTeamId;
  final int? homeScore;
  final int? awayScore;
  final DateTime? date;
  final String? time;
  final String? league;
  final String? leagueId;
  final String? status;
  final String? venue;
  final String? stage;

  static const _knockoutStages = {
    'LAST_32',
    'LAST_16',
    'ROUND_OF_16',
    'QUARTER_FINALS',
    'QUARTER_FINAL',
    'SEMI_FINALS',
    'SEMI_FINAL',
    'THIRD_PLACE',
    'FINAL',
  };

  static bool isKnockoutStage(String? stage) =>
      stage != null && _knockoutStages.contains(stage.toUpperCase());

  String get scoreText {
    if (homeScore == null || awayScore == null) return 'vs';
    return '$homeScore - $awayScore';
  }

  String get title => '$homeTeam - $awayTeam';

  factory Match.fromJson(Map<String, dynamic> json) {
    final statusJson = json['status'];
    final statusMap = statusJson is Map<String, dynamic> ? statusJson : null;
    final reasonJson = statusMap?['reason'];
    final reasonMap = reasonJson is Map<String, dynamic> ? reasonJson : null;
    final competition = _asMap(json['competition']);
    final homeTeam = _asMap(json['homeTeam']);
    final awayTeam = _asMap(json['awayTeam']);
    final score = _asMap(json['score']);
    final fullTime = _asMap(score?['fullTime']);
    final halfTime = _asMap(score?['halfTime']);

    return Match(
      id: _firstString(json, ['idEvent', 'eventId', 'matchId', 'id']) ?? '',
      homeTeam:
          _firstString(json, [
            'strHomeTeam',
            'homeTeamName',
            'homeTeam',
            'homeName',
            'home_team',
            'teamHomeName',
          ]) ??
          _nestedName(homeTeam) ??
          'Ev Sahibi',
      awayTeam:
          _firstString(json, [
            'strAwayTeam',
            'awayTeamName',
            'awayTeam',
            'awayName',
            'away_team',
            'teamAwayName',
          ]) ??
          _nestedName(awayTeam) ??
          'Deplasman',
      homeTeamId:
          _firstString(json, ['idHomeTeam', 'homeTeamId', 'homeId']) ??
          _firstString(homeTeam ?? const {}, ['id']),
      awayTeamId:
          _firstString(json, ['idAwayTeam', 'awayTeamId', 'awayId']) ??
          _firstString(awayTeam ?? const {}, ['id']),
      homeScore: _toInt(
        json['intHomeScore'] ??
            json['homeTeamScore'] ??
            json['homeScore'] ??
            json['homeGoals'] ??
            fullTime?['home'] ??
            halfTime?['home'],
      ),
      awayScore: _toInt(
        json['intAwayScore'] ??
            json['awayTeamScore'] ??
            json['awayScore'] ??
            json['awayGoals'] ??
            fullTime?['away'] ??
            halfTime?['away'],
      ),
      date: DateTime.tryParse(
        _firstString(json, [
              'utcDate',
              'dateEvent',
              'matchDate',
              'date',
              'startTime',
            ]) ??
            '',
      ),
      time:
          _firstString(json, ['strTime', 'time', 'matchTime']) ??
          _firstString(statusMap ?? const {}, ['utcTime']),
      league:
          _firstString(json, ['strLeague', 'leagueName', 'league']) ??
          _firstString(competition ?? const {}, ['name']),
      leagueId:
          _firstString(json, ['idLeague', 'leagueId']) ??
          _firstString(competition ?? const {}, ['code', 'id']),
      status:
          _firstString(json, ['strStatus', 'matchStatus', 'status']) ??
          _firstString(reasonMap ?? const {}, ['short']) ??
          _statusFromFlags(statusMap),
      venue: _firstString(json, ['strVenue', 'venue', 'stadium']),
      stage: _firstString(json, ['strStage', 'stage']),
    );
  }

  static String? _statusFromFlags(Map<String, dynamic>? status) {
    if (status == null) return null;
    if (status['finished'] == true) return 'FINISHED';
    if (status['started'] == true) return 'IN_PLAY';
    if (status['cancelled'] == true) return 'CANCELLED';
    return null;
  }

  static Map<String, dynamic>? _asMap(Object? value) {
    return value is Map<String, dynamic> ? value : null;
  }

  static String? _nestedName(Object? value) {
    if (value is Map<String, dynamic>) {
      return _firstString(value, [
        'name',
        'shortName',
        'tla',
        'strTeam',
        'teamName',
      ]);
    }
    return null;
  }

  static String? _firstString(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is Map || value is List) continue;
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }
    return null;
  }

  static int? _toInt(Object? value) {
    if (value == null) return null;
    return int.tryParse(value.toString());
  }
}
