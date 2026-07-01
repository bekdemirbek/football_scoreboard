import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_theme.dart';
import '../../models/favorite_team.dart';
import '../../models/match.dart';
import '../../models/standing.dart';
import '../../providers/api_providers.dart';
import '../../widgets/fade_route.dart';
import '../../widgets/screen_header.dart';
import '../../widgets/shimmer_box.dart';
import '../matches/match_detail_page.dart';
import '../team/team_squad_page.dart';
import '../matches/widgets/league_selector.dart';
import '../matches/widgets/match_card.dart';
import '../matches/widgets/team_badge.dart';

class StandingsPage extends ConsumerWidget {
  const StandingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final standings = ref.watch(standingsProvider);
    final selectedLeague = ref.watch(selectedStandingsLeagueProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () => ref.read(standingsProvider.notifier).refresh(),
          color: AppColors.accentGreen,
          backgroundColor: AppColors.cardSurface,
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 100),
            children: [
              ScreenHeader(
                title: 'Puan Durumu',
                searchHint: 'Takım ara…',
                onSearchChanged: (q) =>
                    ref.read(standingsSearchProvider.notifier).set(q),
              ),
              const SizedBox(height: 16),
              LeagueSelector(
                selectedLeague: selectedLeague,
                onLeagueSelected: (league) => ref
                    .read(selectedStandingsLeagueProvider.notifier)
                    .selectLeague(league),
              ),
              const SizedBox(height: 16),
              standings.when(
                loading: () => const _StandingsSkeleton(),
                error: (error, _) => _StandingsMessage(
                  title: 'Puan tablosu yüklenemedi',
                  message: error.toString(),
                  onPressed: () =>
                      ref.read(standingsProvider.notifier).refresh(),
                ),
                data: (items) {
                  if (items.isEmpty) {
                    return _StandingsMessage(
                      title: 'Puan tablosu bulunamadı',
                      message:
                          '${selectedLeague.name} için API tarafında veri yok.',
                      onPressed: () =>
                          ref.read(standingsProvider.notifier).refresh(),
                    );
                  }
                  final query = ref
                      .watch(standingsSearchProvider)
                      .trim()
                      .toLowerCase();
                  final filtered = query.isEmpty
                      ? items
                      : items
                            .where(
                              (s) => s.teamName.toLowerCase().contains(query),
                            )
                            .toList();
                  if (filtered.isEmpty) {
                    return _StandingsMessage(
                      title: 'Sonuç yok',
                      message: '"$query" için eşleşen takım yok.',
                      onPressed: () =>
                          ref.read(standingsSearchProvider.notifier).set(''),
                    );
                  }
                  return _GroupedStandings(items: filtered);
                },
              ),
              const SizedBox(height: 16),
              const _Legend(),
              const _KnockoutSection(),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Grouped Standings ─────────────────────────────────────────────────────────

class _GroupedStandings extends StatelessWidget {
  const _GroupedStandings({required this.items});
  final List<Standing> items;

  @override
  Widget build(BuildContext context) {
    final groups = items.map((s) => s.group).whereType<String>().toSet();

    if (groups.length < 2) {
      return _StandingsTable(items: items);
    }

    final byGroup = <String, List<Standing>>{};
    for (final item in items) {
      byGroup.putIfAbsent(item.group ?? '', () => <Standing>[]).add(item);
    }

    final entries = byGroup.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final entry in entries) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
            child: Text(
              entry.key,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          _StandingsTable(items: entry.value),
          const SizedBox(height: 16),
        ],
      ],
    );
  }
}

// ─── Standings Table ───────────────────────────────────────────────────────────

class _StandingsTable extends StatelessWidget {
  const _StandingsTable({required this.items});
  final List<Standing> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 16,
            spreadRadius: -4,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          const _TableHeader(),
          for (int i = 0; i < items.length; i++)
            _StandingRow(
              standing: items[i],
              total: items.length,
              isLast: i == items.length - 1,
            ),
        ],
      ),
    );
  }
}

// ─── Table Header ──────────────────────────────────────────────────────────────

