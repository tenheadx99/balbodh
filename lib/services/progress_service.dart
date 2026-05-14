import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/game_progress.dart';

class ProgressService {
  static final ProgressService _instance = ProgressService._internal();
  factory ProgressService() => _instance;
  ProgressService._internal();

  late Box _progressBox;
  static const String _boxName = 'progress';

  final Map<String, GameProgress> _cache = {};
  bool _loaded = false;

  Future<void> init() async {
    if (_loaded) return;
    _progressBox = await Hive.openBox(_boxName);
    _loadFromHive();
    _loaded = true;
  }

  void _loadFromHive() {
    final keys = _progressBox.keys.cast<String>();
    for (final key in keys) {
      final raw = _progressBox.get(key) as String?;
      if (raw != null) {
        try {
          final json = jsonDecode(raw) as Map<String, dynamic>;
          _cache[key] = GameProgress.fromJson(json);
        } catch (_) {}
      }
    }
  }

  Future<void> _saveToHive(String module) async {
    final progress = _cache[module];
    if (progress != null) {
      await _progressBox.put(module, jsonEncode(progress.toJson()));
    }
  }

  GameProgress getOrCreate(String module) {
    if (!_cache.containsKey(module)) {
      _cache[module] = GameProgress(module: module);
    }
    return _cache[module]!;
  }

  void recordAttempt(String module, String letter, bool correct) {
    final progress = getOrCreate(module);
    progress.recordAttempt(letter, correct);
    _saveToHive(module);
  }

  void addStar(String module) {
    getOrCreate(module).addStar();
    _saveToHive(module);
  }

  int getStars(String module) => getOrCreate(module).totalStars;
  int getMasteredCount(String module) => getOrCreate(module).masteredCount;

  int get totalStarsAcrossModules =>
      _cache.values.fold(0, (sum, p) => sum + p.totalStars);

  List<MapEntry<String, int>> get moduleStars =>
      _cache.entries.map((e) => MapEntry(e.key, e.value.totalStars)).toList();

  Future<void> resetAll() async {
    _cache.clear();
    await _progressBox.clear();
  }
}
