import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/audio/audio_service.dart';
import '../../games/bubble_widget.dart';
import '../../games/reward_overlay.dart';
import '../../models/bubble_letter.dart';
import '../../services/progress_service.dart';

enum GamePhase { intro, playing, correct, wrong, complete }

class BubblePopGame extends StatefulWidget {
  final ModuleType module;

  const BubblePopGame({super.key, required this.module});

  @override
  State<BubblePopGame> createState() => _BubblePopGameState();
}

class _BubblePopGameState extends State<BubblePopGame>
    with TickerProviderStateMixin {
  final AudioService _audio = AudioService();
  final ProgressService _progress = ProgressService();
  final Random _random = Random();

  GamePhase _phase = GamePhase.intro;
  List<_BubbleData> _bubbles = [];
  BubbleLetter? _currentTarget;
  String _introLetter = '';

  int _correctCount = 0;
  int _streak = 0;
  int _stars = 0;
  int _wrongAttempts = 0;
  int _currentLevel = 0;
  int _levelSize = 3;

  bool _hintActive = false;
  bool _showReward = false;
  String _rewardMessage = '';

  late AnimationController _bgController;
  late Animation<double> _bgAnimation;

  Timer? _spawnTimer;
  Timer? _floatTimer;

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

    _initGame();
  }

  void _initGame() {
    _allLetters = widget.module == ModuleType.hindi
        ? BubbleLetter.hindiLetters
        : BubbleLetter.abcLetters;

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
    if (_sessionLetterIndex >= _sessionLetters.length) {
      _currentLevel++;
      _loadNextLevel();
      return;
    }

    _currentTarget = _sessionLetters[_sessionLetterIndex];
    _introLetter = _currentTarget!.letter;
    _phase = GamePhase.intro;
    _hintActive = false;
    _bubbles = [];

    setState(() {});

    _speakIntro();

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) _startPlaying();
    });
  }

  Future<void> _speakIntro() async {
    final target = _currentTarget!;
    if (widget.module == ModuleType.hindi) {
      final msg = 'ढूंढो अक्षर ${target.letter}';
      await _audio.speakHindi(msg);
    } else {
      final msg = 'Find the letter ${target.letter}';
      await _audio.speakEnglish(msg);
    }
    await _audio.playLetterSound(target.letter,
        widget.module == ModuleType.hindi ? 'hindi' : 'abc');
    if (target.objectName.isNotEmpty) {
      await Future.delayed(const Duration(milliseconds: 500));
      final objMsg = widget.module == ModuleType.hindi
          ? '${target.letter} for ${target.objectName}'
          : '${target.letter} for ${target.objectName}';
      if (widget.module == ModuleType.hindi) {
        await _audio.speakHindi(objMsg);
      } else {
        await _audio.speakEnglish(objMsg);
      }
    }
  }

  void _startPlaying() {
    _phase = GamePhase.playing;
    _wrongAttempts = 0;
    _spawnBubbles();
    _startSpawning();
    setState(() {});
  }

  void _spawnBubbles() {
    _bubbles = [];
    final target = _currentTarget!;

    final correctBubble = _BubbleData(
      letter: target,
      x: _random.nextDouble() * (MediaQuery.of(context).size.width - 100) + 50,
      y: MediaQuery.of(context).size.height + 50,
      color: AppColors.bubbleColors[_random.nextInt(AppColors.bubbleColors.length)],
      isTarget: true,
    );
    _bubbles.add(correctBubble);

    final distractorCount = min(_currentLevel + 2, 4);
    final distractors = <BubbleLetter>[];
    final pool = _allLetters
        .where((l) => l.letter != target.letter)
        .toList()
      ..shuffle();

    for (int i = 0; i < distractorCount && i < pool.length; i++) {
      distractors.add(pool[i]);
    }

    for (final d in distractors) {
      _bubbles.add(_BubbleData(
        letter: d,
        x: _random.nextDouble() * (MediaQuery.of(context).size.width - 100) + 50,
        y: MediaQuery.of(context).size.height + 50 +
            _random.nextDouble() * 100,
        color:
            AppColors.bubbleColors[_random.nextInt(AppColors.bubbleColors.length)],
        isTarget: false,
      ));
    }

    _bubbles.shuffle();
    _startFloating();
  }

  void _startSpawning() {
    _spawnTimer?.cancel();
    _spawnTimer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (_phase == GamePhase.playing && mounted) {
        _spawnBubbles();
      }
    });
  }

  void _startFloating() {
    _floatTimer?.cancel();
    _floatTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (_phase != GamePhase.playing || !mounted) return;
      setState(() {
        for (final b in _bubbles) {
          b.y -= 1.2 + _currentLevel * 0.1;
          b.x += sin(b.y * 0.02) * 0.5;
        }
        _bubbles.removeWhere((b) => b.y < -100);
      });
    });
  }

  void _onCorrectPop() {
    if (_phase != GamePhase.playing) return;

    _phase = GamePhase.correct;
    _correctCount++;
    _streak++;
    _stars++;
    _progress.recordAttempt(
        widget.module == ModuleType.hindi ? 'hindi' : 'abc',
        _currentTarget!.letter,
        true);
    _progress.addStar(widget.module == ModuleType.hindi ? 'hindi' : 'abc');

    _audio.playEncouragement();

    if (_streak >= 3) {
      _rewardMessage = '🔥 Amazing!\n$_streak in a row!';
      _stars++;
    } else {
      _rewardMessage = '⭐ Great!';
    }

    _showReward = true;
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
    _progress.recordAttempt(
        widget.module == ModuleType.hindi ? 'hindi' : 'abc',
        _currentTarget!.letter,
        false);

    _audio.playTryAgain();
    setState(() {});

    if (_wrongAttempts >= 3) {
      _hintActive = true;
      _audio.speakEnglish('Look for the letter ${_currentTarget!.letter}');
      setState(() {});
    }
  }

  void _showLevelComplete() {
    _showReward = true;
    _rewardMessage = '🎉 Level Complete!\nYou learned $_levelSize letters!';
    setState(() {});

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      _showReward = false;
      _currentLevel++;
      _loadNextLevel();
      setState(() {});
    });
  }

  void _showCompletion() {
    _phase = GamePhase.complete;
    _showReward = true;
    _rewardMessage = '🎉 You did it!\nAll letters mastered!';
    setState(() {});
  }

  void _onHint() {
    if (_phase != GamePhase.playing) return;
    _hintActive = true;
    _audio.speakEnglish('Look for ${_currentTarget!.letter}');
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
    _spawnTimer?.cancel();
    _floatTimer?.cancel();
    _bgController.dispose();
    _audio.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: () {
          if (_phase == GamePhase.complete) {
            Navigator.of(context).pop();
          }
        },
        child: Container(
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGameArea() {
    return Stack(
      children: [
        ..._bubbles.map((b) => BubbleWidget(
              key: ValueKey('${b.letter.letter}_${b.x}_${b.y}'),
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
              icon: const Icon(Icons.arrow_back, size: 32, color: AppColors.textDark),
              onPressed: () => Navigator.of(context).pop(),
            ),
            const Spacer(),
            _buildStarDisplay(),
            const SizedBox(width: 8),
            _buildStreakDisplay(),
            const SizedBox(width: 8),
            _buildLevelBadge(),
          ],
        ),
      ),
    );
  }

  Widget _buildStarDisplay() {
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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('⭐', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 4),
          Text(
            '$_stars',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakDisplay() {
    if (_streak < 2) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.orange.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🔥', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 4),
          Text(
            '$_streak',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'Level ${_currentLevel + 1}',
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
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
              child: Transform.scale(
                scale: value,
                child: child,
              ),
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
                'Find this letter!',
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
            const Text(
              '🎉',
              style: TextStyle(fontSize: 80),
            ),
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
                color: Colors.white70,
              ),
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

class _BubbleData {
  final BubbleLetter letter;
  double x;
  double y;
  final Color color;
  final bool isTarget;

  _BubbleData({
    required this.letter,
    required this.x,
    required this.y,
    required this.color,
    required this.isTarget,
  });
}
