import 'package:flutter/material.dart';

import '../../../core/app_theme.dart';
import '../../../models/match.dart';
import 'team_badge.dart';

class MatchCard extends StatelessWidget {
  const MatchCard({
    super.key,
    required this.match,
    required this.onTap,
    this.hasFavorite = false,
    this.isLoading = false,
  });

  final Match match;
  final VoidCallback onTap;
  final bool hasFavorite;
  final bool isLoading;

  bool get _isLive {
    final s = match.status?.toLowerCase() ?? '';
    return s.contains('live') ||
        s.contains('canlı') ||
        s.contains('canli') ||
        s.contains("'") ||
        RegExp(r'^\d+\s*$').hasMatch(s);
  }

  bool get _isFinished {
    final s = match.status?.trim().toUpperCase() ?? '';
    return s == 'MS' || s == 'FINISHED' || s == 'FT';
  }

  String get _minuteText {
    final v = match.status?.trim();
    if (v == null || v.isEmpty || v.toUpperCase() == 'LIVE') return 'CANLI';
    return v.contains("'") ? v : "$v'";
  }

  String get _time {
    final raw = match.time;
    if (raw != null && raw.trim().isNotEmpty) {
      final parts = raw.trim().split(':');
      if (parts.length >= 2) return '${parts[0]}:${parts[1]}';
      return raw.trim();
    }
    final date = match.date;
    if (date == null) return '--:--';
    final local = date.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    // ── Canlı maçlar: gradient border + pulse (LiveMatchCard) ──────────────
    if (_isLive) {
      return AnimatedOpacity(
        duration: const Duration(milliseconds: 250),
        opacity: isLoading ? 0.5 : 1.0,
        child: LiveMatchCard(
          homeTeam: match.homeTeam,
          awayTeam: match.awayTeam,
          homeScore: match.homeScore,
          awayScore: match.awayScore,
          minute: _minuteText,
          onTap: onTap,
          hasFavorite: hasFavorite,
          homeLeading: TeamBadge(teamName: match.homeTeam, size: 30),
          awayTrailing: TeamBadge(teamName: match.awayTeam, size: 30),
        ),
      );
    }

    final finished = _isFinished;
    final hasScore = match.homeScore != null && match.awayScore != null;
    final homeWin = hasScore && match.homeScore! > match.awayScore!;
    final awayWin = hasScore && match.awayScore! > match.homeScore!;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 250),
      opacity: isLoading ? 0.5 : 1.0,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 76),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.cardBorder, width: 1),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.cardBgRaised, AppColors.cardBg],
            ),
            boxShadow: const [
              BoxShadow(
                color: AppColors.cardShadow,
                blurRadius: 10,
                spreadRadius: -4,
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Column(
            children: [
              // ── Üst durum satırı (MS / saat / favori) ─────────────────
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: finished
                          ? AppColors.badgeBg
                          : AppColors.accentGreen.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      finished ? 'MS' : _time,
                      style: TextStyle(
                        color: finished
                            ? AppColors.textSecondary
                            : AppColors.accentGreen,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (hasFavorite)
                    const Icon(
                      Icons.star_rounded,
                      color: AppColors.goldColor,
                      size: 14,
                    ),
                ],
              ),
              const SizedBox(height: 11),
              // ── Takımlar + skor ───────────────────────────────────────
              Row(
                children: [
                  TeamBadge(teamName: match.homeTeam, size: 30),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      match.homeTeam,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13.5,
                        fontWeight: homeWin ? FontWeight.w800 : FontWeight.w600,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      hasScore
                          ? '${match.homeScore} - ${match.awayScore}'
                          : 'VS',
                      style: TextStyle(
                        color: hasScore
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                        fontSize: hasScore ? 22 : 14,
                        fontWeight: FontWeight.w800,
                        height: 1.0,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      match.awayTeam,
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13.5,
                        fontWeight: awayWin ? FontWeight.w800 : FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  TeamBadge(teamName: match.awayTeam, size: 30),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
