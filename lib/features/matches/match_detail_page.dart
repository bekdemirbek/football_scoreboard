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
    final ac = Theme.of(context).extension<AppColors>()!;
    final favNotifier = ref.watch(favoriteTeamsProvider.notifier);
    final homeFav = favNotifier.isFavoriteByName(match.homeTeam);
    final awayFav = favNotifier.isFavoriteByName(match.awayTeam);
    final detail = ref.watch(matchDetailProvider(match)).value;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // ── Gradient Background ──────────────────────────────────────
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [ac.gradientStart, ac.gradientEnd],
                ),
              ),
            ),
          ),
          // ── Content ──────────────────────────────────────────────────
          SafeArea(
            child: Column(
              children: [
                // ── App Bar ───────────────────────────────────────────
                _DetailAppBar(ac: ac, league: match.league),
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
                            .toggle(FavoriteTeam(
                              id: match.homeTeamId ?? '',
                              name: match.homeTeam,
                            )),
                        onToggleAway: () => ref
                            .read(favoriteTeamsProvider.notifier)
                            .toggle(FavoriteTeam(
                              id: match.awayTeamId ?? '',
                              name: match.awayTeam,
                            )),
                      ),
                      const SizedBox(height: 16),
                      // ── Info Cards ──────────────────────────────────
                      _InfoSection(match: match, ac: ac),
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
  const _DetailAppBar({required this.ac, required this.league});
  final AppColors ac;
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
                color: ac.cardSurface,
                border: Border.all(color: ac.cardBorder),
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: ac.textPrimary,
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
              style: TextStyle(
                color: ac.textSecondary,
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
  const _InfoSection({required this.match, required this.ac});
  final Match match;
  final AppColors ac;

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
        color: ac.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ac.cardBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++)
            _InfoRow(
              icon: items[i].icon,
              label: items[i].label,
              value: items[i].value,
              ac: ac,
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
    required this.ac,
    required this.hasBorder,
  });

  final IconData icon;
  final String label;
  final String value;
  final AppColors ac;
  final bool hasBorder;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: hasBorder
          ? BoxDecoration(
              border: Border(top: BorderSide(color: ac.divider)),
            )
          : null,
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: primary.withValues(alpha: 0.1),
            ),
            child: Icon(icon, color: primary, size: 16),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: ac.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: ac.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
