import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/settings/settings_repository.dart';
import '../data/phone_auth_service.dart';

typedef Clock = DateTime Function();

/// Current time; overridden in tests.
final clockProvider = Provider<Clock>((ref) => DateTime.now);

enum OtpPhase { idle, sending, codeSent, verifying, signedIn }

/// Why the current code can no longer be used.
enum CodeDiscarded { none, expired, attemptsUsed }

@immutable
class OtpState {
  const OtpState({
    this.phase = OtpPhase.idle,
    this.phone,
    this.verificationId,
    this.resendToken,
    this.sentAt,
    this.resendAvailableAt,
    this.wrongAttempts = 0,
    this.discarded = CodeDiscarded.none,
    this.error,
  });

  final OtpPhase phase;

  /// E.164 number the code was sent to.
  final String? phone;
  final String? verificationId;
  final int? resendToken;
  final DateTime? sentAt;
  final DateTime? resendAvailableAt;
  final int wrongAttempts;
  final CodeDiscarded discarded;

  /// Last error from Firebase, for an Arabic message (core/errors/arabic_errors.dart).
  final Object? error;

  bool get hasCode => verificationId != null;

  OtpState copyWith({
    OtpPhase? phase,
    String? phone,
    int? wrongAttempts,
    Object? error,
    bool clearError = false,
  }) =>
      OtpState(
        phase: phase ?? this.phase,
        phone: phone ?? this.phone,
        verificationId: verificationId,
        resendToken: resendToken,
        sentAt: sentAt,
        resendAvailableAt: resendAvailableAt,
        wrongAttempts: wrongAttempts ?? this.wrongAttempts,
        discarded: discarded,
        error: clearError ? null : (error ?? this.error),
      );

  /// Drops the code so it cannot be tried again (FR-006, FR-007). The resend timer stays.
  OtpState discard(CodeDiscarded reason, {int? wrongAttempts}) => OtpState(
        phase: OtpPhase.codeSent,
        phone: phone,
        resendToken: resendToken,
        sentAt: sentAt,
        resendAvailableAt: resendAvailableAt,
        wrongAttempts: wrongAttempts ?? this.wrongAttempts,
        discarded: reason,
      );
}

/// Sends and checks sign-in codes, enforcing the code rules in the app because Firebase does not
/// let us set them (research R1):
/// - FR-006: a code is treated as expired `codeValiditySeconds` after it was sent.
/// - FR-007: a code is discarded after `maxCodeAttempts` wrong entries.
/// - FR-008: a new code cannot be sent until `resendWaitSeconds` after the last one.
/// All three values come from `settings/auth`.
class OtpController extends Notifier<OtpState> {
  OtpController({this.changePhone = false});

  /// True for changing the number of a signed-in account (FR-025) instead of signing in.
  final bool changePhone;

  @override
  OtpState build() => const OtpState();

  AuthSettings get _settings => ref.read(authSettingsProvider).value ?? const AuthSettings();

  DateTime get _now => ref.read(clockProvider)();

  PhoneAuthService get _service => ref.read(phoneAuthServiceProvider);

  // ---- Derived values for the UI ----

  bool isExpired([DateTime? now]) {
    final sentAt = state.sentAt;
    if (sentAt == null) return false;
    return !(now ?? _now).isBefore(sentAt.add(Duration(seconds: _settings.codeValiditySeconds)));
  }

  /// Time left before a new code may be sent; zero when allowed.
  Duration resendWait([DateTime? now]) {
    final at = state.resendAvailableAt;
    if (at == null) return Duration.zero;
    final left = at.difference(now ?? _now);
    return left.isNegative ? Duration.zero : left;
  }

  bool canResend([DateTime? now]) => resendWait(now) == Duration.zero;

  int get attemptsLeft => (_settings.maxCodeAttempts - state.wrongAttempts).clamp(0, 1 << 30);

  int get codeValidityMinutes => (_settings.codeValiditySeconds / 60).ceil();

  // ---- Actions ----

  /// Sends a code to [phoneE164]. Sending to the same number again before the resend wait is over
  /// keeps the current code instead of sending another SMS (FR-008).
  Future<void> sendCode(String phoneE164) async {
    if (state.phase == OtpPhase.sending || state.phase == OtpPhase.verifying) return;
    final samePhone = state.phone == phoneE164;
    if (samePhone && state.hasCode && !canResend()) return;

    state = state.copyWith(phase: OtpPhase.sending, phone: phoneE164, clearError: true);
    try {
      final result = await _service.sendCode(phoneE164, resendToken: samePhone ? state.resendToken : null);
      final now = _now;
      state = switch (result) {
        CodeSent(:final verificationId, :final resendToken) => OtpState(
            phase: OtpPhase.codeSent,
            phone: phoneE164,
            verificationId: verificationId,
            resendToken: resendToken,
            sentAt: now,
            resendAvailableAt: now.add(Duration(seconds: _settings.resendWaitSeconds)),
          ),
        AutoVerified() => OtpState(phase: OtpPhase.signedIn, phone: phoneE164),
      };
    } catch (e) {
      state = OtpState(
        phase: state.hasCode ? OtpPhase.codeSent : OtpPhase.idle,
        phone: phoneE164,
        verificationId: state.verificationId,
        resendToken: state.resendToken,
        sentAt: state.sentAt,
        resendAvailableAt: state.resendAvailableAt,
        wrongAttempts: state.wrongAttempts,
        discarded: state.discarded,
        error: e,
      );
    }
  }

  /// Sends a new code to the same number once the resend wait is over (FR-008).
  Future<void> resend() async {
    final phone = state.phone;
    if (phone == null || !canResend()) return;
    await sendCode(phone);
  }

  /// Checks [smsCode] against the current code.
  Future<void> verify(String smsCode) async {
    final verificationId = state.verificationId;
    if (verificationId == null || state.phase == OtpPhase.verifying) return;
    if (isExpired()) {
      state = state.discard(CodeDiscarded.expired);
      return;
    }

    state = state.copyWith(phase: OtpPhase.verifying, clearError: true);
    try {
      if (changePhone) {
        await _service.updatePhoneNumber(verificationId, smsCode);
      } else {
        await _service.signInWithCode(verificationId, smsCode);
      }
      state = state.copyWith(phase: OtpPhase.signedIn);
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'invalid-verification-code':
          final wrong = state.wrongAttempts + 1;
          state = wrong >= _settings.maxCodeAttempts
              ? state.discard(CodeDiscarded.attemptsUsed, wrongAttempts: wrong)
              : state.copyWith(phase: OtpPhase.codeSent, wrongAttempts: wrong, error: e);
        case 'session-expired':
          state = state.discard(CodeDiscarded.expired);
        default:
          state = state.copyWith(phase: OtpPhase.codeSent, error: e);
      }
    } catch (e) {
      state = state.copyWith(phase: OtpPhase.codeSent, error: e);
    }
  }

  /// Starts over with a different number.
  void reset() => state = const OtpState();
}

final otpControllerProvider = NotifierProvider<OtpController, OtpState>(OtpController.new);

/// Separate state for changing the number from the account screen.
final phoneChangeOtpProvider =
    NotifierProvider<OtpController, OtpState>(() => OtpController(changePhone: true));
