/// Bir takımın kadro bilgisi (football-data `/teams/{id}`).
/// Not: football-data ücretsiz planı oyuncu-başı gol/asist sezon
/// istatistiği vermez; mevcut alanlar pozisyon, uyruk ve yaştır.
class TeamSquad {
  const TeamSquad({
    required this.teamName,
    this.coachName,
    this.players = const [],
  });

  final String teamName;
  final String? coachName;
  final List<SquadPlayer> players;

  factory TeamSquad.fromJson(Map<String, dynamic> json) {
    final squad = json['squad'];
    final coach = json['coach'];
    final players = <SquadPlayer>[];
    if (squad is List) {
      for (final item in squad) {
        if (item is Map<String, dynamic>) {
          players.add(SquadPlayer.fromJson(item));
        }
      }
    }

    return TeamSquad(
      teamName: (json['name'] ?? json['shortName'] ?? 'Takım').toString(),
      coachName: coach is Map<String, dynamic>
          ? coach['name']?.toString()
          : null,
      players: players,
    );
  }

  /// Pozisyon grubuna göre sıralı oyuncular: Kaleci → Defans → Orta Saha → Forvet.
  Map<SquadPositionGroup, List<SquadPlayer>> get byGroup {
    final map = <SquadPositionGroup, List<SquadPlayer>>{};
    for (final p in players) {
      map.putIfAbsent(p.group, () => <SquadPlayer>[]).add(p);
    }
    return map;
  }
}

enum SquadPositionGroup { goalkeeper, defence, midfield, attack, other }

extension SquadPositionGroupLabel on SquadPositionGroup {
  String get label => switch (this) {
    SquadPositionGroup.goalkeeper => 'Kaleciler',
    SquadPositionGroup.defence => 'Defans',
    SquadPositionGroup.midfield => 'Orta Saha',
    SquadPositionGroup.attack => 'Forvet',
    SquadPositionGroup.other => 'Diğer',
  };

  int get order => switch (this) {
    SquadPositionGroup.goalkeeper => 0,
    SquadPositionGroup.defence => 1,
    SquadPositionGroup.midfield => 2,
    SquadPositionGroup.attack => 3,
    SquadPositionGroup.other => 4,
  };
}

class SquadPlayer {
  const SquadPlayer({
    required this.name,
    this.position,
    this.nationality,
    this.dateOfBirth,
    this.shirtNumber,
  });

  final String name;
  final String? position;
  final String? nationality;
  final DateTime? dateOfBirth;
  final int? shirtNumber;

  factory SquadPlayer.fromJson(Map<String, dynamic> json) {
    return SquadPlayer(
      name: (json['name'] ?? 'Bilinmeyen').toString(),
      position: json['position']?.toString(),
      nationality: json['nationality']?.toString(),
      dateOfBirth: DateTime.tryParse(json['dateOfBirth']?.toString() ?? ''),
      shirtNumber: json['shirtNumber'] is int
          ? json['shirtNumber'] as int
          : int.tryParse(json['shirtNumber']?.toString() ?? ''),
    );
  }

  int? get age {
    final dob = dateOfBirth;
    if (dob == null) return null;
    final now = DateTime.now();
    var years = now.year - dob.year;
    if (now.month < dob.month ||
        (now.month == dob.month && now.day < dob.day)) {
      years--;
    }
    return years;
  }

  SquadPositionGroup get group {
    final p = position?.toLowerCase() ?? '';
    if (p.contains('keeper')) return SquadPositionGroup.goalkeeper;
    if (p.contains('back') || p.contains('defen')) {
      return SquadPositionGroup.defence;
    }
    if (p.contains('midfield')) return SquadPositionGroup.midfield;
    if (p.contains('forward') ||
        p.contains('offen') ||
        p.contains('winger') ||
        p.contains('striker') ||
        p.contains('attack')) {
      return SquadPositionGroup.attack;
    }
    return SquadPositionGroup.other;
  }
}
