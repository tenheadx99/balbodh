class GameProgress {
  final String module;
  final Set<String> masteredLetters;
  final Map<String, int> attempts;
  final Map<String, int> correctCount;
  int totalStars;
  int totalGamesPlayed;

  GameProgress({
    required this.module,
    Set<String>? masteredLetters,
    Map<String, int>? attempts,
    Map<String, int>? correctCount,
    this.totalStars = 0,
    this.totalGamesPlayed = 0,
  })  : masteredLetters = masteredLetters ?? {},
        attempts = attempts ?? {},
        correctCount = correctCount ?? {};

  void recordAttempt(String letter, bool correct) {
    attempts[letter] = (attempts[letter] ?? 0) + 1;
    if (correct) {
      correctCount[letter] = (correctCount[letter] ?? 0) + 1;
      if ((correctCount[letter] ?? 0) >= 3) {
        masteredLetters.add(letter);
      }
    }
  }

  bool isMastered(String letter) => masteredLetters.contains(letter);

  double masteryPercent(String letter) {
    final total = attempts[letter] ?? 0;
    if (total == 0) return 0;
    return (correctCount[letter] ?? 0) / total;
  }

  int get masteredCount => masteredLetters.length;

  void addStar() => totalStars++;
  void addGamePlayed() => totalGamesPlayed++;

  Map<String, dynamic> toJson() => {
    'module': module,
    'masteredLetters': masteredLetters.toList(),
    'attempts': attempts,
    'correctCount': correctCount,
    'totalStars': totalStars,
    'totalGamesPlayed': totalGamesPlayed,
  };

  factory GameProgress.fromJson(Map<String, dynamic> json) => GameProgress(
    module: json['module'] as String,
    masteredLetters: (json['masteredLetters'] as List).toSet().cast<String>(),
    attempts: (json['attempts'] as Map).map((k, v) => MapEntry(k as String, v as int)),
    correctCount: (json['correctCount'] as Map).map((k, v) => MapEntry(k as String, v as int)),
    totalStars: json['totalStars'] as int? ?? 0,
    totalGamesPlayed: json['totalGamesPlayed'] as int? ?? 0,
  );
}
