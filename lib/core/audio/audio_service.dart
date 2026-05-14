import 'package:flutter_tts/flutter_tts.dart';

class AudioService {
  final FlutterTts _tts = FlutterTts();
  bool _initialized = false;

  AudioService() {
    _init();
  }

  Future<void> _init() async {
    await _tts.setLanguage('hi-IN');
    await _tts.setSpeechRate(0.4);
    await _tts.setPitch(1.3);
    await _tts.setVolume(1.0);
    _initialized = true;
  }

  Future<void> speak(String text, {String language = 'hi-IN'}) async {
    if (!_initialized) await _init();
    await _tts.setLanguage(language);
    await _tts.speak(text);
  }

  Future<void> speakEnglish(String text) async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.45);
    await _tts.speak(text);
  }

  Future<void> speakHindi(String text) async {
    await _tts.setLanguage('hi-IN');
    await _tts.setSpeechRate(0.4);
    await _tts.speak(text);
  }

  Future<void> playLetterSound(String letter, String module) async {
    if (module == 'hindi') {
      await speakHindi(letter);
    } else {
      await speakEnglish(letter);
    }
  }

  Future<void> playEncouragement() async {
    final messages = [
      'Great job!',
      'Amazing!',
      'Wonderful!',
      'Super!',
      'Fantastic!',
    ];
    final index = DateTime.now().millisecondsSinceEpoch % messages.length;
    await speakEnglish(messages[index]);
  }

  Future<void> playTryAgain() async {
    await speakEnglish('Try again!');
  }

  Future<void> dispose() {
    return _tts.stop();
  }
}
