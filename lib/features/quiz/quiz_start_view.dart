import 'package:flutter/material.dart';

import '../../core/app_theme.dart';
import '../../widgets/fade_route.dart';
import 'quiz_leaderboard_page.dart';
import 'quiz_play_page.dart';

/// Quiz başlangıç kartı (görsel 1). Oyunlar sekmesindeki "Quiz" segmentinde
/// gösterilir; "Quiz'e başla" tam ekran oyun akışını açar.
class QuizStartView extends StatelessWidget {
  const QuizStartView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Tanıtım kartı ────────────────────────────────────────────────
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.cardBorder),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.cardBgRaised, AppColors.cardBg],
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.accentGreen.withValues(alpha: 0.12),
                  border: Border.all(
                    color: AppColors.accentGreen.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                ),
                child: const Icon(
                  Icons.sports_soccer_rounded,
                  color: AppColors.accentGreen,
                  size: 34,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Futbol bilgini test et',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '100 soruluk havuzdan rastgele 10 soru seçilecek. '
                'Hızlı ve doğru cevapla.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // ── İki bilgi kartı ──────────────────────────────────────────────
        Row(
          children: const [
            Expanded(
              child: _InfoTile(
                icon: Icons.help_outline_rounded,
                title: '10 soru',
                subtitle: 'her turda',
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _InfoTile(
                icon: Icons.schedule_rounded,
                title: 'Süreli',
                subtitle: 'cevap ver',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // ── Başla butonu ─────────────────────────────────────────────────
        FilledButton.icon(
          onPressed: () => Navigator.of(
            context,
          ).push(FadeRoute(child: const QuizPlayPage())),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.accentGreen,
            foregroundColor: AppColors.bgPrimary,
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          icon: const Icon(Icons.play_arrow_rounded, size: 22),
          label: const Text("Quiz'e başla"),
        ),
        const SizedBox(height: 12),
        // ── Liderlik linki ───────────────────────────────────────────────
        Center(
          child: TextButton.icon(
            onPressed: () => Navigator.of(
              context,
            ).push(FadeRoute(child: const QuizLeaderboardPage())),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
            ),
            icon: const Icon(Icons.emoji_events_outlined, size: 17),
            label: const Text(
              'Liderlik tablosunu gör',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.accentGreen, size: 20),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
