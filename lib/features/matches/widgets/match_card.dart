import 'package:flutter/material.dart';

import '../../../core/app_theme.dart';
import '../../../models/match.dart';
import 'team_badge.dart';

class MatchCard extends StatelessWidget {
  const MatchCard({
    super.key,
    required this.match,
    required this.onTap,
    this.hasFavorite = false,
    this.isLoading = false,
  });

  final Match match;
  final VoidCallback onTap;
  final bool hasFavorite;
  final bool isLoading;

  bool get _isLive {
    final s = match.status?.toLowerCase() ?? '';
    return s.contains('live') ||
        s.contains('canlı') ||
        s.contains('canli') ||
        s.contains("'") ||
        RegExp(r'^\d+\s*$').hasMatch(s);
  }

  bool get _isFinished {
    final s = match.status?.trim().toUpperCase() ?? '';
    return s == 'MS' || s == 'FINISHED' || s == 'FT';
  }

  @override
  Widget build(BuildContext context) {
    final ac = Theme.of(context).extension<AppColors>()!;
    final live = _isLive;
    final finished = _isFinished;
    final hasScore = match.homeScore != null && match.awayScore != null;

    final glowColor = live ? ac.liveColor : null;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 250),
      opacity: isLoading ? 0.5 : 1.0,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          constraints: const BoxConstraints(minHeight: 80),
          decoration: BoxDecoration(
            color: live ? ac.liveBg : ac.cardSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: live
                  ? ac.liveColor.withValues(alpha: 0.35)
                  : ac.cardBorder,
              width: live ? 1.2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: (glowColor ?? ac.cardShadow).withValues(
                  alpha: live ? 0.22 : 0.06,
                ),
                blurRadius: live ? 20 : 10,
                spreadRadius: live ? -2 : -4,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Row(
              children: [
                // ── Left accent stripe for live ──────────────────────
                if (live)
                  Container(
                    width: 3,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          ac.liveColor,
                          ac.liveColor.withValues(alpha: 0.4),
                        ],
                      ),
                    ),
                  ),
                // ── Time / Status block ──────────────────────────────
                Container(
                  width: 62,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: live
                      ? _LiveStatus(status: match.status, ac: ac)
                      : _TimeStatus(match: match, finished: finished, ac: ac),
                ),
                // ── Divider ──────────────────────────────────────────
                Container(
                  width: 1,
                  height: 44,
                  color: ac.divider,
                ),
                const SizedBox(width: 12),
                // ── Teams ────────────────────────────────────────────
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _TeamRow(name: match.homeTeam, ac: ac),
                        const SizedBox(height: 10),
                        _TeamRow(name: match.awayTeam, ac: ac),
                      ],
                    ),
                  ),
                ),
                // ── Score / Favorite ─────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _ScoreBox(
                        value: hasScore ? '${match.homeScore}' : '—',
                        highlight: hasScore &&
                            match.homeScore! > (match.awayScore ?? -1),
                        ac: ac,
                      ),
                      const SizedBox(height: 8),
                      _ScoreBox(
                        value: hasScore ? '${match.awayScore}' : '—',
                        highlight: hasScore &&
                            match.awayScore! > (match.homeScore ?? -1),
                        ac: ac,
                      ),
                    ],
                  ),
                ),
                // ── Favorite star ────────────────────────────────────
                if (hasFavorite)
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: Icon(
                      Icons.star_rounded,
                      color: ac.goldColor,
                      size: 16,
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

// ─── Live Status ───────────────────────────────────────────────────────────────

class _LiveStatus extends StatefulWidget {
  const _LiveStatus({required this.status, required this.ac});
  final String? status;
  final AppColors ac;

  @override
  State<_LiveStatus> createState() => _LiveStatusState();
}

class _LiveStatusState extends State<_LiveStatus>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulse = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _minuteText {
    final v = widget.status?.trim();
    if (v == null || v.isEmpty || v.toUpperCase() == 'LIVE') return 'CANLI';
    return v.contains("'") ? v : "$v'";
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Pulsing dot
        AnimatedBuilder(
          animation: _pulse,
          builder: (_, __) => Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.ac.liveColor,
              boxShadow: [
                BoxShadow(
                  color: widget.ac.liveColor
                      .withValues(alpha: 0.7 * _pulse.value),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          _minuteText,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: widget.ac.liveColor,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}

// ─── Time Status ───────────────────────────────────────────────────────────────

class _TimeStatus extends StatelessWidget {
  const _TimeStatus({
    required this.match,
    required this.finished,
    required this.ac,
  });

  final Match match;
  final bool finished;
  final AppColors ac;

  String get _time {
    final raw = match.time;
    if (raw != null && raw.trim().isNotEmpty) {
      final parts = raw.trim().split(':');
      if (parts.length >= 2) return '${parts[0]}:${parts[1]}';
      return raw.trim();
    }
    final date = match.date;
    if (date == null) return '--:--';
    final local = date.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          finished ? 'MS' : _time,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: finished ? ac.textTertiary : ac.textPrimary,
            fontSize: 15,
            height: 1,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          finished ? 'bitti' : 'başlamadı',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: ac.textTertiary,
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}

// ─── Team Row ──────────────────────────────────────────────────────────────────

class _TeamRow extends StatelessWidget {
  const _TeamRow({required this.name, required this.ac});
  final String name;
  final AppColors ac;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        TeamBadge(teamName: name, size: 24),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: ac.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.1,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Score Box ─────────────────────────────────────────────────────────────────

class _ScoreBox extends StatelessWidget {
  const _ScoreBox({
    required this.value,
    required this.highlight,
    required this.ac,
  });

  final String value;
  final bool highlight;
  final AppColors ac;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Text(
      value,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: highlight ? primary : ac.textPrimary,
        fontSize: 17,
        height: 1,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}
