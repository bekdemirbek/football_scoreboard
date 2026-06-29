import 'dart:ui';

import 'package:flutter/material.dart';

import '../core/app_theme.dart';

/// A premium card with subtle transparency + blur (glassmorphism).
/// Use [GlassCard.solid] for a fully opaque elevated card.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.borderRadius = 14.0,
    this.padding = EdgeInsets.zero,
    this.margin = EdgeInsets.zero,
    this.blur = 18.0,
    this.onTap,
    this.highlightColor,
    this.glowColor,
  });

  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double blur;
  final VoidCallback? onTap;
  final Color? highlightColor;
  final Color? glowColor;

  @override
  Widget build(BuildContext context) {
    final ac = Theme.of(context).extension<AppColors>()!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cardDecoration = BoxDecoration(
      color: ac.cardSurface,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: highlightColor?.withValues(alpha: 0.35) ?? ac.cardBorder,
        width: isDark ? 1.0 : 1.2,
      ),
      boxShadow: [
        BoxShadow(
          color:
              glowColor?.withValues(alpha: isDark ? 0.18 : 0.08) ??
              ac.cardShadow,
          blurRadius: glowColor != null ? 24 : 12,
          spreadRadius: glowColor != null ? -2 : -4,
        ),
        if (!isDark)
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.9),
            blurRadius: 0,
            spreadRadius: 0,
            offset: const Offset(0, -1),
          ),
      ],
    );

    Widget content = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: cardDecoration,
          child: child,
        ),
      ),
    );

    if (onTap != null) {
      content = Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(borderRadius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          splashColor: (highlightColor ?? ac.cardBorder).withValues(alpha: 0.1),
          highlightColor: (highlightColor ?? ac.cardBorder).withValues(
            alpha: 0.06,
          ),
          child: content,
        ),
      );
    }

    return Padding(padding: margin, child: content);
  }
}
