class Team {
  const Team({
    required this.id,
    required this.name,
    this.badgeUrl,
    this.country,
  });

  final String id;
  final String name;
  final String? badgeUrl;
  final String? country;

  factory Team.fromJson(Map<String, dynamic> json) {
    return Team(
      id: _firstString(json, ['idTeam', 'teamId', 'id']) ?? '',
      name: _firstString(json, ['strTeam', 'teamName', 'name']) ?? 'Unknown Team',
      badgeUrl: _firstString(json, ['strBadge', 'badgeUrl', 'logo', 'image']),
      country: _firstString(json, ['strCountry', 'country', 'countryName']),
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
}
