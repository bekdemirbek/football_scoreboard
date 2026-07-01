import 'package:flutter/material.dart';

import '../../../core/app_theme.dart';
import '../../../models/match_detail.dart';
import '../../../models/match_event.dart';

class MatchEventsTab extends StatelessWidget {
  const MatchEventsTab({super.key, required this.detail});

  final MatchDetail detail;

  @override
  Widget build(BuildContext context) {
    final relevant = detail.events
        .where((e) => e.isGoal || e.isCard || e.isSubstitution)
        .toList(growable: false);

    if (relevant.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            'Bu maç için olay verisi yok.',
            style: TextStyle(
              color: AppColors.textTertiary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        for (final event in relevant)
          _EventRow(event: event, isHome: detail.isHomeEvent(event)),
      ],
    );
  }
}

class _EventRow extends StatelessWidget {
  const _EventRow({required this.event, required this.isHome});

  final MatchEvent event;
  final bool isHome;

  @override
  Widget build(BuildContext context) {
    final sideColor = isHome ? AppColors.accentGreen : AppColors.accentOrange;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: sideColor, width: 3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 30,
            child: Text(
              event.minuteLabel,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          _EventIcon(event: event),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (_subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    _subtitle!,
                    style: const TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          _EventTag(event: event),
        ],
      ),
    );
  }

  String get _title {
    if (event.isSubstitution) return event.assistName ?? '?';
    return event.playerName;
  }

  String? get _subtitle {
    if (event.isSubstitution) return '${event.playerName} yerine girdi';
    if (event.isGoal && event.assistName != null) {
      return 'Asist: ${event.assistName}';
    }
    if (event.isCard) return event.detail;
    return null;
  }
}

class _EventIcon extends StatelessWidget {
  const _EventIcon({required this.event});
  final MatchEvent event;

  @override
  Widget build(BuildContext context) {
    if (event.isGoal) {
      return _circle(
        color: AppColors.accentGreen,
        child: const Icon(Icons.sports_soccer, color: Colors.white, size: 16),
      );
    }
    if (event.isCard) {
      return _circle(
        color: event.isRedCard ? AppColors.liveRed : AppColors.goldColor,
        child: Container(
          width: 9,
          height: 13,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      );
    }
    return _circle(
      color: AppColors.textMuted,
      child: const Icon(
        Icons.swap_horiz_rounded,
        color: Colors.white,
        size: 16,
      ),
    );
  }

  Widget _circle({required Color color, required Widget child}) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      alignment: Alignment.center,
      child: child,
    );
  }
}

class _EventTag extends StatelessWidget {
  const _EventTag({required this.event});
  final MatchEvent event;

  @override
  Widget build(BuildContext context) {
    final (label, color) = _tag;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  (String, Color) get _tag {
    if (event.isGoal) {
      if (event.isOwnGoal) return ('KENDİ KALESİNE', AppColors.liveRed);
      if (event.isPenalty) return ('PENALTI GOLÜ', AppColors.accentGreen);
      return ('GOL', AppColors.accentGreen);
    }
    if (event.isCard) {
      return event.isRedCard
          ? ('KIRMIZI KART', AppColors.liveRed)
          : ('SARI KART', AppColors.goldColor);
    }
    return ('DEĞİŞİKLİK', AppColors.textMuted);
  }
}
