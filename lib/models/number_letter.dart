import 'bubble_letter.dart';

class NumberLetter {
  /// Word names indexed by their numeric value (index 0 = "Zero", 1 = "One", …).
  static const List<String> _names = [
    'Zero', 'One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven',
    'Eight', 'Nine', 'Ten', 'Eleven', 'Twelve', 'Thirteen', 'Fourteen',
    'Fifteen', 'Sixteen', 'Seventeen', 'Eighteen', 'Nineteen', 'Twenty',
  ];

  static List<BubbleLetter> generate(int count) {
    return List.generate(count, (i) {
      final n = i + 1; // numbers start at 1
      // names[n] is safe because n is 1..count and count <= 20
      final wordName = (n < _names.length) ? _names[n] : '$n';
      return BubbleLetter(
        letter: '$n',
        displayName: '$n',
        objectName: wordName, // e.g. "One", "Two", … "Twenty"
        module: ModuleType.math,
      );
    });
  }

  static List<BubbleLetter> get numbers1to20 => generate(20);

  /// Returns the English word for a number (1-20), e.g. wordFor(3) == "Three".
  static String wordFor(int n) {
    if (n >= 1 && n < _names.length) return _names[n];
    return '$n';
  }
}
