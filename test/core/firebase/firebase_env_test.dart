import 'package:delnono/core/firebase/firebase_init.dart';
import 'package:delnono/core/firebase/firebase_options_prod.dart';
import 'package:flutter_test/flutter_test.dart';

// Development and tests must never reach the real project (see firebase_init.dart).
void main() {
  test('the default build uses the emulator-only demo project', () {
    expect(firebaseEnv, 'demo');
    expect(useProdFirebase, isFalse);
    expect(firebaseOptions.projectId, 'demo-delnono');
  });

  test('prod options point at dr-elnono-clinic with the eg.drelnono.app apps', () {
    expect(ProdFirebaseOptions.android.projectId, 'dr-elnono-clinic');
    expect(ProdFirebaseOptions.ios.projectId, 'dr-elnono-clinic');
    expect(ProdFirebaseOptions.ios.iosBundleId, 'eg.drelnono.app');
    expect(ProdFirebaseOptions.android.appId, startsWith('1:689130598694:android:'));
  });
}
