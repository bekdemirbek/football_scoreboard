import 'package:flutter/material.dart';

import '../../../core/app_theme.dart';
import '../../../models/match_statistic.dart';
import 'team_badge.dart';

class MatchStatsTab extends StatelessWidget {
  const MatchStatsTab({
    super.key,
    required this.rows,
    this.homeTeam,
    this.awayTeam,
  });

  final List<MatchStatRow> rows;
  final String? homeTeam;
  final String? awayTeam;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            'Bu maç için istatistik verisi yok.',
            style: TextStyle(
              color: AppColors.textTertiary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.cardBgRaised, AppColors.cardBg],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
      child: Column(
        children: [
          if (homeTeam != null && awayTeam != null) ...[
            _StatsTeamHeader(homeTeam: homeTeam!, awayTeam: awayTeam!),
            const SizedBox(height: 16),
          ],
          for (final row in rows)
            StatBar(
              label: row.label,
              // Bar oranı homeRatio ile birebir; metinler ham değerlerden gelir.
              leftValue: (row.homeRatio * 1000).round(),
              rightValue: 1000 - (row.homeRatio * 1000).round(),
              leftDisplay: row.homeDisplay,
              rightDisplay: row.awayDisplay,
            ),
        ],
      ),
    );
  }
}

class _StatsTeamHeader extends StatelessWidget {
  const _StatsTeamHeader({required this.homeTeam, required this.awayTeam});

  final String homeTeam;
  final String awayTeam;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            children: [
              TeamBadge(teamName: homeTeam, size: 40),
              const SizedBox(height: 7),
              Text(
                homeTeam,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            'MAÇ\nİSTATİSTİKLERİ',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              height: 1.25,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Expanded(
          child: Column(
            children: [
              TeamBadge(teamName: awayTeam, size: 40),
              const SizedBox(height: 7),
              Text(
                awayTeam,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
