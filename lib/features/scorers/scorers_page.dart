import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_theme.dart';
import '../../models/scorer.dart';
import '../../providers/api_providers.dart';
import '../../widgets/shimmer_box.dart';
import '../matches/widgets/league_selector.dart';

class ScorersPage extends ConsumerWidget {
  const ScorersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ac = Theme.of(context).extension<AppColors>()!;
    final selectedLeague = ref.watch(selectedScorersLeagueProvider);
    final scorers = ref.watch(scorersProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: scorers.when(
          loading: () => _ScorersLoading(
            selectedLeague: selectedLeague,
            ac: ac,
            ref: ref,
          ),
          error: (error, _) => _ScorersMessage(
            title: 'Gol krallığı yüklenemedi',
            message: error.toString(),
            selectedLeague: selectedLeague,
            onPressed: () => ref.read(scorersProvider.notifier).refresh(),
            ref: ref,
          ),
          data: (items) => items.isEmpty
              ? _ScorersMessage(
                  title: 'Veri bulunamadı',
                  message:
                      '${selectedLeague.name} için bu sezon skor verisi yok.',
                  selectedLeague: selectedLeague,
                  onPressed: () =>
                      ref.read(scorersProvider.notifier).refresh(),
                  ref: ref,
                )
              : _ScorersContent(
                  scorers: items,
                  selectedLeague: selectedLeague,
                  ref: ref,
                ),
        ),
      ),
    );
  }
}

// ─── Content ───────────────────────────────────────────────────────────────────

class _ScorersContent extends StatelessWidget {
  const _ScorersContent({
    required this.scorers,
    required this.selectedLeague,
    required this.ref,
  });

  final List<Scorer> scorers;
  final dynamic selectedLeague;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final ac = Theme.of(context).extension<AppColors>()!;
    final maxGoals = scorers.isEmpty ? 1 : scorers.first.goals;

    return RefreshIndicator(
      onRefresh: () => ref.read(scorersProvider.notifier).refresh(),
      color: Theme.of(context).colorScheme.primary,
      backgroundColor: ac.cardSurface,
      child: ListView.builder(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 100),
        itemCount: scorers.length + 2, // header + league selector + items
        itemBuilder: (context, index) {
          if (index == 0) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ScorersHeader(ac: ac),
                const SizedBox(height: 16),
                LeagueSelector(
                  selectedLeague: selectedLeague,
                  onLeagueSelected: (l) => ref
                      .read(selectedScorersLeagueProvider.notifier)
                      .selectLeague(l),
                ),
                const SizedBox(height: 20),
              ],
            );
          }
          if (index == 1) {
            return _TopThreePodium(
              scorers: scorers.take(3).toList(),
              maxGoals: maxGoals,
              ac: ac,
            );
          }
          final scorer = scorers[index - 2];
          if (scorer.rank <= 3) return const SizedBox.shrink();

          return _ScorerRow(
            scorer: scorer,
            maxGoals: maxGoals,
            ac: ac,
            animationDelay: Duration(milliseconds: (scorer.rank - 3) * 60),
          );
        },
      ),
    );
  }
}

// ─── Header ────────────────────────────────────────────────────────────────────

class _ScorersHeader extends StatelessWidget {
  const _ScorersHeader({required this.ac});
  final AppColors ac;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => LinearGradient(
        colors: [ac.headerGradientStart, ac.headerGradientEnd],
      ).createShader(bounds),
      child: const Text(
        'Gol Krallığı',
        style: TextStyle(
          color: Colors.white,
          fontSize: 28,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.8,
        ),
      ),
    );
  }
}

// ─── Top-3 Podium ──────────────────────────────────────────────────────────────

class _TopThreePodium extends StatefulWidget {
  const _TopThreePodium({
    required this.scorers,
    required this.maxGoals,
    required this.ac,
  });

  final List<Scorer> scorers;
  final int maxGoals;
  final AppColors ac;

  @override
  State<_TopThreePodium> createState() => _TopThreePodiumState();
}

class _TopThreePodiumState extends State<_TopThreePodium>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          for (int i = 0; i < widget.scorers.length; i++)
            _PodiumCard(
              scorer: widget.scorers[i],
              maxGoals: widget.maxGoals,
              ac: widget.ac,
              controller: _controller,
              delay: i * 0.18,
            ),
        ],
      ),
    );
  }
}

class _PodiumCard extends StatelessWidget {
  const _PodiumCard({
    required this.scorer,
    required this.maxGoals,
    required this.ac,
    required this.controller,
    required this.delay,
  });

