import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/audio/audio_service.dart';
import '../../core/audio/sound_effect_service.dart';
import '../../games/reward_overlay.dart';
import '../../services/progress_service.dart';

class PatternPuzzleGame extends StatefulWidget {
  const PatternPuzzleGame({super.key});

  @override
  State<PatternPuzzleGame> createState() => _PatternPuzzleGameState();
}

class _PatternPuzzleGameState extends State<PatternPuzzleGame> {
  final AudioService _audio = AudioService();
  final SoundEffectService _sfx = SoundEffectService();
  final ProgressService _progress = ProgressService();
  final Random _random = Random();

  static const _emojis = ['🔴', '🔵', '🟡', '🟢', '🟠', '🟣', '⬛', '⬜'];
  static const _letters = ['A', 'B', 'C', 'D'];

  int _stars = 0;
  int _level = 1;
  int _done = 0;
  List<String> _pattern = [];
  String _correctAnswer = '';
  List<String> _choices = [];

  @override
  void initState() {
    super.initState();
    _newPattern();
  }

  void _newPattern() {
    final useEmoji = _random.nextBool();
    // Shuffle so patterns vary instead of always using the pool's
    // first symbols.
    final pool = List.of(useEmoji ? _emojis : _letters)..shuffle(_random);

    final patternType = _random.nextInt(3);
    switch (patternType) {
      case 0: // ABAB
        _pattern = [pool[0], pool[1], pool[0], pool[1]];
        _correctAnswer = pool[0];
        break;
      case 1: // AABB
        _pattern = [pool[0], pool[0], pool[1], pool[1]];
        _correctAnswer = pool[0];
        break;
      case 2: // ABCABC
        _pattern = [pool[0], pool[1], pool[2], pool[0], pool[1]];
        _correctAnswer = pool[2];
        break;
    }

    _choices = [_correctAnswer];
    for (int i = 0; i < 3; i++) {
      String c;
      do { c = pool[_random.nextInt(pool.length)]; } while (_choices.contains(c));
      _choices.add(c);
    }
    _choices.shuffle();

    _audio.speakEnglish('What comes next?');
    setState(() {});
  }

  void _pickChoice(String c) {
    if (c == _correctAnswer) {
      _done++;
      _stars++;
      _progress.addStar('games');
      _sfx.playCorrect();
      _audio.speakEnglish('Correct! Pattern complete!');
      if (_done % 5 == 0) {
        _level++;
        _audio.speakEnglish('Level $_level!');
        showRewardOverlay(context, message: 'Level $_level!');
      }
      _newPattern();
    } else {
      _sfx.playWrong();
      _audio.playTryAgain();
    }
  }

  @override
  void dispose() { _audio.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFB39DDB), Color(0xFFD1C4E9)]),
      ),
      child: SafeArea(child: Column(children: [
        _buildTopBar(),
        const SizedBox(height: 20),
        const Text('What comes next?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textDark)),
        const SizedBox(height: 16),
        _buildPattern(),
        const SizedBox(height: 32),
        _buildChoices(),
      ])),
    ),
  );

  Widget _buildTopBar() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    child: Row(children: [
      IconButton(icon: const Icon(Icons.arrow_back, size: 28, color: AppColors.textDark), onPressed: () => Navigator.pop(context)),
      const Spacer(), _badge('⭐ $_stars'), const SizedBox(width: 6), _badge('Lv $_level'),
    ]),
  );

  Widget _badge(String t) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.85), borderRadius: BorderRadius.circular(16)),
    child: Text(t, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textDark)),
  );

  Widget _buildPattern() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 24),
    child: Column(children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          ..._pattern.map((e) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(e, style: const TextStyle(fontSize: 36)),
          )),
          Container(
            width: 50, height: 50, margin: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.warning, width: 2),
            ),
            child: const Center(child: Text('?', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.orange))),
          ),
        ],
      ),
    ]),
  );

  Widget _buildChoices() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 32),
    child: Wrap(
      spacing: 16, runSpacing: 16, alignment: WrapAlignment.center,
      children: _choices.map((c) => GestureDetector(
        onTap: () => _pickChoice(c),
        child: Container(
          width: 70, height: 70,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 6, offset: const Offset(0, 4))]),
          child: Center(child: Text(c, style: const TextStyle(fontSize: 32))),
        ),
      )).toList(),
    ),
  );
}
