import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/settings/settings_repository.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/clinics/data/clinics_repository.dart';

enum StaffRole { doctor, secretary }

/// The signed-in staff member (`staff/{uid}`, 005 data-model.md). Null when signed out, not staff,
/// or disabled.
class StaffSession {
  const StaffSession({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.clinicId,
    this.mustChangePassword = false,
  });

  final String uid;
  final String name;
  final String email;
  final StaffRole role;

  /// The secretary's clinic; null for the doctor (every clinic).
  final String? clinicId;
  final bool mustChangePassword;

  bool get isDoctor => role == StaffRole.doctor;
}

/// Email sign-in for staff; guardians use phone codes in the app (005 clarification).
abstract interface class StaffAuth {
  Future<void> signIn(String email, String password);
  Future<void> changePassword(String newPassword);
  Future<void> signOut();
}

class FirebaseStaffAuth implements StaffAuth {
  FirebaseStaffAuth(this._auth);

  final FirebaseAuth _auth;

  @override
  Future<void> signIn(String email, String password) =>
      _auth.signInWithEmailAndPassword(email: email.trim(), password: password);

  @override
  Future<void> changePassword(String newPassword) => _auth.currentUser!.updatePassword(newPassword);

  @override
  Future<void> signOut() => _auth.signOut();
}

final staffAuthProvider = Provider<StaffAuth>((ref) => FirebaseStaffAuth(ref.watch(firebaseAuthProvider)));

/// The staff record of the signed-in user, live: disabling or a role change applies at once.
final staffSessionProvider = StreamProvider<StaffSession?>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value(null);
  return ref
      .watch(firestoreProvider)
      .doc('staff/${user.uid}')
      .snapshots()
      .map((s) {
        final d = s.data();
        if (d == null || d['active'] != true) return null;
        return StaffSession(
          uid: user.uid,
          name: d['name'] as String? ?? '',
          email: d['email'] as String? ?? user.email ?? '',
          role: d['role'] == 'doctor' ? StaffRole.doctor : StaffRole.secretary,
          clinicId: d['clinicId'] as String?,
          mustChangePassword: d['mustChangePassword'] == true,
        );
      })
      .handleError((Object _) => null);
});

/// The clinic the dashboard shows: the secretary's own; for the doctor, the one picked in the top
/// bar (the main clinic until then).
class SelectedClinic extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String clinicId) => state = clinicId;
}

final selectedClinicIdProvider = NotifierProvider<SelectedClinic, String?>(SelectedClinic.new);

/// The clinic every clinic screen works on: the secretary's own (D-47); for the doctor the picked
/// clinic, else the main clinic.
final currentClinicIdProvider = Provider<String?>((ref) {
  final staff = ref.watch(staffSessionProvider).value;
  if (staff == null) return null;
  if (!staff.isDoctor) return staff.clinicId;
  return ref.watch(selectedClinicIdProvider) ?? ref.watch(mainClinicProvider)?.id;
});
