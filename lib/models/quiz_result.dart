/// Bir quiz turunun sonucu (liderlik tablosu kaydı).
/// Yerel olarak shared_preferences'ta JSON string listesi olarak saklanır.
class QuizResult {
  const QuizResult({
    required this.id,
    required this.correctCount,
    required this.totalQuestions,
    required this.elapsed,
    required this.playedAt,
    this.playerName = 'Sen',
  });

  final String id;
  final int correctCount;
  final int totalQuestions;
  final Duration elapsed;
  final DateTime playedAt;
  final String playerName; // şimdilik "Sen", ileride özelleştirilebilir

  Map<String, dynamic> toJson() => {
    'id': id,
    'correctCount': correctCount,
    'totalQuestions': totalQuestions,
    'elapsedSeconds': elapsed.inSeconds,
    'playedAt': playedAt.toIso8601String(),
    'playerName': playerName,
  };

  factory QuizResult.fromJson(Map<String, dynamic> json) => QuizResult(
    id: json['id']?.toString() ?? '',
    correctCount: (json['correctCount'] as num?)?.toInt() ?? 0,
    totalQuestions: (json['totalQuestions'] as num?)?.toInt() ?? 0,
    elapsed: Duration(seconds: (json['elapsedSeconds'] as num?)?.toInt() ?? 0),
    playedAt:
        DateTime.tryParse(json['playedAt']?.toString() ?? '') ?? DateTime.now(),
    playerName: json['playerName']?.toString() ?? 'Sen',
  );

  /// `dakika:saniye` biçimi (örn. `2:13`, `0:47`).
  String get formattedTime {
    final minutes = elapsed.inMinutes.toString();
    final seconds = (elapsed.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
