import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Tracks how long the app is used each day and enforces an optional
/// daily screen-time limit set from the Parent Dashboard.
class UsageService extends ChangeNotifier {
  static final UsageService _instance = UsageService._internal();
  factory UsageService() => _instance;
  UsageService._internal();

  static const String _boxName = 'usage';
  static const Duration _tick = Duration(seconds: 15);

  late Box _box;
  Timer? _timer;
  bool _loaded = false;

  Future<void> init() async {
    if (_loaded) return;
    _box = await Hive.openBox(_boxName);
    _loaded = true;
    resume();
  }

  String get _todayKey {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// 0 means no limit.
  int get dailyLimitMinutes =>
      _loaded ? _box.get('dailyLimitMinutes', defaultValue: 0) : 0;

  bool get limitEnabled => dailyLimitMinutes > 0;

  int get _usedSecondsToday =>
      _loaded ? _box.get('used_$_todayKey', defaultValue: 0) : 0;

  int get _extraSecondsToday =>
      _loaded ? _box.get('extra_$_todayKey', defaultValue: 0) : 0;

  bool get _pausedForToday =>
      _loaded && _box.get('off_$_todayKey', defaultValue: false);

  int get usedMinutesToday => _usedSecondsToday ~/ 60;

  bool get limitReached =>
      limitEnabled &&
      !_pausedForToday &&
      _usedSecondsToday >= dailyLimitMinutes * 60 + _extraSecondsToday;

  Future<void> setDailyLimitMinutes(int minutes) async {
    if (!_loaded) return;
    await _box.put('dailyLimitMinutes', minutes);
    notifyListeners();
  }

  /// Lets a parent extend today's play after the limit is reached.
  Future<void> grantExtraMinutes(int minutes) async {
    if (!_loaded) return;
    await _box.put('extra_$_todayKey', _extraSecondsToday + minutes * 60);
    notifyListeners();
  }

  /// Suspends the limit until tomorrow without changing the setting.
  Future<void> disableForToday() async {
    if (!_loaded) return;
    await _box.put('off_$_todayKey', true);
    notifyListeners();
  }

  /// Starts counting foreground time. Safe to call repeatedly.
  void resume() {
    if (!_loaded) return;
    _timer ??= Timer.periodic(_tick, (_) => _accumulate());
  }

  /// Stops counting while the app is backgrounded.
  void pause() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _accumulate() async {
    if (!_loaded) return;
    await _box.put('used_$_todayKey', _usedSecondsToday + _tick.inSeconds);
    notifyListeners();
  }
}
