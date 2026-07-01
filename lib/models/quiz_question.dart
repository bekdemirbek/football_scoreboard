class QuizQuestion {
  const QuizQuestion({
    required this.id,
    required this.category,
    required this.difficulty,
    required this.question,
    required this.options,
    required this.correctIndex,
  });

  final String id;
  final String category;
  final String difficulty; // easy / medium / hard
  final String question;
  final List<String> options; // her zaman 4 eleman
  final int correctIndex;

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      id: json['id']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      difficulty: json['difficulty']?.toString() ?? 'medium',
      question: json['question']?.toString() ?? '',
      options: (json['options'] as List? ?? const [])
          .map((e) => e.toString())
          .toList(growable: false),
      correctIndex: json['correctIndex'] is int
          ? json['correctIndex'] as int
          : int.tryParse(json['correctIndex']?.toString() ?? '0') ?? 0,
    );
  }

  /// Şıkları karıştırılmış yeni bir kopya döndürür; doğru cevabın yeni
  /// konumu [correctIndex] olarak güncellenir.
  QuizQuestion shuffledOptions() {
    final correctAnswer = options[correctIndex];
    final shuffled = List<String>.from(options)..shuffle();
    return QuizQuestion(
      id: id,
      category: category,
      difficulty: difficulty,
      question: question,
      options: shuffled,
      correctIndex: shuffled.indexOf(correctAnswer),
    );
  }
}
