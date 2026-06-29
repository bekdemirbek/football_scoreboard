import 'package:flutter/material.dart';

import '../../../core/app_theme.dart';

class MatchesHeader extends StatelessWidget {
  const MatchesHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final ac = Theme.of(context).extension<AppColors>()!;
    final primary = Theme.of(context).colorScheme.primary;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // ── Logo ────────────────────────────────────────────────────────
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [ac.headerGradientStart, ac.headerGradientEnd],
            ),
            boxShadow: [
              BoxShadow(
                color: ac.headerGradientStart.withValues(alpha: 0.4),
                blurRadius: 12,
                spreadRadius: -2,
              ),
            ],
          ),
          child: const Icon(
            Icons.sports_soccer_rounded,
            color: Colors.white,
            size: 18,
          ),
        ),
        const SizedBox(width: 10),
        // ── Brand Name ──────────────────────────────────────────────────
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [ac.headerGradientStart, ac.headerGradientEnd],
          ).createShader(bounds),
          child: const Text(
            'MAÇKART',
            style: TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
        ),
        const Spacer(),
        // ── Notification Button ─────────────────────────────────────────
        _IconBtn(
          icon: Icons.notifications_outlined,
          color: ac.textSecondary,
          onTap: () {},
          badge: true,
          badgeColor: primary,
        ),
      ],
    );
  }
}

class _IconBtn extends StatelessWidget {
  const _IconBtn({
    required this.icon,
    required this.color,
    required this.onTap,
    this.badge = false,
    this.badgeColor,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool badge;
  final Color? badgeColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.08),
              border: Border.all(color: color.withValues(alpha: 0.12)),
            ),
            child: Icon(icon, color: color, size: 19),
          ),
          if (badge && badgeColor != null)
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: badgeColor,
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).extension<AppColors>()!.gradientStart,
                    width: 1.5,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
