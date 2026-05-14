enum ModuleType { abc, hindi, math }

class BubbleLetter {
  final String letter;
  final String displayName;
  final String objectName;
  final ModuleType module;
  final bool isVowel;

  const BubbleLetter({
    required this.letter,
    required this.displayName,
    this.objectName = '',
    this.module = ModuleType.abc,
    this.isVowel = false,
  });

  static List<BubbleLetter> get abcLetters => const [
    BubbleLetter(letter: 'A', displayName: 'A', objectName: 'Apple'),
    BubbleLetter(letter: 'B', displayName: 'B', objectName: 'Ball'),
    BubbleLetter(letter: 'C', displayName: 'C', objectName: 'Cat'),
    BubbleLetter(letter: 'D', displayName: 'D', objectName: 'Dog'),
    BubbleLetter(letter: 'E', displayName: 'E', objectName: 'Elephant'),
    BubbleLetter(letter: 'F', displayName: 'F', objectName: 'Fish'),
    BubbleLetter(letter: 'G', displayName: 'G', objectName: 'Goat'),
    BubbleLetter(letter: 'H', displayName: 'H', objectName: 'Hat'),
    BubbleLetter(letter: 'I', displayName: 'I', objectName: 'Ice cream'),
    BubbleLetter(letter: 'J', displayName: 'J', objectName: 'Jug'),
    BubbleLetter(letter: 'K', displayName: 'K', objectName: 'Kite'),
    BubbleLetter(letter: 'L', displayName: 'L', objectName: 'Lion'),
    BubbleLetter(letter: 'M', displayName: 'M', objectName: 'Monkey'),
    BubbleLetter(letter: 'N', displayName: 'N', objectName: 'Nest'),
    BubbleLetter(letter: 'O', displayName: 'O', objectName: 'Orange'),
    BubbleLetter(letter: 'P', displayName: 'P', objectName: 'Penguin'),
    BubbleLetter(letter: 'Q', displayName: 'Q', objectName: 'Queen'),
    BubbleLetter(letter: 'R', displayName: 'R', objectName: 'Rabbit'),
    BubbleLetter(letter: 'S', displayName: 'S', objectName: 'Sun'),
    BubbleLetter(letter: 'T', displayName: 'T', objectName: 'Tiger'),
    BubbleLetter(letter: 'U', displayName: 'U', objectName: 'Umbrella'),
    BubbleLetter(letter: 'V', displayName: 'V', objectName: 'Violin'),
    BubbleLetter(letter: 'W', displayName: 'W', objectName: 'Watch'),
    BubbleLetter(letter: 'X', displayName: 'X', objectName: 'Xylophone'),
    BubbleLetter(letter: 'Y', displayName: 'Y', objectName: 'Yak'),
    BubbleLetter(letter: 'Z', displayName: 'Z', objectName: 'Zebra'),
  ];

