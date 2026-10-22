import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// `settings/auth` (data-model.md). Defaults apply when the document or a field is missing.
class AuthSettings {
  const AuthSettings({
    this.codeValiditySeconds = 300,
    this.maxCodeAttempts = 5,
    this.resendWaitSeconds = 60,
    this.dailySmsCapPerNumber = 5,
    this.maxLinkAttempts = 3,
    this.reverifyAfterDays = 90,
  });

  factory AuthSettings.fromMap(Map<String, dynamic>? data) {
    const d = AuthSettings();
    if (data == null) return d;
    return AuthSettings(
      codeValiditySeconds: _int(data['codeValiditySeconds']) ?? d.codeValiditySeconds,
      maxCodeAttempts: _int(data['maxCodeAttempts']) ?? d.maxCodeAttempts,
      resendWaitSeconds: _int(data['resendWaitSeconds']) ?? d.resendWaitSeconds,
      dailySmsCapPerNumber: _int(data['dailySmsCapPerNumber']) ?? d.dailySmsCapPerNumber,
      maxLinkAttempts: _int(data['maxLinkAttempts']) ?? d.maxLinkAttempts,
      reverifyAfterDays: _int(data['reverifyAfterDays']) ?? d.reverifyAfterDays,
    );
  }

  final int codeValiditySeconds;
  final int maxCodeAttempts;
  final int resendWaitSeconds;
  final int dailySmsCapPerNumber;
  final int maxLinkAttempts;
  final int reverifyAfterDays;
}

/// `settings/policy`. Version 1 with empty text until the clinic's policy is loaded.
class PolicySettings {
  const PolicySettings({this.currentVersion = 1, this.privacyPolicyText = '', this.termsText = ''});

  factory PolicySettings.fromMap(Map<String, dynamic>? data) {
    const d = PolicySettings();
    if (data == null) return d;
    return PolicySettings(
      currentVersion: _int(data['currentVersion']) ?? d.currentVersion,
      privacyPolicyText: data['privacyPolicyText'] as String? ?? d.privacyPolicyText,
      termsText: data['termsText'] as String? ?? d.termsText,
    );
  }

  final int currentVersion;
  final String privacyPolicyText;
  final String termsText;
}

/// `settings/clinic`.
class ClinicSettings {
  const ClinicSettings({this.whatsappNumber});

  factory ClinicSettings.fromMap(Map<String, dynamic>? data) =>
      ClinicSettings(whatsappNumber: data?['whatsappNumber'] as String?);

  /// E.164; null until the clinic supplies it.
  final String? whatsappNumber;
}

int? _int(Object? value) => value is num ? value.toInt() : null;

class SettingsRepository {
  SettingsRepository(this._db);

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _doc(String id) => _db.collection('settings').doc(id);

  Stream<AuthSettings> watchAuth() => _doc('auth').snapshots().map((s) => AuthSettings.fromMap(s.data()));

  Stream<PolicySettings> watchPolicy() =>
      _doc('policy').snapshots().map((s) => PolicySettings.fromMap(s.data()));

  Stream<ClinicSettings> watchClinic() =>
      _doc('clinic').snapshots().map((s) => ClinicSettings.fromMap(s.data()));
}

final firestoreProvider = Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);

final settingsRepositoryProvider =
    Provider<SettingsRepository>((ref) => SettingsRepository(ref.watch(firestoreProvider)));

final authSettingsProvider =
    StreamProvider<AuthSettings>((ref) => ref.watch(settingsRepositoryProvider).watchAuth());

final policySettingsProvider =
    StreamProvider<PolicySettings>((ref) => ref.watch(settingsRepositoryProvider).watchPolicy());

final clinicSettingsProvider =
    StreamProvider<ClinicSettings>((ref) => ref.watch(settingsRepositoryProvider).watchClinic());
