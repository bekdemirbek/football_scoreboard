import 'package:flutter/material.dart';

// ─── Custom Color Extension ───────────────────────────────────────────────────

@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.gradientStart,
    required this.gradientEnd,
    required this.cardSurface,
    required this.cardBorder,
    required this.cardShadow,
    required this.liveColor,
    required this.liveBg,
    required this.championColor,
    required this.europaColor,
    required this.relegationColor,
    required this.goldColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.divider,
    required this.shimmerBase,
    required this.shimmerHighlight,
    required this.navBg,
    required this.navBorder,
    required this.headerGradientStart,
    required this.headerGradientEnd,
    required this.selectedPill,
    required this.unselectedPill,
    required this.leagueBadgeBg,
  });

  final Color gradientStart;
  final Color gradientEnd;
  final Color cardSurface;
  final Color cardBorder;
  final Color cardShadow;
  final Color liveColor;
  final Color liveBg;
  final Color championColor;
  final Color europaColor;
  final Color relegationColor;
  final Color goldColor;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color divider;
  final Color shimmerBase;
  final Color shimmerHighlight;
  final Color navBg;
  final Color navBorder;
  final Color headerGradientStart;
  final Color headerGradientEnd;
  final Color selectedPill;
  final Color unselectedPill;
  final Color leagueBadgeBg;

  // ─── Dark Mode Palette ─────────────────────────────────────────────────────
  static const dark = AppColors(
    gradientStart: Color(0xFF07091A),
    gradientEnd: Color(0xFF0D1528),
    cardSurface: Color(0x0FFFFFFF),
    cardBorder: Color(0x16FFFFFF),
    cardShadow: Color(0x44000000),
    liveColor: Color(0xFFFF4757),
    liveBg: Color(0x22FF4757),
    championColor: Color(0xFF00E5A0),
    europaColor: Color(0xFF4F8CFF),
    relegationColor: Color(0xFFFF4757),
    goldColor: Color(0xFFFFD060),
    textPrimary: Color(0xFFF1F5F9),
    textSecondary: Color(0xFF94A3B8),
    textTertiary: Color(0xFF475569),
    divider: Color(0x14FFFFFF),
    shimmerBase: Color(0xFF1E293B),
    shimmerHighlight: Color(0xFF2D3F55),
    navBg: Color(0xE00D1525),
    navBorder: Color(0x18FFFFFF),
    headerGradientStart: Color(0xFF00E5A0),
    headerGradientEnd: Color(0xFF4F8CFF),
    selectedPill: Color(0xFF00E5A0),
    unselectedPill: Color(0xFF1C2B3F),
    leagueBadgeBg: Color(0xFF1C2B3F),
  );

  // ─── Light Mode Palette ────────────────────────────────────────────────────
  static const light = AppColors(
    gradientStart: Color(0xFFF0F5FF),
    gradientEnd: Color(0xFFE3F5EF),
    cardSurface: Color(0xF2FFFFFF),
    cardBorder: Color(0xFFDDE8F5),
    cardShadow: Color(0x0A000000),
    liveColor: Color(0xFFE53935),
    liveBg: Color(0x14E53935),
    championColor: Color(0xFF0A7C5C),
    europaColor: Color(0xFF2563EB),
    relegationColor: Color(0xFFD32F2F),
    goldColor: Color(0xFFF59E0B),
    textPrimary: Color(0xFF0F172A),
    textSecondary: Color(0xFF475569),
    textTertiary: Color(0xFF94A3B8),
    divider: Color(0x14000000),
    shimmerBase: Color(0xFFE8EFF8),
    shimmerHighlight: Color(0xFFF8FAFF),
    navBg: Color(0xF5FFFFFF),
    navBorder: Color(0x22000000),
    headerGradientStart: Color(0xFF0A7C5C),
    headerGradientEnd: Color(0xFF2563EB),
    selectedPill: Color(0xFF0A7C5C),
    unselectedPill: Color(0xFFEEF2FB),
    leagueBadgeBg: Color(0xFFEEF2FB),
  );

  @override
  AppColors copyWith({
    Color? gradientStart,
    Color? gradientEnd,
    Color? cardSurface,
    Color? cardBorder,
    Color? cardShadow,
    Color? liveColor,
    Color? liveBg,
    Color? championColor,
    Color? europaColor,
    Color? relegationColor,
    Color? goldColor,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? divider,
    Color? shimmerBase,
    Color? shimmerHighlight,
    Color? navBg,
    Color? navBorder,
    Color? headerGradientStart,
    Color? headerGradientEnd,
    Color? selectedPill,
    Color? unselectedPill,
    Color? leagueBadgeBg,
  }) {
    return AppColors(
      gradientStart: gradientStart ?? this.gradientStart,
      gradientEnd: gradientEnd ?? this.gradientEnd,
      cardSurface: cardSurface ?? this.cardSurface,
      cardBorder: cardBorder ?? this.cardBorder,
      cardShadow: cardShadow ?? this.cardShadow,
      liveColor: liveColor ?? this.liveColor,
      liveBg: liveBg ?? this.liveBg,
      championColor: championColor ?? this.championColor,
      europaColor: europaColor ?? this.europaColor,
      relegationColor: relegationColor ?? this.relegationColor,
      goldColor: goldColor ?? this.goldColor,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      divider: divider ?? this.divider,
      shimmerBase: shimmerBase ?? this.shimmerBase,
      shimmerHighlight: shimmerHighlight ?? this.shimmerHighlight,
      navBg: navBg ?? this.navBg,
      navBorder: navBorder ?? this.navBorder,
      headerGradientStart: headerGradientStart ?? this.headerGradientStart,
      headerGradientEnd: headerGradientEnd ?? this.headerGradientEnd,
      selectedPill: selectedPill ?? this.selectedPill,
      unselectedPill: unselectedPill ?? this.unselectedPill,
      leagueBadgeBg: leagueBadgeBg ?? this.leagueBadgeBg,
    );
  }

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      gradientStart: Color.lerp(gradientStart, other.gradientStart, t)!,
      gradientEnd: Color.lerp(gradientEnd, other.gradientEnd, t)!,
      cardSurface: Color.lerp(cardSurface, other.cardSurface, t)!,
      cardBorder: Color.lerp(cardBorder, other.cardBorder, t)!,
      cardShadow: Color.lerp(cardShadow, other.cardShadow, t)!,
      liveColor: Color.lerp(liveColor, other.liveColor, t)!,
      liveBg: Color.lerp(liveBg, other.liveBg, t)!,
      championColor: Color.lerp(championColor, other.championColor, t)!,
      europaColor: Color.lerp(europaColor, other.europaColor, t)!,
      relegationColor: Color.lerp(relegationColor, other.relegationColor, t)!,
      goldColor: Color.lerp(goldColor, other.goldColor, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      shimmerBase: Color.lerp(shimmerBase, other.shimmerBase, t)!,
      shimmerHighlight: Color.lerp(
        shimmerHighlight,
        other.shimmerHighlight,
        t,
      )!,
      navBg: Color.lerp(navBg, other.navBg, t)!,
      navBorder: Color.lerp(navBorder, other.navBorder, t)!,
      headerGradientStart: Color.lerp(
        headerGradientStart,
        other.headerGradientStart,
        t,
      )!,
      headerGradientEnd: Color.lerp(
        headerGradientEnd,
        other.headerGradientEnd,
        t,
      )!,
      selectedPill: Color.lerp(selectedPill, other.selectedPill, t)!,
      unselectedPill: Color.lerp(unselectedPill, other.unselectedPill, t)!,
      leagueBadgeBg: Color.lerp(leagueBadgeBg, other.leagueBadgeBg, t)!,
    );
  }
}

