import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_theme.dart';
import '../../models/favorite_team.dart';
import '../../providers/api_providers.dart';
import '../../widgets/fade_route.dart';
import '../../widgets/screen_header.dart';
import '../matches/match_detail_page.dart';
import '../matches/widgets/match_card.dart';
import '../matches/widgets/team_badge.dart';
import 'team_profile_sheet.dart';

class FavoritesPage extends ConsumerWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoritesAsync = ref.watch(favoriteTeamsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: favoritesAsync.when(
          loading: () =>
              const Center(child: CircularProgressIndicator.adaptive()),
          error: (e, _) => _ErrorState(message: e.toString()),
          data: (teams) => teams.isEmpty
              ? const _EmptyState()
              : _FavoritesContent(teams: teams),
        ),
      ),
    );
  }
}

// ─── Content ───────────────────────────────────────────────────────────────────

class _FavoritesContent extends ConsumerWidget {
  const _FavoritesContent({required this.teams});

  final List<FavoriteTeam> teams;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favNotifier = ref.watch(favoriteTeamsProvider.notifier);

    return RefreshIndicator(
      onRefresh: () => ref.refresh(favoriteTeamsProvider.future),
      color: AppColors.accentGreen,
      backgroundColor: AppColors.cardSurface,
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 100),
        children: [
          const ScreenHeader(title: 'Favoriler'),
          const SizedBox(height: 8),
          const Center(
            child: Text(
              'Takıma tıkla → profil ve maç geçmişi',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 16),
          for (final team in teams) ...[
            _TeamSection(team: team, favNotifier: favNotifier),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }
}

// ─── Per-team section ──────────────────────────────────────────────────────────

class _TeamSection extends ConsumerWidget {
  const _TeamSection({required this.team, required this.favNotifier});

  final FavoriteTeam team;
  final FavoriteTeamsNotifier favNotifier;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => TeamProfileSheet.show(context, team),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.cardSurface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              children: [
                TeamBadge(teamName: team.name, size: 36),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    team.name,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textTertiary,
                  size: 20,
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () =>
                      ref.read(favoriteTeamsProvider.notifier).toggle(team),
                  behavior: HitTestBehavior.opaque,
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(
                      Icons.star_rounded,
                      color: AppColors.goldColor,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (team.id.isNotEmpty)
          _TeamMatchPreview(team: team, favNotifier: favNotifier),
      ],
    );
  }
}

// ─── Inline match preview (3 most-recent + next) ───────────────────────────────

class _TeamMatchPreview extends ConsumerWidget {
  const _TeamMatchPreview({required this.team, required this.favNotifier});

  final FavoriteTeam team;
  final FavoriteTeamsNotifier favNotifier;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchesAsync = ref.watch(teamMatchesProvider(team.id));

    return matchesAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.only(top: 8),
        child: _MatchSkeleton(),
      ),
      error: (e, _) => const Padding(
        padding: EdgeInsets.only(top: 8, left: 4),
        child: Text(
          'Maçlar yüklenemedi',
          style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
        ),
      ),
      data: (matches) {
        if (matches.isEmpty) return const SizedBox.shrink();

        final now = DateTime.now();
        final next = matches
            .where((m) => m.date != null && !m.date!.isBefore(now))
            .firstOrNull;
        final recent = matches
            .where((m) => m.date != null && m.date!.isBefore(now))
            .toList()
            .reversed
            .take(2)
            .toList();

        final preview = [if (next != null) next, ...recent];
        if (preview.isEmpty) return const SizedBox.shrink();

        return Column(
          children: [
            const SizedBox(height: 8),
            for (final m in preview) ...[
              MatchCard(
                match: m,
                hasFavorite:
                    favNotifier.isFavoriteByName(m.homeTeam) ||
                    favNotifier.isFavoriteByName(m.awayTeam),
                onTap: () => Navigator.of(
                  context,
                ).push(FadeRoute(child: MatchDetailPage(match: m))),
              ),
              const SizedBox(height: 6),
            ],
            GestureDetector(
              onTap: () => TeamProfileSheet.show(context, team),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Tüm maçları gör',
                      style: TextStyle(
                        color: AppColors.accentGreen,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 13,
                      color: AppColors.accentGreen,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─── Match skeleton ────────────────────────────────────────────────────────────

class _MatchSkeleton extends StatelessWidget {
  const _MatchSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.textTertiary,
          ),
        ),
      ),
    );
  }
}

// ─── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppColors.goldColor.withValues(alpha: 0.3),
                    AppColors.goldColor.withValues(alpha: 0.1),
                  ],
                ),
                border: Border.all(
                  color: AppColors.goldColor.withValues(alpha: 0.5),
                  width: 1.5,
                ),
              ),
              child: const Icon(
                Icons.star_rounded,
                color: AppColors.goldColor,
                size: 38,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Henüz favori takım yok',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Puan Tablosu\'nda bir takım satırına dokun — altın yıldız görününce favorilere eklendi.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Error state ───────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              color: AppColors.textTertiary,
              size: 40,
            ),
            const SizedBox(height: 16),
            const Text(
              'Favoriler yüklenemedi',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
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
      ),
    );
  }
}
