import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_theme.dart';
import '../../models/quiz_result.dart';
import '../../providers/api_providers.dart';
import '../../widgets/fade_route.dart';
import '../../widgets/screen_header.dart';
import 'quiz_leaderboard_page.dart';

/// Quiz oyun akışı: sorular → sonuç. Süre sayacı (canlı saat) bu ekranın
/// State'inde tutulur; quiz durumu [quizControllerProvider]'da yönetilir.
class QuizPlayPage extends ConsumerStatefulWidget {
  const QuizPlayPage({super.key});

  @override
  ConsumerState<QuizPlayPage> createState() => _QuizPlayPageState();
}

class _QuizPlayPageState extends ConsumerState<QuizPlayPage> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    // İlk kareden sonra turu başlat (build sırasında state değiştirmemek için).
    WidgetsBinding.instance.addPostFrameCallback((_) => _restart());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _restart() async {
    await ref.read(quizControllerProvider.notifier).start();
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final state = ref.read(quizControllerProvider);
      if (state.isFinished) {
        _ticker?.cancel();
      } else {
        setState(() {}); // canlı saati yenile
      }
    });
  }

  void _onSelect(int index) {
    final notifier = ref.read(quizControllerProvider.notifier);
    notifier.selectAnswer(index);
    // Doğru/yanlış geri bildirimini göster, sonra otomatik ilerle.
    Future.delayed(const Duration(milliseconds: 950), () {
      if (mounted) notifier.next();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(quizControllerProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
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
          SafeArea(bottom: false, child: _buildBody(state)),
        ],
      ),
    );
  }

  Widget _buildBody(QuizState state) {
    if (state.isLoading || !state.hasQuestions) {
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: ScreenHeader(
              title: 'Futbol Quiz',
              onBack: () => Navigator.of(context).pop(),
            ),
          ),
          const Expanded(child: Center(child: CircularProgressIndicator())),
        ],
      );
    }

    if (state.isFinished && state.result != null) {
      return _ResultView(
        result: state.result!,
        onReplay: _restart,
        onLeaderboard: () => Navigator.of(
          context,
        ).push(FadeRoute(child: const QuizLeaderboardPage())),
        onClose: () => Navigator.of(context).pop(),
      );
    }

    return _QuestionView(
      state: state,
      onSelect: _onSelect,
      onClose: () => Navigator.of(context).pop(),
    );
  }
}

// ─── Soru ekranı ─────────────────────────────────────────────────────────────────

class _QuestionView extends StatelessWidget {
  const _QuestionView({
    required this.state,
    required this.onSelect,
    required this.onClose,
  });

  final QuizState state;
  final ValueChanged<int> onSelect;
  final VoidCallback onClose;

