import 'package:flutter/material.dart';

import '../../../core/app_theme.dart';
import '../../../models/football_league.dart';

class LeagueSelector extends StatelessWidget {
  const LeagueSelector({
    super.key,
    required this.selectedLeague,
    required this.onLeagueSelected,
  });

  final FootballLeague selectedLeague;
  final ValueChanged<FootballLeague> onLeagueSelected;

  @override
  Widget build(BuildContext context) {
    final ac = Theme.of(context).extension<AppColors>()!;
    final primary = Theme.of(context).colorScheme.primary;

    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: footballLeagues.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final league = footballLeagues[index];
          final selected = league.id == selectedLeague.id;

          return GestureDetector(
            onTap: () => onLeagueSelected(league),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: selected
                    ? LinearGradient(
                        colors: [ac.headerGradientStart, ac.headerGradientEnd],
                      )
                    : null,
                color: selected ? null : ac.unselectedPill,
                border: Border.all(
                  color: selected ? Colors.transparent : ac.cardBorder,
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: primary.withValues(alpha: 0.35),
                          blurRadius: 10,
                          spreadRadius: -2,
                        ),
                      ]
                    : null,
              ),
              alignment: Alignment.center,
              child: Text(
                league.name,
                style: TextStyle(
                  color: selected ? Colors.white : ac.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
