class LineupPlayer {
  const LineupPlayer({
    required this.id,
    required this.name,
    this.number,
    this.position,
    this.grid,
  });

  final int id;
  final String name;
  final int? number;
  final String? position;
  final String? grid;

  factory LineupPlayer.fromJson(Map<String, dynamic> json) {
    final player = json['player'] as Map<String, dynamic>? ?? const {};
    return LineupPlayer(
      id: (player['id'] as num?)?.toInt() ?? 0,
      name: player['name']?.toString() ?? '',
      number: (player['number'] as num?)?.toInt(),
      position: player['pos']?.toString(),
      grid: player['grid']?.toString(),
    );
  }
}

class TeamLineup {
  const TeamLineup({
    required this.teamId,
    required this.teamName,
    this.formation,
    required this.startXI,
    required this.substitutes,
    this.coachName,
  });

  final int teamId;
  final String teamName;
  final String? formation;
  final List<LineupPlayer> startXI;
  final List<LineupPlayer> substitutes;
  final String? coachName;

  static const _positionOrder = ['G', 'D', 'M', 'F'];

  List<LineupPlayer> get startXIByPosition {
    final sorted = [...startXI];
    sorted.sort((a, b) {
      final aIndex = _positionOrder.indexOf(a.position ?? '');
      final bIndex = _positionOrder.indexOf(b.position ?? '');
      return (aIndex == -1 ? 99 : aIndex).compareTo(bIndex == -1 ? 99 : bIndex);
    });
    return sorted;
  }

  factory TeamLineup.fromJson(Map<String, dynamic> json) {
    final team = json['team'] as Map<String, dynamic>? ?? const {};
    final coach = json['coach'] as Map<String, dynamic>?;

    return TeamLineup(
      teamId: (team['id'] as num?)?.toInt() ?? 0,
      teamName: team['name']?.toString() ?? '',
      formation: json['formation']?.toString(),
      startXI: (json['startXI'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(LineupPlayer.fromJson)
          .toList(growable: false),
      substitutes: (json['substitutes'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(LineupPlayer.fromJson)
          .toList(growable: false),
      coachName: coach?['name']?.toString(),
    );
  }
}
