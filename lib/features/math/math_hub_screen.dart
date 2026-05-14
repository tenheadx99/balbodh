import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../models/bubble_letter.dart';
import '../../models/number_letter.dart';
import '../../services/streak_service.dart';
import '../abc/bubble_pop_game.dart';
import 'counting_game.dart';
import 'trace_game.dart';
import 'addition_game.dart';

class MathHubScreen extends StatelessWidget {
  const MathHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF81C784), Color(0xFFC8E6C9)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 24),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back,
                          size: 32, color: AppColors.textDark),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const Spacer(),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  '🔢',
                  style: TextStyle(fontSize: 64),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Math Fun',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Counting, tracing & adding',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textDark.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 40),
                Expanded(
                  child: ListView(
                    children: [
                      _GameCard(
                        emoji: '🍎',
                        title: 'Fruit Counting',
                        subtitle: 'Count and tap the right number',
                        color: const Color(0xFFFF8C42),
                        onTap: () => _openGame(
                            context, const CountingGame()),
                      ),
                      const SizedBox(height: 16),
                      _GameCard(
                        emoji: '✏️',
                        title: 'Number Tracing',
                        subtitle: 'Trace numbers 1 to 20',
                        color: const Color(0xFF6C5CE7),
                        onTap: () => _openGame(
                            context, const TraceGame()),
                      ),
                      const SizedBox(height: 16),
                      _GameCard(
                        emoji: '➕',
                        title: 'Addition Fun',
                        subtitle: 'Add two groups of objects',
                        color: const Color(0xFFE91E63),
                        onTap: () => _openGame(
                            context, const AdditionGame()),
                      ),
                      const SizedBox(height: 16),
                      _GameCard(
                        emoji: '🔵',
                        title: 'Number Pop',
                        subtitle: 'Pop bubbles with numbers 1-20',
                        color: const Color(0xFF00BCD4),
                        onTap: () {
                          StreakService().markToday();
                          _openGame(
                            context,
                            BubblePopGame(
                              module: ModuleType.math,
                              customLetters: NumberLetter.numbers1to20,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openGame(BuildContext context, Widget game) {
    StreakService().markToday();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => game),
    );
  }
}

class _GameCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _GameCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 48)),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textDark.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios,
                color: AppColors.textDark),
          ],
        ),
      ),
    );
  }
}
