import 'package:hive_flutter/hive_flutter.dart';

class StreakService {
  static final StreakService _instance = StreakService._internal();
  factory StreakService() => _instance;
  StreakService._internal();

  late Box _streakBox;
  static const String _boxName = 'streak';

  bool _loaded = false;

  Future<void> init() async {
    if (_loaded) return;
    _streakBox = await Hive.openBox(_boxName);
    _loaded = true;
  }

  Set<String> get _dates {
    final raw = _streakBox.get('dates', defaultValue: <String>[]) as List;
    return raw.cast<String>().toSet();
  }

  Future<void> markToday() async {
    final today = _todayKey();
    final dates = _dates;
    if (dates.add(today)) {
      await _streakBox.put('dates', dates.toList());
    }
  }

  bool get isPlayedToday {
    return _dates.contains(_todayKey());
  }

  bool isDatePlayed(DateTime date) {
    final key = _dateKey(date);
    return _dates.contains(key);
  }

  int get currentStreak {
    final dates = _dates.map(_parseDate).where((d) => d != null).cast<DateTime>().toList()
      ..sort((a, b) => b.compareTo(a));

    if (dates.isEmpty) return 0;

    int streak = 0;
    final today = DateTime.now();
    var checkDate = DateTime(today.year, today.month, today.day);

    for (final d in dates) {
      final normalized = DateTime(d.year, d.month, d.day);
      if (normalized == checkDate) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else if (normalized == checkDate.add(const Duration(days: 1))) {
        continue;
      } else {
        break;
      }
    }
    return streak;
  }

  int get totalDaysPlayed => _dates.length;

  List<DateTime> get allDates {
    return _dates
        .map(_parseDate)
        .where((d) => d != null)
        .cast<DateTime>()
        .toList()
      ..sort();
  }

  int daysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  String _todayKey() => _dateKey(DateTime.now());
  String _dateKey(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  DateTime? _parseDate(String key) {
    try {
      final parts = key.split('-');
      return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
    } catch (_) {
      return null;
    }
  }
}