class _TableHeader extends StatelessWidget {
  const _TableHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.headerGradientStart.withValues(alpha: 0.2),
            AppColors.headerGradientEnd.withValues(alpha: 0.15),
          ],
        ),
        border: const Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: const Row(
        children: [
          SizedBox(width: 26, child: _HeaderCell('#')),
          Expanded(child: _HeaderCell('TAKIM')),
          SizedBox(width: 26, child: _HeaderCell('O', end: true)),
          SizedBox(width: 26, child: _HeaderCell('G', end: true)),
          SizedBox(width: 26, child: _HeaderCell('B', end: true)),
          SizedBox(width: 26, child: _HeaderCell('M', end: true)),
          SizedBox(width: 40, child: _HeaderCell('PUAN', end: true)),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell(this.text, {this.end = false});
  final String text;
  final bool end;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: end ? TextAlign.end : TextAlign.start,
      style: const TextStyle(
        color: AppColors.textTertiary,
        fontSize: 9,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.8,
      ),
    );
  }
}

// ─── Standing Row ──────────────────────────────────────────────────────────────

class _StandingRow extends ConsumerWidget {
  const _StandingRow({
    required this.standing,
    required this.total,
    required this.isLast,
  });
  final Standing standing;
  final int total;
  final bool isLast;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFav = ref
        .watch(favoriteTeamsProvider.notifier)
        .isFavoriteByName(standing.teamName);

    // Bölge: ilk 4 → Avrupa kupaları (yeşil), son 3 → küme düşme (kırmızı).
    final Color? zoneColor = standing.rank <= 4
        ? AppColors.championColor
        : standing.rank > total - 3
        ? AppColors.relegationColor
        : null;

    final Color rowBg = standing.rank == 1
        ? AppColors.goldColor.withValues(alpha: 0.12)
        : zoneColor != null
        ? zoneColor.withValues(alpha: 0.06)
        : Colors.transparent;

