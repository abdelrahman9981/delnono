import 'package:delnono/core/settings/settings_repository.dart';
import 'package:delnono/features/auth/application/otp_controller.dart';
import 'package:delnono/features/auth/data/phone_auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

const phone = '+201012345678';

/// Non-default values, so the tests prove the controller reads settings/auth.
const settings = AuthSettings(codeValiditySeconds: 120, maxCodeAttempts: 3, resendWaitSeconds: 30);

Future<(ProviderContainer, OtpController, FakeClock, FakePhoneAuthService)> setUp_({
  AuthSettings authSettings = settings,
}) async {
  final clock = FakeClock();
  final service = FakePhoneAuthService();
  final container = ProviderContainer(overrides: [
    clockProvider.overrideWithValue(clock.call),
    phoneAuthServiceProvider.overrideWithValue(service),
    authSettingsProvider.overrideWith((ref) => Stream.value(authSettings)),
  ]);
  addTearDown(container.dispose);
  container.listen(authSettingsProvider, (_, _) {});
  await container.read(authSettingsProvider.future);
  return (container, container.read(otpControllerProvider.notifier), clock, service);
}

void main() {
  test('sending a code records when it was sent and when resend is allowed', () async {
    final (container, otp, clock, service) = await setUp_();
    await otp.sendCode(phone);

    final s = container.read(otpControllerProvider);
    expect(s.phase, OtpPhase.codeSent);
    expect(s.verificationId, 'verification-1');
    expect(s.sentAt, clock.now);
    expect(s.resendAvailableAt, clock.now.add(const Duration(seconds: 30)));
    expect(service.sent.single.phone, phone);
  });

  group('FR-006 code validity from settings', () {
    test('valid just before codeValiditySeconds, expired at it', () async {
      final (container, otp, clock, service) = await setUp_();
      await otp.sendCode(phone);

      clock.advance(const Duration(seconds: 119));
      expect(otp.isExpired(), isFalse);
      clock.advance(const Duration(seconds: 1));
      expect(otp.isExpired(), isTrue);
    });

    test('an expired code is discarded without asking Firebase', () async {
      final (container, otp, clock, service) = await setUp_();
      await otp.sendCode(phone);
      clock.advance(const Duration(seconds: 120));

      await otp.verify('123456');
      final s = container.read(otpControllerProvider);
      expect(s.verificationId, isNull);
      expect(s.discarded, CodeDiscarded.expired);
      expect(service.tried, isEmpty);
    });

    test('Firebase session-expired also discards the code', () async {
      final (container, otp, clock, _) = await setUp_();
      final service = _ThrowingService('session-expired');
      container.updateOverrides([
        clockProvider.overrideWithValue(clock.call),
        phoneAuthServiceProvider.overrideWithValue(service),
        authSettingsProvider.overrideWith((ref) => Stream.value(settings)),
      ]);
      await otp.sendCode(phone);
      await otp.verify('123456');
      expect(container.read(otpControllerProvider).discarded, CodeDiscarded.expired);
    });
  });

  group('FR-007 wrong attempts from settings', () {
    test('counts wrong entries and discards the code at maxCodeAttempts', () async {
      final (container, otp, clock, service) = await setUp_();
      await otp.sendCode(phone);

      await otp.verify('000000');
      expect(container.read(otpControllerProvider).wrongAttempts, 1);
      expect(otp.attemptsLeft, 2);
      expect(container.read(otpControllerProvider).error, isA<FirebaseAuthException>());

      await otp.verify('000000');
      expect(otp.attemptsLeft, 1);
      expect(container.read(otpControllerProvider).hasCode, isTrue);

      await otp.verify('000000');
      final s = container.read(otpControllerProvider);
      expect(s.verificationId, isNull);
      expect(s.discarded, CodeDiscarded.attemptsUsed);
      expect(otp.attemptsLeft, 0);

      await otp.verify('123456');
      expect(service.tried, hasLength(3), reason: 'no attempt after the code was discarded');
    });

    test('the right code signs in', () async {
      final (container, otp, _, _) = await setUp_();
      await otp.sendCode(phone);
      await otp.verify('000000');
      await otp.verify('123456');
      expect(container.read(otpControllerProvider).phase, OtpPhase.signedIn);
    });

    test('after signing in, the same number gets a fresh code right away', () async {
      final (container, otp, _, service) = await setUp_();
      await otp.sendCode(phone);
      await otp.verify('123456');
      expect(container.read(otpControllerProvider).hasCode, isFalse);
      await otp.sendCode(phone);
      expect(service.sent, hasLength(2), reason: 'the used code is not reused');
    });

    test('a new code resets the count', () async {
      final (container, otp, clock, _) = await setUp_();
      await otp.sendCode(phone);
      for (var i = 0; i < 3; i++) {
        await otp.verify('000000');
      }
      clock.advance(const Duration(seconds: 30));
      await otp.resend();
      final s = container.read(otpControllerProvider);
      expect(s.hasCode, isTrue);
      expect(s.wrongAttempts, 0);
      expect(s.discarded, CodeDiscarded.none);
    });
  });

  group('FR-008 resend wait from settings', () {
    test('remaining seconds are exposed and resend is blocked until zero', () async {
      final (container, otp, clock, service) = await setUp_();
      await otp.sendCode(phone);

      expect(otp.resendWait(), const Duration(seconds: 30));
      expect(otp.canResend(), isFalse);
      await otp.resend();
      expect(service.sent, hasLength(1));

      clock.advance(const Duration(seconds: 18));
      expect(otp.resendWait(), const Duration(seconds: 12));

      clock.advance(const Duration(seconds: 12));
      expect(otp.canResend(), isTrue);
      await otp.resend();
      expect(service.sent, hasLength(2));
      expect(service.sent.last.resendToken, 42, reason: 'Android resend token is passed back');
      expect(container.read(otpControllerProvider).verificationId, 'verification-2');
    });

    test('sending to the same number again during the wait keeps the current code', () async {
      final (container, otp, clock, service) = await setUp_();
      await otp.sendCode(phone);
      clock.advance(const Duration(seconds: 5));
      await otp.sendCode(phone);
      expect(service.sent, hasLength(1));
      expect(container.read(otpControllerProvider).verificationId, 'verification-1');
    });

    test('a different number is sent right away', () async {
      final (_, otp, _, service) = await setUp_();
      await otp.sendCode(phone);
      await otp.sendCode('+201112345678');
      expect(service.sent, hasLength(2));
      expect(service.sent.last.resendToken, isNull);
    });
  });

  test('defaults apply when settings/auth is missing', () async {
    final (container, otp, clock, _) = await setUp_(authSettings: const AuthSettings());
    await otp.sendCode(phone);
    expect(otp.resendWait(), const Duration(seconds: 60));
    clock.advance(const Duration(seconds: 299));
    expect(otp.isExpired(), isFalse);
    clock.advance(const Duration(seconds: 1));
    expect(otp.isExpired(), isTrue);
    expect(otp.attemptsLeft, 5);
    expect(otp.codeValidityMinutes, 5);
  });

  test('a send failure keeps the error for an Arabic message', () async {
    final (container, otp, _, service) = await setUp_();
    service.sendError = FirebaseAuthException(code: 'too-many-requests');
    await otp.sendCode(phone);
    final s = container.read(otpControllerProvider);
    expect(s.phase, OtpPhase.idle);
    expect((s.error as FirebaseAuthException).code, 'too-many-requests');
  });
}

class _ThrowingService implements PhoneAuthService {
  _ThrowingService(this.code);

  final String code;

  @override
  Future<SendCodeResult> sendCode(String phoneE164, {int? resendToken}) async =>
      const CodeSent('verification-x', null);

  @override
  Future<void> signInWithCode(String verificationId, String smsCode) async =>
      throw FirebaseAuthException(code: code);

  @override
  Future<void> updatePhoneNumber(String verificationId, String smsCode) async =>
      throw FirebaseAuthException(code: code);
}