  static List<BubbleLetter> get hindiLetters => const [
    BubbleLetter(letter: 'अ', displayName: 'अ', objectName: 'अनार', module: ModuleType.hindi, isVowel: true),
    BubbleLetter(letter: 'आ', displayName: 'आ', objectName: 'आम', module: ModuleType.hindi, isVowel: true),
    BubbleLetter(letter: 'इ', displayName: 'इ', objectName: 'इमली', module: ModuleType.hindi, isVowel: true),
    BubbleLetter(letter: 'ई', displayName: 'ई', objectName: 'ईख', module: ModuleType.hindi, isVowel: true),
    BubbleLetter(letter: 'उ', displayName: 'उ', objectName: 'उल्लू', module: ModuleType.hindi, isVowel: true),
    BubbleLetter(letter: 'ऊ', displayName: 'ऊ', objectName: 'ऊंट', module: ModuleType.hindi, isVowel: true),
    BubbleLetter(letter: 'ए', displayName: 'ए', objectName: 'एक', module: ModuleType.hindi, isVowel: true),
    BubbleLetter(letter: 'ऐ', displayName: 'ऐ', objectName: 'ऐनक', module: ModuleType.hindi, isVowel: true),
    BubbleLetter(letter: 'ओ', displayName: 'ओ', objectName: 'ओखली', module: ModuleType.hindi, isVowel: true),
    BubbleLetter(letter: 'औ', displayName: 'औ', objectName: 'औरत', module: ModuleType.hindi, isVowel: true),
    BubbleLetter(letter: 'क', displayName: 'क', objectName: 'कबूतर', module: ModuleType.hindi),
    BubbleLetter(letter: 'ख', displayName: 'ख', objectName: 'खरगोश', module: ModuleType.hindi),
    BubbleLetter(letter: 'ग', displayName: 'ग', objectName: 'गाय', module: ModuleType.hindi),
    BubbleLetter(letter: 'घ', displayName: 'घ', objectName: 'घर', module: ModuleType.hindi),
    BubbleLetter(letter: 'ङ', displayName: 'ङ', objectName: 'डंका', module: ModuleType.hindi),
    BubbleLetter(letter: 'च', displayName: 'च', objectName: 'चूहा', module: ModuleType.hindi),
    BubbleLetter(letter: 'छ', displayName: 'छ', objectName: 'छाता', module: ModuleType.hindi),
    BubbleLetter(letter: 'ज', displayName: 'ज', objectName: 'जहाज', module: ModuleType.hindi),
    BubbleLetter(letter: 'झ', displayName: 'झ', objectName: 'झंडा', module: ModuleType.hindi),
    BubbleLetter(letter: 'ञ', displayName: 'ञ', objectName: 'ज्ञान', module: ModuleType.hindi),
    BubbleLetter(letter: 'ट', displayName: 'ट', objectName: 'टमाटर', module: ModuleType.hindi),
    BubbleLetter(letter: 'ठ', displayName: 'ठ', objectName: 'ठंडा', module: ModuleType.hindi),
    BubbleLetter(letter: 'ड', displayName: 'ड', objectName: 'डाकिया', module: ModuleType.hindi),
    BubbleLetter(letter: 'ढ', displayName: 'ढ', objectName: 'ढोल', module: ModuleType.hindi),
    BubbleLetter(letter: 'ण', displayName: 'ण', objectName: 'करण', module: ModuleType.hindi),
    BubbleLetter(letter: 'त', displayName: 'त', objectName: 'तारा', module: ModuleType.hindi),
    BubbleLetter(letter: 'थ', displayName: 'थ', objectName: 'थर्मस', module: ModuleType.hindi),
    BubbleLetter(letter: 'द', displayName: 'द', objectName: 'दवात', module: ModuleType.hindi),
    BubbleLetter(letter: 'ध', displayName: 'ध', objectName: 'धनुष', module: ModuleType.hindi),
    BubbleLetter(letter: 'न', displayName: 'न', objectName: 'नल', module: ModuleType.hindi),
    BubbleLetter(letter: 'प', displayName: 'प', objectName: 'पंखा', module: ModuleType.hindi),
    BubbleLetter(letter: 'फ', displayName: 'फ', objectName: 'फूल', module: ModuleType.hindi),
    BubbleLetter(letter: 'ब', displayName: 'ब', objectName: 'बंदर', module: ModuleType.hindi),
    BubbleLetter(letter: 'भ', displayName: 'भ', objectName: 'भालू', module: ModuleType.hindi),
    BubbleLetter(letter: 'म', displayName: 'म', objectName: 'मछली', module: ModuleType.hindi),
    BubbleLetter(letter: 'य', displayName: 'य', objectName: 'यज्ञ', module: ModuleType.hindi),
    BubbleLetter(letter: 'र', displayName: 'र', objectName: 'रथ', module: ModuleType.hindi),
    BubbleLetter(letter: 'ल', displayName: 'ल', objectName: 'लट्टू', module: ModuleType.hindi),
    BubbleLetter(letter: 'व', displayName: 'व', objectName: 'वटवृक्ष', module: ModuleType.hindi),
    BubbleLetter(letter: 'श', displayName: 'श', objectName: 'शेर', module: ModuleType.hindi),
    BubbleLetter(letter: 'ष', displayName: 'ष', objectName: 'षटकोण', module: ModuleType.hindi),
    BubbleLetter(letter: 'स', displayName: 'स', objectName: 'सूरज', module: ModuleType.hindi),
    BubbleLetter(letter: 'ह', displayName: 'ह', objectName: 'हाथी', module: ModuleType.hindi),
  ];
}
