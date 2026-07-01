import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_theme.dart';
import '../../../models/match.dart';
import '../../../models/match_detail.dart';
import '../../../providers/api_providers.dart';
import '../../../widgets/shimmer_box.dart';
import 'match_events_card.dart';
import 'match_lineups_card.dart';
import 'match_statistics_card.dart';

class MatchDetailSections extends ConsumerWidget {
  const MatchDetailSections({super.key, required this.match});

  final Match match;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(matchDetailProvider(match));

    return detailAsync.when(
      loading: () => const _LoadingSkeleton(),
      error: (_, _) => const _InfoNotice(
        message: 'Maç detayları yüklenirken bir sorun oluştu.',
      ),
      data: (detail) {
        if (!detail.available) {
          return _InfoNotice(
            message: detail.reason ?? 'Bu maç için detay verisi bulunamadı.',
          );
        }
        if (!detail.hasAnyData) {
          return const _InfoNotice(
            message: 'Bu maç için henüz kadro veya istatistik yayınlanmadı.',
          );
        }

        return _DetailTabs(detail: detail, match: match);
      },
    );
  }
}

class _DetailTabs extends StatefulWidget {
  const _DetailTabs({required this.detail, required this.match});

  final MatchDetail detail;
  final Match match;

  @override
  State<_DetailTabs> createState() => _DetailTabsState();
}

class _DetailTabsState extends State<_DetailTabs> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final detail = widget.detail;

    final tabs = <(String, Widget)>[
      if (detail.hasEvents) ('Maç', MatchEventsTab(detail: detail)),
      if (detail.hasLineups)
        (
          'Kadro',
          MatchLineupsTab(home: detail.homeLineup!, away: detail.awayLineup!),
        ),
      if (detail.hasStats)
        (
          'İstatistik',
          MatchStatsTab(
            rows: detail.statRows,
            homeTeam: widget.match.homeTeam,
            awayTeam: widget.match.awayTeam,
          ),
        ),
    ];

    if (tabs.isEmpty) return const SizedBox.shrink();
    final index = _index.clamp(0, tabs.length - 1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SegmentedTabBar(
          labels: [for (final t in tabs) t.$1],
          selectedIndex: index,
          onSelected: (i) => setState(() => _index = i),
        ),
        const SizedBox(height: 14),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: KeyedSubtree(key: ValueKey(index), child: tabs[index].$2),
        ),
      ],
    );
  }
}

class _SegmentedTabBar extends StatelessWidget {
  const _SegmentedTabBar({
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    const primary = AppColors.accentGreen;
    const onPrimary = AppColors.bgPrimary;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.unselectedPill,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          for (var i = 0; i < labels.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: () => onSelected(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: BoxDecoration(
                    color: i == selectedIndex ? primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    labels[i],
                    style: TextStyle(
                      color: i == selectedIndex
                          ? onPrimary
                          : AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LoadingSkeleton extends StatelessWidget {
  const _LoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ShimmerBox(height: 40, borderRadius: 12),
        const SizedBox(height: 14),
        for (final height in const [110.0, 160.0]) ...[
          Container(
            decoration: BoxDecoration(
              color: AppColors.cardSurface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.cardBorder),
            ),
            padding: const EdgeInsets.all(16),
            child: ShimmerBox(height: height, borderRadius: 10),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _InfoNotice extends StatelessWidget {
  const _InfoNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: AppColors.textTertiary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
