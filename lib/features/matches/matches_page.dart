import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_theme.dart';
import '../../models/football_league.dart';
import '../../models/match.dart';
import '../../providers/api_providers.dart';
import '../../widgets/fade_route.dart';
import '../../widgets/shimmer_box.dart';
import 'match_detail_page.dart';
import 'widgets/league_selector.dart';
import 'widgets/match_card.dart';
import 'widgets/matches_date_strip.dart';
import 'widgets/matches_header.dart';

class MatchesPage extends ConsumerWidget {
  const MatchesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedMatchDateProvider);
    final matches = ref.watch(matchesProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: matches.when(
          loading: () => _MatchesLoading(selectedDate: selectedDate),
          error: (error, _) => _MatchesMessage(
            title: 'Maçlar yüklenemedi',
            message: error.toString(),
            actionLabel: 'Tekrar dene',
            selectedDate: selectedDate,
            onPressed: () => ref.read(matchesProvider.notifier).refresh(),
          ),
          data: (items) {
            if (items.isEmpty) {
              return _MatchesMessage(
                title: 'Maç bulunamadı',
                message:
                    '${_formatDate(selectedDate)} için API tarafında maç verisi yok.',
                actionLabel: 'Yenile',
                selectedDate: selectedDate,
                onPressed: () => ref.read(matchesProvider.notifier).refresh(),
              );
            }
            return _MatchesContent(
              matches: items,
              selectedDate: selectedDate,
              onRefresh: () => ref.read(matchesProvider.notifier).refresh(),
            );
          },
        ),
      ),
    );
  }
}

// ─── Content ───────────────────────────────────────────────────────────────────

class _MatchesContent extends ConsumerWidget {
  const _MatchesContent({
    required this.matches,
    required this.selectedDate,
    required this.onRefresh,
  });

