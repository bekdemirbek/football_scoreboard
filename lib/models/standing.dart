class Standing {
  const Standing({
    required this.teamId,
    required this.teamName,
    required this.rank,
    required this.played,
    required this.win,
    required this.draw,
    required this.loss,
    required this.points,
    this.group,
  });

  final String teamId;
  final String teamName;
  final int rank;
  final int played;
  final int win;
  final int draw;
  final int loss;
  final int points;
  final String? group;

  factory Standing.fromJson(Map<String, dynamic> json, {String? group}) {
    final team = json['team'] is Map<String, dynamic>
        ? json['team'] as Map<String, dynamic>
        : null;

    return Standing(
      teamId:
          _firstString(json, ['idTeam', 'teamId', 'id']) ??
          _firstString(team ?? const {}, ['id']) ??
          '',
      teamName:
          _firstString(json, ['strTeam', 'teamName', 'name']) ??
          _firstString(team ?? const {}, ['name', 'shortName', 'tla']) ??
          'Unknown Team',
      rank: _toInt(json['intRank'] ?? json['rank'] ?? json['position']),
      played: _toInt(
        json['intPlayed'] ??
            json['played'] ??
            json['matches'] ??
            json['playedGames'],
      ),
      win: _toInt(json['intWin'] ?? json['win'] ?? json['wins'] ?? json['won']),
      draw: _toInt(json['intDraw'] ?? json['draw'] ?? json['draws']),
      loss: _toInt(
        json['intLoss'] ?? json['loss'] ?? json['losses'] ?? json['lost'],
      ),
      points: _toInt(json['intPoints'] ?? json['points'] ?? json['pts']),
      group: group,
    );
  }

  static String? _firstString(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }
    return null;
  }

  static int _toInt(Object? value) {
    return int.tryParse((value ?? '0').toString()) ?? 0;
  }
}