    return InkWell(
      onTap: () => Navigator.of(context).push(
        FadeRoute(
          child: TeamSquadPage(
            teamId: standing.teamId,
            teamName: standing.teamName,
          ),
        ),
      ),
      onLongPress: () => ref
          .read(favoriteTeamsProvider.notifier)
          .toggle(FavoriteTeam(id: standing.teamId, name: standing.teamName)),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: rowBg,
          border: isLast
              ? null
              : const Border(
                  top: BorderSide(color: AppColors.divider, width: 0.5),
                ),
        ),
        child: Row(
          children: [
            // ── Zone stripe (ince renkli şerit) ─────────────────────
            Container(
              width: 4,
              height: double.infinity,
              decoration: BoxDecoration(
                gradient: zoneColor != null
                    ? LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [zoneColor, zoneColor.withValues(alpha: 0.3)],
                      )
                    : null,
                color: zoneColor == null ? Colors.transparent : null,
              ),
            ),
            const SizedBox(width: 9),
            // ── Rank ────────────────────────────────────────────────
            SizedBox(
              width: 22,
              child: _RankBadge(rank: standing.rank, zoneColor: zoneColor),
            ),
            const SizedBox(width: 8),
            // ── Team ────────────────────────────────────────────────
            Expanded(
              child: Row(
                children: [
                  TeamBadge(teamName: standing.teamName, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      standing.teamName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 12,
                        fontWeight: isFav ? FontWeight.w800 : FontWeight.w600,
                      ),
                    ),
                  ),
                  if (isFav)
                    const Padding(
                      padding: EdgeInsets.only(right: 4),
                      child: Icon(
                        Icons.star_rounded,
                        color: AppColors.goldColor,
                        size: 13,
                      ),
                    ),
                ],
              ),
            ),
            _StatCell(standing.played),
            _StatCell(standing.win),
            _StatCell(standing.draw),
            _StatCell(standing.loss),
            // ── Points ──────────────────────────────────────────────
            SizedBox(
              width: 40,
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Text(
                  '${standing.points}',
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                    color: AppColors.accentGreen,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RankBadge extends StatelessWidget {
  const _RankBadge({required this.rank, required this.zoneColor});
  final int rank;
  final Color? zoneColor;

  @override
  Widget build(BuildContext context) {
    final isTop = rank <= 3;
    return Text(
      '$rank',
      textAlign: TextAlign.center,
      style: TextStyle(
        color: zoneColor ?? AppColors.textSecondary,
        fontSize: 12,
        fontWeight: isTop ? FontWeight.w900 : FontWeight.w700,
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell(this.value);
  final int value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 26,
      child: Text(
        '$value',
        textAlign: TextAlign.end,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ─── Legend ────────────────────────────────────────────────────────────────────

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    return const Wrap(
      spacing: 14,
      runSpacing: 6,
      children: [
        _LegendItem(color: AppColors.championColor, label: 'Avrupa kupaları'),
        _LegendItem(color: AppColors.relegationColor, label: 'Küme düşme'),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 4),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ─── Knockout Section ──────────────────────────────────────────────────────────

class _KnockoutSection extends ConsumerWidget {
  const _KnockoutSection();

  static const _stageOrder = [
    'LAST_32',
    'LAST_16',
    'ROUND_OF_16',
    'QUARTER_FINALS',
    'QUARTER_FINAL',
    'SEMI_FINALS',
    'SEMI_FINAL',
    'THIRD_PLACE',
    'FINAL',
  ];

  static const _stageLabels = {
    'LAST_32': 'Son 32',
    'LAST_16': 'Son 16',
    'ROUND_OF_16': 'Son 16',
    'QUARTER_FINALS': 'Çeyrek Final',
    'QUARTER_FINAL': 'Çeyrek Final',
    'SEMI_FINALS': 'Yarı Final',
    'SEMI_FINAL': 'Yarı Final',
    'THIRD_PLACE': '3.lük Maçı',
    'FINAL': 'Final',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final knockout = ref.watch(knockoutMatchesProvider);
    final favNotifier = ref.watch(favoriteTeamsProvider.notifier);

    return knockout.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (matches) {
        if (matches.isEmpty) return const SizedBox.shrink();

        final byStage = <String, List<Match>>{};
        for (final match in matches) {
          final stage = match.stage?.toUpperCase() ?? '';
          byStage.putIfAbsent(stage, () => <Match>[]).add(match);
        }
        final orderedStages = _stageOrder.where(byStage.containsKey).toList();

        return Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.emoji_events_rounded,
                    color: AppColors.headerGradientStart,
                    size: 18,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Eleme Eşleşmeleri',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              for (final stage in orderedStages) ...[
                _StageHeader(label: _stageLabels[stage] ?? stage),
                const SizedBox(height: 8),
                for (final match in byStage[stage]!) ...[
                  MatchCard(
                    match: match,
                    hasFavorite:
                        favNotifier.isFavoriteByName(match.homeTeam) ||
                        favNotifier.isFavoriteByName(match.awayTeam),
                    onTap: () => Navigator.of(
                      context,
                    ).push(FadeRoute(child: MatchDetailPage(match: match))),
                  ),
                  const SizedBox(height: 8),
                ],
                const SizedBox(height: 8),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _StageHeader extends StatelessWidget {
  const _StageHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.leagueBadgeBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.accentGreen.withValues(alpha: 0.25),
            ),
          ),
          child: Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: AppColors.accentGreen,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
            ),
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(child: Divider(height: 1, color: AppColors.divider)),
      ],
    );
  }
}

// ─── Skeleton ──────────────────────────────────────────────────────────────────

class _StandingsSkeleton extends StatelessWidget {
  const _StandingsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(height: 38, color: AppColors.shimmerBase),
          for (var i = 0; i < 8; i++)
            Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: AppColors.divider, width: 0.5),
                ),
              ),
              child: Row(
                children: [
                  ShimmerBox(width: 20, height: 14, borderRadius: 4),
                  const SizedBox(width: 10),
                  ShimmerBox(width: 22, height: 22, borderRadius: 11),
                  const SizedBox(width: 8),
                  ShimmerBox(
                    width: 100 + (i % 3) * 20.0,
                    height: 12,
                    borderRadius: 5,
                  ),
                  const Spacer(),
                  ShimmerBox(width: 32, height: 16, borderRadius: 5),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Error / Empty Message ─────────────────────────────────────────────────────

class _StandingsMessage extends StatelessWidget {
  const _StandingsMessage({
    required this.title,
    required this.message,
    required this.onPressed,
  });

  final String title;
  final String message;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 54),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accentGreen.withValues(alpha: 0.1),
              border: Border.all(
                color: AppColors.accentGreen.withValues(alpha: 0.2),
              ),
            ),
            child: const Icon(
              Icons.leaderboard_outlined,
              color: AppColors.accentGreen,
              size: 32,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
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
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: onPressed,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Yenile'),
          ),
        ],
      ),
    );
  }
}
