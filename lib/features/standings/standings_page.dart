import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_theme.dart';
import '../../models/football_league.dart';
import '../../models/match.dart';
import '../../models/standing.dart';
import '../../providers/api_providers.dart';
import '../../widgets/fade_route.dart';
import '../../widgets/shimmer_box.dart';
import '../matches/match_detail_page.dart';
import '../matches/widgets/match_card.dart';
import '../matches/widgets/team_badge.dart';

class StandingsPage extends ConsumerWidget {
  const StandingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final standings = ref.watch(standingsProvider);
    final selectedLeague = ref.watch(selectedStandingsLeagueProvider);
    final ac = Theme.of(context).extension<AppColors>()!;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () => ref.read(standingsProvider.notifier).refresh(),
          color: Theme.of(context).colorScheme.primary,
          backgroundColor: ac.cardSurface,
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 100),
            children: [
              // ── Header ───────────────────────────────────────────────
              _StandingsHeader(ac: ac),
              const SizedBox(height: 16),
              // ── League Dropdown ──────────────────────────────────────
              _PremiumDropdown(
                selectedLeague: selectedLeague,
                ac: ac,
                onChanged: (league) {
                  if (league == null) return;
                  ref
                      .read(selectedStandingsLeagueProvider.notifier)
                      .selectLeague(league);
                },
              ),
              const SizedBox(height: 16),
              // ── Content ──────────────────────────────────────────────
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
                  return _GroupedStandings(items: items);
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

// ─── Header ────────────────────────────────────────────────────────────────────

class _StandingsHeader extends StatelessWidget {
  const _StandingsHeader({required this.ac});
  final AppColors ac;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [ac.headerGradientStart, ac.headerGradientEnd],
          ).createShader(bounds),
          child: const Text(
            'Puan Tablosu',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
        ),
        const Spacer(),
        Icon(
          Icons.leaderboard_rounded,
          color: ac.headerGradientStart,
          size: 24,
        ),
      ],
    );
  }
}

// ─── Premium Dropdown ──────────────────────────────────────────────────────────

class _PremiumDropdown extends StatelessWidget {
  const _PremiumDropdown({
    required this.selectedLeague,
    required this.ac,
    required this.onChanged,
  });

