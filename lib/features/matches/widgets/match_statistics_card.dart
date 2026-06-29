import 'package:flutter/material.dart';

import '../../../core/app_theme.dart';
import '../../../models/match_statistic.dart';

class MatchStatsTab extends StatelessWidget {
  const MatchStatsTab({super.key, required this.rows});

  final List<MatchStatRow> rows;

  @override
  Widget build(BuildContext context) {
    final ac = Theme.of(context).extension<AppColors>()!;

    if (rows.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            'Bu maç için istatistik verisi yok.',
            style: TextStyle(
              color: ac.textTertiary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: ac.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ac.cardBorder),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [for (final row in rows) _StatBarRow(row: row, ac: ac)],
      ),
    );
  }
}

class _StatBarRow extends StatelessWidget {
  const _StatBarRow({required this.row, required this.ac});

  final MatchStatRow row;
  final AppColors ac;

  @override
  Widget build(BuildContext context) {
    const homeColor = Color(0xFF2563EB);
    const awayColor = Color(0xFFE0A639);
    final homeFlex = (row.homeRatio * 100).round().clamp(1, 99);
    final awayFlex = 100 - homeFlex;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                row.homeDisplay,
                style: TextStyle(
                  color: ac.textPrimary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Expanded(
                child: Text(
                  row.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: ac.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                row.awayDisplay,
                style: TextStyle(
                  color: ac.textPrimary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Row(
              children: [
                Expanded(
                  flex: homeFlex,
                  child: Container(height: 5, color: homeColor),
                ),
                const SizedBox(width: 2),
                Expanded(
                  flex: awayFlex,
                  child: Container(height: 5, color: awayColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
