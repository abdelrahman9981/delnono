import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

/// Like test_driver/integration_test.dart, and saves screenshots the test takes (run with
/// `--dart-define=SCREENSHOTS=true`) to `build/screenshots/NAME.png`.
Future<void> main() => integrationDriver(
      onScreenshot: (name, bytes, [args]) async {
        final file = File('build/screenshots/$name.png');
        file.parent.createSync(recursive: true);
        file.writeAsBytesSync(bytes);
        return true;
      },
    );
