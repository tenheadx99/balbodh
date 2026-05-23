import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/audio/audio_service.dart';
import '../../core/audio/sound_effect_service.dart';
import '../../services/ad_service.dart';
import '../../games/bubble_widget.dart';
import '../../games/reward_overlay.dart';
import '../../models/bubble_letter.dart';
import '../../services/progress_service.dart';

enum GamePhase { intro, playing, correct, wrong, complete }

class BubblePopGame extends StatefulWidget {
  final ModuleType module;
  final List<BubbleLetter>? customLetters;

  const BubblePopGame({super.key, required this.module, this.customLetters});

  @override
  State<BubblePopGame> createState() => _BubblePopGameState();
}

class _BubblePopGameState extends State<BubblePopGame>
    with TickerProviderStateMixin {
  final AudioService _audio = AudioService();
  final SoundEffectService _sfx = SoundEffectService();
  final ProgressService _progress = ProgressService();
  final Random _random = Random();

  GamePhase _phase = GamePhase.intro;
  final List<_BubbleSprite> _bubbles = [];
  BubbleLetter? _currentTarget;
  String _introLetter = '';

  int _correctCount = 0;
  int _streak = 0;
  int _stars = 0;
  int _wrongAttempts = 0;
  int _currentLevel = 0;
  int _levelSize = 3;
  int _nextBubbleId = 0;

  bool _hintActive = false;
  bool _showReward = false;
  bool _showAdOffer = false;
  String _rewardMessage = '';

  late AnimationController _bgController;
  late Animation<double> _bgAnimation;

  Timer? _spawnTimer;
  Timer? _floatTimer;
  Timer? _inactivityTimer;

  int _inactivitySeconds = 0;
  double _screenW = 400;
  double _screenH = 800;

  String get _moduleKey {
    switch (widget.module) {
      case ModuleType.hindi:
        return 'hindi';
      case ModuleType.math:
        return 'math';
      case ModuleType.abc:
        return 'abc';
    }
  }

  List<BubbleLetter> _allLetters = [];
  List<BubbleLetter> _sessionLetters = [];
  int _sessionLetterIndex = 0;

  @override
  void initState() {
    super.initState();

    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _bgAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _bgController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _screenW = MediaQuery.of(context).size.width;
      _screenH = MediaQuery.of(context).size.height;
      _initGame();
    });
  }

  void _initGame() {
    _allLetters = widget.customLetters ?? (widget.module == ModuleType.hindi
        ? BubbleLetter.hindiLetters
        : BubbleLetter.abcLetters);
    _currentLevel = 0;
    _loadNextLevel();
  }

  void _loadNextLevel() {
    final start = _currentLevel * _levelSize;
    final end = min(start + _levelSize, _allLetters.length);

    if (start >= _allLetters.length) {
      _showCompletion();
      return;
    }

    _sessionLetters = _allLetters.sublist(start, end);
    _sessionLetterIndex = 0;
    _correctCount = 0;
    _levelSize = min(_levelSize + 1, 5);
    _startIntro();
  }

  void _startIntro() {
    _cancelAllTimers();
    if (_sessionLetterIndex >= _sessionLetters.length) {
      _currentLevel++;
      _loadNextLevel();
      return;
    }

    _currentTarget = _sessionLetters[_sessionLetterIndex];
    _introLetter = _currentTarget!.letter;
    _phase = GamePhase.intro;
    _hintActive = false;
    _bubbles.clear();
    _inactivitySeconds = 0;

    setState(() {});
    _speakIntro();

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) _startPlaying();
    });
  }

  Future<void> _speakIntro() async {
    final target = _currentTarget!;
    if (widget.module == ModuleType.hindi) {
      await _audio.speakHindi('ढूंढो अक्षर ${target.letter}');
      await _audio.playLetterSound(target.letter, 'hindi');
      if (target.objectName.isNotEmpty) {
        await Future.delayed(const Duration(milliseconds: 500));
        await _audio.speakHindi('${target.letter} for ${target.objectName}');
      }
    } else if (widget.module == ModuleType.math) {
      // For numbers: say "Find number Three" using the word name
      final word = target.objectName.isNotEmpty ? target.objectName : target.letter;
      await _audio.speakEnglish('Find number $word');
    } else {
      await _audio.speakEnglish('Find the letter ${target.letter}');
      await _audio.playLetterSound(target.letter, 'abc');
      if (target.objectName.isNotEmpty) {
        await Future.delayed(const Duration(milliseconds: 500));
        await _audio.speakEnglish('${target.letter} for ${target.objectName}');
      }
    }
  }

  void _startPlaying() {
    _phase = GamePhase.playing;
    _wrongAttempts = 0;
    _inactivitySeconds = 0;
    _bubbles.clear();
    _spawnInitialBubbles();
    _startSpawnTimer();
    _startFloatTimer();
    _startInactivityTimer();
    setState(() {});
  }

  void _spawnInitialBubbles() {
    final targetCount = 1;
    final distractorCount = min(_currentLevel + 2, 4);
    final total = targetCount + distractorCount;

    for (int i = 0; i < total; i++) {
      _addBubble(
        isTarget: i == 0,
        yOffset: _random.nextDouble() * _screenH * 0.3,
      );
    }
  }

  void _addBubble({bool isTarget = false, double yOffset = 0}) {
    final target = _currentTarget!;
    final letter = isTarget
        ? target
        : _randomDistractor(target);

    _bubbles.add(_BubbleSprite(
      id: _nextBubbleId++,
      letter: letter,
      x: 50 + _random.nextDouble() * (_screenW - 150),
      y: _screenH + 50 + yOffset,
      speed: 1.0 + _random.nextDouble() * 0.8 + _currentLevel * 0.05,
      wobblePhase: _random.nextDouble() * pi * 2,
      wobbleAmp: 0.3 + _random.nextDouble() * 0.4,
      color: AppColors.bubbleColors[_random.nextInt(AppColors.bubbleColors.length)],
      isTarget: isTarget,
    ));
  }

  BubbleLetter _randomDistractor(BubbleLetter exclude) {
    final pool = _allLetters.where((l) => l.letter != exclude.letter).toList();
    return pool[_random.nextInt(pool.length)];
  }

  void _startSpawnTimer() {
    _spawnTimer?.cancel();
    _spawnTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (_phase != GamePhase.playing || !mounted) return;
      _addBubble(isTarget: false);
      if (_random.nextBool()) _addBubble(isTarget: false);
      setState(() {});
    });
  }

  void _startFloatTimer() {
    _floatTimer?.cancel();
    _floatTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (_phase != GamePhase.playing || !mounted) return;
      setState(() {
        for (final b in _bubbles) {
          final wobble = sin(b.y * 0.02 + b.wobblePhase) * b.wobbleAmp;
          b.y -= b.speed;
          b.x += wobble;
        }
        _bubbles.removeWhere((b) => b.y < -120);
      });
    });
  }

  void _startInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivitySeconds = 0;
    _inactivityTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_phase != GamePhase.playing || !mounted) return;
      _inactivitySeconds++;
      if (_inactivitySeconds >= 8 && !_hintActive) {
        _hintActive = true;
        final t = _currentTarget!;
        final hint = widget.module == ModuleType.math
            ? 'Look for number ${t.objectName.isNotEmpty ? t.objectName : t.letter}'
            : 'Look for ${t.letter}';
        _audio.speakEnglish(hint);
        setState(() {});
        Future.delayed(const Duration(seconds: 4), () {
          if (mounted) {
            _hintActive = false;
            setState(() {});
          }
        });
      }
    });
  }

  void _cancelAllTimers() {
    _spawnTimer?.cancel();
    _spawnTimer = null;
    _floatTimer?.cancel();
    _floatTimer = null;
    _inactivityTimer?.cancel();
    _inactivityTimer = null;
  }

  void _onCorrectPop() {
    if (_phase != GamePhase.playing) return;

    _phase = GamePhase.correct;
    _correctCount++;
    _streak++;
    _stars++;

    final mod = _moduleKey;
    _progress.recordAttempt(mod, _currentTarget!.letter, true);
    _progress.addStar(mod);

    _sfx.playCorrect();

    if (_streak >= 3) {
      _rewardMessage = '🔥 Amazing!\n$_streak in a row!';
      _stars++;
      _sfx.playStreak();
    } else {
      _rewardMessage = '⭐ Great!';
      _sfx.playStar();
    }

    _audio.playEncouragement(hindi: widget.module == ModuleType.hindi);

    _showReward = true;
    _cancelAllTimers();
    setState(() {});

    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      _showReward = false;
      _sessionLetterIndex++;

      if (_correctCount >= _levelSize) {
        _phase = GamePhase.complete;
        _showLevelComplete();
      } else {
        _startIntro();
      }
      setState(() {});
    });
  }

  void _onWrongPop() {
    if (_phase != GamePhase.playing) return;

    _streak = 0;
    _wrongAttempts++;
    _progress.recordAttempt(_moduleKey, _currentTarget!.letter, false);

    _sfx.playWrong();
    _audio.playTryAgain(hindi: widget.module == ModuleType.hindi);
    setState(() {});

    if (_wrongAttempts >= 3 && !_hintActive) {
      _hintActive = true;
      _audio.speakEnglish('Look for the letter ${_currentTarget!.letter}');
      setState(() {});
    }
  }

  void _showLevelComplete() {
    _sfx.playFanfare();
    _showReward = true;
    _rewardMessage = '🎉 Level $_currentLevel Complete!';
    setState(() {});

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() {
        _showReward = false;
        _showAdOffer = true;
      });
    });
  }

  void _onAdRewarded() {
    _stars += 3;
    _sfx.playStreak();
    _audio.speakEnglish('Bonus stars!');
    _proceedAfterLevel();
  }

  void _proceedAfterLevel() {
    _showAdOffer = false;
    _currentLevel++;
    _loadNextLevel();
    setState(() {});
  }

  void _showCompletion() {
    _cancelAllTimers();
    _phase = GamePhase.complete;
    _showReward = true;
    _rewardMessage = widget.module == ModuleType.math
        ? '🎉 All numbers mastered!'
        : '🎉 All letters mastered!';
    setState(() {});
  }

  void _onHint() {
    if (_phase != GamePhase.playing) return;
    _hintActive = true;
    _sfx.playTap();
    final t = _currentTarget!;
    final hint = widget.module == ModuleType.math
        ? 'Look for number ${t.objectName.isNotEmpty ? t.objectName : t.letter}'
        : 'Look for the letter ${t.letter}';
    _audio.speakEnglish(hint);
    setState(() {});

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _hintActive = false;
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _cancelAllTimers();
    _bgController.dispose();
    _audio.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.lerp(
                AppColors.backgroundStart,
                AppColors.backgroundEnd,
                _bgAnimation.value,
              )!,
              Color.lerp(
                AppColors.backgroundEnd,
                AppColors.backgroundStart,
                _bgAnimation.value,
              )!,
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              _buildGameArea(),
              _buildTopBar(),
              if (_phase == GamePhase.intro) _buildIntroOverlay(),
              if (_showReward) _buildRewardOverlay(),
              if (_phase == GamePhase.complete && !_showReward)
                _buildCompletionScreen(),
              if (_showAdOffer) _buildAdOffer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdOffer() {
    return Container(
      color: Colors.black.withValues(alpha: 0.4),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('⭐', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 12),
              const Text(
                'Double your stars?',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Watch a short ad to earn 3 bonus stars!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textDark.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        AdService().showRewardedAd(onRewarded: _onAdRewarded);
                      },
                      icon: const Icon(Icons.play_circle, size: 20),
                      label: const Text('Watch Ad'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.warning,
                        foregroundColor: AppColors.textDark,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        textStyle: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _proceedAfterLevel,
                      child: const Text('Skip',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textDark)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameArea() {
    return Stack(
      children: [
        ..._bubbles.map((b) => BubbleWidget(
              key: ValueKey(b.id),
              letter: b.letter,
              xPosition: b.x,
              yPosition: b.y,
              size: 75.0,
              color: b.color,
              isTarget: b.isTarget,
              isHinted: b.isTarget && _hintActive,
              onPopped: _onCorrectPop,
              onWrong: _onWrongPop,
            )),
        if (_phase == GamePhase.playing)
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Find: ${_currentTarget?.displayName ?? ""}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
              ),
            ),
          ),
        if (_phase == GamePhase.playing)
          Positioned(
            right: 16,
            bottom: 80,
            child: GestureDetector(
              onTap: _onHint,
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadow,
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text('💡', style: TextStyle(fontSize: 28)),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTopBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back,
                  size: 32, color: AppColors.textDark),
              onPressed: () => Navigator.of(context).pop(),
            ),
            const Spacer(),
            _badgeContainer(
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('⭐', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 4),
                  Text('$_stars',
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark)),
                ],
              ),
            ),
            if (_streak >= 2) ...[
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.orange.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🔥', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 4),
                    Text('$_streak',
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.white)),
                  ],
                ),
              ),
            ],
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('Level ${_currentLevel + 1}',
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _badgeContainer(Widget child) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildIntroOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.3),
      child: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 500),
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.scale(scale: value, child: child),
            );
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.5),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    _introLetter,
                    style: const TextStyle(
                      fontSize: 64,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Pop the right bubble!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRewardOverlay() {
    return RewardOverlay(
      message: _rewardMessage,
      showConfetti: _streak >= 3 || _phase == GamePhase.complete,
    );
  }

  Widget _buildCompletionScreen() {
    return Container(
      color: Colors.black.withValues(alpha: 0.4),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 80)),
            const SizedBox(height: 24),
            Text(
              'All Letters\nMastered!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                shadows: [
                  Shadow(
                    blurRadius: 10,
                    color: Colors.black.withValues(alpha: 0.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'You earned $_stars stars! ⭐',
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.white70),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.home),
              label: const Text('Go Home'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                textStyle: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BubbleSprite {
  final int id;
  final BubbleLetter letter;
  double x;
  double y;
  final double speed;
  final double wobblePhase;
  final double wobbleAmp;
  final Color color;
  final bool isTarget;

  _BubbleSprite({
    required this.id,
    required this.letter,
    required this.x,
    required this.y,
    required this.speed,
    required this.wobblePhase,
    required this.wobbleAmp,
    required this.color,
    required this.isTarget,
  });
}
