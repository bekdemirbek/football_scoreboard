import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_theme.dart';
import '../../providers/theme_provider.dart';
import '../matches/matches_page.dart';
import '../standings/standings_page.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;

  static const _pages = [MatchesPage(), StandingsPage(), _ComingSoonPage()];

  @override
  Widget build(BuildContext context) {
    final ac = Theme.of(context).extension<AppColors>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: Stack(
        children: [
          // ── Gradient Background ─────────────────────────────────────────
          Positioned.fill(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [ac.gradientStart, ac.gradientEnd],
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
        navBg: ac.navBg,
        navBorder: ac.navBorder,
        isDark: isDark,
        primaryColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}

// ─── Premium Navigation Bar ────────────────────────────────────────────────────

class _PremiumNavBar extends ConsumerWidget {
  const _PremiumNavBar({
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.navBg,
    required this.navBorder,
    required this.isDark,
    required this.primaryColor,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final Color navBg;
  final Color navBorder;
  final bool isDark;
  final Color primaryColor;

  static const _destinations = [
    (
      icon: Icons.calendar_today_outlined,
      active: Icons.calendar_today,
      label: 'Maçlar',
    ),
    (icon: Icons.bar_chart_outlined, active: Icons.bar_chart, label: 'Puan T.'),
    (
      icon: Icons.star_border_rounded,
      active: Icons.star_rounded,
      label: 'Favoriler',
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider).value ?? ThemeMode.system;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: navBg,
            border: Border(top: BorderSide(color: navBorder, width: 1)),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 64,
              child: Row(
                children: [
                  // ── Nav Items ────────────────────────────────────────────
                  for (int i = 0; i < _destinations.length; i++)
                    Expanded(
                      child: _NavItem(
                        icon: _destinations[i].icon,
                        activeIcon: _destinations[i].active,
                        label: _destinations[i].label,
                        isSelected: i == selectedIndex,
                        primaryColor: primaryColor,
                        onTap: () => onDestinationSelected(i),
                        isDark: isDark,
                      ),
                    ),
                  // ── Theme Toggle ─────────────────────────────────────────
                  _ThemeToggleButton(
                    themeMode: themeMode,
                    primaryColor: primaryColor,
                    isDark: isDark,
                    onTap: () => ref.read(themeModeProvider.notifier).toggle(),
                  ),
                  const SizedBox(width: 4),
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
    required this.primaryColor,
    required this.onTap,
    required this.isDark,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final Color primaryColor;
  final VoidCallback onTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final ac = Theme.of(context).extension<AppColors>()!;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? primaryColor.withValues(alpha: isDark ? 0.18 : 0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                isSelected ? activeIcon : icon,
                color: isSelected ? primaryColor : ac.textTertiary,
                size: 22,
              ),
            ),
            const SizedBox(height: 2),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 220),
              style: TextStyle(
                color: isSelected ? primaryColor : ac.textTertiary,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeToggleButton extends StatelessWidget {
  const _ThemeToggleButton({
    required this.themeMode,
    required this.primaryColor,
    required this.isDark,
    required this.onTap,
  });

  final ThemeMode themeMode;
  final Color primaryColor;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isEffectivelyDark =
        themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system && isDark);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 44,
          height: 26,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13),
            color: isEffectivelyDark
                ? primaryColor.withValues(alpha: 0.25)
                : primaryColor.withValues(alpha: 0.12),
            border: Border.all(
              color: primaryColor.withValues(alpha: 0.4),
              width: 1,
            ),
          ),
          child: Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                left: isEffectivelyDark ? 20 : 2,
                top: 2,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: primaryColor,
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withValues(alpha: 0.4),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: Icon(
                    isEffectivelyDark ? Icons.dark_mode : Icons.light_mode,
                    size: 12,
                    color: isDark ? const Color(0xFF003320) : Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Coming Soon Page ──────────────────────────────────────────────────────────

class _ComingSoonPage extends StatelessWidget {
  const _ComingSoonPage();

  @override
  Widget build(BuildContext context) {
    final ac = Theme.of(context).extension<AppColors>()!;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      ac.goldColor.withValues(alpha: 0.3),
                      ac.goldColor.withValues(alpha: 0.1),
                    ],
                  ),
                  border: Border.all(
                    color: ac.goldColor.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                ),
                child: Icon(Icons.star_rounded, color: ac.goldColor, size: 38),
              ),
              const SizedBox(height: 20),
              Text(
                'Favoriler',
                style: TextStyle(
                  color: ac.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Yakında geliyor...',
                style: TextStyle(
                  color: ac.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
