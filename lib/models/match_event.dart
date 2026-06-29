class MatchEvent {
  const MatchEvent({
    required this.minute,
    this.extraMinute,
    this.teamId,
    required this.teamName,
    required this.playerName,
    this.assistName,
    required this.type,
    required this.detail,
  });

  final int minute;
  final int? extraMinute;
  final int? teamId;
  final String teamName;
  final String playerName;
  final String? assistName;
  final String type;
  final String detail;

  bool get isGoal => type == 'Goal';
  bool get isCard => type == 'Card';
  bool get isSubstitution => type.toLowerCase() == 'subst';
  bool get isOwnGoal => detail.toLowerCase().contains('own goal');
  bool get isPenalty => detail.toLowerCase().contains('penalty');
  bool get isRedCard => detail.toLowerCase().contains('red');

  String get minuteLabel => extraMinute != null && extraMinute! > 0
      ? "$minute+$extraMinute'"
      : "$minute'";

  factory MatchEvent.fromJson(Map<String, dynamic> json) {
    final time = json['time'] as Map<String, dynamic>? ?? const {};
    final team = json['team'] as Map<String, dynamic>? ?? const {};
    final player = json['player'] as Map<String, dynamic>? ?? const {};
    final assist = json['assist'] as Map<String, dynamic>?;

    return MatchEvent(
      minute: (time['elapsed'] as num?)?.toInt() ?? 0,
      extraMinute: (time['extra'] as num?)?.toInt(),
      teamId: (team['id'] as num?)?.toInt(),
      teamName: team['name']?.toString() ?? '',
      playerName: player['name']?.toString() ?? 'Bilinmiyor',
      assistName: assist?['name']?.toString(),
      type: json['type']?.toString() ?? '',
      detail: json['detail']?.toString() ?? '',
    );
  }
}
