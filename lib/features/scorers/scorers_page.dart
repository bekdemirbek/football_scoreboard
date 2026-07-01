import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_theme.dart';
import '../../models/scorer.dart';
import '../../providers/api_providers.dart';
import '../../widgets/screen_header.dart';
import '../../widgets/shimmer_box.dart';
import '../matches/widgets/league_selector.dart';

class ScorersPage extends ConsumerWidget {
  const ScorersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedLeague = ref.watch(selectedScorersLeagueProvider);
    final mode = ref.watch(scorerSortModeProvider);
    final scorers = ref.watch(scorersProvider);

    final title = mode == ScorerSortMode.assists
        ? 'Asist Krallığı'
        : 'Gol Krallığı';

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: scorers.when(
          loading: () =>
              _ScorersLoading(selectedLeague: selectedLeague, ref: ref),
          error: (error, _) => _ScorersMessage(
            title: '$title yüklenemedi',
            message: error.toString(),
            selectedLeague: selectedLeague,
            onPressed: () => ref.read(scorersProvider.notifier).refresh(),
            ref: ref,
          ),
          data: (items) {
            final query = ref.watch(scorersSearchProvider).trim().toLowerCase();
            final ranked = _rankFor(items, mode)
                .where(
                  (e) =>
                      query.isEmpty ||
                      e.scorer.playerName.toLowerCase().contains(query) ||
                      e.scorer.teamName.toLowerCase().contains(query),
                )
                .toList();
            return ranked.isEmpty
                ? _ScorersMessage(
                    title: query.isEmpty ? 'Veri bulunamadı' : 'Sonuç yok',
                    message: query.isEmpty
                        ? '${selectedLeague.name} için bu sezon veri yok.'
                        : '"$query" için eşleşen oyuncu/takım yok.',
                    selectedLeague: selectedLeague,
                    onPressed: () =>
                        ref.read(scorersProvider.notifier).refresh(),
                    ref: ref,
                  )
                : _ScorersContent(
                    entries: ranked,
                    mode: mode,
                    selectedLeague: selectedLeague,
                    ref: ref,
                  );
          },
        ),
      ),
    );
  }
}

/// Moda göre sıralanmış (rank, scorer, value) üçlüleri üretir.
/// Asist modunda asiste göre yeniden sıralayıp yeniden numaralandırır.
List<_RankedScorer> _rankFor(List<Scorer> items, ScorerSortMode mode) {
  if (mode == ScorerSortMode.assists) {
    final sorted = [...items]..sort((a, b) => b.assists.compareTo(a.assists));
    final withAssists = sorted.where((s) => s.assists > 0).toList();
    return [
      for (var i = 0; i < withAssists.length; i++)
        _RankedScorer(
          rank: i + 1,
          scorer: withAssists[i],
          value: withAssists[i].assists,
        ),
    ];
  }
  return [
    for (final s in items)
      _RankedScorer(rank: s.rank, scorer: s, value: s.goals),
  ];
}

class _RankedScorer {
  const _RankedScorer({
    required this.rank,
    required this.scorer,
    required this.value,
  });

  final int rank;
  final Scorer scorer;
  final int value;
}

// ─── Header + League selector (her durumda aynı) ───────────────────────────────

class _ScorersTop extends ConsumerWidget {
  const _ScorersTop({required this.selectedLeague});

  final dynamic selectedLeague;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(scorerSortModeProvider);
    final title = mode == ScorerSortMode.assists
        ? 'Asist Krallığı'
        : 'Gol Krallığı';

    return Column(
      children: [
        ScreenHeader(
          title: title,
          searchHint: 'Oyuncu veya takım ara…',
          onSearchChanged: (q) =>
              ref.read(scorersSearchProvider.notifier).set(q),
        ),
        const SizedBox(height: 16),
        SegmentedTabs<ScorerSortMode>(
          items: const [ScorerSortMode.goals, ScorerSortMode.assists],
          selected: mode,
          labelOf: (m) =>
              m == ScorerSortMode.assists ? 'Asist Krallığı' : 'Gol Krallığı',
          onSelected: (m) =>
              ref.read(scorerSortModeProvider.notifier).select(m),
        ),
        const SizedBox(height: 12),
        LeagueSelector(
          selectedLeague: selectedLeague,
          onLeagueSelected: (l) =>
              ref.read(selectedScorersLeagueProvider.notifier).selectLeague(l),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

// ─── Content ───────────────────────────────────────────────────────────────────

class _ScorersContent extends StatelessWidget {
  const _ScorersContent({
    required this.entries,
    required this.mode,
    required this.selectedLeague,
    required this.ref,
  });

  final List<_RankedScorer> entries;
  final ScorerSortMode mode;
  final dynamic selectedLeague;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => ref.read(scorersProvider.notifier).refresh(),
      color: AppColors.accentGreen,
      backgroundColor: AppColors.cardSurface,
      child: ListView.builder(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        itemCount: entries.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _ScorersTop(selectedLeague: selectedLeague);
          }
          final entry = entries[index - 1];
          return _ScorerRow(
            key: ValueKey('${mode.name}-${entry.scorer.playerName}'),
            rank: entry.rank,
            playerName: entry.scorer.playerName,
            teamName: entry.scorer.teamName,
            value: entry.value,
            animationDelay: Duration(milliseconds: (index - 1) * 45),
          );
        },
      ),
    );
  }
}

