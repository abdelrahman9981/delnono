import 'package:cloud_functions/cloud_functions.dart';
import 'package:delnono/app/l10n/app_localizations_ar.dart';
import 'package:delnono/core/errors/arabic_errors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final l10n = AppLocalizationsAr();

  String auth(String code) => arabicErrorMessage(FirebaseAuthException(code: code), l10n);
  String fn(String code) =>
      arabicErrorMessage(FirebaseFunctionsException(code: code, message: code), l10n);

  test('maps Firebase Auth codes', () {
    expect(auth('invalid-verification-code'), l10n.errInvalidCode);
    expect(auth('session-expired'), l10n.errCodeExpired);
    expect(auth('too-many-requests'), l10n.errTooManyRequests);
    expect(auth('credential-already-in-use'), l10n.errNumberInUse);
    expect(auth('quota-exceeded'), l10n.errSmsQuota);
  });

  test('maps callable codes from contracts/callables.md', () {
    expect(fn('unauthenticated'), l10n.errUnauthenticated);
    expect(fn('already-exists'), l10n.errAlreadyExists);
    expect(fn('failed-precondition'), l10n.errPolicyOutdated);
    expect(fn('invalid-argument'), l10n.errInvalidInput);
    expect(fn('not-found'), l10n.errNoClinicChildren);
    expect(fn('permission-denied'), l10n.errBirthDateMismatch);
    expect(fn('resource-exhausted'), l10n.errLocked);
  });

  test('offline errors from Auth and callables share one message (FR-032)', () {
    expect(auth('network-request-failed'), l10n.errNoConnection);
    expect(fn('unavailable'), l10n.errNoConnection);
    expect(fn('deadline-exceeded'), l10n.errNoConnection);
  });

  test('unknown codes and other errors fall back to the generic message', () {
    expect(auth('some-new-code'), l10n.errGeneric);
    expect(fn('internal'), l10n.errGeneric);
    expect(arabicErrorMessage(StateError('x'), l10n), l10n.errGeneric);
  });

  test('every message is Arabic', () {
    final arabic = RegExp(r'[؀-ۿ]');
    for (final m in [
      l10n.errInvalidCode, l10n.errCodeExpired, l10n.errTooManyRequests, l10n.errNoConnection,
      l10n.errNumberInUse, l10n.errSmsQuota, l10n.errUnauthenticated, l10n.errAlreadyExists,
      l10n.errPolicyOutdated, l10n.errInvalidInput, l10n.errNoClinicChildren,
      l10n.errBirthDateMismatch, l10n.errLocked, l10n.errGeneric,
    ]) {
      expect(m, matches(arabic));
    }
  });
}
