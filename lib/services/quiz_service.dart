import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../models/quiz_question.dart';

/// Quiz soru havuzunu asset'ten okuyan ve bir tur için rastgele soru seçen
/// servis. ApiService gibi veriyi okuyup kullanıma hazır hâle getirir.
class QuizService {
  QuizService({this.assetPath = 'assets/data/quiz_questions.json'});

  final String assetPath;

  Future<List<QuizQuestion>> loadQuestionPool() async {
    final raw = await rootBundle.loadString(assetPath);
    final data = jsonDecode(raw);
    if (data is! List) return const [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(QuizQuestion.fromJson)
        .toList(growable: false);
  }

  /// Havuzdan rastgele [count] soru seçer; hem soru sırasını hem de her
  /// sorunun şık sırasını karıştırır (ezberi önlemek için her turda yeniden).
  Future<List<QuizQuestion>> buildQuiz({int count = 10}) async {
    final pool = await loadQuestionPool();
    final shuffledPool = List<QuizQuestion>.from(pool)..shuffle();
    return shuffledPool
        .take(count)
        .map((q) => q.shuffledOptions())
        .toList(growable: false);
  }
}
