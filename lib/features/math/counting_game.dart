import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/audio/audio_service.dart';
import '../../core/audio/sound_effect_service.dart';
import '../../games/reward_overlay.dart';
import '../../models/math_question.dart';
import '../../services/progress_service.dart';

class CountingGame extends StatefulWidget {
  const CountingGame({super.key});

  @override
  State<CountingGame> createState() => _CountingGameState();
}

class _CountingGameState extends State<CountingGame> {
  final AudioService _audio = AudioService();
  final SoundEffectService _sfx = SoundEffectService();
  final ProgressService _progress = ProgressService();
  final Random _random = Random();

  int _level = 1;
  int _stars = 0;
  int _streak = 0;
  int _correctCount = 0;
  int _maxNumber = 5;

  MathQuestion? _current;
  int? _selectedOption;
  bool _showReward = false;
  String _rewardMessage = '';

  @override
  void initState() {
    super.initState();
    _nextQuestion();
  }

  void _nextQuestion() {
    _maxNumber = _level <= 2 ? 5 : (_level <= 4 ? 10 : 20);
    _current = MathQuestion.generateCounting(_maxNumber, _random);
    _selectedOption = null;
    setState(() {});
  }

  void _onSelectOption(int value) {
    if (_selectedOption != null || _current == null) return;

    _selectedOption = value;
    setState(() {});

    if (value == _current!.correctAnswer) {
      _streak++;
      _stars++;
      _correctCount++;
      _progress.addStar('math');
      _sfx.playCorrect();
      _audio.speakEnglish('Correct! ${_current!.correctAnswer}!');

      if (_streak >= 3) {
        _rewardMessage = '🔥 Amazing streak!';
        _stars++;
        _progress.addStar('math');
        _sfx.playStreak();
      } else {
        _rewardMessage = '⭐ Great!';
        _sfx.playStar();
      }

      _showReward = true;
      setState(() {});

      Future.delayed(const Duration(seconds: 1), () {
        if (!mounted) return;
        _showReward = false;
        if (_correctCount >= 5) {
          _correctCount = 0;
          _level++;
        }
        _nextQuestion();
      });
    } else {
      _streak = 0;
      _sfx.playWrong();
      _audio.playTryAgain();
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) {
          _selectedOption = null;
          setState(() {});
        }
      });
    }
  }

  @override
  void dispose() {
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
            colors: [Color(0xFFFFF9C4), Color(0xFFFFF3E0)],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  _buildTopBar(),
                  _buildQuestion(),
                  _buildObjectDisplay(),
                  const Spacer(),
                  _buildOptionsGrid(),
                  const SizedBox(height: 30),
                ],
              ),
              if (_showReward)
                RewardOverlay(
                  message: _rewardMessage,
                  showConfetti: _streak >= 3,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back,
                size: 32, color: AppColors.textDark),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const Spacer(),
          _buildBadge('Level $_level', AppColors.secondary),
          const SizedBox(width: 8),
          _buildStarBadge(),
          if (_streak >= 2) ...[
            const SizedBox(width: 8),
            _buildBadge('🔥 $_streak', AppColors.orange),
          ],
        ],
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildStarBadge() {
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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('⭐', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 4),
          Text(
            '$_stars',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestion() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(
        _current?.question ?? '',
        style: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          color: AppColors.textDark,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildObjectDisplay() {
    if (_current == null) return const SizedBox.shrink();

    final emoji = _current!.emoji;
    final count = _current!.count;
    const double itemSize = 48;

    return SizedBox(
      height: 160,
      child: Center(
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: List.generate(count, (i) {
            final delay = i * 50;
            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: Duration(milliseconds: 300 + delay),
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.scale(
                    scale: value,
                    child: child,
                  ),
                );
              },
              child: Text(emoji, style: const TextStyle(fontSize: itemSize)),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildOptionsGrid() {
    if (_current == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 2,
        children: _current!.options.map((option) {
          final isSelected = _selectedOption == option;
          final isCorrect = isSelected && option == _current!.correctAnswer;
          final isWrong = isSelected && option != _current!.correctAnswer;

          Color bgColor = AppColors.cardBg;
          if (isCorrect) bgColor = AppColors.success;
          if (isWrong) bgColor = AppColors.primary;

          return GestureDetector(
            onTap: () => _onSelectOption(option),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: isSelected ? 8 : 4,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: isCorrect
                    ? Border.all(color: Colors.green, width: 3)
                    : isWrong
                        ? Border.all(color: Colors.red, width: 3)
                        : null,
              ),
              child: Center(
                child: Text(
                  '$option',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: isSelected
                        ? Colors.white
                        : AppColors.textDark,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
