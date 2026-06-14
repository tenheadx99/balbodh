import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app.dart';
import 'firebase_options.dart';
import 'services/progress_service.dart';
import 'services/remote_config_service.dart';
import 'services/settings_service.dart';
import 'services/streak_service.dart';
import 'services/usage_service.dart';
import 'core/audio/sound_effect_service.dart';
import 'services/ad_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  await ProgressService().init();
  await SettingsService().init();
  await SoundEffectService().init();
  await StreakService().init();
  await UsageService().init();

  // Firebase + Remote Config drive the ad kill-switch. Both are guarded:
  // if Firebase isn't configured yet, ads fail open (stay enabled).
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase init skipped: $e');
  }
  await RemoteConfigService().init();

  await AdService().init();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
    ),
  );
  runApp(BalBodhApp());
}
