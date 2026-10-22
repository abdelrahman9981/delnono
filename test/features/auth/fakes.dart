import 'package:delnono/features/auth/data/phone_auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// A clock the test moves by hand.
class FakeClock {
  FakeClock([DateTime? start]) : now = start ?? DateTime(2026, 10, 23, 10);

  DateTime now;

  void advance(Duration d) => now = now.add(d);

  DateTime call() => now;
}

/// Accepts [validCode]; any other code fails like Firebase does.
class FakePhoneAuthService implements PhoneAuthService {
  FakePhoneAuthService({this.validCode = '123456', this.sendError});

  final String validCode;
  Object? sendError;
  final sent = <({String phone, int? resendToken})>[];
  final tried = <String>[];

  @override
  Future<SendCodeResult> sendCode(String phoneE164, {int? resendToken}) async {
    sent.add((phone: phoneE164, resendToken: resendToken));
    if (sendError != null) throw sendError!;
    return CodeSent('verification-${sent.length}', 42);
  }

  @override
  Future<void> signInWithCode(String verificationId, String smsCode) async {
    tried.add(smsCode);
    if (smsCode != validCode) throw FirebaseAuthException(code: 'invalid-verification-code');
  }
}
