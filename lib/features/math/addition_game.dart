import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/audio/audio_service.dart';
import '../../games/reward_overlay.dart';
import '../../models/math_question.dart';

class AdditionGame extends StatefulWidget {
  const AdditionGame({super.key});

  @override
  State<AdditionGame> createState() => _AdditionGameState();
}

class _AdditionGameState extends State<AdditionGame> {
  final AudioService _audio = AudioService();
  final Random _random = Random();

  int _stars = 0;
  int _streak = 0;
  int _correctCount = 0;
  int _level = 1;
  int _maxSum = 5;

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
    _maxSum = _level <= 2 ? 5 : (_level <= 4 ? 10 : 15);
    _current = MathQuestion.generateAddition(_maxSum, _random);
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
      _audio.speakEnglish('Correct! ${_current!.correctAnswer}!');

      _rewardMessage = _streak >= 3 ? '🔥 Amazing!' : '⭐ Great!';
      if (_streak >= 3) _stars++;

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
    if (_current == null) return const SizedBox.shrink();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF8BBD0), Color(0xFFFCE4EC)],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  _buildTopBar(),
                  _buildQuestion(),
                  _buildVisualGroups(),
                  const SizedBox(height: 20),
                  _buildOptionsGrid(),
                  const Spacer(),
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
          _badge('Level $_level', AppColors.accent),
          const SizedBox(width: 8),
          _starBadge(),
          if (_streak >= 2) ...[
            const SizedBox(width: 8),
            _badge('🔥 $_streak', AppColors.orange),
          ],
        ],
      ),
    );
  }

  Widget _badge(String text, Color color) {
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

  Widget _starBadge() {
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
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Text(
        _current!.question,
        style: const TextStyle(
          fontSize: 40,
          fontWeight: FontWeight.w900,
          color: AppColors.textDark,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildVisualGroups() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          _objectRow('🍎', _current!.count),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('+', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900)),
          ),
          _objectRow('🍎', _current!.correctAnswer - _current!.count),
        ],
      ),
    );
  }

  Widget _objectRow(String emoji, int count) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 6,
      runSpacing: 6,
      children: List.generate(
        count,
        (_) => Text(emoji, style: const TextStyle(fontSize: 36)),
      ),
    );
  }

  Widget _buildOptionsGrid() {
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

          return GestureDetector(
            onTap: () => _onSelectOption(option),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              decoration: BoxDecoration(
                color: isCorrect
                    ? AppColors.success
                    : isWrong
                        ? AppColors.primary
                        : AppColors.cardBg,
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
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    color: isSelected ? Colors.white : AppColors.textDark,
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