  final Scorer scorer;
  final int maxGoals;
  final AppColors ac;
  final AnimationController controller;
  final double delay;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final slideAnim = Tween<Offset>(
      begin: const Offset(-0.3, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: controller,
        curve: Interval(delay, delay + 0.6, curve: Curves.easeOutCubic),
      ),
    );

    final fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: controller,
        curve: Interval(delay, delay + 0.5, curve: Curves.easeOut),
      ),
    );

    final medalColor = _medalColor(scorer.rank);
    final fraction = maxGoals > 0 ? scorer.goals / maxGoals : 0.0;

    return FadeTransition(
      opacity: fadeAnim,
      child: SlideTransition(
        position: slideAnim,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: ac.cardSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: medalColor.withValues(alpha: 0.45),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: medalColor.withValues(alpha: isDark ? 0.18 : 0.1),
                blurRadius: 14,
                spreadRadius: -2,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // ── Medal badge ─────────────────────────────────────────
                _MedalBadge(rank: scorer.rank, color: medalColor),
                const SizedBox(width: 14),
                // ── Player info ──────────────────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        scorer.playerName,
                        style: TextStyle(
                          color: ac.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        scorer.teamName,
                        style: TextStyle(
                          color: ac.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      // ── Goal bar ──────────────────────────────────────
                      _AnimatedGoalBar(
                        fraction: fraction,
                        color: medalColor,
                        controller: controller,
                        delay: delay + 0.2,
                        ac: ac,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                // ── Stats ────────────────────────────────────────────────
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _StatChip(
                      value: scorer.goals,
                      label: 'GOL',
                      color: medalColor,
                      primary: primary,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${scorer.assists} asist',
                      style: TextStyle(
                        color: ac.textTertiary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _medalColor(int rank) => switch (rank) {
    1 => const Color(0xFFFFD700),
    2 => const Color(0xFFC0C0C0),
    _ => const Color(0xFFCD7F32),
  };
}

// ─── Medal Badge ───────────────────────────────────────────────────────────────

class _MedalBadge extends StatefulWidget {
  const _MedalBadge({required this.rank, required this.color});
  final int rank;
  final Color color;

  @override
  State<_MedalBadge> createState() => _MedalBadgeState();
}

class _MedalBadgeState extends State<_MedalBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glow;

  @override
  void initState() {
    super.initState();
    _glow = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final icon = switch (widget.rank) {
      1 => '🥇',
      2 => '🥈',
      _ => '🥉',
    };

    return AnimatedBuilder(
      animation: _glow,
      builder: (_, child) => Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.color.withValues(alpha: 0.12),
          border: Border.all(
            color: widget.color.withValues(
              alpha: 0.4 + 0.3 * _glow.value,
            ),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: widget.color.withValues(alpha: 0.15 + 0.2 * _glow.value),
              blurRadius: 12 + 6 * _glow.value,
              spreadRadius: -2,
            ),
          ],
        ),
        child: child,
      ),
      child: Center(
        child: Text(icon, style: const TextStyle(fontSize: 22)),
      ),
    );
  }
}

// ─── Animated Goal Bar ─────────────────────────────────────────────────────────

class _AnimatedGoalBar extends StatelessWidget {
  const _AnimatedGoalBar({
    required this.fraction,
    required this.color,
    required this.controller,
    required this.delay,
    required this.ac,
  });

  final double fraction;
  final Color color;
  final AnimationController controller;
  final double delay;
  final AppColors ac;

  @override
  Widget build(BuildContext context) {
    final barAnim = Tween<double>(begin: 0, end: fraction).animate(
      CurvedAnimation(
        parent: controller,
        curve: Interval(
          delay.clamp(0.0, 0.9),
          (delay + 0.5).clamp(0.0, 1.0),
          curve: Curves.easeOutCubic,
        ),
      ),
    );

    return AnimatedBuilder(
      animation: barAnim,
      builder: (_, __) => LayoutBuilder(
        builder: (context, constraints) {
          final barW = constraints.maxWidth;
          final fillW = barW * barAnim.value;

          return Stack(
            children: [
              Container(
                height: 5,
                decoration: BoxDecoration(
                  color: ac.divider,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              Container(
                height: 5,
                width: fillW.clamp(0, barW),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  gradient: LinearGradient(
                    colors: [
                      color.withValues(alpha: 0.7),
                      color,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.5),
                      blurRadius: 6,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─── Stat Chip ─────────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.value,
    required this.label,
    required this.color,
    required this.primary,
    required this.isDark,
  });

  final int value;
  final String label;
  final Color color;
  final Color primary;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.18 : 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$value',
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color.withValues(alpha: 0.8),
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Regular Scorer Row (rank 4+) ─────────────────────────────────────────────

class _ScorerRow extends StatefulWidget {
  const _ScorerRow({
    required this.scorer,
    required this.maxGoals,
    required this.ac,
    required this.animationDelay,
  });

  final Scorer scorer;
  final int maxGoals;
  final AppColors ac;
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
      duration: const Duration(milliseconds: 500),
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
    final ac = widget.ac;
    final scorer = widget.scorer;
    final primary = Theme.of(context).colorScheme.primary;
    final fraction =
        widget.maxGoals > 0 ? scorer.goals / widget.maxGoals : 0.0;

    return FadeTransition(
      opacity: _controller,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.08, 0),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
        ),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: ac.cardSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: ac.cardBorder),
          ),
          child: Row(
            children: [
              // ── Rank number ────────────────────────────────────────────
              SizedBox(
                width: 28,
                child: Text(
                  '${scorer.rank}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: ac.textTertiary,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // ── Name + bar ─────────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      scorer.playerName,
                      style: TextStyle(
                        color: ac.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      scorer.teamName,
                      style: TextStyle(
                        color: ac.textTertiary,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    _AnimatedGoalBar(
                      fraction: fraction,
                      color: primary,
                      controller: _controller,
                      delay: 0.2,
                      ac: ac,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              // ── Goals + assists ────────────────────────────────────────
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${scorer.goals}',
                    style: TextStyle(
                      color: primary,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    '${scorer.assists} ast',
                    style: TextStyle(
                      color: ac.textTertiary,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Loading State ─────────────────────────────────────────────────────────────

class _ScorersLoading extends StatelessWidget {
  const _ScorersLoading({
    required this.selectedLeague,
    required this.ac,
    required this.ref,
  });

  final dynamic selectedLeague;
  final AppColors ac;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 100),
      children: [
        _ScorersHeader(ac: ac),
        const SizedBox(height: 16),
        LeagueSelector(
          selectedLeague: selectedLeague,
          onLeagueSelected: (l) =>
              ref.read(selectedScorersLeagueProvider.notifier).selectLeague(l),
        ),
        const SizedBox(height: 20),
        for (var i = 0; i < 3; i++) ...[
          _SkeletonPodiumCard(ac: ac),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 4),
        for (var i = 0; i < 7; i++) ...[
          _SkeletonRow(ac: ac),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _SkeletonPodiumCard extends StatelessWidget {
  const _SkeletonPodiumCard({required this.ac});
  final AppColors ac;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90,
      decoration: BoxDecoration(
        color: ac.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ac.cardBorder),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          ShimmerBox(width: 48, height: 48, borderRadius: 24),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ShimmerBox(width: 140, height: 14, borderRadius: 6),
                const SizedBox(height: 6),
                ShimmerBox(width: 90, height: 11, borderRadius: 5),
                const SizedBox(height: 10),
                ShimmerBox(height: 5, borderRadius: 3),
              ],
            ),
          ),
          const SizedBox(width: 14),
          ShimmerBox(width: 48, height: 40, borderRadius: 8),
        ],
      ),
    );
  }
}

class _SkeletonRow extends StatelessWidget {
  const _SkeletonRow({required this.ac});
  final AppColors ac;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: ac.cardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ac.cardBorder),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          ShimmerBox(width: 28, height: 14, borderRadius: 5),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ShimmerBox(width: 120, height: 12, borderRadius: 5),
                const SizedBox(height: 5),
                ShimmerBox(width: 80, height: 10, borderRadius: 4),
                const SizedBox(height: 6),
                ShimmerBox(height: 5, borderRadius: 3),
              ],
            ),
          ),
          const SizedBox(width: 14),
          ShimmerBox(width: 30, height: 36, borderRadius: 6),
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
    final ac = Theme.of(context).extension<AppColors>()!;
    final primary = Theme.of(context).colorScheme.primary;

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 100),
      children: [
        _ScorersHeader(ac: ac),
        const SizedBox(height: 16),
        LeagueSelector(
          selectedLeague: selectedLeague,
          onLeagueSelected: (l) =>
              ref.read(selectedScorersLeagueProvider.notifier).selectLeague(l),
        ),
        const SizedBox(height: 80),
        Center(
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: primary.withValues(alpha: 0.1),
              border: Border.all(
                color: primary.withValues(alpha: 0.2),
                width: 1.5,
              ),
            ),
            child: Center(
              child: Text(
                '🥇',
                style: const TextStyle(fontSize: 36),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: ac.textPrimary,
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
          style: TextStyle(
            color: ac.textSecondary,
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
