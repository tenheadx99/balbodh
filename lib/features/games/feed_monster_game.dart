import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/audio/audio_service.dart';
import '../../core/audio/sound_effect_service.dart';
import '../../models/bubble_letter.dart';

class FeedMonsterGame extends StatefulWidget {
  const FeedMonsterGame({super.key});

  @override
  State<FeedMonsterGame> createState() => _FeedMonsterGameState();
}

class _FeedMonsterGameState extends State<FeedMonsterGame> {
  final AudioService _audio = AudioService();
  final SoundEffectService _sfx = SoundEffectService();

  int _stars = 0;
  int _streak = 0;
  int _level = 1;
  int _fed = 0;
  String _targetLetter = 'A';
  String _targetObject = 'Apple';

  final List<_FoodOption> _options = [];
  int _nextId = 0;
  bool _waiting = false;

  final List<BubbleLetter> _pool = [];
  int _poolIndex = 0;

  @override
  void initState() {
    super.initState();
    _pool.addAll(BubbleLetter.abcLetters);
    _pool.shuffle();
    _nextRound();
  }

  void _nextRound() {
    if (_poolIndex >= _pool.length) {
      _pool.shuffle();
      _poolIndex = 0;
    }

    final target = _pool[_poolIndex];
    _poolIndex++;
    _targetLetter = target.letter;
    _targetObject = target.objectName;
    _waiting = false;

    _options.clear();
    _options.add(_FoodOption(
      id: _nextId++,
      letter: target.letter,
      emoji: _letterEmoji(target.letter),
      isCorrect: true,
    ));

    final distractorCount = min(2 + _level, 4);
    final distractors = _pool
        .where((l) => l.letter != target.letter)
        .toList();
    distractors.shuffle();

    for (int i = 0; i < distractorCount && i < distractors.length; i++) {
      _options.add(_FoodOption(
        id: _nextId++,
        letter: distractors[i].letter,
        emoji: _letterEmoji(distractors[i].letter),
        isCorrect: false,
      ));
    }

    _options.shuffle();

    _audio.speakEnglish('Feed me $_targetLetter for $_targetObject!');
    setState(() {});
  }

  String _letterEmoji(String letter) {
    final map = {
      'A': '🍎', 'B': '⚽', 'C': '🐱', 'D': '🐶', 'E': '🐘',
      'F': '🐟', 'G': '🐐', 'H': '🎩', 'I': '🍦', 'J': '🏺',
      'K': '🪁', 'L': '🦁', 'M': '🐵', 'N': '🪺', 'O': '🍊',
      'P': '🐧', 'Q': '👑', 'R': '🐰', 'S': '☀️', 'T': '🐯',
      'U': '☂️', 'V': '🎻', 'W': '⌚', 'X': '🎵', 'Y': '🐃',
      'Z': '🦓',
    };
    return map[letter] ?? '🍎';
  }

  void _feedMonster(int id) {
    if (_waiting) return;

    final option = _options.firstWhere((o) => o.id == id);
    _waiting = true;

    if (option.isCorrect) {
      _fed++;
      _streak++;
      _stars++;
      _sfx.playCorrect();

      if (_streak >= 3) {
        _stars++;
        _audio.speakEnglish('Yum! $_targetLetter! Amazing!');
      } else {
        _audio.speakEnglish('Yum! $_targetLetter!');
      }

      setState(() {
        option.caught = true;
      });

      Future.delayed(const Duration(milliseconds: 800), () {
        if (!mounted) return;
        if (_fed >= 5) {
          _fed = 0;
          _level++;
          _audio.speakEnglish('Level $_level!');
        }
        _nextRound();
      });
    } else {
      _streak = 0;
      _sfx.playWrong();
      _audio.playTryAgain();
      setState(() {
        option.wrong = true;
      });
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() => option.wrong = false);
          _waiting = false;
        }
      });
    }
  }

  @override
  void dispose() {
    _audio.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFC8E6C9), Color(0xFFE8F5E9)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(),
              _buildMonsterArea(),
              _buildQuestion(),
              Expanded(child: _buildFoodOptions()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back,
                size: 28, color: AppColors.textDark),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const Spacer(),
          _badge('⭐ $_stars'),
          const SizedBox(width: 6),
          if (_streak >= 2) _badge('🔥 $_streak'),
          const SizedBox(width: 6),
          _badge('Lv $_level'),
        ],
      ),
    );
  }

  Widget _badge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(text,
          style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark)),
    );
  }

  Widget _buildMonsterArea() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.95, end: 1.05),
            duration: const Duration(milliseconds: 1000),
            builder: (context, value, child) {
              return Transform.scale(scale: value, child: child);
            },
            child: const Text('👾', style: TextStyle(fontSize: 80)),
          ),
          const Text(
            'Feed me!',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestion() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$_targetLetter  ',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: AppColors.primary,
            ),
          ),
          Text(
            '= $_targetObject',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFoodOptions() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: GridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.2,
        children: _options.map((opt) {
          Color bg = Colors.white;
          if (opt.caught) bg = AppColors.success;
          if (opt.wrong) bg = AppColors.primary;

          return GestureDetector(
            onTap: () => _feedMonster(opt.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(20),
                border: opt.caught
                    ? Border.all(color: Colors.green, width: 3)
                    : opt.wrong
                        ? Border.all(color: Colors.red, width: 3)
                        : null,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: 6,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    opt.emoji,
                    style: TextStyle(
                      fontSize: opt.caught ? 32 : 40,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    opt.letter,
                    style: TextStyle(
                      fontSize: opt.caught ? 18 : 24,
                      fontWeight: FontWeight.w800,
                      color: opt.caught
                          ? Colors.green
                          : AppColors.textDark,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _FoodOption {
  final int id;
  final String letter;
  final String emoji;
  final bool isCorrect;
  bool caught;
  bool wrong;

  _FoodOption({
    required this.id,
    required this.letter,
    required this.emoji,
    required this.isCorrect,
    this.caught = false,
    this.wrong = false,
  });
}
