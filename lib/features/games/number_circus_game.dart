import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/audio/audio_service.dart';
import '../../core/audio/sound_effect_service.dart';
import '../../games/reward_overlay.dart';
import '../../services/progress_service.dart';

class NumberCircusGame extends StatefulWidget {
  const NumberCircusGame({super.key});

  @override
  State<NumberCircusGame> createState() => _NumberCircusGameState();
}

class _NumberCircusGameState extends State<NumberCircusGame> {
  final AudioService _audio = AudioService();
  final SoundEffectService _sfx = SoundEffectService();
  final ProgressService _progress = ProgressService();
  final Random _random = Random();
  static const _animals = ['🐒', '🐘', '🦁', '🐯', '🐻', '🦊', '🐰', '🐸'];

  int _targetSum = 5;
  int _stars = 0;
  int _level = 1;
  int _done = 0;
  final List<_CircusNumber> _numbers = [];
  int? _selected;

  @override
  void initState() {
    super.initState();
    _newRound();
  }

  void _newRound() {
    _selected = null;
    _numbers.clear();
    _targetSum = 2 + _random.nextInt(4 + _level);
    final a = 1 + _random.nextInt(_targetSum - 1);
    final b = _targetSum - a;
    final nums = [a, b];
    for (int i = 0; i < 2; i++) {
      final n = 1 + _random.nextInt(9);
      if (n != a && n != b) nums.add(n);
    }
    nums.shuffle();
    for (final n in nums) {
      _numbers.add(_CircusNumber(
        number: n,
        animal: _animals[_random.nextInt(_animals.length)],
      ));
    }
    _audio.speakEnglish('Make $_targetSum!');
    setState(() {});
  }

  void _tapNumber(int idx) {
    if (_selected == idx) {
      _selected = null;
      setState(() {});
      return;
    }
    if (_selected == null) {
      _selected = idx;
      setState(() {});
      return;
    }
    final sum = _numbers[_selected!].number + _numbers[idx].number;
    if (sum == _targetSum) {
      _done++;
      _stars++;
      _progress.addStar('games');
      _sfx.playCorrect();
      _audio.speakEnglish('$_targetSum! Great!');
      if (_done % 5 == 0) {
        _level++;
        _audio.speakEnglish('Level $_level!');
        showRewardOverlay(context, message: 'Level $_level!');
      }
      _newRound();
    } else {
      _sfx.playWrong();
      _audio.playTryAgain();
      _selected = null;
      setState(() {});
    }
  }

  @override
  void dispose() { _audio.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFE57373), Color(0xFFFFCDD2)]),
      ),
      child: SafeArea(child: Column(children: [
        _buildTopBar(),
        _buildRingmaster(),
        _buildTarget(),
        Expanded(child: _buildGrid()),
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

  Widget _buildRingmaster() => const Padding(
    padding: EdgeInsets.only(top: 8),
    child: Text('🎪', style: TextStyle(fontSize: 48)),
  );

  Widget _buildTarget() => Padding(
    padding: const EdgeInsets.all(12),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.8), borderRadius: BorderRadius.circular(20)),
      child: Text('Make  $_targetSum', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: AppColors.textDark)),
    ),
  );

  Widget _buildGrid() => Padding(
    padding: const EdgeInsets.all(16),
    child: GridView.count(
      crossAxisCount: 2, mainAxisSpacing: 16, crossAxisSpacing: 16,
      children: List.generate(_numbers.length, (i) {
        final n = _numbers[i];
        final sel = _selected == i;
        return GestureDetector(
          onTap: () => _tapNumber(i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: sel ? AppColors.success.withValues(alpha: 0.3) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: sel ? Border.all(color: AppColors.success, width: 3) : null,
              boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 6, offset: const Offset(0, 4))],
            ),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(n.animal, style: const TextStyle(fontSize: 40)),
              const SizedBox(height: 4),
              Text('${n.number}', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: AppColors.textDark)),
            ]),
          ),
        );
      }),
    ),
  );
}

class _CircusNumber {
  final int number; final String animal;
  _CircusNumber({required this.number, required this.animal});
}
