import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_repository.dart';

sealed class SendCodeResult {
  const SendCodeResult();
}

/// The SMS was sent; the guardian types the code.
class CodeSent extends SendCodeResult {
  const CodeSent(this.verificationId, this.resendToken);

  final String verificationId;

  /// Android only; iOS always returns null.
  final int? resendToken;
}

/// Android verified the number without a typed code (instant verification or SMS auto-retrieval)
/// and the guardian is already signed in.
class AutoVerified extends SendCodeResult {
  const AutoVerified();
}

/// Phone sign-in. Code rules FR-006 to FR-008 are enforced by the OTP controller, not here
/// (research R1).
abstract interface class PhoneAuthService {
  Future<SendCodeResult> sendCode(String phoneE164, {int? resendToken});

  /// Throws [FirebaseAuthException] (`invalid-verification-code`, `session-expired`, …).
  Future<void> signInWithCode(String verificationId, String smsCode);

  /// Moves the signed-in account to the number the code was sent to (FR-025), then refreshes the
  /// ID token so callables see the new number. Throws `credential-already-in-use` when the number
  /// belongs to another account (FR-025a).
  Future<void> updatePhoneNumber(String verificationId, String smsCode);
}

class FirebasePhoneAuthService implements PhoneAuthService {
  FirebasePhoneAuthService(this._auth);

  final FirebaseAuth _auth;

  @override
  Future<SendCodeResult> sendCode(String phoneE164, {int? resendToken}) async {
    // The web has no verifyPhoneNumber: signInWithPhoneNumber sends the code behind an invisible
    // reCAPTCHA (D-43 web demo). Its verification id signs in or moves the number like on phones.
    if (kIsWeb) return CodeSent((await _auth.signInWithPhoneNumber(phoneE164)).verificationId, null);
    return _sendOnPhone(phoneE164, resendToken);
  }

  Future<SendCodeResult> _sendOnPhone(String phoneE164, int? resendToken) {
    final result = Completer<SendCodeResult>();

    void fail(Object error) {
      if (!result.isCompleted) result.completeError(error);
    }

    _auth
        .verifyPhoneNumber(
          phoneNumber: phoneE164,
          forceResendingToken: resendToken,
          verificationCompleted: (credential) async {
            // Android can verify on its own, before or after `codeSent`. Signing in here moves the
            // guardian on through the router guard either way.
            try {
              await _auth.signInWithCredential(credential);
              if (!result.isCompleted) result.complete(const AutoVerified());
            } catch (e) {
              fail(e);
            }
          },
          verificationFailed: fail,
          codeSent: (verificationId, token) {
            if (!result.isCompleted) result.complete(CodeSent(verificationId, token));
          },
          codeAutoRetrievalTimeout: (_) {},
        )
        .catchError(fail);

    return result.future;
  }

  @override
  Future<void> signInWithCode(String verificationId, String smsCode) => _auth.signInWithCredential(
        PhoneAuthProvider.credential(verificationId: verificationId, smsCode: smsCode),
      );

  @override
  Future<void> updatePhoneNumber(String verificationId, String smsCode) async {
    final user = _auth.currentUser;
    if (user == null) throw FirebaseAuthException(code: 'user-not-found');
    await user.updatePhoneNumber(PhoneAuthProvider.credential(verificationId: verificationId, smsCode: smsCode));
    await user.getIdToken(true);
  }
}

final phoneAuthServiceProvider =
    Provider<PhoneAuthService>((ref) => FirebasePhoneAuthService(ref.watch(firebaseAuthProvider)));
