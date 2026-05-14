import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../services/streak_service.dart';

class DailyStreakScreen extends StatefulWidget {
  const DailyStreakScreen({super.key});

  @override
  State<DailyStreakScreen> createState() => _DailyStreakScreenState();
}

class _DailyStreakScreenState extends State<DailyStreakScreen> {
  final StreakService _streak = StreakService();
  late DateTime _currentMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _currentMonth = DateTime(now.year, now.month, 1);
  }

  void _prevMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final canGoNext = _currentMonth.year < now.year ||
        (_currentMonth.year == now.year && _currentMonth.month < now.month);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFB39DDB), Color(0xFFD1C4E9)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 8),
              _buildStreakStats(),
              const SizedBox(height: 16),
              _buildMonthNav(canGoNext),
              const SizedBox(height: 8),
              _buildCalendar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
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
          const Text(
            '📅 Daily Streak',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: AppColors.textDark,
            ),
          ),
          const Spacer(),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildStreakStats() {
    final streak = _streak.currentStreak;
    final total = _streak.totalDaysPlayed;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: _statCard('🔥 $streak', 'Day Streak', AppColors.orange),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _statCard('📆 $total', 'Total Days', AppColors.secondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _statCard(
              _streak.isPlayedToday ? '✅' : '❌',
              'Today',
              _streak.isPlayedToday ? AppColors.success : AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textDark.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthNav(bool canGoNext) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left,
                size: 36, color: AppColors.textDark),
            onPressed: _currentMonth.month > 1 || _currentMonth.year > 2020
                ? _prevMonth
                : null,
          ),
          Text(
            '${months[_currentMonth.month - 1]} ${_currentMonth.year}',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
          IconButton(
            icon: Icon(Icons.chevron_right,
                size: 36,
                color: canGoNext
                    ? AppColors.textDark
                    : AppColors.textDark.withValues(alpha: 0.2)),
            onPressed: canGoNext ? _nextMonth : null,
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    final daysInMonth = _streak.daysInMonth(
        _currentMonth.year, _currentMonth.month);
    final firstWeekday =
        DateTime(_currentMonth.year, _currentMonth.month, 1).weekday;
    final dayNames = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(24),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: dayNames
                    .map((d) => SizedBox(
                          width: 36,
                          child: Text(
                            d,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark.withValues(alpha: 0.6),
                            ),
                          ),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 7,
                  physics: const NeverScrollableScrollPhysics(),
                  children: List.generate(
                    firstWeekday - 1 + daysInMonth,
                    (i) {
                      if (i < firstWeekday - 1) {
                        return const SizedBox.shrink();
                      }
                      final day = i - firstWeekday + 2;
                      final date = DateTime(_currentMonth.year,
                          _currentMonth.month, day);
                      final isPlayed = _streak.isDatePlayed(date);
                      final isToday = _isToday(date);

                      return _dayCell(day, isPlayed, isToday);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dayCell(int day, bool isPlayed, bool isToday) {
    final bgColor = isPlayed
        ? AppColors.success
        : isToday
            ? AppColors.warning.withValues(alpha: 0.6)
            : Colors.transparent;

    return Container(
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        border: isToday && !isPlayed
            ? Border.all(color: AppColors.warning, width: 2)
            : null,
      ),
      child: Center(
        child: Text(
          '$day',
          style: TextStyle(
            fontSize: 14,
            fontWeight: isPlayed || isToday ? FontWeight.w800 : FontWeight.w500,
            color: isPlayed
                ? Colors.white
                : AppColors.textDark.withValues(alpha: 0.8),
          ),
        ),
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}
