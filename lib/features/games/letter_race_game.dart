import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/audio/audio_service.dart';
import '../../core/audio/sound_effect_service.dart';

class LetterRaceGame extends StatefulWidget {
  const LetterRaceGame({super.key});

  @override
  State<LetterRaceGame> createState() => _LetterRaceGameState();
}

class _LetterRaceGameState extends State<LetterRaceGame> {
  final AudioService _audio = AudioService();
  final SoundEffectService _sfx = SoundEffectService();
  final List<String> _letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.split('');
  int _currentIndex = 0;
  int _stars = 0;
  int _level = 1;

  @override
  void initState() {
    super.initState();
    _nextTarget();
  }

  void _nextTarget() {
    if (_currentIndex >= _letters.length) {
      setState(() {});
      return;
    }
    _audio.speakEnglish('Drive to ${_letters[_currentIndex]}');
    setState(() {});
  }

  void _pickLetter(String letter) {
    if (letter == _letters[_currentIndex]) {
      _stars++;
      _sfx.playCorrect();
      _audio.speakEnglish(letter);
      _currentIndex++;
      if (_currentIndex % 5 == 0) {
        _level++;
        _audio.speakEnglish('Level $_level!');
      }
      if (_currentIndex < _letters.length) {
        _nextTarget();
      } else {
        _sfx.playFanfare();
      }
      setState(() {});
    } else {
      _sfx.playWrong();
      _audio.playTryAgain();
    }
  }

  List<String> _options() {
    if (_currentIndex >= _letters.length) return [];
    final target = _letters[_currentIndex];
    final opts = <String>{target};
    final pool = _letters.where((l) => l != target).toList()..shuffle();
    for (int i = 0; i < 3 && i < pool.length; i++) {
      opts.add(pool[i]);
    }
    return opts.toList()..shuffle();
  }

  @override
  void dispose() {
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
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [Color(0xFF81D4FA), Color(0xFFE1F5FE)],
          ),
        ),
        child: SafeArea(child: done ? _buildWin() : Column(children: [
          _buildTopBar(),
          _buildTrack(),
          const Spacer(),
          _buildOptions(),
          const SizedBox(height: 24),
        ])),
      ),
    );
  }

  Widget _buildTopBar() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    child: Row(children: [
      IconButton(icon: const Icon(Icons.arrow_back, size: 28, color: AppColors.textDark), onPressed: () => Navigator.pop(context)),
      const Spacer(),
      _badge('⭐ $_stars'), const SizedBox(width: 6),
      _badge('Lv $_level'),
    ]),
  );

  Widget _badge(String t) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.85), borderRadius: BorderRadius.circular(16)),
    child: Text(t, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textDark)),
  );

  Widget _buildTrack() {
    final progress = _currentIndex / _letters.length;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        const Text('🚗', style: TextStyle(fontSize: 40)),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: LinearProgressIndicator(
            value: progress, minHeight: 16,
            backgroundColor: Colors.white.withValues(alpha: 0.5),
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.secondary),
          ),
        ),
        const SizedBox(height: 8),
        Text('Find: ${_currentIndex < _letters.length ? _letters[_currentIndex] : ""}',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.textDark)),
      ]),
    );
  }

  Widget _buildOptions() {
    final opts = _options();
    if (opts.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Wrap(
        spacing: 16, runSpacing: 16,
        alignment: WrapAlignment.center,
        children: opts.map((l) => GestureDetector(
          onTap: () => _pickLetter(l),
          child: Container(
            width: 70, height: 70,
            decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 6, offset: const Offset(0, 4))],
            ),
            child: Center(child: Text(l, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: AppColors.textDark))),
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildWin() => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    const Text('🏁', style: TextStyle(fontSize: 72)),
    const SizedBox(height: 16),
    const Text('Race Complete!', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: AppColors.textDark)),
    Text('⭐ $_stars stars  •  Lv $_level', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textDark)),
    const SizedBox(height: 24),
    ElevatedButton.icon(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.home), label: const Text('Home'),
      style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary, padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14))),
  ]));
}
