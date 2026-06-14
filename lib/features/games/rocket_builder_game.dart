import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/audio/audio_service.dart';
import '../../core/audio/sound_effect_service.dart';
import '../../games/reward_overlay.dart';
import '../../services/progress_service.dart';

class RocketBuilderGame extends StatefulWidget {
  const RocketBuilderGame({super.key});

  @override
  State<RocketBuilderGame> createState() => _RocketBuilderGameState();
}

class _RocketBuilderGameState extends State<RocketBuilderGame> {
  final AudioService _audio = AudioService();
  final SoundEffectService _sfx = SoundEffectService();
  final ProgressService _progress = ProgressService();
  final Random _random = Random();

  int _parts = 0;
  static const _totalParts = 6;
  int _stars = 0;
  int _level = 1;
  int _answered = 0;
  bool _launched = false;

  String _targetLetter = 'A';
  final List<String> _options = [];

  @override
  void initState() {
    super.initState();
    _newQuestion();
  }

  void _newQuestion() {
    _targetLetter = String.fromCharCode(65 + _random.nextInt(26));
    _options.clear();
    _options.add(_targetLetter);
    for (int i = 0; i < 3; i++) {
      String l;
      do { l = String.fromCharCode(65 + _random.nextInt(26)); } while (_options.contains(l));
      _options.add(l);
    }
    _options.shuffle();
    if (_parts < _totalParts) {
      _audio.speakEnglish('Find $_targetLetter to build the rocket!');
    }
    setState(() {});
  }

  void _pickLetter(String l) {
    if (_parts >= _totalParts || _launched) return;
    if (l == _targetLetter) {
      _parts++;
      _stars++;
      _answered++;
      _progress.addStar('games');
      _sfx.playCorrect();
      _audio.speakEnglish('$_targetLetter! Part added!');
      if (_answered % 5 == 0) { _level++; _audio.speakEnglish('Level $_level!'); }
      if (_parts >= _totalParts) {
        _launched = true;
        _sfx.playFanfare();
        _audio.speakEnglish('Rocket complete! 3, 2, 1, Blast off!');
        showRewardOverlay(context, message: 'Blast Off!');
        setState(() {});
      } else {
        _newQuestion();
      }
    } else {
      _sfx.playWrong();
      _audio.playTryAgain();
    }
  }

  List<String> _rocketParts() {
    if (_launched) return ['🚀'];
    final parts = <String>[];
    if (_parts > 0) parts.add('🔥');
    if (_parts > 1) parts.add('🪟');
    if (_parts > 2) parts.add('🛸');
    if (_parts > 3) parts.add('📡');
    if (_parts > 4) parts.add('⚡');
    if (_parts > 5) parts.add('🚀');
    return parts;
  }

  @override
  void dispose() { _audio.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: _launched ? [Colors.orange.shade300, Colors.yellow.shade100] : [Color(0xFF37474F), Color(0xFF546E7A)]),
      ),
      child: SafeArea(child: _launched ? _buildLaunch() : Column(children: [
        _buildTopBar(),
        _buildRocket(),
        const SizedBox(height: 12),
        _buildQuestion(),
        const Spacer(),
        _buildOptions(),
        const SizedBox(height: 24),
      ])),
    ),
  );

  Widget _buildTopBar() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    child: Row(children: [
      IconButton(icon: const Icon(Icons.arrow_back, size: 28, color: Colors.white), onPressed: () => Navigator.pop(context)),
      const Spacer(), _badge('⭐ $_stars', Colors.white), const SizedBox(width: 6),
      _badge('$_parts/$_totalParts', Colors.white),
    ]),
  );

  Widget _badge(String t, Color c) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(color: c.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(16)),
    child: Text(t, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: c)),
  );

  Widget _buildRocket() {
    final parts = _rocketParts();
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(children: [
        Text('Build the Rocket!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white.withValues(alpha: 0.8))),
        const SizedBox(height: 8),
        SizedBox(
          height: 140,
          child: Center(child: Text(
            parts.isEmpty ? '🛸' : parts.last,
            style: TextStyle(fontSize: 60 + _parts * 8.0),
          )),
        ),
        if (_parts > 0 && _parts < _totalParts)
          LinearProgressIndicator(value: _parts / _totalParts, backgroundColor: Colors.white.withValues(alpha: 0.2), valueColor: const AlwaysStoppedAnimation<Color>(Colors.greenAccent), minHeight: 8),
        if (_parts > 0)
          Text('$_parts / $_totalParts', style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.6))),
      ]),
    );
  }

  Widget _buildQuestion() => Text('Find: $_targetLetter', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white));

  Widget _buildOptions() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 32),
    child: Wrap(spacing: 16, runSpacing: 16, alignment: WrapAlignment.center,
      children: _options.map((l) => GestureDetector(
        onTap: () => _pickLetter(l),
        child: Container(
          width: 64, height: 64,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 6, offset: const Offset(0, 4))]),
          child: Center(child: Text(l, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: AppColors.textDark))),
        ),
      )).toList(),
    ),
  );

  Widget _buildLaunch() => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: -300.0), duration: const Duration(seconds: 2),
      builder: (c, v, _) => Transform.translate(offset: Offset(0, v), child: const Text('🚀', style: TextStyle(fontSize: 80))),
    ),
    const SizedBox(height: 24),
    const Text('Blast Off! 🎉', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white)),
    Text('⭐ $_stars stars', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white70)),
    const SizedBox(height: 24),
    ElevatedButton.icon(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.home), label: const Text('Home'),
      style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary, padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14))),
  ]));
}
