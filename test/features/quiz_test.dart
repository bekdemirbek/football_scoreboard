import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:football_scoreboard/models/quiz_question.dart';
import 'package:football_scoreboard/models/quiz_result.dart';
import 'package:football_scoreboard/providers/api_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('QuizQuestion.shuffledOptions', () {
    test('şıklar karışsa da doğru cevap correctIndex ile hizalı kalır', () {
      const question = QuizQuestion(
        id: 'q1',
        category: 'Test',
        difficulty: 'easy',
        question: 'Doğru cevap A mı?',
        options: ['A-doğru', 'B', 'C', 'D'],
        correctIndex: 0,
      );

      // Birçok kez karıştır; her seferinde correctIndex gerçek doğru cevabı
      // (metin olarak) göstermeli.
      for (var i = 0; i < 50; i++) {
        final shuffled = question.shuffledOptions();
        expect(shuffled.options, hasLength(4));
        expect(shuffled.options.toSet(), question.options.toSet());
        expect(shuffled.options[shuffled.correctIndex], 'A-doğru');
      }
    });
  });

  group('QuizResult', () {
    test('formattedTime dakika:saniye biçiminde', () {
      final r = QuizResult(
        id: '1',
        correctCount: 9,
        totalQuestions: 10,
        elapsed: const Duration(minutes: 2, seconds: 8),
        playedAt: DateTime(2026, 7, 1),
      );
      expect(r.formattedTime, '2:08');
    });

    test('toJson/fromJson gidiş-dönüşü korunur', () {
      final r = QuizResult(
        id: 'abc',
        correctCount: 7,
        totalQuestions: 10,
        elapsed: const Duration(seconds: 95),
        playedAt: DateTime.utc(2026, 7, 1, 12),
      );
      final back = QuizResult.fromJson(r.toJson());
      expect(back.id, r.id);
      expect(back.correctCount, 7);
      expect(back.elapsed, const Duration(seconds: 95));
    });
  });

  group('Liderlik sıralaması (QuizLeaderboardNotifier)', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('önce skora (yüksek→düşük), eşitlikte süreye (kısa→uzun) göre', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // build() tamamlansın (boş liste yüklensin).
      await container.read(quizLeaderboardProvider.future);
      final notifier = container.read(quizLeaderboardProvider.notifier);

      final now = DateTime(2026, 7, 1);
      await notifier.addResult(QuizResult(
        id: 'a',
        correctCount: 8,
        totalQuestions: 10,
        elapsed: const Duration(seconds: 120),
        playedAt: now,
      ));
      await notifier.addResult(QuizResult(
        id: 'b',
        correctCount: 10,
        totalQuestions: 10,
        elapsed: const Duration(seconds: 200),
        playedAt: now,
      ));
      await notifier.addResult(QuizResult(
        id: 'c',
        correctCount: 10,
        totalQuestions: 10,
        elapsed: const Duration(seconds: 150),
        playedAt: now,
      ));

      final list = container.read(quizLeaderboardProvider).value!;
      // c (10/150) > b (10/200) > a (8/120)
      expect(list.map((r) => r.id).toList(), ['c', 'b', 'a']);
    });

    test('kaydedilen sonuç kalıcıdır (yeni container aynı veriyi yükler)',
        () async {
      final c1 = ProviderContainer();
      await c1.read(quizLeaderboardProvider.future);
      await c1.read(quizLeaderboardProvider.notifier).addResult(
            QuizResult(
              id: 'x',
              correctCount: 5,
              totalQuestions: 10,
              elapsed: const Duration(seconds: 60),
              playedAt: DateTime(2026, 7, 1),
            ),
          );
      c1.dispose();

      final c2 = ProviderContainer();
      addTearDown(c2.dispose);
      final loaded = await c2.read(quizLeaderboardProvider.future);
      expect(loaded.map((r) => r.id), contains('x'));
    });
  });
}
