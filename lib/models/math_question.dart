import 'dart:math';

enum MathGameType { counting, tracing, addition }

class MathQuestion {
  final int correctAnswer;
  final List<int> options;
  final String question;
  final String emoji;
  final int count;

  MathQuestion({
    required this.correctAnswer,
    required this.options,
    required this.question,
    this.emoji = '🍎',
    this.count = 0,
  });

  static MathQuestion generateCounting(int maxNumber, Random random) {
    final count = random.nextInt(maxNumber) + 1;
    final emojis = ['🍎', '🐱', '⭐', '🌸', '🐟', '🍭', '🐦', '🦋'];
    final emoji = emojis[random.nextInt(emojis.length)];

    final options = <int>{count};
    while (options.length < 4) {
      final offset = random.nextInt(5) + 1;
      final sign = random.nextBool() ? 1 : -1;
      final wrong = count + sign * offset;
      if (wrong > 0 && wrong <= maxNumber + 3) {
        options.add(wrong);
      }
    }
    final shuffled = options.toList()..shuffle(random);

    return MathQuestion(
      correctAnswer: count,
      options: shuffled,
      question: 'How many $emoji?',
      emoji: emoji,
      count: count,
    );
  }

  static MathQuestion generateAddition(int maxSum, Random random) {
    final a = random.nextInt(maxSum ~/ 2) + 1;
    final b = random.nextInt(maxSum - a) + 1;
    final sum = a + b;
    final emojis = ['🍎', '🐱', '⭐', '🌸', '🐟'];
    final emoji = emojis[random.nextInt(emojis.length)];

    final options = <int>{sum};
    while (options.length < 4) {
      final offset = random.nextInt(4) + 1;
      final sign = random.nextBool() ? 1 : -1;
      final wrong = sum + sign * offset;
      if (wrong > 0) {
        options.add(wrong);
      }
    }
    final shuffled = options.toList()..shuffle(random);

    return MathQuestion(
      correctAnswer: sum,
      options: shuffled,
      question: '$a + $b = ?',
      emoji: emoji,
      count: a,
    );
  }
}
