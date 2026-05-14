import 'package:flutter_tts/flutter_tts.dart';
import '../../services/settings_service.dart';
import 'hindi_voice_data.dart';

class AudioService {
  final FlutterTts _tts = FlutterTts();
  bool _initialized = false;

  AudioService() {
    _init();
  }

  Future<void> _init() async {
    await _tts.setSpeechRate(0.4);
    await _tts.setPitch(1.3);
    await _tts.setVolume(1.0);
    _initialized = true;
  }

  Future<void> _ensureInit() async {
    if (!_initialized) await _init();
  }

  Future<void> speak(String text, {String language = 'hi-IN'}) async {
    await _ensureInit();
    if (!SettingsService().soundEnabled) return;
    await _tts.setLanguage(language);
    await _tts.speak(text);
  }

  Future<void> speakEnglish(String text) async {
    if (!SettingsService().soundEnabled) return;
    await _ensureInit();
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.45);
    await _tts.speak(text);
  }

  Future<void> speakHindi(String text) async {
    if (!SettingsService().soundEnabled) return;
    if (!SettingsService().hindiVoiceEnabled) {
      await speakEnglish(text);
      return;
    }
    await _ensureInit();
    await _tts.setLanguage('hi-IN');
    await _tts.setSpeechRate(0.4);
    await _tts.speak(text);
  }

  Future<void> playLetterSound(String letter, String module) async {
    if (module == 'hindi') {
      final sound = HindiVoiceData.letterSounds[letter] ?? letter;
      await speakHindi(sound);
    } else {
      await speakEnglish(letter);
    }
  }

  Future<void> playLetterWithObject(String letter, String module) async {
    if (module == 'hindi') {
      final object = HindiVoiceData.objectNames[letter] ?? '';
      await speakHindi('$letter for $object');
    } else {
      await speakEnglish(letter);
    }
  }

  Future<void> playEncouragement({bool hindi = false}) async {
    if (hindi && SettingsService().hindiVoiceEnabled) {
      final messages = HindiVoiceData.encouragements;
      final index = DateTime.now().millisecondsSinceEpoch % messages.length;
      await speakHindi(messages[index]);
    } else {
      final messages = [
        'Great job!', 'Amazing!', 'Wonderful!',
        'Super!', 'Fantastic!', 'Awesome!',
      ];
      final index = DateTime.now().millisecondsSinceEpoch % messages.length;
      await speakEnglish(messages[index]);
    }
  }

  Future<void> playTryAgain({bool hindi = false}) async {
    if (hindi && SettingsService().hindiVoiceEnabled) {
      final messages = HindiVoiceData.tryAgainMessages;
      final index = DateTime.now().millisecondsSinceEpoch % messages.length;
      await speakHindi(messages[index]);
    } else {
      await speakEnglish('Try again!');
    }
  }

  Future<void> playNumber(int number, {bool hindi = false}) async {
    if (hindi && SettingsService().hindiVoiceEnabled) {
      if (number >= 0 && number < HindiVoiceData.numberNames.length) {
        await speakHindi(HindiVoiceData.numberNames[number]);
      }
    } else {
      await speakEnglish('$number');
    }
  }

  Future<void> playCount(int count, {bool hindi = false}) async {
    final noun = count == 1 ? 'object' : 'objects';
    if (hindi && SettingsService().hindiVoiceEnabled) {
      await speakHindi('${HindiVoiceData.numberNames[count]} चीज़ें');
    } else {
      await speakEnglish('$count $noun');
    }
  }

  Future<void> dispose() {
    return _tts.stop();
  }
}
