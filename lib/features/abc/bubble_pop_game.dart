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

class _BubblePopGameState extends State<BubblePopGame> with TickerProviderStateMixin {
  final AudioService _audio = AudioService();
  final SoundEffectService _sfx = SoundEffectService();
  final ProgressService _progress = ProgressService();
  final Random _random = Random();

  GamePhase _phase = GamePhase.intro;
  final List<_BubbleSprite> _bubbles = [];
  final List<_BubblePopParticle> _particles = [];
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

  // Mascot guide reactions
  String _mascotEmoji = '🐱';
  String _mascotTalk = 'Find my matching bubble!';

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
      duration: const Duration(seconds: 4),
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

    Future.delayed(const Duration(milliseconds: 3200), () {
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
        await _audio.speakHindi('${target.letter} से ${target.objectName}');
      }
    } else if (widget.module == ModuleType.math) {
      final word = target.objectName.isNotEmpty ? target.objectName : target.letter;
      await _audio.speakEnglish('Find number $word');
    } else {
      await _audio.speakEnglish('Find the letter ${target.letter}');
      await _audio.playLetterSound(target.letter, 'abc');
      if (target.objectName.isNotEmpty) {
        await Future.delayed(const Duration(milliseconds: 500));
        await _audio.speakEnglish('${target.letter} is for ${target.objectName}');
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
        yOffset: _random.nextDouble() * _screenH * 0.25,
      );
    }
  }

  void _addBubble({bool isTarget = false, double yOffset = 0}) {
    final target = _currentTarget!;
    final letter = isTarget ? target : _randomDistractor(target);

    _bubbles.add(_BubbleSprite(
      id: _nextBubbleId++,
      letter: letter,
      x: 60 + _random.nextDouble() * (_screenW - 140),
      y: _screenH + 60 + yOffset,
      speed: 1.1 + _random.nextDouble() * 0.9 + _currentLevel * 0.06,
      wobblePhase: _random.nextDouble() * pi * 2,
      wobbleAmp: 0.3 + _random.nextDouble() * 0.5,
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
    _spawnTimer = Timer.periodic(const Duration(milliseconds: 2600), (_) {
      if (_phase != GamePhase.playing || !mounted) return;
      _addBubble(isTarget: false);
      if (_random.nextBool()) _addBubble(isTarget: false);
      setState(() {});
    });
  }

  void _triggerBubbleParticles(double originX, double originY, Color color) {
    for (int i = 0; i < 14; i++) {
      final angle = _random.nextDouble() * 2 * pi;
      final speed = 1.5 + _random.nextDouble() * 4.0;
      _particles.add(_BubblePopParticle(
        x: originX,
        y: originY,
        vx: cos(angle) * speed,
        vy: sin(angle) * speed - 1.0,
        size: 5.0 + _random.nextDouble() * 10.0,
        color: color.withValues(alpha: 0.8),
      ));
    }
  }

  void _startFloatTimer() {
    _floatTimer?.cancel();
    _floatTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (_phase != GamePhase.playing || !mounted) return;
      setState(() {
        // Float bubbles
        for (final b in _bubbles) {
          final wobble = sin(b.y * 0.02 + b.wobblePhase) * b.wobbleAmp;
          b.y -= b.speed;
          b.x += wobble;
        }
        _bubbles.removeWhere((b) => b.y < -120);

        // Physics for popped bubble droplets
        for (final p in _particles) {
          p.x += p.vx;
          p.y += p.vy;
          p.vy += 0.12; // weak water gravity
          p.opacity -= 0.03; // fast fade pop
        }
        _particles.removeWhere((p) => p.opacity <= 0);
      });
    });
  }

  void _startInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivitySeconds = 0;
    _inactivityTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_phase != GamePhase.playing || !mounted) return;
      _inactivitySeconds++;
      if (_inactivitySeconds >= 7 && !_hintActive) {
        _hintActive = true;
        final t = _currentTarget!;
        final hint = widget.module == ModuleType.math
            ? 'Look for number ${t.displayName}'
            : 'Look for ${t.displayName}';
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

    // Retrieve target bubble position to burst water bubbles
    final targetB = _bubbles.firstWhere((b) => b.isTarget, orElse: () => _bubbles.first);
    _triggerBubbleParticles(targetB.x, targetB.y, targetB.color);

    _phase = GamePhase.correct;
    _correctCount++;
    _streak++;
    _stars++;

    final mod = _moduleKey;
    _progress.recordAttempt(mod, _currentTarget!.letter, true);
    _progress.addStar(mod);

    _sfx.playCorrect();

    setState(() {
      _mascotEmoji = '🥳';
      if (_streak >= 3) {
        _rewardMessage = '🔥 Double Sparkle!\n$_streak in a row!';
        _stars++;
        _sfx.playStreak();
      } else {
        _rewardMessage = '⭐ Bubble Popped!';
        _sfx.playStar();
      }
    });

    _audio.playEncouragement(hindi: widget.module == ModuleType.hindi);

    _showReward = true;
    _cancelAllTimers();

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      setState(() {
        _showReward = false;
        _mascotEmoji = '🐱';
        _sessionLetterIndex++;

        if (_correctCount >= _levelSize) {
          _phase = GamePhase.complete;
          _showLevelComplete();
        } else {
          _startIntro();
        }
      });
    });
  }

  void _onWrongPop() {
    if (_phase != GamePhase.playing) return;

    _streak = 0;
    _wrongAttempts++;
    _progress.recordAttempt(_moduleKey, _currentTarget!.letter, false);

    _sfx.playWrong();
    _audio.playTryAgain(hindi: widget.module == ModuleType.hindi);
    setState(() {
      _mascotEmoji = '😮';
      _mascotTalk = 'Oops! That is a different bubble!';
    });

    Future.delayed(const Duration(milliseconds: 1400), () {
      if (mounted && _mascotEmoji == '😮') {
        setState(() {
          _mascotEmoji = '🐱';
        });
      }
    });

    if (_wrongAttempts >= 3 && !_hintActive) {
      _hintActive = true;
      _audio.speakEnglish('Tap the bubble with ${_currentTarget!.letter}');
      setState(() {});
    }
  }

  void _showLevelComplete() {
    _sfx.playFanfare();
    _showReward = true;
    _rewardMessage = '🎉 Level ${_currentLevel + 1} Complete!';
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
    _audio.speakEnglish('Bonus stars! You are amazing!');
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
        ? '🎉 Master of Numbers!'
        : '🎉 Alphabet Expert!';
    setState(() {});
  }

  void _onHint() {
    if (_phase != GamePhase.playing) return;
    _hintActive = true;
    _sfx.playTap();
    final t = _currentTarget!;
    final hint = widget.module == ModuleType.math
        ? 'Look for number ${t.displayName}'
        : 'Look for ${t.displayName}';
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
              if (_phase == GamePhase.playing) _buildMascotBanner(),
              if (_phase == GamePhase.intro) _buildEducationalIntroOverlay(),
              if (_showReward) _buildRewardOverlay(),
              if (_phase == GamePhase.complete && !_showReward) _buildCompletionScreen(),
              if (_showAdOffer) _buildAdOffer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdOffer() {
    return Container(
      color: Colors.black.withValues(alpha: 0.55),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🎁', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 12),
              Text(
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
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 24),
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
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _proceedAfterLevel,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.grey),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        'Skip',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark,
                        ),
                      ),
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
        // 1. Floating glassmorphic bubbles
        ..._bubbles.map((b) => BubbleWidget(
              key: ValueKey(b.id),
              letter: b.letter,
              xPosition: b.x,
              yPosition: b.y,
              size: 78.0,
              color: b.color,
              isTarget: b.isTarget,
              isHinted: b.isTarget && _hintActive,
              onPopped: _onCorrectPop,
              onWrong: _onWrongPop,
            )),

        // 2. Custom particle paint overlay
        IgnorePointer(
          child: CustomPaint(
            size: Size(_screenW, _screenH),
            painter: _BubbleDropletPainter(_particles),
          ),
        ),

        // 3. Hint bulb button
        if (_phase == GamePhase.playing)
          Positioned(
            right: 16,
            bottom: 24,
            child: GestureDetector(
              onTap: _onHint,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.95),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadow,
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text('💡', style: TextStyle(fontSize: 30)),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMascotBanner() {
    return Positioned(
      top: 66,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.88),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: Row(
          children: [
            Text(_mascotEmoji, style: const TextStyle(fontSize: 34)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _mascotTalk,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                  const SizedBox(height: 1),
                  Row(
                    children: [
                      const Text(
                        'Pop: ',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark),
                      ),
                      Text(
                        _currentTarget?.displayName ?? "",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.primary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
              icon: const Icon(Icons.arrow_back, size: 32, color: AppColors.textDark),
              onPressed: () => Navigator.of(context).pop(),
            ),
            const Spacer(),
            _badgeContainer(
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('⭐', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 4),
                  Text('$_stars',
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textDark)),
                ],
              ),
            ),
            if (_streak >= 2) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.orange,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: AppColors.orange.withValues(alpha: 0.3), blurRadius: 4),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🔥', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 4),
                    Text('$_streak',
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: Colors.white)),
                  ],
                ),
              ),
            ],
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('Level ${_currentLevel + 1}',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _badgeContainer(Widget child) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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

  Widget _buildEducationalIntroOverlay() {
    final target = _currentTarget!;
    
    // Custom subtexts for bilingual Hindi, English, and Math
    String subtitle = 'Pop the matching bubbles!';
    Widget visualRepresentation = const SizedBox.shrink();

    if (widget.module == ModuleType.hindi) {
      subtitle = '${target.letter} से ${target.objectName}';
      visualRepresentation = Text(
        target.objectName.isNotEmpty ? _letterToEmoji(target.letter) : '🕉️',
        style: const TextStyle(fontSize: 68),
      );
    } else if (widget.module == ModuleType.abc) {
      subtitle = '${target.letter} is for ${target.objectName}';
      visualRepresentation = Text(
        _letterToEmoji(target.letter),
        style: const TextStyle(fontSize: 68),
      );
    } else if (widget.module == ModuleType.math) {
      subtitle = 'Trace & Count: ${target.objectName}';
      // Renders a grid of stars corresponding to the number count! Extremely educational!
      int count = int.tryParse(target.letter) ?? 1;
      visualRepresentation = Wrap(
        spacing: 4,
        runSpacing: 4,
        alignment: WrapAlignment.center,
        children: List.generate(count.clamp(1, 10), (index) {
          return const Text('⭐', style: TextStyle(fontSize: 32));
        }) + (count > 10 ? [const Text('...', style: TextStyle(fontSize: 24, color: Colors.white))] : []),
      );
    }

    return Container(
      color: Colors.black.withValues(alpha: 0.45),
      child: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 600),
          curve: Curves.elasticOut,
          builder: (context, value, child) {
            return Transform.scale(scale: value, child: child);
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE8F5E9), Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: Colors.white, width: 4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.secondary],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.4),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      _introLetter,
                      style: const TextStyle(
                        fontSize: 56,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green.shade100, width: 2),
                  ),
                  child: visualRepresentation,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Listen & pop the correct bubble!',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _letterToEmoji(String letter) {
    final map = {
      // English
      'A': '🍎', 'B': '⚽', 'C': '🐱', 'D': '🐶', 'E': '🐘',
      'F': '🐟', 'G': '🐐', 'H': '🎩', 'I': '🍦', 'J': '🏺',
      'K': '🪁', 'L': '🦁', 'M': '🐵', 'N': '🪺', 'O': '🍊',
      'P': '🐧', 'Q': '👑', 'R': '🐰', 'S': '☀️', 'T': '🐯',
      'U': '☂️', 'V': '🎻', 'W': '⌚', 'X': '🎵', 'Y': '🐃',
      'Z': '🦓',
      // Hindi
      'अ': '🍊', 'आ': '🥭', 'इ': '🍇', 'ई': '🎋', 'उ': '🦉',
      'ऊ': '🧶', 'ऋ': '🧘', 'ए': '🦶', 'ऐ': '👓', 'ओ': '💧',
      'औ': '💊', 'अं': '🍇', 'क': '🕊️', 'ख': '🐰', 'ग': '🏺',
      'घ': '🏡', 'च': '🥄', 'छ': '☂️', 'ज': '🚢', 'झ': '🚩',
      'ट': '🍅', 'ठ': '🪵', 'ड': '🥁', 'ढ': '🛡️', 'त': '🍉',
      'थ': '⚖️', 'द': '🦷', 'ध': '🏹', 'न': 'tap', 'प': '🪁',
      'फ': '🍎', 'ब': '🐐', 'भ': '🐻', 'म': '🐟', 'य': '🧘',
      'र': '🚗', 'ल': '🪵', 'व': '🌳', 'श': '🍯', 'ष': '🎨',
      'स': '🍎', 'ह': '🐘',
    };
    return map[letter] ?? '🎈';
  }

  Widget _buildRewardOverlay() {
    return RewardOverlay(
      message: _rewardMessage,
      showConfetti: _streak >= 3 || _phase == GamePhase.complete,
    );
  }

  Widget _buildCompletionScreen() {
    return Container(
      color: Colors.black.withValues(alpha: 0.5),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 20)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🏆', style: TextStyle(fontSize: 72)),
              const SizedBox(height: 16),
              Text(
                widget.module == ModuleType.math
                    ? 'Math Master!'
                    : 'Language Expert!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You mastered all target values and earned $_stars stars!',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.home),
                label: const Text('Back to Home'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
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

class _BubblePopParticle {
  double x;
  double y;
  double vx;
  double vy;
  double size;
  Color color;
  double opacity = 1.0;

  _BubblePopParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.color,
  });
}

class _BubbleDropletPainter extends CustomPainter {
  final List<_BubblePopParticle> particles;
  _BubbleDropletPainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    
    for (final p in particles) {
      paint.color = p.color.withValues(alpha: p.opacity.clamp(0.0, 1.0));
      
      // Draw shiny soap bubble droplet (circle with a small inner highlight point)
      canvas.drawCircle(Offset(p.x, p.y), p.size, paint);
      
      final highlightPaint = Paint()
        ..color = Colors.white.withValues(alpha: p.opacity * 0.7)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(p.x - p.size * 0.3, p.y - p.size * 0.3), p.size * 0.25, highlightPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