// ─── Theme Builder ─────────────────────────────────────────────────────────────

class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme => _build(
    brightness: Brightness.dark,
    primary: const Color(0xFF00E5A0),
    onPrimary: const Color(0xFF003320),
    secondary: const Color(0xFF4F8CFF),
    onSecondary: const Color(0xFF001A6B),
    tertiary: const Color(0xFFFFD060),
    surface: const Color(0xFF111827),
    onSurface: const Color(0xFFF1F5F9),
    surfaceContainerHighest: const Color(0xFF1E293B),
    outline: const Color(0xFF334155),
    scaffoldBg: const Color(0xFF07091A),
    extension: AppColors.dark,
  );

  static ThemeData get lightTheme => _build(
    brightness: Brightness.light,
    primary: const Color(0xFF0A7C5C),
    onPrimary: const Color(0xFFFFFFFF),
    secondary: const Color(0xFF2563EB),
    onSecondary: const Color(0xFFFFFFFF),
    tertiary: const Color(0xFFF59E0B),
    surface: const Color(0xFFF8FAFF),
    onSurface: const Color(0xFF0F172A),
    surfaceContainerHighest: const Color(0xFFE8F0FE),
    outline: const Color(0xFFCBD5E1),
    scaffoldBg: const Color(0xFFF0F5FF),
    extension: AppColors.light,
  );

  static ThemeData _build({
    required Brightness brightness,
    required Color primary,
    required Color onPrimary,
    required Color secondary,
    required Color onSecondary,
    required Color tertiary,
    required Color surface,
    required Color onSurface,
    required Color surfaceContainerHighest,
    required Color outline,
    required Color scaffoldBg,
    required AppColors extension,
  }) {
    final isDark = brightness == Brightness.dark;

    final scheme = ColorScheme(
      brightness: brightness,
      primary: primary,
      onPrimary: onPrimary,
      secondary: secondary,
      onSecondary: onSecondary,
      tertiary: tertiary,
      onTertiary: isDark ? const Color(0xFF3A2000) : Colors.white,
      error: isDark ? const Color(0xFFFF4757) : const Color(0xFFD32F2F),
      onError: Colors.white,
      surface: surface,
      onSurface: onSurface,
      surfaceContainerHighest: surfaceContainerHighest,
      outline: outline,
      outlineVariant: isDark
          ? const Color(0x18FFFFFF)
          : const Color(0xFFDDE8F5),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffoldBg,
      extensions: [extension],
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: onSurface,
        titleTextStyle: TextStyle(
          color: onSurface,
          fontSize: 18,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.3,
        ),
        iconTheme: IconThemeData(color: onSurface),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: extension.cardSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: extension.cardBorder),
        ),
      ),
      dividerTheme: DividerThemeData(color: extension.divider, thickness: 1),
      listTileTheme: const ListTileThemeData(contentPadding: EdgeInsets.zero),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        side: BorderSide.none,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: primary),
    );
  }
}