  final FootballLeague selectedLeague;
  final AppColors ac;
  final ValueChanged<FootballLeague?> onChanged;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final leagues = footballLeagues.where((l) => l.id != null).toList();

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: ac.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primary.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.08),
            blurRadius: 12,
            spreadRadius: -2,
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<FootballLeague>(
          value: selectedLeague,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: primary),
          dropdownColor: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF1A2540)
              : Colors.white,
          borderRadius: BorderRadius.circular(14),
          style: TextStyle(
            color: ac.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
          items: leagues
              .map(
                (league) => DropdownMenuItem(
                  value: league,
                  child: Text(league.name, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
          onChanged: onChanged,
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

    final ac = Theme.of(context).extension<AppColors>()!;
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
              style: TextStyle(
                color: ac.textPrimary,
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
    final ac = Theme.of(context).extension<AppColors>()!;

    return Container(
      decoration: BoxDecoration(
        color: ac.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ac.cardBorder),
        boxShadow: [
          BoxShadow(color: ac.cardShadow, blurRadius: 16, spreadRadius: -4),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          const _TableHeader(),
          for (int i = 0; i < items.length; i++)
            _StandingRow(standing: items[i], isLast: i == items.length - 1),
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
    final ac = Theme.of(context).extension<AppColors>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ac.headerGradientStart.withValues(alpha: isDark ? 0.2 : 0.12),
            ac.headerGradientEnd.withValues(alpha: isDark ? 0.15 : 0.08),
          ],
        ),
        border: Border(bottom: BorderSide(color: ac.divider)),
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
    final ac = Theme.of(context).extension<AppColors>()!;
    return Text(
      text,
      textAlign: end ? TextAlign.end : TextAlign.start,
      style: TextStyle(
        color: ac.textTertiary,
        fontSize: 9,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.8,
      ),
    );
  }
}

// ─── Standing Row ──────────────────────────────────────────────────────────────

class _StandingRow extends ConsumerWidget {
  const _StandingRow({required this.standing, required this.isLast});
  final Standing standing;
  final bool isLast;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ac = Theme.of(context).extension<AppColors>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isFav =
        ref.watch(favoriteTeamsProvider).value?.contains(standing.teamName) ??
        false;

    // Zone detection (Premier League style — adapt as needed)
    final Color? zoneColor = standing.rank <= 4
        ? ac.championColor
        : standing.rank == 5
        ? ac.europaColor
        : standing.rank >= 18
        ? ac.relegationColor
        : null;

    final Color rowBg = standing.rank == 1
        ? ac.goldColor.withValues(alpha: isDark ? 0.12 : 0.07)
        : zoneColor != null
        ? zoneColor.withValues(alpha: isDark ? 0.06 : 0.04)
        : Colors.transparent;

    return InkWell(
      onTap: () =>
          ref.read(favoriteTeamsProvider.notifier).toggle(standing.teamName),
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: rowBg,
          border: isLast
              ? null
              : Border(top: BorderSide(color: ac.divider, width: 0.5)),
        ),
        child: Row(
          children: [
            // ── Zone stripe ─────────────────────────────────────────
            Container(
              width: 3,
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
              child: _RankBadge(
                rank: standing.rank,
                zoneColor: zoneColor,
                ac: ac,
              ),
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
                        color: ac.textPrimary,
                        fontSize: 12,
                        fontWeight: isFav ? FontWeight.w800 : FontWeight.w600,
                      ),
                    ),
                  ),
                  if (isFav)
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Icon(
                        Icons.star_rounded,
                        color: ac.goldColor,
                        size: 13,
                      ),
                    ),
                ],
              ),
            ),
            _StatCell(standing.played, ac),
            _StatCell(standing.win, ac),
            _StatCell(standing.draw, ac),
            _StatCell(standing.loss, ac),
            // ── Points ──────────────────────────────────────────────
            SizedBox(
              width: 40,
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Text(
                  '${standing.points}',
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
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
  const _RankBadge({
    required this.rank,
    required this.zoneColor,
    required this.ac,
  });
  final int rank;
  final Color? zoneColor;
  final AppColors ac;

  @override
  Widget build(BuildContext context) {
    final isTop = rank <= 3;
    return Text(
      '$rank',
      textAlign: TextAlign.center,
      style: TextStyle(
        color: zoneColor ?? ac.textSecondary,
        fontSize: 12,
        fontWeight: isTop ? FontWeight.w900 : FontWeight.w700,
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell(this.value, this.ac);
  final int value;
  final AppColors ac;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 26,
      child: Text(
        '$value',
        textAlign: TextAlign.end,
        style: TextStyle(
          color: ac.textSecondary,
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
    final ac = Theme.of(context).extension<AppColors>()!;
    return Wrap(
      spacing: 14,
      runSpacing: 6,
      children: [
        _LegendItem(color: ac.championColor, label: 'Şampiyonlar Ligi'),
        _LegendItem(color: ac.europaColor, label: 'Avrupa Ligi'),
        _LegendItem(color: ac.relegationColor, label: 'Küme düşme'),
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
    final ac = Theme.of(context).extension<AppColors>()!;
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
          style: TextStyle(
            color: ac.textSecondary,
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
    final ac = Theme.of(context).extension<AppColors>()!;
    final favorites =
        ref.watch(favoriteTeamsProvider).value ?? const <String>{};

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
              Row(
                children: [
                  Icon(
                    Icons.emoji_events_rounded,
                    color: ac.headerGradientStart,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Eleme Eşleşmeleri',
                    style: TextStyle(
                      color: ac.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              for (final stage in orderedStages) ...[
                _StageHeader(label: _stageLabels[stage] ?? stage, ac: ac),
                const SizedBox(height: 8),
                for (final match in byStage[stage]!) ...[
                  MatchCard(
                    match: match,
                    hasFavorite:
                        favorites.contains(match.homeTeam) ||
                        favorites.contains(match.awayTeam),
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
  const _StageHeader({required this.label, required this.ac});
  final String label;
  final AppColors ac;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: ac.leagueBadgeBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: primary.withValues(alpha: 0.25)),
          ),
          child: Text(
            label.toUpperCase(),
            style: TextStyle(
              color: primary,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: Divider(height: 1, color: ac.divider)),
      ],
    );
  }
}

// ─── Skeleton ──────────────────────────────────────────────────────────────────

class _StandingsSkeleton extends StatelessWidget {
  const _StandingsSkeleton();

  @override
  Widget build(BuildContext context) {
    final ac = Theme.of(context).extension<AppColors>()!;
    return Container(
      decoration: BoxDecoration(
        color: ac.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ac.cardBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(height: 38, color: ac.shimmerBase),
          for (var i = 0; i < 8; i++)
            Container(
              height: 46,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: ac.divider, width: 0.5)),
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
    final ac = Theme.of(context).extension<AppColors>()!;
    final primary = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 54),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: primary.withValues(alpha: 0.1),
              border: Border.all(color: primary.withValues(alpha: 0.2)),
            ),
            child: Icon(Icons.leaderboard_outlined, color: primary, size: 32),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: ac.textPrimary,
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
            style: TextStyle(
              color: ac.textSecondary,
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
