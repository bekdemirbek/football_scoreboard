import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_theme.dart';
import '../../models/favorite_team.dart';
import '../../models/match.dart';
import '../../providers/api_providers.dart';
import 'widgets/match_detail_sections.dart';
import 'widgets/match_hero_card.dart';

class MatchDetailPage extends ConsumerWidget {
  const MatchDetailPage({super.key, required this.match});

  final Match match;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favNotifier = ref.watch(favoriteTeamsProvider.notifier);
    final homeFav = favNotifier.isFavoriteByName(match.homeTeam);
    final awayFav = favNotifier.isFavoriteByName(match.awayTeam);
    final detail = ref.watch(matchDetailProvider(match)).value;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // ── Gradient Background ──────────────────────────────────────
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.gradientStart, AppColors.gradientEnd],
                ),
              ),
            ),
          ),
          // ── Content ──────────────────────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                // ── App Bar ───────────────────────────────────────────
                _DetailAppBar(league: match.league),
                // ── Scrollable Body ───────────────────────────────────
                Expanded(
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                    children: [
                      // ── Hero Score Card ─────────────────────────────
                      MatchHeroCard(
                        match: match,
                        homeFav: homeFav,
                        awayFav: awayFav,
                        detail: detail,
                        onToggleHome: () => ref
                            .read(favoriteTeamsProvider.notifier)
                            .toggle(
                              FavoriteTeam(
                                id: match.homeTeamId ?? '',
                                name: match.homeTeam,
                              ),
                            ),
                        onToggleAway: () => ref
                            .read(favoriteTeamsProvider.notifier)
                            .toggle(
                              FavoriteTeam(
                                id: match.awayTeamId ?? '',
                                name: match.awayTeam,
                              ),
                            ),
                      ),
                      const SizedBox(height: 16),
                      // ── Info Cards ──────────────────────────────────
                      _InfoSection(match: match),
                      const SizedBox(height: 16),
                      // ── Olaylar / Kadro / İstatistik ─────────────────
                      MatchDetailSections(match: match),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── App Bar ───────────────────────────────────────────────────────────────────

class _DetailAppBar extends StatelessWidget {
  const _DetailAppBar({required this.league});
  final String? league;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.cardSurface,
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: AppColors.textPrimary,
                size: 16,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              league ?? 'Maç Detayı',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Info Section ──────────────────────────────────────────────────────────────

class _InfoSection extends StatelessWidget {
  const _InfoSection({required this.match});
  final Match match;

  @override
  Widget build(BuildContext context) {
    final items = [
      if (match.time != null)
        (icon: Icons.schedule_rounded, label: 'Saat', value: match.time!),
      (
        icon: Icons.flag_rounded,
        label: 'Durum',
        value: match.status ?? 'Planlandı',
      ),
      if (match.venue != null && match.venue!.isNotEmpty)
        (icon: Icons.stadium_rounded, label: 'Stadyum', value: match.venue!),
    ];

    if (items.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++)
            _InfoRow(
              icon: items[i].icon,
              label: items[i].label,
              value: items[i].value,
              hasBorder: i > 0,
            ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.hasBorder,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool hasBorder;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: hasBorder
          ? const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.divider)),
            )
          : null,
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accentGreen.withValues(alpha: 0.1),
            ),
            child: Icon(icon, color: AppColors.accentGreen, size: 16),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
