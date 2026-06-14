import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/audio/audio_service.dart';
import '../../core/audio/sound_effect_service.dart';
import '../../games/reward_overlay.dart';
import '../../services/progress_service.dart';

class WordWormGame extends StatefulWidget {
  const WordWormGame({super.key});

  @override
  State<WordWormGame> createState() => _WordWormGameState();
}

class _WordWormGameState extends State<WordWormGame> {
  final AudioService _audio = AudioService();
  final SoundEffectService _sfx = SoundEffectService();
  final ProgressService _progress = ProgressService();
  final Random _random = Random();

  static const _words = [
    ('CAT', 'C', '🐱'), ('DOG', 'D', '🐶'), ('SUN', 'S', '☀️'), ('BIG', 'B', '🐘'),
    ('HAT', 'H', '🎩'), ('JAM', 'J', '🍓'), ('KIT', 'K', '🪁'), ('LIP', 'L', '👄'),
    ('MOP', 'M', '🧹'), ('NET', 'N', '🪺'), ('PAN', 'P', '🍳'), ('RUG', 'R', '🟫'),
    ('TOP', 'T', '🎯'), ('VAN', 'V', '🚐'), ('WIG', 'W', '💇'), ('YAK', 'Y', '🐃'),
    ('ZIP', 'Z', '🤐'), ('CUP', 'C', '☕'), ('BED', 'B', '🛏️'), ('FAN', 'F', '🪭'),
  ];

  String _word = ''; String _missing = ''; String _emoji = '';
  int _missingIndex = 0;
  int _stars = 0;
  int _level = 1;
  int _done = 0;

  @override
  void initState() {
    super.initState();
    _nextWord();
  }

  void _nextWord() {
    final w = _words[_random.nextInt(_words.length)];
    _word = w.$1; _emoji = w.$3;
    _missingIndex = _random.nextInt(3);
    _missing = w.$1[_missingIndex];
    _audio.speakEnglish('${w.$1}: fill the missing letter');
    setState(() {});
  }

  List<String> _options() {
    final opts = <String>{_missing};
    final pool = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.replaceAll(_missing, '');
    for (int i = 0; i < 3; i++) {
      opts.add(pool[_random.nextInt(pool.length)]);
    }
    return opts.toList()..shuffle();
  }

  void _pickLetter(String l) {
    if (l == _missing) {
      _done++;
      _stars++;
      _progress.addStar('games');
      _sfx.playCorrect();
      _audio.speakEnglish(_word);
      if (_done % 5 == 0) {
        _level++;
        _audio.speakEnglish('Level $_level!');
        showRewardOverlay(context, message: 'Level $_level!');
      }
      _nextWord();
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
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFA5D6A7), Color(0xFFE8F5E9)]),
      ),
      child: SafeArea(child: Column(children: [
        _buildTopBar(),
        const Spacer(),
        _buildWorm(),
        const SizedBox(height: 24),
        _buildWord(),
        const Spacer(),
        _buildOptions(),
        const SizedBox(height: 32),
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

  Widget _buildWorm() => Column(children: [
    const Text('🐛', style: TextStyle(fontSize: 56)),
    Text('$_emoji  $_word', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textDark)),
  ]);

  Widget _buildWord() {
    final chars = _word.split('');
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        final show = i != _missingIndex;
        return Container(
          width: 64, height: 72, margin: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: show ? Colors.white : AppColors.warning.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(12),
            border: show ? null : Border.all(color: AppColors.warning, width: 2),
            boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 4, offset: const Offset(0, 3))],
          ),
          child: Center(child: Text(
            show ? chars[i] : '?',
            style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: show ? AppColors.textDark : AppColors.orange),
          )),
        );
      }),
    );
  }

  Widget _buildOptions() {
    final opts = _options();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Wrap(
        spacing: 16, runSpacing: 16, alignment: WrapAlignment.center,
        children: opts.map((l) => GestureDetector(
          onTap: () => _pickLetter(l),
          child: Container(
            width: 60, height: 60,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 6, offset: const Offset(0, 4))]),
            child: Center(child: Text(l, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.textDark))),
          ),
        )).toList(),
      ),
    );
  }
}
