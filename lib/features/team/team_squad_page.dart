import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_theme.dart';
import '../../models/favorite_team.dart';
import '../../models/team_squad.dart';
import '../../providers/api_providers.dart';
import '../../widgets/screen_header.dart';
import '../../widgets/shimmer_box.dart';
import '../matches/widgets/team_badge.dart';

/// Bir takıma tıklanınca açılan kadro ekranı: oyuncu listesi pozisyona
/// göre gruplu (Kaleci/Defans/Orta Saha/Forvet), her oyuncunun forma no,
/// pozisyon, uyruk ve yaşı ile.
class TeamSquadPage extends ConsumerWidget {
  const TeamSquadPage({
    super.key,
    required this.teamId,
    required this.teamName,
  });

  final String teamId;
  final String teamName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final squadAsync = ref.watch(teamSquadProvider(teamId));
    final favNotifier = ref.watch(favoriteTeamsProvider.notifier);
    final isFav = favNotifier.isFavoriteByName(teamName);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.gradientStart, AppColors.gradientEnd],
                ),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: ScreenHeader(
                    title: 'Kadro',
                    onBack: () => Navigator.of(context).pop(),
                  ),
                ),
                Expanded(
                  child: squadAsync.when(
                    loading: () => _SquadLoading(teamName: teamName),
                    error: (e, _) => _SquadError(
                      teamName: teamName,
                      message: e.toString(),
                      onRetry: () => ref.invalidate(teamSquadProvider(teamId)),
                    ),
                    data: (squad) => _SquadContent(
                      squad: squad,
                      teamName: teamName,
                      isFav: isFav,
                      onToggleFav: () => favNotifier.toggle(
                        FavoriteTeam(id: teamId, name: teamName),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Header (badge + isim + teknik direktör + favori) ──────────────────────────

class _SquadTeamHeader extends StatelessWidget {
  const _SquadTeamHeader({
    required this.teamName,
    this.coachName,
    this.playerCount,
    this.isFav,
    this.onToggleFav,
  });

  final String teamName;
  final String? coachName;
  final int? playerCount;
  final bool? isFav;
  final VoidCallback? onToggleFav;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.cardBgRaised, AppColors.cardBg],
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          TeamBadge(teamName: teamName, size: 52),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  teamName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  [
                    if (playerCount != null) '$playerCount oyuncu',
                    if (coachName != null) 'TD: $coachName',
                  ].join('  ·  '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (onToggleFav != null)
            GestureDetector(
              onTap: onToggleFav,
              behavior: HitTestBehavior.opaque,
              child: Icon(
                (isFav ?? false)
                    ? Icons.star_rounded
                    : Icons.star_border_rounded,
                color: (isFav ?? false)
                    ? AppColors.goldColor
                    : AppColors.textTertiary,
                size: 26,
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Content ───────────────────────────────────────────────────────────────────

class _SquadContent extends StatelessWidget {
  const _SquadContent({
    required this.squad,
    required this.teamName,
    required this.isFav,
    required this.onToggleFav,
  });

  final TeamSquad squad;
  final String teamName;
  final bool isFav;
  final VoidCallback onToggleFav;

  @override
  Widget build(BuildContext context) {
    final groups = squad.byGroup;
    final orderedGroups = groups.keys.toList()
      ..sort((a, b) => a.order.compareTo(b.order));

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        _SquadTeamHeader(
          teamName: squad.teamName.isNotEmpty ? squad.teamName : teamName,
          coachName: squad.coachName,
          playerCount: squad.players.length,
          isFav: isFav,
          onToggleFav: onToggleFav,
        ),
        const SizedBox(height: 16),
        if (squad.players.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Text(
                'Bu takım için kadro verisi bulunamadı.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          )
        else
          for (final group in orderedGroups) ...[
            _GroupHeader(label: group.label, count: groups[group]!.length),
            const SizedBox(height: 8),
            for (final player in groups[group]!) ...[
              _PlayerTile(player: player),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 8),
          ],
      ],
    );
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.label, required this.count});
  final String label;
  final int count;

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
            '${label.toUpperCase()}  ·  $count',
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

class _PlayerTile extends StatelessWidget {
  const _PlayerTile({required this.player});
  final SquadPlayer player;

  @override
  Widget build(BuildContext context) {
    final style = _groupStyle(player.group);
    final meta = [
      if (player.nationality != null) player.nationality!,
      if (player.age != null) '${player.age} yaş',
    ].join('  ·  ');

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
        color: AppColors.cardBg,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          // ── Pozisyon renkli forma rozeti (no varsa numara, yoksa ikon) ──
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: style.color.withValues(alpha: 0.14),
              border: Border.all(color: style.color.withValues(alpha: 0.5)),
            ),
            child: player.shirtNumber != null
                ? Text(
                    '${player.shirtNumber}',
                    style: TextStyle(
                      color: style.color,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  )
                : Icon(style.icon, color: style.color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (meta.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    meta,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          // ── Pozisyon etiketi (renkli chip) ──────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: style.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _positionShort(player),
              style: TextStyle(
                color: style.color,
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Pozisyon için kısa etiket: detaylı pozisyon varsa ondan, yoksa
  /// grup kısaltması (KAL/DEF/OS/FOR).
  String _positionShort(SquadPlayer player) {
    final pos = player.position;
    if (pos != null && pos.length <= 14) return pos;
    return switch (player.group) {
      SquadPositionGroup.goalkeeper => 'KAL',
      SquadPositionGroup.defence => 'DEF',
      SquadPositionGroup.midfield => 'OS',
      SquadPositionGroup.attack => 'FOR',
      SquadPositionGroup.other => '—',
    };
  }
}

class _GroupStyle {
  const _GroupStyle(this.color, this.icon);
  final Color color;
  final IconData icon;
}

_GroupStyle _groupStyle(SquadPositionGroup group) {
  return switch (group) {
    SquadPositionGroup.goalkeeper => const _GroupStyle(
      AppColors.goldColor,
      Icons.sports_handball_rounded,
    ),
    SquadPositionGroup.defence => const _GroupStyle(
      Color(0xFF4F8CFF),
      Icons.shield_rounded,
    ),
    SquadPositionGroup.midfield => const _GroupStyle(
      AppColors.accentGreen,
      Icons.sync_alt_rounded,
    ),
    SquadPositionGroup.attack => const _GroupStyle(
      AppColors.accentOrange,
      Icons.sports_soccer_rounded,
    ),
    SquadPositionGroup.other => const _GroupStyle(
      AppColors.textSecondary,
      Icons.person_rounded,
    ),
  };
}

// ─── Loading ───────────────────────────────────────────────────────────────────

class _SquadLoading extends StatelessWidget {
  const _SquadLoading({required this.teamName});
  final String teamName;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        _SquadTeamHeader(teamName: teamName),
        const SizedBox(height: 16),
        for (var i = 0; i < 8; i++) ...[
          Container(
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.cardBorder),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            child: Row(
              children: [
                ShimmerBox(width: 34, height: 34, borderRadius: 17),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ShimmerBox(width: 140, height: 13, borderRadius: 5),
                      const SizedBox(height: 6),
                      ShimmerBox(width: 90, height: 10, borderRadius: 4),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

// ─── Error ─────────────────────────────────────────────────────────────────────

class _SquadError extends StatelessWidget {
  const _SquadError({
    required this.teamName,
    required this.message,
    required this.onRetry,
  });

  final String teamName;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        _SquadTeamHeader(teamName: teamName),
        const SizedBox(height: 60),
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
              Icons.groups_rounded,
              color: AppColors.accentGreen,
              size: 36,
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Kadro yüklenemedi',
          textAlign: TextAlign.center,
          style: TextStyle(
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
        const SizedBox(height: 24),
        Center(
          child: FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Tekrar dene'),
          ),
        ),
      ],
    );
  }
}
