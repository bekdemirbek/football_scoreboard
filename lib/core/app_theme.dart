import 'package:flutter/material.dart';

/// MaçKart Tasarım Sistemi
/// Dark + Emerald/Gold spor uygulaması teması.
///
/// Tüm renkler `AppColors.*` statik sabitlerinden, tüm metin stilleri
/// `AppTextStyles.*`'tan gelir. Uygulama sadece-dark çalışır.
class AppColors {
  const AppColors._();

  // ─── Arka plan katmanları ─────────────────────────────────────────────
  static const Color bgPrimary = Color(0xFF090C0A);
  static const Color bgSecondary = Color(0xFF0C100D);
  static const Color cardBg = Color(0xFF121814);
  static const Color cardBgRaised = Color(0xFF161D18);
  static const Color cardBorder = Color(0xFF202820);

  // ─── Vurgu renkleri ───────────────────────────────────────────────────
  static const Color accentGreen = Color(0xFF27C06A); // zümrüt
  static const Color accentGreenSoft = Color(0xFF1E9E57);
  static const Color accentOrange = Color(0xFFE08A2E); // amber
  static const Color liveRed = Color(0xFFE23B4E);

  // ─── Metin renkleri ───────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFFF2F5F1);
  static const Color textSecondary = Color(0xFF8C968D);
  static const Color textMuted = Color(0xFF5A645B);

  // ─── Takım rozetleri için varsayılan arka plan ────────────────────────
  static const Color badgeBg = Color(0xFF1B231D);

  // ─── Saha (lineup) zemini ─────────────────────────────────────────────
  static const Color pitchField = Color(0xFF0D3322);
  static const Color pitchFieldStripe = Color(0xFF0F3C28);
  static const Color pitchLine = Color(0x8CFFFFFF);

  // ─── Uygulama genelinde kullanılan türetilmiş tokenlar ────────────────
  static const Color gradientStart = bgPrimary;
  static const Color gradientEnd = bgSecondary;
  static const Color cardSurface = cardBg;
  static const Color cardShadow = Color(0x73000000);

  static const Color liveColor = liveRed;
  static const Color liveBg = Color(0x22E23B4E);

  static const Color championColor = accentGreen; // Şampiyonlar Ligi / ilk sıra
  static const Color europaColor = Color(0xFF4F8CFF); // Avrupa Ligi
  static const Color relegationColor = liveRed; // Küme düşme
  static const Color goldColor = Color(0xFFE3B23C); // Lider / 1. sıra vurgusu

  static const Color textTertiary = textMuted;
  static const Color divider = Color(0x12FFFFFF);

  static const Color shimmerBase = cardBg;
  static const Color shimmerHighlight = cardBorder;

  static const Color navBg = Color(0xF20C100D);
  static const Color navBorder = cardBorder;

  static const Color headerGradientStart = accentGreen;
  static const Color headerGradientEnd = goldColor;

  static const Color selectedPill = accentGreen;
  static const Color unselectedPill = badgeBg;
  static const Color leagueBadgeBg = badgeBg;
}

