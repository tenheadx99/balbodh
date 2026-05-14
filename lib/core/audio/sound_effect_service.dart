import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../services/settings_service.dart';

enum SoundEffect {
  pop,
  correct,
  wrong,
  starEarned,
  tap,
  fanfare,
  streak,
  pageFlip,
}

class SoundEffectService {
  static final SoundEffectService _instance = SoundEffectService._internal();
  factory SoundEffectService() => _instance;
  SoundEffectService._internal();

  final AudioPlayer _player = AudioPlayer();
  bool _initialized = false;

  static const Map<SoundEffect, String> _assetPaths = {
    SoundEffect.pop: 'sounds/pop.mp3',
    SoundEffect.correct: 'sounds/correct.mp3',
    SoundEffect.wrong: 'sounds/wrong.mp3',
    SoundEffect.starEarned: 'sounds/star.mp3',
    SoundEffect.tap: 'sounds/tap.mp3',
    SoundEffect.fanfare: 'sounds/fanfare.mp3',
    SoundEffect.streak: 'sounds/streak.mp3',
    SoundEffect.pageFlip: 'sounds/pageflip.mp3',
  };

  Future<void> init() async {
    _initialized = true;
  }

  Future<void> play(SoundEffect effect) async {
    if (!_initialized) await init();
    if (!SettingsService().soundEnabled) return;

    try {
      final path = _assetPaths[effect]!;
      final src = AssetSource(path);
      await _player.stop();
      await _player.play(src);
    } catch (_) {
      _playFallback(effect);
    }
  }

  void _playFallback(SoundEffect effect) {
    switch (effect) {
      case SoundEffect.tap:
      case SoundEffect.pop:
      case SoundEffect.pageFlip:
        HapticFeedback.lightImpact();
        break;
      case SoundEffect.correct:
      case SoundEffect.starEarned:
      case SoundEffect.streak:
      case SoundEffect.fanfare:
        HapticFeedback.heavyImpact();
        break;
      case SoundEffect.wrong:
        HapticFeedback.mediumImpact();
        break;
    }
  }

  Future<void> playCorrect() => play(SoundEffect.correct);
  Future<void> playWrong() => play(SoundEffect.wrong);
  Future<void> playPop() => play(SoundEffect.pop);
  Future<void> playStar() => play(SoundEffect.starEarned);
  Future<void> playTap() => play(SoundEffect.tap);
  Future<void> playFanfare() => play(SoundEffect.fanfare);
  Future<void> playStreak() => play(SoundEffect.streak);

  void dispose() {
    _player.dispose();
  }
}
