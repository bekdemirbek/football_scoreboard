import 'package:flutter/material.dart';

import '../../../core/app_theme.dart';
import '../../../models/match.dart';
import '../../../models/match_detail.dart';
import '../../../models/match_event.dart';
import 'team_badge.dart';

class MatchHeroCard extends StatelessWidget {
  const MatchHeroCard({
    super.key,
    required this.match,
    required this.homeFav,
    required this.awayFav,
    required this.onToggleHome,
    required this.onToggleAway,
    this.detail,
  });

  final Match match;
  final bool homeFav;
  final bool awayFav;
  final VoidCallback onToggleHome;
  final VoidCallback onToggleAway;
  final MatchDetail? detail;

  bool get _isLive {
    final s = match.status?.toLowerCase() ?? '';
    return s.contains('live') ||
        s.contains('canlı') ||
        s.contains("'") ||
        RegExp(r'^\d+\s*$').hasMatch(s);
  }

  List<MatchEvent> _scorersFor(bool home) {
    final d = detail;
    if (d == null) return const [];
    return d.goals
        .where((g) => d.isHomeEvent(g) == home)
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final ac = Theme.of(context).extension<AppColors>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final hasScore = match.homeScore != null && match.awayScore != null;
    final live = _isLive;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: isDark ? const Color(0xFF060B14) : ac.cardSurface,
        border: Border.all(
          color: primary.withValues(alpha: isDark ? 0.25 : 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: isDark ? 0.18 : 0.1),
            blurRadius: 30,
            spreadRadius: -5,
          ),
        ],
      ),
      child: Stack(
        children: [
          // ── Stadium glow background ─────────────────────────────────
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    ac.headerGradientStart.withValues(
                      alpha: isDark ? 0.22 : 0.14,
                    ),
                    ac.headerGradientEnd.withValues(
                      alpha: isDark ? 0.18 : 0.10,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: -40,
            left: -30,
            child: _Floodlight(color: ac.headerGradientStart, size: 160),
          ),
          Positioned(
            top: -40,
            right: -30,
            child: _Floodlight(color: ac.headerGradientEnd, size: 160),
          ),
          // ── Content ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                if (live) ...[
                  _LiveBadge(status: match.status, ac: ac),
                  const SizedBox(height: 16),
                ],
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _TeamHero(
                        name: match.homeTeam,
                        isFav: homeFav,
                        onFavTap: onToggleHome,
                        scorers: _scorersFor(true),
                        ac: ac,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Column(
                        children: [
                          Text(
                            hasScore
                                ? '${match.homeScore}  -  ${match.awayScore}'
                                : 'VS',
                            style: TextStyle(
                              color: hasScore
                                  ? ac.textPrimary
                                  : ac.textTertiary,
                              fontSize: hasScore ? 28 : 22,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1,
                            ),
                          ),
                          if (!hasScore) ...[
                            const SizedBox(height: 4),
                            Text(
                              match.time ?? '--:--',
                              style: TextStyle(
                                color: primary,
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Expanded(
                      child: _TeamHero(
                        name: match.awayTeam,
                        isFav: awayFav,
                        onFavTap: onToggleAway,
                        scorers: _scorersFor(false),
                        ac: ac,
                        alignEnd: true,
                      ),
                    ),
                  ],
                ),
                if (!live && match.status != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: ac.cardSurface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: ac.cardBorder),
                    ),
                    child: Text(
                      _statusLabel(match.status),
                      style: TextStyle(
                        color: ac.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _statusLabel(String? s) {
    if (s == null || s.isEmpty) return 'Planlandı';
    final up = s.toUpperCase();
    if (up == 'MS' || up == 'FT' || up == 'FINISHED') return '● Maç Bitti';
    if (up == 'SCHEDULED' || up == 'TIMED') return '⏱ Planlandı';
    if (up == 'POSTPONED') return '⚠ Ertelendi';
    return s;
  }
}

class _Floodlight extends StatelessWidget {
  const _Floodlight({required this.color, required this.size});
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color.withValues(alpha: 0.28), color.withValues(alpha: 0)],
          ),
        ),
      ),
    );
  }
}

class _TeamHero extends StatelessWidget {
  const _TeamHero({
    required this.name,
    required this.isFav,
    required this.onFavTap,
    required this.scorers,
    required this.ac,
    this.alignEnd = false,
  });

  final String name;
  final bool isFav;
  final VoidCallback onFavTap;
  final List<MatchEvent> scorers;
  final AppColors ac;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onFavTap,
      child: Column(
        crossAxisAlignment: alignEnd
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          TeamBadge(teamName: name, size: 48),
          const SizedBox(height: 10),
          Text(
            name,
            maxLines: 2,
            textAlign: alignEnd ? TextAlign.end : TextAlign.start,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: ac.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 6),
          Icon(
            isFav ? Icons.star_rounded : Icons.star_border_rounded,
            color: isFav ? ac.goldColor : ac.textTertiary,
            size: 20,
          ),
          if (scorers.isNotEmpty) ...[
            const SizedBox(height: 6),
            for (final scorer in scorers)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  '⚽ ${scorer.playerName} ${scorer.minuteLabel}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: alignEnd ? TextAlign.end : TextAlign.start,
                  style: TextStyle(
                    color: ac.textSecondary,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _LiveBadge extends StatefulWidget {
  const _LiveBadge({required this.status, required this.ac});
  final String? status;
  final AppColors ac;

  @override
  State<_LiveBadge> createState() => _LiveBadgeState();
}

class _LiveBadgeState extends State<_LiveBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String get _minute {
    final v = widget.status?.trim();
    if (v == null || v.toUpperCase() == 'LIVE') return '';
    return v.contains("'") ? ' $v' : " $v'";
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: widget.ac.liveColor.withValues(
            alpha: 0.1 + 0.08 * _anim.value,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: widget.ac.liveColor.withValues(
              alpha: 0.4 + 0.2 * _anim.value,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: widget.ac.liveColor.withValues(alpha: 0.3 * _anim.value),
              blurRadius: 16,
              spreadRadius: -2,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.ac.liveColor,
                boxShadow: [
                  BoxShadow(
                    color: widget.ac.liveColor.withValues(
                      alpha: 0.7 * _anim.value,
                    ),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 7),
            Text(
              'CANLI$_minute',
              style: TextStyle(
                color: widget.ac.liveColor,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
