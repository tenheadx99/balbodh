enum StickerCategory { abc, hindi, math, bonus }

class Sticker {
  final String id;
  final String emoji;
  final String name;
  final StickerCategory category;
  final int starsRequired;
  final String description;

  const Sticker({
    required this.id,
    required this.emoji,
    required this.name,
    required this.category,
    this.starsRequired = 0,
    this.description = '',
  });

  static List<Sticker> get all => [...abcStickers, ...hindiStickers, ...mathStickers, ...bonusStickers];

  static List<Sticker> get abcStickers => const [
    Sticker(id: 'a1', emoji: '🐶', name: 'Puppy', category: StickerCategory.abc, starsRequired: 1, description: 'Learn A-D'),
    Sticker(id: 'a2', emoji: '🐱', name: 'Kitty', category: StickerCategory.abc, starsRequired: 3, description: 'Learn E-H'),
    Sticker(id: 'a3', emoji: '🦊', name: 'Fox', category: StickerCategory.abc, starsRequired: 5, description: 'Learn I-L'),
    Sticker(id: 'a4', emoji: '🐻', name: 'Bear', category: StickerCategory.abc, starsRequired: 8, description: 'Learn M-P'),
    Sticker(id: 'a5', emoji: '🐼', name: 'Panda', category: StickerCategory.abc, starsRequired: 12, description: 'Learn Q-T'),
    Sticker(id: 'a6', emoji: '🦁', name: 'Lion', category: StickerCategory.abc, starsRequired: 16, description: 'Learn U-X'),
    Sticker(id: 'a7', emoji: '🐯', name: 'Tiger', category: StickerCategory.abc, starsRequired: 20, description: 'Learn Y-Z'),
    Sticker(id: 'a8', emoji: '🦅', name: 'Eagle', category: StickerCategory.abc, starsRequired: 26, description: 'All ABC!'),
  ];

  static List<Sticker> get hindiStickers => const [
    Sticker(id: 'h1', emoji: '🌺', name: 'Phool', category: StickerCategory.hindi, starsRequired: 2, description: 'स्वर 4'),
    Sticker(id: 'h2', emoji: '🌻', name: 'Suraj', category: StickerCategory.hindi, starsRequired: 5, description: 'स्वर 8'),
    Sticker(id: 'h3', emoji: '🌴', name: 'Ped', category: StickerCategory.hindi, starsRequired: 8, description: 'व्यंजन 5'),
    Sticker(id: 'h4', emoji: '🐘', name: 'Hathi', category: StickerCategory.hindi, starsRequired: 12, description: 'व्यंजन 10'),
    Sticker(id: 'h5', emoji: '🦚', name: 'Mor', category: StickerCategory.hindi, starsRequired: 16, description: 'व्यंजन 15'),
    Sticker(id: 'h6', emoji: '🐅', name: 'Sher', category: StickerCategory.hindi, starsRequired: 20, description: 'व्यंजन 20'),
    Sticker(id: 'h7', emoji: '🐪', name: 'Oont', category: StickerCategory.hindi, starsRequired: 25, description: 'व्यंजन 30'),
    Sticker(id: 'h8', emoji: '🦜', name: 'Tota', category: StickerCategory.hindi, starsRequired: 35, description: 'All Hindi!'),
  ];

  static List<Sticker> get mathStickers => const [
    Sticker(id: 'm1', emoji: '🌈', name: 'Rainbow', category: StickerCategory.math, starsRequired: 2, description: 'Count 1-5'),
    Sticker(id: 'm2', emoji: '🚀', name: 'Rocket', category: StickerCategory.math, starsRequired: 5, description: 'Count 1-10'),
    Sticker(id: 'm3', emoji: '🎸', name: 'Guitar', category: StickerCategory.math, starsRequired: 8, description: 'Trace 1-5'),
    Sticker(id: 'm4', emoji: '🎨', name: 'Palette', category: StickerCategory.math, starsRequired: 12, description: 'Trace 1-10'),
    Sticker(id: 'm5', emoji: '🏆', name: 'Trophy', category: StickerCategory.math, starsRequired: 16, description: 'Add 1-5'),
    Sticker(id: 'm6', emoji: '🎪', name: 'Circus', category: StickerCategory.math, starsRequired: 20, description: 'Add 1-10'),
    Sticker(id: 'm7', emoji: '🎡', name: 'Ferris', category: StickerCategory.math, starsRequired: 25, description: 'Count 1-20'),
    Sticker(id: 'm8', emoji: '🏅', name: 'Medal', category: StickerCategory.math, starsRequired: 30, description: 'All Math!'),
  ];

  static List<Sticker> get bonusStickers => const [
    Sticker(id: 'b1', emoji: '👑', name: 'Crown', category: StickerCategory.bonus, starsRequired: 10, description: '10 total stars'),
    Sticker(id: 'b2', emoji: '💎', name: 'Diamond', category: StickerCategory.bonus, starsRequired: 25, description: '25 total stars'),
    Sticker(id: 'b3', emoji: '🌟', name: 'Superstar', category: StickerCategory.bonus, starsRequired: 50, description: '50 total stars'),
    Sticker(id: 'b4', emoji: '🏰', name: 'Castle', category: StickerCategory.bonus, starsRequired: 75, description: '75 total stars'),
    Sticker(id: 'b5', emoji: '🌌', name: 'Galaxy', category: StickerCategory.bonus, starsRequired: 100, description: '100 total stars!'),
  ];
}
