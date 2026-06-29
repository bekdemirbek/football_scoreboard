import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_theme.dart';
import '../../models/favorite_team.dart';
import '../../providers/api_providers.dart';
import '../../widgets/fade_route.dart';
import '../matches/match_detail_page.dart';
import '../matches/widgets/match_card.dart';
import '../matches/widgets/team_badge.dart';

class TeamProfileSheet extends ConsumerWidget {
  const TeamProfileSheet({super.key, required this.team});

  final FavoriteTeam team;

  static Future<void> show(BuildContext context, FavoriteTeam team) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TeamProfileSheet(team: team),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ac = Theme.of(context).extension<AppColors>()!;
    final primary = Theme.of(context).colorScheme.primary;
    final screenH = MediaQuery.sizeOf(context).height;

    return Container(
      constraints: BoxConstraints(maxHeight: screenH * 0.82),
      decoration: BoxDecoration(
        color: ac.gradientStart,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: ac.cardBorder, width: 1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Drag handle ──────────────────────────────────────────────────
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: ac.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // ── Team header ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                TeamBadge(teamName: team.name, size: 48),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        team.name,
                        style: TextStyle(
                          color: ac.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        'Takım Profili',
                        style: TextStyle(
                          color: ac.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                _FavoriteToggle(team: team),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Divider(height: 1, color: ac.divider),
          // ── Match list ───────────────────────────────────────────────────
          Flexible(
            child: team.id.isEmpty
                ? _NoIdState(ac: ac)
                : _TeamMatchesList(team: team, primary: primary, ac: ac),
          ),
        ],
      ),
    );
  }
}

// ─── Favorite toggle button ────────────────────────────────────────────────────

class _FavoriteToggle extends ConsumerWidget {
  const _FavoriteToggle({required this.team});
  final FavoriteTeam team;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ac = Theme.of(context).extension<AppColors>()!;
    final isFav = ref.watch(favoriteTeamsProvider.notifier).isFavorite(team);

    return GestureDetector(
      onTap: () => ref.read(favoriteTeamsProvider.notifier).toggle(team),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isFav
              ? ac.goldColor.withValues(alpha: 0.15)
              : ac.cardSurface,
          border: Border.all(
            color: isFav
                ? ac.goldColor.withValues(alpha: 0.5)
                : ac.cardBorder,
          ),
        ),
        child: Icon(
          isFav ? Icons.star_rounded : Icons.star_border_rounded,
          color: isFav ? ac.goldColor : ac.textTertiary,
          size: 22,
        ),
      ),
    );
  }
}

// ─── No-ID fallback ────────────────────────────────────────────────────────────

class _NoIdState extends StatelessWidget {
  const _NoIdState({required this.ac});
  final AppColors ac;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.info_outline_rounded, color: ac.textTertiary, size: 36),
          const SizedBox(height: 12),
          Text(
            'Maç geçmişi için takımı puan tablosundan ekle.',
            textAlign: TextAlign.center,
            style: TextStyle(color: ac.textSecondary, fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }
}

// ─── Match list ────────────────────────────────────────────────────────────────

class _TeamMatchesList extends ConsumerWidget {
  const _TeamMatchesList({
    required this.team,
    required this.primary,
    required this.ac,
  });

  final FavoriteTeam team;
  final Color primary;
  final AppColors ac;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchesAsync = ref.watch(teamMatchesProvider(team.id));
    final favNotifier = ref.watch(favoriteTeamsProvider.notifier);

    return matchesAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator.adaptive(),
        ),
      ),
      error: (e, _) => _ErrorState(message: e.toString(), ac: ac),
      data: (matches) {
        if (matches.isEmpty) return _EmptyMatchState(ac: ac);

        final now = DateTime.now();
        final past = matches
            .where((m) => m.date != null && m.date!.isBefore(now))
            .toList()
            .reversed
            .take(5)
            .toList();
        final upcoming = matches
            .where((m) => m.date != null && !m.date!.isBefore(now))
            .take(3)
            .toList();

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            if (upcoming.isNotEmpty) ...[
              _SectionLabel(label: 'YAKLAŞAN MAÇLAR', ac: ac, primary: primary),
              const SizedBox(height: 10),
              for (final m in upcoming) ...[
                MatchCard(
                  match: m,
                  hasFavorite: favNotifier.isFavoriteByName(m.homeTeam) ||
                      favNotifier.isFavoriteByName(m.awayTeam),
                  onTap: () => Navigator.of(context).push(
                    FadeRoute(child: MatchDetailPage(match: m)),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              const SizedBox(height: 16),
            ],
            if (past.isNotEmpty) ...[
              _SectionLabel(label: 'SON MAÇLAR', ac: ac, primary: primary),
              const SizedBox(height: 10),
              for (final m in past) ...[
                MatchCard(
                  match: m,
                  hasFavorite: favNotifier.isFavoriteByName(m.homeTeam) ||
                      favNotifier.isFavoriteByName(m.awayTeam),
                  onTap: () => Navigator.of(context).push(
                    FadeRoute(child: MatchDetailPage(match: m)),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ],
          ],
        );
      },
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({
    required this.label,
    required this.ac,
    required this.primary,
  });

  final String label;
  final AppColors ac;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: ac.leagueBadgeBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: primary.withValues(alpha: 0.25)),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: primary,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: Divider(height: 1, color: ac.divider)),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.ac});
  final String message;
  final AppColors ac;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off_rounded, color: ac.textTertiary, size: 36),
          const SizedBox(height: 12),
          Text(
            'Maçlar yüklenemedi',
            style: TextStyle(
              color: ac.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: ac.textSecondary, fontSize: 12, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _EmptyMatchState extends StatelessWidget {
  const _EmptyMatchState({required this.ac});
  final AppColors ac;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.sports_soccer_rounded, color: ac.textTertiary, size: 36),
          const SizedBox(height: 12),
          Text(
            'Bu dönemde maç bulunamadı',
            style: TextStyle(color: ac.textSecondary, fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }
}
