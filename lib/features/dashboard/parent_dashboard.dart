import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../models/bubble_letter.dart';
import '../../models/game_progress.dart';
import '../../models/sticker.dart';
import '../../services/progress_service.dart';
import '../../services/usage_service.dart';

class ParentDashboard extends StatelessWidget {
  final ProgressService progressService;

  const ParentDashboard({super.key, required this.progressService});

  @override
  Widget build(BuildContext context) {
    final abcProgress = progressService.getOrCreate('abc');
    final hindiProgress = progressService.getOrCreate('hindi');
    final mathProgress = progressService.getOrCreate('math');

    final totalStars = progressService.totalStarsAcrossModules;
    final abcMastered = abcProgress.masteredCount;
    final hindiMastered = hindiProgress.masteredCount;
    final totalAbc = BubbleLetter.abcLetters.length;
    final totalHindi = BubbleLetter.hindiLetters.length;
    final collectedStickers = Sticker.all
        .where((s) => totalStars >= s.starsRequired)
        .length;
    final totalStickers = Sticker.all.length;

    final abcPercent = totalAbc > 0 ? abcMastered / totalAbc : 0.0;
    final hindiPercent = totalHindi > 0 ? hindiMastered / totalHindi : 0.0;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE8EAF6), Color(0xFFC5CAE9)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                const SizedBox(height: 24),
                _buildSummaryCards(totalStars, collectedStickers,
                    totalStickers),
                const SizedBox(height: 24),
                _buildSectionTitle('⏱️ Screen Time'),
                const SizedBox(height: 12),
                const _ScreenTimeCard(),
                const SizedBox(height: 24),
                _buildSectionTitle('📚 Letters Progress'),
                const SizedBox(height: 12),
                _buildProgressCard(
                  icon: '🔤',
                  title: 'English Alphabet',
                  mastered: abcMastered,
                  total: totalAbc,
                  percent: abcPercent,
                  color: AppColors.primary,
                  details: abcProgress.masteredLetters.toList(),
                ),
                const SizedBox(height: 12),
                _buildProgressCard(
                  icon: '🕉️',
                  title: 'हिंदी वर्णमाला',
                  mastered: hindiMastered,
                  total: totalHindi,
                  percent: hindiPercent,
                  color: AppColors.accent,
                  details: hindiProgress.masteredLetters.toList(),
                ),
                const SizedBox(height: 12),
                _buildSectionTitle('🔢 Math Progress'),
                const SizedBox(height: 12),
                _buildMathCard(mathProgress),
                const SizedBox(height: 24),
                _buildSectionTitle('⭐ Recent Activity'),
                const SizedBox(height: 12),
                _buildActivityList(),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Center(
            child: Icon(Icons.admin_panel_settings,
                color: Colors.white, size: 28),
          ),
        ),
        const SizedBox(width: 16),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Parent Dashboard',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
            Text(
              'Learning progress at a glance',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.close, size: 28, color: AppColors.textDark),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  Widget _buildSummaryCards(
      int totalStars, int collectedStickers, int totalStickers) {
    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            emoji: '⭐',
            value: '$totalStars',
            label: 'Stars',
            color: AppColors.warning,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            emoji: '🎯',
            value: '$collectedStickers/$totalStickers',
            label: 'Stickers',
            color: AppColors.secondary,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: AppColors.textDark,
      ),
    );
  }

  Widget _buildProgressCard({
    required String icon,
    required String title,
    required int mastered,
    required int total,
    required double percent,
    required Color color,
    required List<String> details,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    Text(
                      '$mastered of $total letters mastered',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textDark.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${(percent * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: percent,
              backgroundColor: Colors.grey.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 10,
            ),
          ),
          if (details.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Mastered: ${details.take(10).join(", ")}${details.length > 10 ? "..." : ""}',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textDark.withValues(alpha: 0.5),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMathCard(GameProgress mathProgress) {
    final stars = mathProgress.totalStars;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Text('🔢', style: TextStyle(fontSize: 32)),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Math Games',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                Text(
                  'Counting • Tracing • Addition',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('⭐', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 4),
                Text(
                  '$stars',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityList() {
    final abcProgress = progressService.getOrCreate('abc');
    final hindiProgress = progressService.getOrCreate('hindi');

    final items = <_ActivityItem>[];

    if (abcProgress.masteredCount > 0) {
      items.add(_ActivityItem(
        emoji: '🔤',
        text: 'Learned ${abcProgress.masteredCount} English letters',
        stars: abcProgress.totalStars,
      ));
    }
    if (hindiProgress.masteredCount > 0) {
      items.add(_ActivityItem(
        emoji: '🕉️',
        text: 'Learned ${hindiProgress.masteredCount} Hindi letters',
        stars: hindiProgress.totalStars,
      ));
    }

    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Center(
          child: Text(
            'No activity yet. Start playing! 🎮',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textDark,
            ),
          ),
        ),
      );
    }

    return Column(
      children: items.map((item) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Text(item.emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item.text,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textDark,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '⭐ ${item.stars}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String emoji;
  final String value;
  final String label;
  final Color color;

  const _SummaryCard({
    required this.emoji,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 36)),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textDark.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScreenTimeCard extends StatefulWidget {
  const _ScreenTimeCard();

  @override
  State<_ScreenTimeCard> createState() => _ScreenTimeCardState();
}

class _ScreenTimeCardState extends State<_ScreenTimeCard> {
  final UsageService _usage = UsageService();

  static const _options = [0, 15, 30, 45, 60, 90];

  @override
  void initState() {
    super.initState();
    _usage.addListener(_onChanged);
  }

  @override
  void dispose() {
    _usage.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final limit = _usage.dailyLimitMinutes;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('⏱️', style: TextStyle(fontSize: 32)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Daily Limit',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    Text(
                      'Played today: ${_usage.usedMinutesToday} min',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textDark.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _options.map((minutes) {
              final selected = minutes == limit;
              return ChoiceChip(
                label: Text(minutes == 0 ? 'Off' : '$minutes min'),
                selected: selected,
                selectedColor: AppColors.primary.withValues(alpha: 0.2),
                onSelected: (_) => _usage.setDailyLimitMinutes(minutes),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          Text(
            'When the limit is reached, a break screen appears. '
            'Only a parent can add more time.',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textDark.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityItem {
  final String emoji;
  final String text;
  final int stars;

  _ActivityItem({
    required this.emoji,
    required this.text,
    required this.stars,
  });
}
