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
    final screenH = MediaQuery.sizeOf(context).height;

    return Container(
      constraints: BoxConstraints(maxHeight: screenH * 0.82),
      decoration: const BoxDecoration(
        color: AppColors.gradientStart,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: AppColors.cardBorder, width: 1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
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
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const Text(
                        'Takım Profili',
                        style: TextStyle(
                          color: AppColors.textSecondary,
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
          const Divider(height: 1, color: AppColors.divider),
          Flexible(
            child: team.id.isEmpty
                ? const _NoIdState()
                : _TeamMatchesList(team: team),
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
    final isFav = ref.watch(favoriteTeamsProvider.notifier).isFavorite(team);

    return GestureDetector(
      onTap: () => ref.read(favoriteTeamsProvider.notifier).toggle(team),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isFav
              ? AppColors.goldColor.withValues(alpha: 0.15)
              : AppColors.cardSurface,
          border: Border.all(
            color: isFav
                ? AppColors.goldColor.withValues(alpha: 0.5)
                : AppColors.cardBorder,
          ),
        ),
        child: Icon(
          isFav ? Icons.star_rounded : Icons.star_border_rounded,
          color: isFav ? AppColors.goldColor : AppColors.textTertiary,
          size: 22,
        ),
      ),
    );
  }
}

// ─── No-ID fallback ────────────────────────────────────────────────────────────

class _NoIdState extends StatelessWidget {
  const _NoIdState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: AppColors.textTertiary,
            size: 36,
          ),
          SizedBox(height: 12),
          Text(
            'Maç geçmişi için takımı puan tablosundan ekle.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Match list ────────────────────────────────────────────────────────────────

class _TeamMatchesList extends ConsumerWidget {
  const _TeamMatchesList({required this.team});

  final FavoriteTeam team;

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
      error: (e, _) => _ErrorState(message: e.toString()),
      data: (matches) {
        if (matches.isEmpty) return const _EmptyMatchState();

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
              const _SectionLabel(label: 'YAKLAŞAN MAÇLAR'),
              const SizedBox(height: 10),
              for (final m in upcoming) ...[
                MatchCard(
                  match: m,
                  hasFavorite:
                      favNotifier.isFavoriteByName(m.homeTeam) ||
                      favNotifier.isFavoriteByName(m.awayTeam),
                  onTap: () => Navigator.of(
                    context,
                  ).push(FadeRoute(child: MatchDetailPage(match: m))),
                ),
                const SizedBox(height: 8),
              ],
              const SizedBox(height: 16),
            ],
            if (past.isNotEmpty) ...[
              const _SectionLabel(label: 'SON MAÇLAR'),
              const SizedBox(height: 10),
              for (final m in past) ...[
                MatchCard(
                  match: m,
                  hasFavorite:
                      favNotifier.isFavoriteByName(m.homeTeam) ||
                      favNotifier.isFavoriteByName(m.awayTeam),
                  onTap: () => Navigator.of(
                    context,
                  ).push(FadeRoute(child: MatchDetailPage(match: m))),
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
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.leagueBadgeBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.accentGreen.withValues(alpha: 0.25),
            ),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.accentGreen,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(child: Divider(height: 1, color: AppColors.divider)),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            color: AppColors.textTertiary,
            size: 36,
          ),
          const SizedBox(height: 12),
          const Text(
            'Maçlar yüklenemedi',
            style: TextStyle(
              color: AppColors.textPrimary,
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
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyMatchState extends StatelessWidget {
  const _EmptyMatchState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.sports_soccer_rounded,
            color: AppColors.textTertiary,
            size: 36,
          ),
          SizedBox(height: 12),
          Text(
            'Bu dönemde maç bulunamadı',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
