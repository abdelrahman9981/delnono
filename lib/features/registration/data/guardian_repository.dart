import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/settings/settings_repository.dart';
import '../../auth/data/auth_repository.dart';

enum Relation { mother, father, other }

/// `guardians/{uid}` (data-model.md). Created only by the `completeRegistration` function.
class Guardian {
  const Guardian({
    required this.uid,
    required this.phone,
    required this.fullName,
    required this.relation,
    this.email,
    required this.consentVersion,
    this.clinicChildrenPending = false,
    this.preferredClinicId,
  });

  factory Guardian.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> snap) {
    final d = snap.data()!;
    return Guardian(
      uid: snap.id,
      phone: d['phone'] as String,
      fullName: d['fullName'] as String,
      relation: Relation.values.asNameMap()[d['relation']] ?? Relation.other,
      email: d['email'] as String?,
      consentVersion: (d['consentVersion'] as num?)?.toInt() ?? 0,
      clinicChildrenPending: d['clinicChildrenPending'] as bool? ?? false,
      preferredClinicId: d['preferredClinicId'] as String?,
    );
  }

  final String uid;
  final String phone;
  final String fullName;
  final Relation relation;
  final String? email;
  final int consentVersion;
  final bool clinicChildrenPending;

  /// The clinic booking starts with («حسابي»); null = choose each time.
  final String? preferredClinicId;
}

class GuardianRepository {
  GuardianRepository(this._db);

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _doc(String uid) => _db.collection('guardians').doc(uid);

  Stream<Guardian?> watch(String uid) =>
      _doc(uid).snapshots().map((s) => s.exists ? Guardian.fromSnapshot(s) : null);

  /// The only fields a guardian may change (contracts/firestore-access.md).
  Future<void> updateDetails(String uid,
          {required String fullName, required Relation relation, String? email}) =>
      _doc(uid).update({
        'fullName': fullName,
        'relation': relation.name,
        'email': email,
        'updatedAt': FieldValue.serverTimestamp(),
      });

  Future<void> setPreferredClinic(String uid, String? clinicId) =>
      _doc(uid).update({'preferredClinicId': clinicId, 'updatedAt': FieldValue.serverTimestamp()});
}

final guardianRepositoryProvider =
    Provider<GuardianRepository>((ref) => GuardianRepository(ref.watch(firestoreProvider)));

/// The signed-in guardian's doc; null when signed out or not registered yet.
final guardianProvider = StreamProvider<Guardian?>((ref) {
  final uid = ref.watch(authStateProvider).value?.uid;
  if (uid == null) return Stream.value(null);
  return ref.watch(guardianRepositoryProvider).watch(uid);
});
