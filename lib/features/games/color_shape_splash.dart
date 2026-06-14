import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/audio/audio_service.dart';
import '../../core/audio/sound_effect_service.dart';
import '../../games/reward_overlay.dart';
import '../../services/progress_service.dart';

class ColorShapeSplash extends StatefulWidget {
  const ColorShapeSplash({super.key});

  @override
  State<ColorShapeSplash> createState() => _ColorShapeSplashState();
}

class _ColorShapeSplashState extends State<ColorShapeSplash> {
  final AudioService _audio = AudioService();
  final SoundEffectService _sfx = SoundEffectService();
  final ProgressService _progress = ProgressService();
  final Random _random = Random();

  static const _shapes = ['●', '■', '▲', '★', '⬟'];
  static const _colors = [Colors.red, Colors.blue, Colors.green, Colors.orange, Colors.purple];

  int _targetShape = 0;
  int _targetColor = 0;
  int _stars = 0;
  int _level = 1;
  int _correct = 0;
  final List<_ShapeTile> _tiles = [];

  static const _colorNames = ['Red', 'Blue', 'Green', 'Orange', 'Purple'];
  static const _shapeNames = ['Circle', 'Square', 'Triangle', 'Star', 'Pentagon'];

  @override
  void initState() {
    super.initState();
    _newRound();
  }

  void _newRound() {
    _targetShape = _random.nextInt(_shapes.length);
    _targetColor = _random.nextInt(_colors.length);
    _tiles.clear();

    for (int i = 0; i < 6; i++) {
      final s = _random.nextInt(_shapes.length);
      final c = _random.nextInt(_colors.length);
      _tiles.add(_ShapeTile(shape: s, color: c, isTarget: s == _targetShape && c == _targetColor));
    }

    if (!_tiles.any((t) => t.isTarget)) {
      final idx = _random.nextInt(_tiles.length);
      _tiles[idx] = _ShapeTile(shape: _targetShape, color: _targetColor, isTarget: true);
    }

    _tiles.shuffle();
    _audio.speakEnglish('Find the ${_colorNames[_targetColor]} ${_shapeNames[_targetShape]}');
    setState(() {});
  }

  void _tapTile(int idx) {
    if (_tiles[idx].isTarget) {
      _stars++;
      _correct++;
      _progress.addStar('games');
      _sfx.playCorrect();
      _audio.speakEnglish('Great!');
      if (_correct % 5 == 0) {
        _level++;
        _audio.speakEnglish('Level $_level!');
        showRewardOverlay(context, message: 'Level $_level!');
      }
      _newRound();
    } else {
      _sfx.playWrong();
      _audio.playTryAgain();
      setState(() => _tiles[idx].wrong = true);
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) setState(() => _tiles[idx].wrong = false);
      });
    }
  }

  @override
  void dispose() {
    _audio.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFCE93D8), Color(0xFFF3E5F5)]),
      ),
      child: SafeArea(child: Column(children: [
        _buildTopBar(),
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

  Widget _buildTarget() => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Column(children: [
      Text('Find this:', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textDark)),
      const SizedBox(height: 8),
      Text(_shapes[_targetShape], style: TextStyle(fontSize: 48, color: _colors[_targetColor])),
      Text('${_colorNames[_targetColor]} ${_shapeNames[_targetShape]}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textDark)),
    ]),
  );

  Widget _buildGrid() => Padding(
    padding: const EdgeInsets.all(16),
    child: GridView.count(
      crossAxisCount: 3, mainAxisSpacing: 12, crossAxisSpacing: 12,
      children: List.generate(_tiles.length, (i) {
        final t = _tiles[i];
        return GestureDetector(
          onTap: () => _tapTile(i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: t.wrong ? AppColors.primary.withValues(alpha: 0.3) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 6, offset: const Offset(0, 4))],
            ),
            child: Center(child: Text(_shapes[t.shape], style: TextStyle(fontSize: 44, color: _colors[t.color]))),
          ),
        );
      }),
    ),
  );
}

class _ShapeTile {
  final int shape; final int color; final bool isTarget; bool wrong = false;
  _ShapeTile({required this.shape, required this.color, required this.isTarget});
}
