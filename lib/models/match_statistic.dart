class MatchStatRow {
  const MatchStatRow({
    required this.type,
    required this.homeValue,
    required this.awayValue,
  });

  final String type;
  final Object? homeValue;
  final Object? awayValue;

  String get label => _labels[type] ?? type;

  String get homeDisplay => homeValue?.toString() ?? '-';
  String get awayDisplay => awayValue?.toString() ?? '-';

  double get homeRatio {
    final h = _toNumeric(homeValue) ?? 0;
    final a = _toNumeric(awayValue) ?? 0;
    if (h + a == 0) return 0.5;
    return h / (h + a);
  }

  static double? _toNumeric(Object? value) {
    if (value == null) return 0;
    return double.tryParse(value.toString().replaceAll('%', ''));
  }

  static const _labels = <String, String>{
    'Ball Possession': 'Topla Oynama',
    'expected_goals': 'Gol Beklentisi (xG)',
    'Total Shots': 'Toplam Şut',
    'Shots on Goal': 'İsabetli Şut',
    'Shots off Goal': 'İsabetsiz Şut',
    'Blocked Shots': 'Engellenen Şut',
    'Corner Kicks': 'Korner',
    'Fouls': 'Faul',
    'Offsides': 'Ofsayt',
    'Yellow Cards': 'Sarı Kart',
    'Red Cards': 'Kırmızı Kart',
    'Goalkeeper Saves': 'Kaleci Kurtarışı',
    'Total passes': 'Toplam Pas',
    'Passes %': 'Pas İsabeti',
  };

  static const orderedTypes = [
    'Ball Possession',
    'expected_goals',
    'Total Shots',
    'Shots on Goal',
    'Shots off Goal',
    'Corner Kicks',
    'Fouls',
    'Offsides',
    'Yellow Cards',
    'Red Cards',
    'Goalkeeper Saves',
    'Passes %',
  ];

  static List<MatchStatRow> buildRows({
    required List<Map<String, dynamic>> homeStats,
    required List<Map<String, dynamic>> awayStats,
  }) {
    final homeMap = {
      for (final s in homeStats) s['type'].toString(): s['value'],
    };
    final awayMap = {
      for (final s in awayStats) s['type'].toString(): s['value'],
    };

    final rows = <MatchStatRow>[];
    for (final type in orderedTypes) {
      if (!homeMap.containsKey(type) && !awayMap.containsKey(type)) continue;
      rows.add(
        MatchStatRow(
          type: type,
          homeValue: homeMap[type],
          awayValue: awayMap[type],
        ),
      );
    }
    return rows;
  }
}
