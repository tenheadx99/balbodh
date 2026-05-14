import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/audio/audio_service.dart';
import '../../core/audio/sound_effect_service.dart';

class BalloonPopGame extends StatefulWidget {
  const BalloonPopGame({super.key});

  @override
  State<BalloonPopGame> createState() => _BalloonPopGameState();
}

class _BalloonPopGameState extends State<BalloonPopGame>
    with TickerProviderStateMixin {
  final AudioService _audio = AudioService();
  final SoundEffectService _sfx = SoundEffectService();
  final Random _random = Random();

  final List<_Balloon> _balloons = [];
  int _nextId = 0;

  final List<String> _letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.split('');
  int _currentIndex = 0;
  int _stars = 0;
  int _level = 1;

  Timer? _floatTimer;
  Timer? _spawnTimer;
  double _areaW = 400;
  double _areaH = 600;

  @override
  void initState() {
    super.initState();
    _audio.speakEnglish('Pop the balloons A to Z!');
    WidgetsBinding.instance.addPostFrameCallback((_) => _startGame());
  }

  void _startGame() {
    _spawnBalloons();
    _spawnTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted) _spawnBalloons();
    });
    _floatTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (!mounted) return;
      setState(() {
        for (final b in _balloons) {
          b.y -= 0.8 + _level * 0.05;
          b.x += sin(b.y * 0.03 + b.phase) * 0.5;
        }
        _balloons.removeWhere((b) => b.y < -60);
      });
    });
  }

  void _spawnBalloons() {
    if (_currentIndex >= _letters.length) return;
    final count = 2 + _random.nextInt(3);
    for (int i = 0; i < count && _balloons.length < 10; i++) {
      final isTarget = _balloons.every((b) => !b.isTarget);
      _balloons.add(_Balloon(
        id: _nextId++,
        letter: isTarget ? _letters[_currentIndex] : _letters[_random.nextInt(_letters.length)],
        x: 30 + _random.nextDouble() * (_areaW - 80),
        y: _areaH + 20 + _random.nextDouble() * 100,
        phase: _random.nextDouble() * 6,
        isTarget: isTarget,
      ));
    }
  }

  void _popBalloon(int id) {
    final idx = _balloons.indexWhere((b) => b.id == id);
    if (idx == -1) return;

    final balloon = _balloons[idx];
    if (balloon.isTarget) {
      _balloons.removeAt(idx);
      _stars++;
      _sfx.playCorrect();
      _audio.speakEnglish(_letters[_currentIndex]);
      _currentIndex++;
      if (_currentIndex >= _letters.length) {
        _sfx.playFanfare();
        _audio.speakEnglish('You did it! A to Z!');
        setState(() {});
        return;
      }
      if (_currentIndex % 5 == 0) {
        _level++;
        _audio.speakEnglish('Level $_level!');
      }
      _audio.speakEnglish('Pop ${_letters[_currentIndex]}');
      _balloons.removeWhere((b) => b.isTarget);
      _spawnBalloons();
    } else {
      _sfx.playWrong();
      setState(() {});
    }
  }

  @override
  void dispose() {
    _floatTimer?.cancel();
    _spawnTimer?.cancel();
    _audio.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final done = _currentIndex >= _letters.length;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFF176), Color(0xFFFFF9C4)],
          ),
        ),
        child: SafeArea(
          child: done ? _buildWin() : Column(children: [
            _buildTopBar(),
            _buildTarget(),
            Expanded(child: _buildArea()),
          ]),
        ),
      ),
    );
  }

  Widget _buildTopBar() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    child: Row(children: [
      IconButton(icon: const Icon(Icons.arrow_back, size: 28, color: AppColors.textDark), onPressed: () => Navigator.pop(context)),
      const Spacer(),
      _badge('⭐ $_stars'), const SizedBox(width: 6),
      _badge('Lv $_level'), const SizedBox(width: 6),
      _badge('🎈 ${26 - _currentIndex}'),
    ]),
  );

  Widget _badge(String t) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.85), borderRadius: BorderRadius.circular(16)),
    child: Text(t, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textDark)),
  );

  Widget _buildTarget() => Center(child: Text(
    'Pop ${_letters[_currentIndex]}',
    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.textDark),
  ));

  Widget _buildArea() => LayoutBuilder(builder: (c, s) {
    _areaW = s.maxWidth; _areaH = s.maxHeight;
    return Stack(children: _balloons.map((b) => Positioned(
      left: b.x, top: b.y,
      child: GestureDetector(
        onTap: () => _popBalloon(b.id),
        child: Container(
          width: 56, height: 68,
          decoration: BoxDecoration(
            color: b.isTarget ? AppColors.primary.withValues(alpha: 0.85) : AppColors.accent.withValues(alpha: 0.6),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28), bottom: Radius.circular(8)),
            boxShadow: [BoxShadow(color: (b.isTarget ? AppColors.primary : AppColors.accent).withValues(alpha: 0.3), blurRadius: 6)],
          ),
          child: Column(children: [
            const SizedBox(height: 8),
            Text(b.letter, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
            const Spacer(),
            Container(width: 2, height: 14, color: Colors.brown.shade300),
          ]),
        ),
      ),
    )).toList());
  });

  Widget _buildWin() => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    const Text('🎈', style: TextStyle(fontSize: 72)),
    const SizedBox(height: 16),
    const Text('A to Z Complete!', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: AppColors.textDark)),
    const SizedBox(height: 8),
    Text('⭐ $_stars stars  •  Lv $_level', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textDark)),
    const SizedBox(height: 24),
    ElevatedButton.icon(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.home), label: const Text('Home'),
      style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary, padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14))),
  ]));
}

class _Balloon {
  final int id; final String letter; double x; double y; final double phase; final bool isTarget;
  _Balloon({required this.id, required this.letter, required this.x, required this.y, required this.phase, required this.isTarget});
}