  final List<Match> matches;
  final DateTime selectedDate;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ac = Theme.of(context).extension<AppColors>()!;
    final selectedLeague = ref.watch(selectedLeagueProvider);
    final favNotifier = ref.watch(favoriteTeamsProvider.notifier);
    final grouped = _groupByLeague(matches);

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: Theme.of(context).colorScheme.primary,
      backgroundColor: ac.cardSurface,
      child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 100),
        children: [
          const MatchesHeader(),
          const SizedBox(height: 14),
          MatchesDateStrip(
            selectedDate: selectedDate,
            onDateSelected: (date) =>
                ref.read(selectedMatchDateProvider.notifier).selectDate(date),
            onCalendarPressed: () => _showCalendarPicker(
              context: context,
              selectedDate: selectedDate,
              onDateSelected: (date) =>
                  ref.read(selectedMatchDateProvider.notifier).selectDate(date),
            ),
          ),
          const SizedBox(height: 12),
          LeagueSelector(
            selectedLeague: selectedLeague,
            onLeagueSelected: (league) =>
                ref.read(selectedLeagueProvider.notifier).selectLeague(league),
          ),
          const SizedBox(height: 20),
          for (final entry in grouped.entries) ...[
            _LeagueSectionHeader(title: entry.key, ac: ac),
            const SizedBox(height: 10),
            for (final match in entry.value) ...[
              MatchCard(
                match: match,
                hasFavorite:
                    favNotifier.isFavoriteByName(match.homeTeam) ||
                    favNotifier.isFavoriteByName(match.awayTeam),
                onTap: () => Navigator.of(
                  context,
                ).push(FadeRoute(child: MatchDetailPage(match: match))),
              ),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

// ─── Loading State ─────────────────────────────────────────────────────────────

class _MatchesLoading extends ConsumerWidget {
  const _MatchesLoading({required this.selectedDate});

  final DateTime selectedDate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ac = Theme.of(context).extension<AppColors>()!;
    final selectedLeague = ref.watch(selectedLeagueProvider);

    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 100),
      children: [
        const MatchesHeader(),
        const SizedBox(height: 14),
        MatchesDateStrip(
          selectedDate: selectedDate,
          onDateSelected: (date) =>
              ref.read(selectedMatchDateProvider.notifier).selectDate(date),
          onCalendarPressed: () => _showCalendarPicker(
            context: context,
            selectedDate: selectedDate,
            onDateSelected: (date) =>
                ref.read(selectedMatchDateProvider.notifier).selectDate(date),
          ),
        ),
        const SizedBox(height: 12),
        LeagueSelector(
          selectedLeague: selectedLeague,
          onLeagueSelected: (league) =>
              ref.read(selectedLeagueProvider.notifier).selectLeague(league),
        ),
        const SizedBox(height: 20),
        // Shimmer league header
        ShimmerBox(width: 120, height: 22, borderRadius: 6),
        const SizedBox(height: 12),
        for (var i = 0; i < 4; i++) ...[
          _ShimmerMatchCard(ac: ac),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 16),
        ShimmerBox(width: 100, height: 22, borderRadius: 6),
        const SizedBox(height: 12),
        for (var i = 0; i < 3; i++) ...[
          _ShimmerMatchCard(ac: ac),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _ShimmerMatchCard extends StatelessWidget {
  const _ShimmerMatchCard({required this.ac});
  final AppColors ac;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: ac.cardSurface,
        border: Border.all(color: ac.cardBorder),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ShimmerBox(width: 24, height: 24, borderRadius: 12),
              const SizedBox(width: 10),
              ShimmerBox(width: 140, height: 13, borderRadius: 6),
              const Spacer(),
              ShimmerBox(width: 24, height: 14, borderRadius: 4),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              ShimmerBox(width: 24, height: 24, borderRadius: 12),
              const SizedBox(width: 10),
              ShimmerBox(width: 110, height: 13, borderRadius: 6),
              const Spacer(),
              ShimmerBox(width: 24, height: 14, borderRadius: 4),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Empty / Error State ───────────────────────────────────────────────────────

class _MatchesMessage extends ConsumerWidget {
  const _MatchesMessage({
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.selectedDate,
    required this.onPressed,
  });

  final String title;
  final String message;
  final String actionLabel;
  final DateTime selectedDate;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ac = Theme.of(context).extension<AppColors>()!;
    final primary = Theme.of(context).colorScheme.primary;
    final selectedLeague = ref.watch(selectedLeagueProvider);

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 100),
      children: [
        const MatchesHeader(),
        const SizedBox(height: 14),
        MatchesDateStrip(
          selectedDate: selectedDate,
          onDateSelected: (date) =>
              ref.read(selectedMatchDateProvider.notifier).selectDate(date),
          onCalendarPressed: () => _showCalendarPicker(
            context: context,
            selectedDate: selectedDate,
            onDateSelected: (date) =>
                ref.read(selectedMatchDateProvider.notifier).selectDate(date),
          ),
        ),
        const SizedBox(height: 12),
        LeagueSelector(
          selectedLeague: selectedLeague,
          onLeagueSelected: (league) =>
              ref.read(selectedLeagueProvider.notifier).selectLeague(league),
        ),
        const SizedBox(height: 80),
        // Illustration
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
            child: Icon(Icons.sports_soccer_rounded, color: primary, size: 36),
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
          style: TextStyle(color: ac.textSecondary, fontSize: 13, height: 1.5),
        ),
        const SizedBox(height: 24),
        Center(
          child: FilledButton.icon(
            onPressed: onPressed,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: Text(actionLabel),
          ),
        ),
      ],
    );
  }
}

// ─── League Section Header ─────────────────────────────────────────────────────

class _LeagueSectionHeader extends StatelessWidget {
  const _LeagueSectionHeader({required this.title, required this.ac});
  final String title;
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
            title.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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

// ─── Helpers ───────────────────────────────────────────────────────────────────

Map<String, List<Match>> _groupByLeague(List<Match> matches) {
  final grouped = <String, List<Match>>{};
  for (final match in matches) {
    final league = _leagueName(match);
    grouped.putIfAbsent(league, () => <Match>[]).add(match);
  }
  return grouped;
}

String _leagueName(Match match) {
  final raw = match.league?.trim();
  if (raw != null && raw.isNotEmpty) return raw;
  final known = footballLeagues.where((league) => league.id == match.leagueId);
  if (known.isNotEmpty) return known.first.name;
  return 'Diğer Maçlar';
}

String _formatDate(DateTime date) {
  return '${date.day} ${_monthName(date.month)}';
}

String _monthName(int month) {
  return switch (month) {
    1 => 'Ocak',
    2 => 'Şubat',
    3 => 'Mart',
    4 => 'Nisan',
    5 => 'Mayıs',
    6 => 'Haziran',
    7 => 'Temmuz',
    8 => 'Ağustos',
    9 => 'Eylül',
    10 => 'Ekim',
    11 => 'Kasım',
    _ => 'Aralık',
  };
}

Future<void> _showCalendarPicker({
  required BuildContext context,
  required DateTime selectedDate,
  required ValueChanged<DateTime> onDateSelected,
}) async {
  final ac = Theme.of(context).extension<AppColors>()!;
  final primary = Theme.of(context).colorScheme.primary;
  final isDark = Theme.of(context).brightness == Brightness.dark;

  final picked = await showDatePicker(
    context: context,
    initialDate: selectedDate,
    firstDate: DateTime(2020),
    lastDate: DateTime(2035),
    helpText: 'Maç Tarihi Seç',
    cancelText: 'Vazgeç',
    confirmText: 'Seç',
    barrierColor: Colors.black.withValues(alpha: 0.5),
    builder: (context, child) {
      return Theme(
        data: ThemeData(
          useMaterial3: true,
          brightness: isDark ? Brightness.dark : Brightness.light,
          colorScheme: ColorScheme(
            brightness: isDark ? Brightness.dark : Brightness.light,
            primary: primary,
            onPrimary: isDark ? const Color(0xFF003320) : Colors.white,
            secondary: primary,
            onSecondary: Colors.white,
            error: Colors.red,
            onError: Colors.white,
            surface: isDark ? const Color(0xFF111827) : Colors.white,
            onSurface: ac.textPrimary,
          ),
          dialogTheme: DialogThemeData(
            backgroundColor: isDark ? const Color(0xFF111827) : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
        child: child ?? const SizedBox.shrink(),
      );
    },
  );

  if (picked != null) {
    onDateSelected(DateTime(picked.year, picked.month, picked.day));
  }
}
