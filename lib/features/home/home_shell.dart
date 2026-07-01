import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_theme.dart';
import '../favorites/favorites_page.dart';
import '../games/games_page.dart';
import '../matches/matches_page.dart';
import '../scorers/scorers_page.dart';
import '../standings/standings_page.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;

  static const _pages = [
    MatchesPage(),
    StandingsPage(),
    GamesPage(),
    ScorersPage(),
    FavoritesPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: Stack(
        children: [
          // ── Gradient Background ─────────────────────────────────────────
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
          // ── Pages ───────────────────────────────────────────────────────
          IndexedStack(index: _selectedIndex, children: _pages),
        ],
      ),
      bottomNavigationBar: _PremiumNavBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
      ),
    );
  }
}

// ─── Premium Navigation Bar ────────────────────────────────────────────────────

class _PremiumNavBar extends StatelessWidget {
  const _PremiumNavBar({
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  static const _destinations = [
    (
      icon: Icons.calendar_today_outlined,
      active: Icons.calendar_today,
      label: 'Maçlar',
    ),
    (icon: Icons.bar_chart_outlined, active: Icons.bar_chart, label: 'Puan T.'),
    (
      icon: Icons.sports_esports_outlined,
      active: Icons.sports_esports,
      label: 'Oyunlar',
    ),
    (
      icon: Icons.emoji_events_outlined,
      active: Icons.emoji_events,
      label: 'Gol K.',
    ),
    (
      icon: Icons.star_border_rounded,
      active: Icons.star_rounded,
      label: 'Favoriler',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.navBg,
            border: Border(
              top: BorderSide(color: AppColors.navBorder, width: 1),
            ),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 64,
              child: Row(
                children: [
                  for (int i = 0; i < _destinations.length; i++)
                    Expanded(
                      child: _NavItem(
                        icon: _destinations[i].icon,
                        activeIcon: _destinations[i].active,
                        label: _destinations[i].label,
                        isSelected: i == selectedIndex,
                        onTap: () => onDestinationSelected(i),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.accentGreen.withValues(alpha: 0.16)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.accentGreen.withValues(alpha: 0.35),
                        blurRadius: 16,
                        spreadRadius: -2,
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? AppColors.accentGreen : AppColors.textMuted,
              size: 22,
            ),
          ),
          const SizedBox(height: 2),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 220),
            style: TextStyle(
              color: isSelected ? AppColors.accentGreen : AppColors.textMuted,
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            ),
            child: Text(label),
          ),
        ],
      ),
    );
  }
}
