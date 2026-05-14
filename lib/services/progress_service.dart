import '../models/game_progress.dart';

class ProgressService {
  static final ProgressService _instance = ProgressService._internal();
  factory ProgressService() => _instance;
  ProgressService._internal();

  final Map<String, GameProgress> _progress = {};

  GameProgress getOrCreate(String module) {
    if (!_progress.containsKey(module)) {
      _progress[module] = GameProgress(module: module);
    }
    return _progress[module]!;
  }

  void recordAttempt(String module, String letter, bool correct) {
    final progress = getOrCreate(module);
    progress.recordAttempt(letter, correct);
  }

  void addStar(String module) {
    getOrCreate(module).addStar();
  }

  int getStars(String module) => getOrCreate(module).totalStars;
  int getMasteredCount(String module) => getOrCreate(module).masteredCount;

  int get totalStarsAcrossModules =>
      _progress.values.fold(0, (sum, p) => sum + p.totalStars);

  List<MapEntry<String, int>> get moduleStars =>
      _progress.entries.map((e) => MapEntry(e.key, e.value.totalStars)).toList();
}
