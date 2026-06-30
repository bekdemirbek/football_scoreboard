class Scorer {
  const Scorer({
    required this.rank,
    required this.playerName,
    required this.teamName,
    required this.goals,
    this.assists = 0,
    this.penalties = 0,
    this.playedMatches,
    this.nationality,
    this.position,
  });

  final int rank;
  final String playerName;
  final String teamName;
  final int goals;
  final int assists;
  final int penalties;
  final int? playedMatches;
  final String? nationality;
  final String? position;

  factory Scorer.fromJson(Map<String, dynamic> json, {required int rank}) {
    final player = json['player'] is Map<String, dynamic>
        ? json['player'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final team = json['team'] is Map<String, dynamic>
        ? json['team'] as Map<String, dynamic>
        : const <String, dynamic>{};

    return Scorer(
      rank: rank,
      playerName: _str(player, ['name', 'shortName']) ??
          _str(json, ['playerName', 'name']) ??
          'Bilinmeyen Oyuncu',
      teamName: _str(team, ['name', 'shortName', 'tla']) ??
          _str(json, ['teamName']) ??
          '',
      goals: _int(json['goals']),
      assists: _int(json['assists']),
      penalties: _int(json['penalties']),
      playedMatches: json['playedMatches'] is int
          ? json['playedMatches'] as int
          : null,
      nationality: _str(player, ['nationality']),
      position: _str(player, ['position']),
    );
  }

  static String? _str(Map<String, dynamic> map, List<String> keys) {
    for (final k in keys) {
      final v = map[k];
      if (v is String && v.trim().isNotEmpty) return v;
    }
    return null;
  }

  static int _int(Object? v) => int.tryParse((v ?? 0).toString()) ?? 0;
}
