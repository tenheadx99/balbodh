import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/audio/audio_service.dart';
import '../../core/audio/sound_effect_service.dart';
import '../../games/reward_overlay.dart';
import '../../services/progress_service.dart';

class SortingFactoryGame extends StatefulWidget {
  const SortingFactoryGame({super.key});

  @override
  State<SortingFactoryGame> createState() => _SortingFactoryGameState();
}

class _SortingFactoryGameState extends State<SortingFactoryGame> {
  final AudioService _audio = AudioService();
  final SoundEffectService _sfx = SoundEffectService();
  final ProgressService _progress = ProgressService();
  final Random _random = Random();

  static const _items = [
    ('🍎', 'A'), ('⚽', 'B'), ('🐱', 'C'), ('🐶', 'D'), ('🐘', 'E'),
    ('🐟', 'F'), ('🍇', 'G'), ('🎩', 'H'), ('🍦', 'I'), ('🏺', 'J'),
    ('🪁', 'K'), ('🦁', 'L'), ('🐵', 'M'), ('🪺', 'N'), ('🍊', 'O'),
    ('🐧', 'P'), ('👑', 'Q'), ('🐰', 'R'), ('☀️', 'S'), ('🐯', 'T'),
    ('☂️', 'U'), ('🎻', 'V'), ('⌚', 'W'), ('🎵', 'X'), ('🐃', 'Y'), ('🦓', 'Z'),
  ];

  final List<_SortItem> _queue = [];
  _SortItem? _current;
  List<String> _bins = [];
  int _stars = 0;
  int _level = 1;
  int _sorted = 0;


  @override
  void initState() {
    super.initState();
    _nextItem();
  }

  void _nextItem() {
    _queue.clear();
    final shuffled = List.of(_items)..shuffle(_random);
    final target = shuffled[0];
    _current = _SortItem(emoji: target.$1, letter: target.$2);
    _bins = _pickBins(target.$2);
    _audio.speakEnglish('Sort ${target.$2} for ${target.$1}!');
    setState(() {});
  }

  // Bins are fixed per item so a wrong tap doesn't reshuffle them.
  List<String> _pickBins(String targetLetter) {
    final letters = <String>[targetLetter];
    final pool = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.replaceAll(targetLetter, '');
    while (letters.length < 3) {
      final l = pool[_random.nextInt(pool.length)];
      if (!letters.contains(l)) letters.add(l);
    }
    return letters..shuffle(_random);
  }

  void _dropOnBin(String binLetter) {
    if (_current == null) return;
    if (binLetter == _current!.letter) {
      _sorted++;
      _stars++;
      _progress.addStar('games');
      _sfx.playCorrect();
      _audio.speakEnglish('Correct! ${_current!.letter}!');
      if (_sorted % 5 == 0) {
        _level++;
        _audio.speakEnglish('Level $_level!');
        showRewardOverlay(context, message: 'Level $_level!');
      }
      _nextItem();
    } else {
      _sfx.playWrong();
      _audio.playTryAgain();
      setState(() {});
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
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [Color(0xFFFFCC80), Color(0xFFFFF3E0)],
          ),
        ),
        child: SafeArea(child: Column(children: [
          _buildTopBar(),
          Expanded(child: _buildConveyor()),
          _buildBins(),
        ])),
      ),
    );
  }

  Widget _buildTopBar() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    child: Row(children: [
      IconButton(icon: const Icon(Icons.arrow_back, size: 28, color: AppColors.textDark), onPressed: () => Navigator.pop(context)),
      const Spacer(),
      _badge('⭐ $_stars'), const SizedBox(width: 6), _badge('Lv $_level'),
    ]),
  );

  Widget _badge(String t) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.85), borderRadius: BorderRadius.circular(16)),
    child: Text(t, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textDark)),
  );

  Widget _buildConveyor() {
    if (_current == null) return const SizedBox.shrink();
    return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Text('🏭', style: TextStyle(fontSize: 48)),
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 6, offset: const Offset(0, 4))]),
        child: Column(children: [
          Text(_current!.emoji, style: const TextStyle(fontSize: 64)),
          const SizedBox(height: 8),
          const Text('Tap the right bin!', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textDark)),
        ]),
      ),
      const SizedBox(height: 12),
      Text('Starts with: ${_current!.letter}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark)),
    ]));
  }

  Widget _buildBins() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: _bins.map((l) => GestureDetector(
          onTap: () => _dropOnBin(l),
          child: Container(
            width: 90, height: 100,
            decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.secondary.withValues(alpha: 0.5), width: 2),
              boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 4, offset: const Offset(0, 3))],
            ),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('📦', style: TextStyle(fontSize: 28)),
              Text(l, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.textDark)),
              Text('bin', style: TextStyle(fontSize: 11, color: AppColors.textDark.withValues(alpha: 0.5))),
            ]),
          ),
        )).toList(),
      ),
    );
  }
}

class _SortItem {
  final String emoji; final String letter;
  _SortItem({required this.emoji, required this.letter});
}