class AppGradients {
  /// Vurgulu kart kenarı: yeşil → altın (görsellerdeki imza kenarlık).
  static const LinearGradient liveCardBorder = LinearGradient(
    colors: [AppColors.accentGreen, AppColors.goldColor],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient greenGlow = LinearGradient(
    colors: [Color(0xFF2FD27A), Color(0xFF159E55)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient orangeGlow = LinearGradient(
    colors: [Color(0xFFF0A93E), Color(0xFFD9791F)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient header = LinearGradient(
    colors: [AppColors.accentGreen, AppColors.goldColor],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Kartların içine verilen hafif dikey parlama (üst biraz aydınlık).
  static final LinearGradient cardSheen = LinearGradient(
    colors: [
      Colors.white.withValues(alpha: 0.05),
      Colors.white.withValues(alpha: 0.0),
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  /// Rütbeye göre kenar/sayı gradyanı (gol krallığı, sıralama).
  static LinearGradient rankGradient(int rank) {
    final colors = switch (rank) {
      1 => const [Color(0xFFF1C24B), Color(0xFFB9842A)], // altın
      2 => const [Color(0xFFD7DEE0), Color(0xFF9AA6A8)], // gümüş
      3 => const [Color(0xFFE0922E), Color(0xFFB05C18)], // bronz
      _ => const [Color(0xFF2FD27A), Color(0xFF159E55)], // yeşil
    };
    return LinearGradient(
      colors: colors,
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }
}

class AppTextStyles {
  static const String fontFamily = 'Outfit'; // veya Inter / SF Pro

  static const TextStyle scoreLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 30,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
    height: 1.0,
  );

  static const TextStyle teamName = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle label = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    letterSpacing: 0.3,
  );

  static const TextStyle minuteLive = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: AppColors.liveRed,
  );

  /// Ekran başlıkları: ortalı, büyük harf, geniş aralıklı.
  static const TextStyle screenTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 19,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
    letterSpacing: 1.5,
  );

  static const TextStyle sectionTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );
}

class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.bgPrimary,
      fontFamily: AppTextStyles.fontFamily,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.accentGreen,
        onPrimary: AppColors.bgPrimary,
        secondary: AppColors.goldColor,
        onSecondary: AppColors.bgPrimary,
        tertiary: AppColors.goldColor,
        surface: AppColors.cardBg,
        onSurface: AppColors.textPrimary,
        surfaceContainerHighest: AppColors.bgSecondary,
        outline: AppColors.cardBorder,
        error: AppColors.liveRed,
        onError: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: AppTextStyles.screenTitle,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
      ),
      listTileTheme: const ListTileThemeData(contentPadding: EdgeInsets.zero),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.bgSecondary,
        selectedItemColor: AppColors.accentGreen,
        unselectedItemColor: AppColors.textMuted,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.accentGreen,
          foregroundColor: AppColors.bgPrimary,
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        side: BorderSide.none,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.accentGreen,
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardBg,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.cardBorder, width: 1),
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------
/// Canlı maç kartı — yeşil→altın gradyan kenarlık + glow, kenarlarda
/// nabız atan renk noktaları (görsellerdeki CANLI SKORLAR kartı).
/// ---------------------------------------------------------------
class LiveMatchCard extends StatefulWidget {
  final String homeTeam;
  final String awayTeam;
  final int? homeScore;
  final int? awayScore;
  final String minute;
  final VoidCallback? onTap;
  final Widget? homeLeading;
  final Widget? awayTrailing;
  final bool hasFavorite;

  const LiveMatchCard({
    super.key,
    required this.homeTeam,
    required this.awayTeam,
    required this.homeScore,
    required this.awayScore,
    required this.minute,
    this.onTap,
    this.homeLeading,
    this.awayTrailing,
    this.hasFavorite = false,
  });

  @override
  State<LiveMatchCard> createState() => _LiveMatchCardState();
}

class _LiveMatchCardState extends State<LiveMatchCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasScore = widget.homeScore != null && widget.awayScore != null;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        padding: const EdgeInsets.all(1.4), // gradient border kalınlığı
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: AppGradients.liveCardBorder,
          boxShadow: [
            BoxShadow(
              color: AppColors.goldColor.withValues(alpha: 0.16),
              blurRadius: 22,
              spreadRadius: -6,
            ),
          ],
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(18.6),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.cardBgRaised, AppColors.cardBg],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _LiveTag(pulse: _pulseController),
                  const Spacer(),
                  if (widget.hasFavorite) ...[
                    const Icon(
                      Icons.star_rounded,
                      color: AppColors.goldColor,
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                  ],
                  Text(widget.minute, style: AppTextStyles.minuteLive),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (widget.homeLeading != null) ...[
                    widget.homeLeading!,
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: Text(
                      widget.homeTeam,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.teamName,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      hasScore
                          ? '${widget.homeScore} - ${widget.awayScore}'
                          : 'VS',
                      style: AppTextStyles.scoreLarge,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      widget.awayTeam,
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.teamName,
                    ),
                  ),
                  if (widget.awayTrailing != null) ...[
                    const SizedBox(width: 10),
                    widget.awayTrailing!,
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LiveTag extends StatelessWidget {
  const _LiveTag({required this.pulse});
  final Animation<double> pulse;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.liveBg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.liveRed.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FadeTransition(
            opacity: pulse,
            child: Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: AppColors.liveRed,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 5),
          const Text(
            'CANLI',
            style: TextStyle(
              color: AppColors.liveRed,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}

/// ---------------------------------------------------------------
/// Gradient istatistik bar'ı (Topla Oynama, Şut, Korner, Faul vb.)
/// İstatistik ekranındaki tüm karşılaştırma barları bunu kullanır.
/// ---------------------------------------------------------------
class StatBar extends StatelessWidget {
  final String label;
  final int leftValue;
  final int rightValue;
  final bool isPercentage;
  final String? leftDisplay;
  final String? rightDisplay;

  const StatBar({
    super.key,
    required this.label,
    required this.leftValue,
    required this.rightValue,
    this.isPercentage = false,
    this.leftDisplay,
    this.rightDisplay,
  });

  @override
  Widget build(BuildContext context) {
    final total = leftValue + rightValue;
    final leftRatio = total == 0 ? 0.5 : leftValue / total;
    final leftFlex = (leftRatio * 100).round().clamp(2, 98);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 52,
                child: Text(
                  leftDisplay ?? '$leftValue${isPercentage ? "%" : ""}',
                  style: const TextStyle(
                    color: AppColors.accentGreen,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(
                width: 52,
                child: Text(
                  rightDisplay ?? '$rightValue${isPercentage ? "%" : ""}',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    color: AppColors.accentOrange,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 7,
              child: Row(
                children: [
                  Expanded(
                    flex: leftFlex,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: AppGradients.greenGlow,
                      ),
                    ),
                  ),
                  const SizedBox(width: 3),
                  Expanded(
                    flex: 100 - leftFlex,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: AppGradients.orangeGlow,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
