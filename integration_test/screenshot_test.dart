import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:integration_test/integration_test.dart';

import 'package:balbodh/app.dart';
import 'package:balbodh/services/progress_service.dart';
import 'package:balbodh/services/settings_service.dart';
import 'package:balbodh/services/streak_service.dart';
import 'package:balbodh/core/audio/sound_effect_service.dart';
import 'package:balbodh/services/ad_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await Hive.initFlutter();
    await ProgressService().init();
    await SettingsService().init();
    await SoundEffectService().init();
    await StreakService().init();
    await AdService().init();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
  });

  testWidgets('App smoke test - verify screens render', (tester) async {
    await tester.pumpWidget(const BalBodhApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('बालबोध'), findsOneWidget);
  }, timeout: const Timeout(Duration(seconds: 30)));
}
