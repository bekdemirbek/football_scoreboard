import 'dart:convert';

class FavoriteTeam {
  const FavoriteTeam({required this.id, required this.name, this.crestUrl});

  final String id;
  final String name;
  final String? crestUrl;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    if (crestUrl != null) 'crestUrl': crestUrl,
  };

  factory FavoriteTeam.fromJson(Map<String, dynamic> json) => FavoriteTeam(
    id: json['id']?.toString() ?? '',
    name: json['name']?.toString() ?? '',
    crestUrl: json['crestUrl']?.toString(),
  );

  static List<FavoriteTeam> listFromPrefs(List<String> raw) {
    final result = <FavoriteTeam>[];
    for (final item in raw) {
      try {
        final decoded = jsonDecode(item);
        if (decoded is Map<String, dynamic>) {
          result.add(FavoriteTeam.fromJson(decoded));
        }
      } catch (_) {
        // Legacy plain-string entries (team names only) — keep them by name.
        if (item.isNotEmpty) {
          result.add(FavoriteTeam(id: '', name: item));
        }
      }
    }
    return result;
  }

  static List<String> listToPrefs(List<FavoriteTeam> teams) =>
      teams.map((t) => jsonEncode(t.toJson())).toList();

  @override
  bool operator ==(Object other) =>
      other is FavoriteTeam && other.id == id && id.isNotEmpty
          ? true
          : other is FavoriteTeam && other.name == name;

  @override
  int get hashCode => id.isNotEmpty ? id.hashCode : name.hashCode;

  @override
  String toString() => 'FavoriteTeam($id, $name)';
}
