import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/app_theme.dart';
import '../../../models/match_lineup.dart';

class LineupPitch extends StatelessWidget {
  const LineupPitch({super.key, required this.home, required this.away});

  final TeamLineup home;
  final TeamLineup away;

  static const _homeColor = AppColors.accentGreen;
  static const _awayColor = AppColors.accentOrange;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 0.72,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            const CustomPaint(painter: _PitchPainter()),
            ..._playerDots(away, topHalf: true, color: _awayColor),
            ..._playerDots(home, topHalf: false, color: _homeColor),
          ],
        ),
      ),
    );
  }

  static const _posRow = {'G': 1, 'D': 2, 'M': 3, 'F': 4};

  static int _rowOf(LineupPlayer p) {
    final grid = p.grid;
    if (grid != null && grid.contains(':')) {
      final parsed = int.tryParse(grid.split(':').first);
      if (parsed != null) return parsed;
    }
    return _posRow[p.position] ?? 2;
  }

  static int _colOf(LineupPlayer p) {
    final grid = p.grid;
    if (grid != null && grid.contains(':')) {
      final parsed = int.tryParse(grid.split(':').last);
      if (parsed != null) return parsed;
    }
    return 0;
  }

  static List<Widget> _playerDots(
    TeamLineup team, {
    required bool topHalf,
    required Color color,
  }) {
    final rows = <int, List<LineupPlayer>>{};
    for (final p in team.startXI) {
      rows.putIfAbsent(_rowOf(p), () => []).add(p);
    }
    if (rows.isEmpty) return const [];
    final maxRow = rows.keys.reduce(math.max);

    final widgets = <Widget>[];
    for (final entry in rows.entries) {
      final row = entry.key;
      final sorted = [...entry.value]
        ..sort((a, b) => _colOf(a).compareTo(_colOf(b)));
      final rowProgress = maxRow <= 1 ? 0.0 : (row - 1) / (maxRow - 1);
      final dy = topHalf
          ? 0.10 + rowProgress * 0.34
          : 0.90 - rowProgress * 0.34;

      for (var i = 0; i < sorted.length; i++) {
        final colFrac = (i + 1) / (sorted.length + 1);
        widgets.add(
          Align(
            alignment: Alignment(colFrac * 2 - 1, dy * 2 - 1),
            child: _PlayerDot(player: sorted[i], color: color),
          ),
        );
      }
    }
    return widgets;
  }
}

class _PlayerDot extends StatelessWidget {
  const _PlayerDot({required this.player, required this.color});
  final LineupPlayer player;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── badgeBg arka planlı yuvarlak rozet + takım renginde halka + glow ──
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.badgeBg,
            border: Border.all(color: color, width: 2),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.55),
                blurRadius: 10,
                spreadRadius: -1,
              ),
              const BoxShadow(
                color: AppColors.cardShadow,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            '${player.number ?? ''}',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          _lastName(player.name),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 8.5,
            fontWeight: FontWeight.w700,
            shadows: [Shadow(color: Colors.black, blurRadius: 3)],
          ),
        ),
      ],
    );
  }

  String _lastName(String name) {
    final parts = name.trim().split(' ');
    return parts.isEmpty ? name : parts.last;
  }
}

class _PitchPainter extends CustomPainter {
  const _PitchPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = AppColors.pitchField;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bg);

    final stripe = Paint()..color = AppColors.pitchFieldStripe;
    const stripeCount = 8;
    final stripeHeight = size.height / stripeCount;
    for (var i = 0; i < stripeCount; i += 2) {
      canvas.drawRect(
        Rect.fromLTWH(0, stripeHeight * i, size.width, stripeHeight),
        stripe,
      );
    }

    final line = Paint()
      ..color = AppColors.pitchLine
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    canvas.drawRect(
      Rect.fromLTWH(8, 8, size.width - 16, size.height - 16),
      line,
    );
    canvas.drawLine(
      Offset(8, size.height / 2),
      Offset(size.width - 8, size.height / 2),
      line,
    );
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width * 0.16,
      line,
    );
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      2,
      Paint()..color = AppColors.pitchLine,
    );

    final boxWidth = size.width * 0.5;
    final boxHeight = size.height * 0.12;
    canvas.drawRect(
      Rect.fromLTWH(size.width / 2 - boxWidth / 2, 8, boxWidth, boxHeight),
      line,
    );
    canvas.drawRect(
      Rect.fromLTWH(
        size.width / 2 - boxWidth / 2,
        size.height - 8 - boxHeight,
        boxWidth,
        boxHeight,
      ),
      line,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
