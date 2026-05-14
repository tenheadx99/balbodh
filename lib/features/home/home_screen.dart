import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../models/bubble_letter.dart';
import '../../services/progress_service.dart';
import '../abc/bubble_pop_game.dart';
import '../math/math_hub_screen.dart';
import '../stickers/sticker_book_screen.dart';
import '../dashboard/parent_dashboard.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends StatelessWidget {
  final ProgressService _progress = ProgressService();
  HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.backgroundStart, AppColors.backgroundEnd],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 24),
                Stack(
                  children: [
                    Center(
                      child: Column(
                        children: [
                          const Text(
                            'बालबोध',
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textDark,
                            ),
                          ),
                          const Text(
                            'BalBodh',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w400,
                              color: AppColors.textDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => SettingsScreen(),
                              ),
                            ),
                            child: Container(
                              width: 44,
                              height: 44,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.8),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Center(
                                child: Icon(Icons.settings,
                                    color: AppColors.textDark, size: 22),
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ParentDashboard(
                                    progressService: _progress),
                              ),
                            ),
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.8),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Center(
                                child: Icon(Icons.admin_panel_settings,
                                    color: AppColors.textDark, size: 22),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Learn through play!',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textDark.withValues(alpha: 0.7),
                      ),
                ),
                const SizedBox(height: 32),
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 20,
                    crossAxisSpacing: 20,
                    childAspectRatio: 0.85,
                    children: [
                      _ModuleCard(
                        emoji: '🔤',
                        title: 'ABC',
                        subtitle: 'English Letters',
                        color: AppColors.primary,
                        onTap: () => _startGame(context, ModuleType.abc),
                      ),
                      _ModuleCard(
                        emoji: '🕉️',
                        title: 'अ आ इ',
                        subtitle: 'हिंदी वर्णमाला',
                        color: AppColors.accent,
                        onTap: () => _startGame(context, ModuleType.hindi),
                      ),
                      _ModuleCard(
                        emoji: '🔢',
                        title: '1 2 3',
                        subtitle: 'Counting & Math',
                        color: AppColors.success,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const MathHubScreen(),
                          ),
                        ),
                      ),
                      _ModuleCard(
                        emoji: '⭐',
                        title: 'Stickers',
                        subtitle: 'My Rewards',
                        color: AppColors.warning,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => StickerBookScreen(
                                progressService: _progress),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _startGame(BuildContext context, ModuleType module) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BubblePopGame(module: module),
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ModuleCard({
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              emoji,
              style: const TextStyle(fontSize: 56),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textDark.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
