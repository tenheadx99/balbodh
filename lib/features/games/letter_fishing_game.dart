import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/audio/audio_service.dart';
import '../../core/audio/sound_effect_service.dart';

class LetterFishingGame extends StatefulWidget {
  const LetterFishingGame({super.key});

  @override
  State<LetterFishingGame> createState() => _LetterFishingGameState();
}

class _LetterFishingGameState extends State<LetterFishingGame> {
  final AudioService _audio = AudioService();
  final SoundEffectService _sfx = SoundEffectService();
  final Random _random = Random();

  final List<_Fish> _fish = [];
  int _nextId = 0;
  int _stars = 0;
  int _level = 1;
  int _caught = 0;
  String _target = 'A';

  Timer? _swimTimer;

  static const _letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  int _letterIdx = 0;

  @override
  void initState() {
    super.initState();
    _spawnFish();
    _nextTarget();
    _swimTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (!mounted) return;
      setState(() {
        for (final f in _fish) {
          f.x += f.dir * f.speed;
          if (f.x < 10 || f.x > 320) f.dir *= -1;
          f.y += sin(f.x * 0.05) * 0.3;
        }
      });
    });
  }

  void _spawnFish() {
    _fish.clear();
    final letters = [_target];
    for (int i = 0; i < 5; i++) {
      String l;
      do { l = _letters[_random.nextInt(26)]; } while (letters.contains(l));
      letters.add(l);
    }
    letters.shuffle();
    for (final l in letters) {
      _fish.add(_Fish(
        id: _nextId++, letter: l,
        x: 20 + _random.nextDouble() * 280,
        y: 50 + _random.nextDouble() * 350,
        speed: 0.4 + _random.nextDouble() * 0.6,
        dir: _random.nextBool() ? 1 : -1,
      ));
    }
  }

  void _nextTarget() {
    _target = _letters[_letterIdx % 26];
    _audio.speakEnglish('Catch $_target');
    setState(() {});
  }

  void _tapFish(int id) {
    final f = _fish.firstWhere((x) => x.id == id);
    if (f.letter == _target) {
      _caught++;
      _stars++;
      _sfx.playCorrect();
      _audio.speakEnglish(_target);
      _letterIdx++;
      if (_letterIdx % 5 == 0) { _level++; _audio.speakEnglish('Level $_level!'); }
      if (_letterIdx >= 26) { _sfx.playFanfare(); _audio.speakEnglish('All letters!'); setState(() {}); return; }
      _fish.removeWhere((x) => x.id == id);
      _addRandomFish();
      _nextTarget();
    } else {
      _sfx.playWrong();
      _audio.playTryAgain();
    }
  }

  void _addRandomFish() {
    String l;
    do { l = _letters[_random.nextInt(26)]; } while (l == _target && _fish.any((f) => f.letter == _target));
    _fish.add(_Fish(
      id: _nextId++, letter: l,
      x: _random.nextDouble() * 280 + 20, y: _random.nextDouble() * 350 + 50,
      speed: 0.4 + _random.nextDouble() * 0.6,
      dir: _random.nextBool() ? 1 : -1,
    ));
  }

  @override
  void dispose() { _swimTimer?.cancel(); _audio.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final done = _letterIdx >= 26;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF81D4FA), Color(0xFFB3E5FC)]),
        ),
        child: SafeArea(child: done ? _buildWin() : Column(children: [
          _buildTopBar(),
          _buildTarget(),
          Expanded(child: _buildPond()),
        ])),
      ),
    );
  }

  Widget _buildTopBar() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    child: Row(children: [
      IconButton(icon: const Icon(Icons.arrow_back, size: 28, color: AppColors.textDark), onPressed: () => Navigator.pop(context)),
      const Spacer(), _badge('⭐ $_stars'), const SizedBox(width: 6), _badge('Lv $_level'), const SizedBox(width: 6),
      _badge('🎣 ${26 - _letterIdx}'),
    ]),
  );

  Widget _badge(String t) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.85), borderRadius: BorderRadius.circular(16)),
    child: Text(t, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textDark)),
  );

  Widget _buildTarget() => Center(child: Padding(
    padding: const EdgeInsets.all(8),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(16)),
      child: Text('🎯 Catch: $_target', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.textDark)),
    ),
  ));

  Widget _buildPond() => ClipRRect(
    borderRadius: BorderRadius.circular(20),
    child: Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue.shade200, width: 2),
      ),
      child: Stack(children: _fish.map((f) => Positioned(
        left: f.x, top: f.y,
        child: GestureDetector(
          onTap: () => _tapFish(f.id),
          child: Container(
            padding: const EdgeInsets.all(8),
            child: Text(f.letter, style: TextStyle(
              fontSize: 28, fontWeight: FontWeight.w900,
              color: f.letter == _target ? AppColors.primary : AppColors.textDark.withValues(alpha: 0.5),
            )),
          ),
        ),
      )).toList()),
    ),
  );

  Widget _buildWin() => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    const Text('🎣', style: TextStyle(fontSize: 72)),
    const SizedBox(height: 16),
    const Text('All Letters Caught!', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.textDark)),
    Text('⭐ $_stars stars  •  Lv $_level', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textDark)),
    const SizedBox(height: 24),
    ElevatedButton.icon(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.home), label: const Text('Home'),
      style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary, padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14))),
  ]));
}

class _Fish {
  final int id; final String letter; double x; double y; final double speed; double dir;
  _Fish({required this.id, required this.letter, required this.x, required this.y, required this.speed, required this.dir});
}