// ─── Scorer Row (görseldeki imza satır) ─────────────────────────────────────────

class _ScorerRow extends StatefulWidget {
  const _ScorerRow({
    super.key,
    required this.rank,
    required this.playerName,
    required this.teamName,
    required this.value,
    required this.animationDelay,
  });

  final int rank;
  final String playerName;
  final String teamName;
  final int value;
  final Duration animationDelay;

  @override
  State<_ScorerRow> createState() => _ScorerRowState();
}

class _ScorerRowState extends State<_ScorerRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );
    Future.delayed(widget.animationDelay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gradient = AppGradients.rankGradient(widget.rank);
    final isTop = widget.rank <= 3;

    return FadeTransition(
      opacity: _controller,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0.06, 0), end: Offset.zero)
            .animate(
              CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
            ),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: EdgeInsets.all(isTop ? 1.4 : 1),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: isTop
                ? gradient
                : LinearGradient(
                    colors: [AppColors.cardBorder, AppColors.cardBorder],
                  ),
            boxShadow: isTop
                ? [
                    BoxShadow(
                      color: gradient.colors.first.withValues(alpha: 0.18),
                      blurRadius: 16,
                      spreadRadius: -4,
                    ),
                  ]
                : null,
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.cardBgRaised, AppColors.cardBg],
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            child: Row(
              children: [
                // ── Sıra numarası (gradyan dolgulu) ─────────────────────
                SizedBox(
                  width: 38,
                  child: ShaderMask(
                    shaderCallback: (b) => gradient.createShader(b),
                    child: Text(
                      '${widget.rank}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        height: 1.0,
                        letterSpacing: -1,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // ── Oyuncu + takım ──────────────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.playerName,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        widget.teamName,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // ── Gol sayısı ──────────────────────────────────────────
                ShaderMask(
                  shaderCallback: (b) => gradient.createShader(b),
                  child: Text(
                    '${widget.value}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      height: 1.0,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Loading State ─────────────────────────────────────────────────────────────

class _ScorersLoading extends StatelessWidget {
  const _ScorersLoading({required this.selectedLeague, required this.ref});

  final dynamic selectedLeague;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      children: [
        _ScorersTop(selectedLeague: selectedLeague),
        for (var i = 0; i < 9; i++) ...[
          const _SkeletonRow(),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _SkeletonRow extends StatelessWidget {
  const _SkeletonRow();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 66,
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          ShimmerBox(width: 28, height: 30, borderRadius: 6),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ShimmerBox(width: 130, height: 14, borderRadius: 5),
                const SizedBox(height: 7),
                ShimmerBox(width: 90, height: 11, borderRadius: 4),
              ],
            ),
          ),
          const SizedBox(width: 14),
          ShimmerBox(width: 30, height: 26, borderRadius: 6),
        ],
      ),
    );
  }
}

// ─── Empty / Error State ───────────────────────────────────────────────────────

class _ScorersMessage extends StatelessWidget {
  const _ScorersMessage({
    required this.title,
    required this.message,
    required this.selectedLeague,
    required this.onPressed,
    required this.ref,
  });

  final String title;
  final String message;
  final dynamic selectedLeague;
  final VoidCallback onPressed;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      children: [
        _ScorersTop(selectedLeague: selectedLeague),
        const SizedBox(height: 64),
        Center(
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accentGreen.withValues(alpha: 0.1),
              border: Border.all(
                color: AppColors.accentGreen.withValues(alpha: 0.2),
                width: 1.5,
              ),
            ),
            child: const Icon(
              Icons.emoji_events_rounded,
              color: AppColors.goldColor,
              size: 36,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
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
        const SizedBox(height: 24),
        Center(
          child: FilledButton.icon(
            onPressed: onPressed,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Tekrar dene'),
          ),
        ),
      ],
    );
  }
}
