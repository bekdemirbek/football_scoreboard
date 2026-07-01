import 'package:flutter/material.dart';

import '../../../core/app_theme.dart';
import '../../../models/football_league.dart';

class LeagueSelector extends StatelessWidget {
  const LeagueSelector({
    super.key,
    required this.selectedLeague,
    required this.onLeagueSelected,
    this.leagues = footballLeagues,
  });

  final FootballLeague selectedLeague;
  final ValueChanged<FootballLeague> onLeagueSelected;
  final List<FootballLeague> leagues;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      // Sağ kenarda hafif fade: listenin yatay olarak kaydırılabildiğini
      // (devamı olduğunu) gösteren görsel ipucu.
      child: ShaderMask(
        shaderCallback: (rect) => const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Colors.white, Colors.white, Colors.transparent],
          stops: [0.0, 0.92, 1.0],
        ).createShader(rect),
        blendMode: BlendMode.dstIn,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(right: 28),
          itemCount: leagues.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final league = leagues[index];
            final selected = league.id == selectedLeague.id;

            return GestureDetector(
              onTap: () => onLeagueSelected(league),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 0,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: selected ? AppGradients.greenGlow : null,
                  color: selected ? null : AppColors.cardBg,
                  border: Border.all(
                    color: selected ? Colors.transparent : AppColors.cardBorder,
                  ),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: AppColors.accentGreen.withValues(alpha: 0.3),
                            blurRadius: 12,
                            spreadRadius: -3,
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  league.name,
                  style: TextStyle(
                    color: selected ? Colors.white : AppColors.textSecondary,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
