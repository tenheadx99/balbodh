import 'dart:io';
import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() async {
  await integrationDriver(
    onScreenshot: (String screenshotName, List<int> screenshotBytes, [Map<String, Object?>? args]) async {
      final locales = ["en-US", "de-DE", "es-ES", "fr-FR", "hi-IN"];
      for (final locale in locales) {
        final File image = await File('screenshots/$locale/$screenshotName.png').create(recursive: true);
        await image.writeAsBytes(screenshotBytes);
        print('Saved screenshot: screenshots/$locale/$screenshotName.png');
      }
      return true;
    },
  );
}
