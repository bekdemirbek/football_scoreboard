import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_theme.dart';
import '../../models/quiz_result.dart';
import '../../providers/api_providers.dart';

/// Quiz liderlik tablosu: doğru sayısına (eşitlikte süreye) göre sıralı
/// kayıtlar. Veri [quizLeaderboardProvider] üzerinden gelir.
class QuizLeaderboardPage extends ConsumerWidget {
  const QuizLeaderboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaderboard = ref.watch(quizLeaderboardProvider);

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
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: _LeaderboardHeader(
                    onBack: () => Navigator.of(context).pop(),
                    onRefresh: () => ref.invalidate(quizLeaderboardProvider),
                  ),
                ),
                Expanded(
                  child: leaderboard.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => _EmptyOrError(message: e.toString()),
                    data: (results) => results.isEmpty
                        ? const _EmptyOrError(
                            message:
                                'Henüz kimse quiz çözmedi. İlk skoru sen yaz!',
                          )
                        : _LeaderboardList(results: results),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LeaderboardHeader extends StatelessWidget {
  const _LeaderboardHeader({required this.onBack, required this.onRefresh});

  final VoidCallback onBack;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Text('LİDERLİK TABLOSU', style: AppTextStyles.screenTitle),
          Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: onBack,
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.cardBg,
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: AppColors.textPrimary,
                  size: 17,
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: onRefresh,
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.cardBg,
                ),
                child: const Icon(
                  Icons.refresh_rounded,
                  color: AppColors.textPrimary,
                  size: 19,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LeaderboardList extends StatelessWidget {
  const _LeaderboardList({required this.results});

  final List<QuizResult> results;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      itemCount: results.length + 1,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        if (index == results.length) {
          return const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Center(
              child: Text(
                'Eşit skorda en hızlı önde sıralanır',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        }
        return _LeaderboardRow(rank: index + 1, result: results[index]);
      },
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  const _LeaderboardRow({required this.rank, required this.result});

  final int rank;
  final QuizResult result;

  @override
  Widget build(BuildContext context) {
    final isFirst = rank == 1;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isFirst ? AppColors.accentGreen : AppColors.cardBorder,
          width: isFirst ? 1.5 : 1,
        ),
        gradient: isFirst
            ? LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  AppColors.accentGreen.withValues(alpha: 0.14),
                  AppColors.accentGreen.withValues(alpha: 0.04),
                ],
              )
            : null,
        color: isFirst ? null : AppColors.cardBg,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      child: Row(
        children: [
          // ── Sıra / kupa ──────────────────────────────────────────────────
          SizedBox(
            width: 28,
            child: isFirst
                ? const Icon(
                    Icons.emoji_events_rounded,
                    color: AppColors.goldColor,
                    size: 22,
                  )
                : Text(
                    '$rank',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          // ── İsim + tarih ─────────────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.playerName,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: isFirst ? FontWeight.w900 : FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatDate(result.playedAt),
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // ── Skor ─────────────────────────────────────────────────────────
          Text(
            '${result.correctCount}/${result.totalQuestions}',
            style: const TextStyle(
              color: AppColors.accentGreen,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 12),
          // ── Süre ─────────────────────────────────────────────────────────
          Text(
            result.formattedTime,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final hh = d.hour.toString().padLeft(2, '0');
    final min = d.minute.toString().padLeft(2, '0');
    return '$dd.$mm · $hh:$min';
  }
}

class _EmptyOrError extends StatelessWidget {
  const _EmptyOrError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accentGreen.withValues(alpha: 0.1),
                border: Border.all(
                  color: AppColors.accentGreen.withValues(alpha: 0.2),
                  width: 1.5,
                ),
              ),
              child: const Icon(
                Icons.emoji_events_outlined,
                color: AppColors.goldColor,
                size: 36,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                height: 1.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
