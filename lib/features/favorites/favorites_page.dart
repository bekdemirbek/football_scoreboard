import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_theme.dart';
import '../../models/favorite_team.dart';
import '../../providers/api_providers.dart';
import '../../widgets/fade_route.dart';
import '../matches/match_detail_page.dart';
import '../matches/widgets/match_card.dart';
import '../matches/widgets/team_badge.dart';
import 'team_profile_sheet.dart';

class FavoritesPage extends ConsumerWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ac = Theme.of(context).extension<AppColors>()!;
    final favoritesAsync = ref.watch(favoriteTeamsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: favoritesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator.adaptive()),
          error: (e, _) => _ErrorState(message: e.toString(), ac: ac),
          data: (teams) => teams.isEmpty
              ? _EmptyState(ac: ac)
              : _FavoritesContent(teams: teams, ac: ac),
        ),
      ),
    );
  }
}

// ─── Content ───────────────────────────────────────────────────────────────────

class _FavoritesContent extends ConsumerWidget {
  const _FavoritesContent({required this.teams, required this.ac});

  final List<FavoriteTeam> teams;
  final AppColors ac;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final primary = Theme.of(context).colorScheme.primary;
    final favNotifier = ref.watch(favoriteTeamsProvider.notifier);

    return RefreshIndicator(
      onRefresh: () => ref.refresh(favoriteTeamsProvider.future),
      color: primary,
      backgroundColor: ac.cardSurface,
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 100),
        children: [
          _FavoritesHeader(ac: ac),
          const SizedBox(height: 20),
          for (final team in teams) ...[
            _TeamSection(
              team: team,
              ac: ac,
              primary: primary,
              favNotifier: favNotifier,
            ),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }
}

// ─── Header ────────────────────────────────────────────────────────────────────

class _FavoritesHeader extends StatelessWidget {
  const _FavoritesHeader({required this.ac});
  final AppColors ac;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [ac.headerGradientStart, ac.headerGradientEnd],
          ).createShader(bounds),
          child: const Text(
            'Favoriler',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.8,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Takıma tıkla → profil ve maç geçmişi',
          style: TextStyle(
            color: ac.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ─── Per-team section ──────────────────────────────────────────────────────────

class _TeamSection extends ConsumerWidget {
  const _TeamSection({
    required this.team,
    required this.ac,
    required this.primary,
    required this.favNotifier,
  });

  final FavoriteTeam team;
  final AppColors ac;
  final Color primary;
  final FavoriteTeamsNotifier favNotifier;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Team header row ────────────────────────────────────────────────
        GestureDetector(
          onTap: () => TeamProfileSheet.show(context, team),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: ac.cardSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: ac.cardBorder),
            ),
            child: Row(
              children: [
                TeamBadge(teamName: team.name, size: 36),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    team.name,
                    style: TextStyle(
                      color: ac.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: ac.textTertiary,
                  size: 20,
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () =>
                      ref.read(favoriteTeamsProvider.notifier).toggle(team),
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.star_rounded,
                      color: ac.goldColor,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // ── Match list (only if team has an ID for API lookup) ─────────────
        if (team.id.isNotEmpty)
          _TeamMatchPreview(team: team, ac: ac, primary: primary, favNotifier: favNotifier),
      ],
    );
  }
}

// ─── Inline match preview (3 most-recent + next) ───────────────────────────────

class _TeamMatchPreview extends ConsumerWidget {
  const _TeamMatchPreview({
    required this.team,
    required this.ac,
    required this.primary,
    required this.favNotifier,
  });

  final FavoriteTeam team;
  final AppColors ac;
  final Color primary;
  final FavoriteTeamsNotifier favNotifier;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchesAsync = ref.watch(teamMatchesProvider(team.id));

    return matchesAsync.when(
      loading: () => Padding(
        padding: const EdgeInsets.only(top: 8),
        child: _MatchSkeleton(ac: ac),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.only(top: 8, left: 4),
        child: Text(
          'Maçlar yüklenemedi',
          style: TextStyle(color: ac.textTertiary, fontSize: 12),
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
                hasFavorite: favNotifier.isFavoriteByName(m.homeTeam) ||
                    favNotifier.isFavoriteByName(m.awayTeam),
                onTap: () => Navigator.of(context).push(
                  FadeRoute(child: MatchDetailPage(match: m)),
                ),
              ),
              const SizedBox(height: 6),
            ],
            // "Tüm maçları gör" link
            GestureDetector(
              onTap: () => TeamProfileSheet.show(context, team),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Tüm maçları gör',
                      style: TextStyle(
                        color: primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 13,
                      color: primary,
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
  const _MatchSkeleton({required this.ac});
  final AppColors ac;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: ac.cardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ac.cardBorder),
      ),
      child: Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: ac.textTertiary,
          ),
        ),
      ),
    );
  }
}

// ─── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.ac});
  final AppColors ac;

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
                    ac.goldColor.withValues(alpha: 0.3),
                    ac.goldColor.withValues(alpha: 0.1),
                  ],
                ),
                border: Border.all(
                  color: ac.goldColor.withValues(alpha: 0.5),
                  width: 1.5,
                ),
              ),
              child: Icon(Icons.star_rounded, color: ac.goldColor, size: 38),
            ),
            const SizedBox(height: 20),
            Text(
              'Henüz favori takım yok',
              style: TextStyle(
                color: ac.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Puan Tablosu\'nda bir takım satırına dokun — altın yıldız görününce favorilere eklendi.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: ac.textSecondary,
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
  const _ErrorState({required this.message, required this.ac});
  final String message;
  final AppColors ac;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_rounded, color: ac.textTertiary, size: 40),
            const SizedBox(height: 16),
            Text(
              'Favoriler yüklenemedi',
              style: TextStyle(
                color: ac.textPrimary,
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
              style: TextStyle(color: ac.textSecondary, fontSize: 12, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
