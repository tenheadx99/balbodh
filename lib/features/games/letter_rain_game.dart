import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/audio/audio_service.dart';
import '../../core/audio/sound_effect_service.dart';
import '../../games/reward_overlay.dart';
import '../../models/bubble_letter.dart';
import '../../services/progress_service.dart';
import '../../services/settings_service.dart';
import '../mascot/mascot_widget.dart';

class LetterRainGame extends StatefulWidget {
  const LetterRainGame({super.key});

  @override
  State<LetterRainGame> createState() => _LetterRainGameState();
}

class _LetterRainGameState extends State<LetterRainGame>
    with TickerProviderStateMixin {
  final AudioService _audio = AudioService();
  final SoundEffectService _sfx = SoundEffectService();
  final ProgressService _progress = ProgressService();
  final Random _random = Random();

  final List<_FallingLetter> _letters = [];
  final GlobalKey _areaKey = GlobalKey();
  int _nextId = 0;

  int _stars = 0;
  int _level = 1;
  int _caught = 0;
  int _missed = 0;
  String _targetLetter = 'A';
  bool _gameOver = false;

  Timer? _spawnTimer;
  Timer? _fallTimer;
  double _areaW = 400;
  double _areaH = 600;

  List<BubbleLetter> _pool = [];
  int _poolIndex = 0;

  @override
  void initState() {
    super.initState();
    _pool = List.from(BubbleLetter.abcLetters)..shuffle();
    _nextTarget();
    _startGame();
  }

  void _nextTarget() {
    if (_poolIndex >= _pool.length) {
      _pool = List.from(BubbleLetter.abcLetters)..shuffle();
      _poolIndex = 0;
    }
    _targetLetter = _pool[_poolIndex].letter;
    _poolIndex++;

    if (_targetLetter == 'Q' || _targetLetter == 'X' || _targetLetter == 'Z') {
      _targetLetter = _pool[_poolIndex].letter;
      _poolIndex++;
    }

    _audio.speakEnglish('Catch $_targetLetter!');
  }

  void _startGame() {
    _spawnTimer = Timer.periodic(Duration(milliseconds: max(1200 - _level * 80, 500)), (_) {
      if (_gameOver || !mounted) return;
      _spawnLetter();
    });

    _fallTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (_gameOver || !mounted) return;
      setState(() {
        for (final l in _letters) {
          l.y += l.speed;
        }
        _letters.removeWhere((l) {
          if (l.y > _areaH + 50) {
            if (l.isTarget) {
              _missed++;
              if (_missed >= 3) _endGame();
            }
            return true;
          }
          return false;
        });
      });
    });
  }

  void _spawnLetter() {
    final isTarget = _random.nextDouble() < 0.4;
    final letter = isTarget
        ? _targetLetter
        : _randomDistractor();

    final spawnX = 30 + _random.nextDouble() * (_areaW - 100);

    _letters.add(_FallingLetter(
      id: _nextId++,
      letter: letter,
      x: spawnX,
      y: -40,
      speed: 1.0 + _random.nextDouble() * 0.5 + _level * 0.05,
      isTarget: isTarget,
    ));
  }

  String _randomDistractor() {
    final pool = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.replaceAll(_targetLetter, '');
    return pool[_random.nextInt(pool.length)];
  }

  void _onTapLetter(int id) {
    if (_gameOver) return;

    final idx = _letters.indexWhere((l) => l.id == id);
    if (idx == -1) return;

    final letter = _letters[idx];
    _letters.removeAt(idx);

    if (letter.isTarget) {
      _caught++;
      _stars++;
      _progress.addStar('games');
      _sfx.playCorrect();
      _audio.speakEnglish(_targetLetter);

      if (_caught >= 5) {
        _level++;
        _caught = 0;
        _audio.speakEnglish('Level $_level!');
        showRewardOverlay(context, message: 'Level $_level!');
      }

      _nextTarget();
      setState(() {});
    } else {
      _sfx.playWrong();
      _audio.playTryAgain();
      setState(() {});
    }
  }

  void _endGame() {
    _gameOver = true;
    _spawnTimer?.cancel();
    _fallTimer?.cancel();
    _sfx.playFanfare();
    setState(() {});
  }

  @override
  void dispose() {
    _spawnTimer?.cancel();
    _fallTimer?.cancel();
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
            colors: [Color(0xFFBBDEFB), Color(0xFFE3F2FD)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(),
              if (_gameOver) _buildGameOver(),
              if (!_gameOver) Expanded(child: _buildPlayArea()),
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
          const SizedBox(width: 4),
          MascotWidget(avatar: SettingsService().avatar, size: 32),
          const Spacer(),
          _badge('⭐ $_stars'),
          const SizedBox(width: 6),
          _badge('Lv $_level'),
          const SizedBox(width: 6),
          _badge('❤️ ${3 - _missed}'),
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
      child: Text(
        text,
        style: const TextStyle(
            fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textDark),
      ),
    );
  }

  Widget _buildPlayArea() {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🎯 ', style: TextStyle(fontSize: 18)),
              Text(
                'Catch: $_targetLetter',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Container(
                key: _areaKey,
                color: Colors.white.withValues(alpha: 0.7),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    _areaW = constraints.maxWidth;
                    _areaH = constraints.maxHeight;
                    return Stack(
                      children: _letters.map((l) {
                        return Positioned(
                          left: l.x,
                          top: l.y,
                          child: GestureDetector(
                            onTap: () => _onTapLetter(l.id),
                            child: Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: l.isTarget
                                    ? AppColors.primary.withValues(alpha: 0.85)
                                    : AppColors.accent.withValues(alpha: 0.6),
                                boxShadow: [
                                  BoxShadow(
                                    color: (l.isTarget
                                            ? AppColors.primary
                                            : AppColors.accent)
                                        .withValues(alpha: 0.3),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  l.letter,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGameOver() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 72)),
            const SizedBox(height: 16),
            const Text(
              'Game Over!',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w900,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '⭐ $_stars stars earned\nLevel $_level reached',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _letters.clear();
                  _stars = 0;
                  _level = 1;
                  _caught = 0;
                  _missed = 0;
                  _gameOver = false;
                  _letters.clear();
                });
                _nextTarget();
                _startGame();
              },
              icon: const Icon(Icons.replay),
              label: const Text('Play Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              ),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.home),
              label: const Text('Home'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FallingLetter {
  final int id;
  final String letter;
  double x;
  double y;
  final double speed;
  final bool isTarget;

  _FallingLetter({
    required this.id,
    required this.letter,
    required this.x,
    required this.y,
    required this.speed,
    required this.isTarget,
  });
}
