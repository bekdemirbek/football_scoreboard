import 'package:flutter/material.dart';

import '../../../core/app_theme.dart';
import '../../../models/match_lineup.dart';
import 'lineup_pitch.dart';
import 'team_badge.dart';

class MatchLineupsTab extends StatelessWidget {
  const MatchLineupsTab({super.key, required this.home, required this.away});

  final TeamLineup home;
  final TeamLineup away;

  @override
  Widget build(BuildContext context) {
    final ac = Theme.of(context).extension<AppColors>()!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FormationHeader(home: home, away: away, ac: ac),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: ac.cardBorder),
          ),
          clipBehavior: Clip.antiAlias,
          child: LineupPitch(home: home, away: away),
        ),
        const SizedBox(height: 14),
        _TeamBenchBlock(lineup: home, dotColor: const Color(0xFF2563EB), ac: ac),
        const SizedBox(height: 10),
        _TeamBenchBlock(lineup: away, dotColor: const Color(0xFFE0A639), ac: ac),
      ],
    );
  }
}

class _FormationHeader extends StatelessWidget {
  const _FormationHeader({required this.home, required this.away, required this.ac});

  final TeamLineup home;
  final TeamLineup away;
  final AppColors ac;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _TeamFormationTag(lineup: home, ac: ac, alignEnd: false)),
        const SizedBox(width: 10),
        Expanded(child: _TeamFormationTag(lineup: away, ac: ac, alignEnd: true)),
      ],
    );
  }
}

class _TeamFormationTag extends StatelessWidget {
  const _TeamFormationTag({
    required this.lineup,
    required this.ac,
    required this.alignEnd,
  });

  final TeamLineup lineup;
  final AppColors ac;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final children = [
      TeamBadge(teamName: lineup.teamName, size: 22),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          lineup.formation ?? lineup.teamName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: alignEnd ? TextAlign.end : TextAlign.start,
          style: TextStyle(
            color: ac.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    ];
    return Row(children: alignEnd ? children.reversed.toList() : children);
  }
}

class _TeamBenchBlock extends StatelessWidget {
  const _TeamBenchBlock({
    required this.lineup,
    required this.dotColor,
    required this.ac,
  });

  final TeamLineup lineup;
  final Color dotColor;
  final AppColors ac;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ac.cardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ac.cardBorder),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              TeamBadge(teamName: lineup.teamName, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  lineup.teamName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: ac.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              for (final player in lineup.startXIByPosition)
                SizedBox(
                  width: 150,
                  child: Text(
                    '${player.number ?? ''}  ${player.name}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: ac.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          if (lineup.substitutes.isNotEmpty) ...[
            const SizedBox(height: 10),
            Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                minTileHeight: 32,
                title: Text(
                  'Yedekler (${lineup.substitutes.length})',
                  style: TextStyle(
                    color: ac.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                childrenPadding: EdgeInsets.zero,
                children: [
                  Wrap(
                    spacing: 14,
                    runSpacing: 6,
                    children: [
                      for (final player in lineup.substitutes)
                        SizedBox(
                          width: 150,
                          child: Text(
                            '${player.number ?? ''}  ${player.name}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: ac.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
          if (lineup.coachName != null) ...[
            const SizedBox(height: 8),
            Text(
              'Teknik Direktör: ${lineup.coachName}',
              style: TextStyle(
                color: ac.textTertiary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
