import 'package:flutter/material.dart';

class TeamBadge extends StatelessWidget {
  const TeamBadge({super.key, required this.teamName, this.size = 34});

  final String teamName;
  final double size;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = _paletteFor(teamName);
    final initials = teamName
        .split(' ')
        .where((p) => p.isNotEmpty)
        .take(2)
        .map((p) => p[0].toUpperCase())
        .join();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: palette.gradient,
        ),
        boxShadow: [
          BoxShadow(
            color: palette.gradient.first.withValues(
              alpha: isDark ? 0.55 : 0.3,
            ),
            blurRadius: size * 0.55,
            spreadRadius: -size * 0.2,
          ),
        ],
        border: Border.all(
          color: Colors.white.withValues(alpha: isDark ? 0.12 : 0.6),
          width: 1,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        initials.isEmpty ? '?' : initials,
        style: TextStyle(
          color: Colors.white,
          fontSize: size <= 22
              ? 7.5
              : size <= 28
              ? 10
              : 12,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.3,
          shadows: const [Shadow(color: Colors.black26, blurRadius: 4)],
        ),
      ),
    );
  }

  _BadgePalette _paletteFor(String value) {
    final hash = value.codeUnits.fold<int>(0, (sum, u) => sum + u);
    const palettes = [
      _BadgePalette([Color(0xFFFF6B6B), Color(0xFFEE5A24)]),
      _BadgePalette([Color(0xFF00E5A0), Color(0xFF0A7C5C)]),
      _BadgePalette([Color(0xFF6C5CE7), Color(0xFF4834D4)]),
      _BadgePalette([Color(0xFFFFD060), Color(0xFFE17B00)]),
      _BadgePalette([Color(0xFF4F8CFF), Color(0xFF2563EB)]),
      _BadgePalette([Color(0xFFFF4F81), Color(0xFFD6006B)]),
      _BadgePalette([Color(0xFF00C6FB), Color(0xFF005BEA)]),
      _BadgePalette([Color(0xFFFDA085), Color(0xFFF6416C)]),
    ];
    return palettes[hash % palettes.length];
  }
}

class _BadgePalette {
  const _BadgePalette(this.gradient);
  final List<Color> gradient;
}