  String _formatElapsed() {
    final start = state.startTime;
    if (start == null) return '0:00';
    final d = DateTime.now().difference(start);
    final m = d.inMinutes.toString();
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final question = state.currentQuestion!;

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 32),
      children: [
        // ── Üst satır: Soru X/10 + süre ─────────────────────────────────
        Row(
          children: [
            GestureDetector(
              onTap: onClose,
              behavior: HitTestBehavior.opaque,
              child: const Icon(
                Icons.close_rounded,
                color: AppColors.textSecondary,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Soru ${state.currentIndex + 1}/${state.total}',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.accentGreen.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.accentGreen.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.schedule_rounded,
                    color: AppColors.accentGreen,
                    size: 14,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    _formatElapsed(),
                    style: const TextStyle(
                      color: AppColors.accentGreen,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        // ── Segment ilerleme çubuğu ──────────────────────────────────────
        _QuizProgressBar(total: state.total, current: state.currentIndex),
        const SizedBox(height: 22),
        // ── Kategori ─────────────────────────────────────────────────────
        Text(
          question.category.toUpperCase(),
          style: const TextStyle(
            color: AppColors.accentGreen,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        // ── Soru metni ───────────────────────────────────────────────────
        Text(
          question.question,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 20),
        // ── Şıklar ───────────────────────────────────────────────────────
        for (var i = 0; i < question.options.length; i++) ...[
          _OptionTile(
            letter: String.fromCharCode(65 + i), // A, B, C, D
            text: question.options[i],
            index: i,
            correctIndex: question.correctIndex,
            selectedIndex: state.selectedIndex,
            answered: state.hasAnswered,
            onTap: () => onSelect(i),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _QuizProgressBar extends StatelessWidget {
  const _QuizProgressBar({required this.total, required this.current});

  final int total;
  final int current;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < total; i++) ...[
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              height: 5,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                gradient: i < current ? AppGradients.greenGlow : null,
                color: i < current ? null : AppColors.cardBorder,
              ),
            ),
          ),
          if (i != total - 1) const SizedBox(width: 5),
        ],
      ],
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.letter,
    required this.text,
    required this.index,
    required this.correctIndex,
    required this.selectedIndex,
    required this.answered,
    required this.onTap,
  });

  final String letter;
  final String text;
  final int index;
  final int correctIndex;
  final int? selectedIndex;
  final bool answered;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Cevap sonrası renk geri bildirimi:
    // doğru şık → yeşil; kullanıcının yanlış seçtiği → kırmızı; diğerleri sönük.
    Color borderColor = AppColors.cardBorder;
    Color bgColor = AppColors.cardBg;
    Color accent = AppColors.textSecondary;

    if (answered) {
      if (index == correctIndex) {
        borderColor = AppColors.accentGreen;
        bgColor = AppColors.accentGreen.withValues(alpha: 0.1);
        accent = AppColors.accentGreen;
      } else if (index == selectedIndex) {
        borderColor = AppColors.liveRed;
        bgColor = AppColors.liveRed.withValues(alpha: 0.1);
        accent = AppColors.liveRed;
      }
    }

    return GestureDetector(
      onTap: answered ? null : onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: 1.4),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 26,
              height: 26,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.withValues(alpha: 0.14),
              ),
              child: Text(
                letter,
                style: TextStyle(
                  color: accent,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (answered && index == correctIndex)
              const Icon(
                Icons.check_circle_rounded,
                color: AppColors.accentGreen,
                size: 20,
              )
            else if (answered && index == selectedIndex)
              const Icon(
                Icons.cancel_rounded,
                color: AppColors.liveRed,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Sonuç ekranı ────────────────────────────────────────────────────────────────

class _ResultView extends ConsumerWidget {
  const _ResultView({
    required this.result,
    required this.onReplay,
    required this.onLeaderboard,
    required this.onClose,
  });

  final QuizResult result;
  final VoidCallback onReplay;
  final VoidCallback onLeaderboard;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaderboard = ref.watch(quizLeaderboardProvider);
    final rank = leaderboard.maybeWhen(
      data: (list) {
        final idx = list.indexWhere((r) => r.id == result.id);
        return idx >= 0 ? idx + 1 : null;
      },
      orElse: () => null,
    );

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            onTap: onClose,
            behavior: HitTestBehavior.opaque,
            child: const Icon(
              Icons.close_rounded,
              color: AppColors.textSecondary,
              size: 22,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accentGreen.withValues(alpha: 0.12),
              border: Border.all(
                color: AppColors.accentGreen.withValues(alpha: 0.4),
                width: 1.5,
              ),
            ),
            child: const Icon(
              Icons.celebration_rounded,
              color: AppColors.accentGreen,
              size: 36,
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Tur tamamlandı',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Sonuçların liderlik tablosuna kaydedildi',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 22),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                label: 'Skor',
                value: '${result.correctCount}/${result.totalQuestions}',
                color: AppColors.accentGreen,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                label: 'Süre',
                value: result.formattedTime,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.cardBorder),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              const Icon(
                Icons.trending_up_rounded,
                color: AppColors.accentGreen,
                size: 20,
              ),
              const SizedBox(width: 10),
              const Text(
                'Şu anki sıralaman',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                rank != null ? '#$rank' : '—',
                style: const TextStyle(
                  color: AppColors.accentGreen,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: onReplay,
          icon: const Icon(Icons.refresh_rounded, size: 18),
          label: const Text('Tekrar oyna'),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: onLeaderboard,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textPrimary,
            side: const BorderSide(color: AppColors.cardBorder),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: const Icon(Icons.emoji_events_rounded, size: 18),
          label: const Text('Liderlik tablosunu gör'),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 26,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}
