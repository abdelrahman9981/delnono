import 'dart:async';

import 'package:delnono/core/firebase/firebase_init.dart';
import 'package:delnono/core/settings/settings_repository.dart';
import 'package:delnono/features/auth/application/otp_controller.dart';
import 'package:delnono/features/auth/data/dev_otp.dart';
import 'package:delnono/features/auth/data/phone_auth_service.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

const phone = '+201000000099';

/// A sign-in that never answers.
class _Silent extends FakePhoneAuthService {
  @override
  Future<void> signInWithCode(String verificationId, String smsCode) => Completer<void>().future;
}

class _Resolver implements DevCodeResolver {
  @override
  Future<String?> realCodeFor(String phoneE164) async => '654321';
}

ProviderContainer containerWith(PhoneAuthService service, {DevCodeResolver? resolver, bool overrideResolver = false}) {
  final c = ProviderContainer(overrides: [
    clockProvider.overrideWithValue(FakeClock().call),
    phoneAuthServiceProvider.overrideWithValue(service),
    authSettingsProvider.overrideWith((ref) => Stream.value(const AuthSettings())),
    if (overrideResolver) devCodeResolverProvider.overrideWithValue(resolver),
  ]);
  addTearDown(c.dispose);
  c.listen(authSettingsProvider, (_, _) {});
  return c;
}

void main() {
  test('a sign-in that never answers ends with an error after the timeout, never a spinner forever', () {
    fakeAsync((async) {
      final c = containerWith(_Silent());
      c.read(authSettingsProvider.future);
      async.flushMicrotasks();
      final otp = c.read(otpControllerProvider.notifier);
      otp.sendCode(phone);
      async.flushMicrotasks();
      otp.verify('123456');
      async.flushMicrotasks();
      expect(c.read(otpControllerProvider).phase, OtpPhase.verifying);
      async.elapse(verifyTimeout);
      final s = c.read(otpControllerProvider);
      expect(s.phase, OtpPhase.codeSent, reason: 'the guardian can try again');
      expect(s.error, isA<TimeoutException>());
    });
  });

  group('D-51 fixed code 123456', () {
    test('emulator builds: 123456 is replaced by the code the emulator issued', () async {
      final service = FakePhoneAuthService(validCode: '654321');
      final c = containerWith(service, resolver: _Resolver(), overrideResolver: true);
      await c.read(authSettingsProvider.future);
      final otp = c.read(otpControllerProvider.notifier);
      await otp.sendCode(phone);
      await otp.verify('123456');
      expect(service.tried, ['654321']);
      expect(c.read(otpControllerProvider).phase, OtpPhase.signedIn);
    });

    test('a non-emulator build (this test run, like prod) has no resolver: 123456 goes through as typed', () async {
      expect(useEmulator, isFalse, reason: 'flutter test runs without USE_EMULATOR, like a prod build');
      final service = FakePhoneAuthService(validCode: '654321');
      final c = containerWith(service);
      expect(c.read(devCodeResolverProvider), isNull);
      await c.read(authSettingsProvider.future);
      final otp = c.read(otpControllerProvider.notifier);
      await otp.sendCode(phone);
      await otp.verify('123456');
      expect(service.tried, ['123456'], reason: 'no bypass: the real check decides');
      expect(c.read(otpControllerProvider).phase, isNot(OtpPhase.signedIn));
    });

    test('the prod project never gets a resolver, even if someone also sets USE_EMULATOR', () {
      expect(devCodeResolverFor(emulator: true, prod: true), isNull);
      expect(devCodeResolverFor(emulator: false, prod: true), isNull);
      expect(devCodeResolverFor(emulator: false, prod: false), isNull);
      expect(devCodeResolverFor(emulator: true, prod: false), isA<EmulatorCodeResolver>());
    });
  });
}
