import 'package:delnono/core/firebase/firebase_init.dart';
import 'package:delnono/features/auth/data/dev_otp.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// D-51: without USE_EMULATOR (every release build, prod or not) there is no 123456 swap. The release
/// binaries are also checked for the resolver's strings (scripts/build_ios_release.sh,
/// scripts/build_web_demo.sh).
void main() {
  test('no dev code resolver outside emulator builds', () {
    expect(useEmulator, isFalse, reason: 'tests run like a release build here');
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(container.read(devCodeResolverProvider), isNull);
  });
}
