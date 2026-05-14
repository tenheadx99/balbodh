import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class SettingsService extends ChangeNotifier {
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  late Box _settingsBox;

  static const String _boxName = 'settings';

  bool _soundEnabled = true;
  bool _hindiVoiceEnabled = true;
  bool _darkMode = false;
  String _language = 'hindi';
  String _childName = '';
  String _avatar = '🐱';

  bool get soundEnabled => _soundEnabled;
  bool get hindiVoiceEnabled => _hindiVoiceEnabled;
  bool get darkMode => _darkMode;
  String get language => _language;
  String get childName => _childName;
  String get avatar => _avatar;

  Future<void> init() async {
    _settingsBox = await Hive.openBox(_boxName);
    _load();
  }

  void _load() {
    _soundEnabled = _settingsBox.get('soundEnabled', defaultValue: true);
    _hindiVoiceEnabled = _settingsBox.get('hindiVoiceEnabled', defaultValue: true);
    _darkMode = _settingsBox.get('darkMode', defaultValue: false);
    _language = _settingsBox.get('language', defaultValue: 'hindi');
    _childName = _settingsBox.get('childName', defaultValue: '');
    _avatar = _settingsBox.get('avatar', defaultValue: '🐱');
    notifyListeners();
  }

  Future<void> setSoundEnabled(bool value) async {
    _soundEnabled = value;
    await _settingsBox.put('soundEnabled', value);
    notifyListeners();
  }

  Future<void> setHindiVoiceEnabled(bool value) async {
    _hindiVoiceEnabled = value;
    await _settingsBox.put('hindiVoiceEnabled', value);
    notifyListeners();
  }

  Future<void> setDarkMode(bool value) async {
    _darkMode = value;
    await _settingsBox.put('darkMode', value);
    notifyListeners();
  }

  Future<void> setLanguage(String value) async {
    _language = value;
    await _settingsBox.put('language', value);
    notifyListeners();
  }

  Future<void> setChildName(String value) async {
    _childName = value;
    await _settingsBox.put('childName', value);
    notifyListeners();
  }

  Future<void> setAvatar(String value) async {
    _avatar = value;
    await _settingsBox.put('avatar', value);
    notifyListeners();
  }

  Future<void> resetAll() async {
    await _settingsBox.clear();
    _load();
  }
}
