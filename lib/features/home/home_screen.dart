import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../models/bubble_letter.dart';
import '../../services/progress_service.dart';
import '../../services/settings_service.dart';
import '../../services/streak_service.dart';
import '../abc/bubble_pop_game.dart';
import '../math/math_hub_screen.dart';
import '../stickers/sticker_book_screen.dart';
import '../stickers/daily_streak_screen.dart';
import '../dashboard/parent_dashboard.dart';
import '../settings/settings_screen.dart';
import '../mascot/mascot_widget.dart';
import '../mascot/mascot_playroom_screen.dart';
import '../games/games_hub_screen.dart';
import '../../widgets/ad_banner_widget.dart';
import '../../widgets/rewarded_ad_button.dart';

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
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const MascotPlayroomScreen(),
                              ),
                            ),
                            child: MascotWidget(
                              avatar: SettingsService().avatar,
                              size: 44,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'बालबोध',
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.textDark,
                                  ),
                                ),
                                Text(
                                  'Learn through play!',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textDark.withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const DailyStreakScreen(),
                              ),
                            ),
                            child: Container(
                              width: 44,
                              height: 44,
                              margin: const EdgeInsets.only(right: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.8),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Center(
                                child: Text('🔥', style: TextStyle(fontSize: 22)),
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => SettingsScreen(),
                              ),
                            ),
                            child: Container(
                              width: 44,
                              height: 44,
                              margin: const EdgeInsets.only(right: 6),
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
                      const SizedBox(height: 16),
                      Expanded(
                        child: ListView(
                          children: [
                            GridView.count(
                              crossAxisCount: 2,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              mainAxisSpacing: 16,
                              crossAxisSpacing: 16,
                              childAspectRatio: 0.9,
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
                                  onTap: () {
                                    StreakService().markToday();
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => const MathHubScreen(),
                                      ),
                                    );
                                  },
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
                            const SizedBox(height: 12),
                            GestureDetector(
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const GamesHubScreen(),
                                ),
                              ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 16),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.orange.withValues(alpha: 0.8),
                                      AppColors.primary.withValues(alpha: 0.8),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.orange.withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Row(
                                  children: [
                                    Text('🎮', style: TextStyle(fontSize: 32)),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'More Fun Games',
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.w800,
                                              color: Colors.white,
                                            ),
                                          ),
                                          Text(
                                            'Letter Rain • Monster • Memory',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.white70,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(Icons.arrow_forward_ios,
                                        color: Colors.white, size: 20),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: RewardedAdButton(
                                emoji: '⭐',
                                label: 'Watch ad for a free star!',
                                subtitle: 'Supports the app & earns you rewards',
                                onRewarded: () {
                                  _progress.addStar('abc');
                                },
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const AdBannerWidget(),
              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
    );
  }

  void _startGame(BuildContext context, ModuleType module) {
    StreakService().markToday();
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
