import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/settings/settings_repository.dart';

class AuthRepository {
  AuthRepository(this._auth, this._db);

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  /// Signs out and clears the offline Firestore cache, so the next person on this phone cannot read
  /// the children's data offline (constitution Principle I).
  Future<void> signOut() async {
    await _auth.signOut();
    await _db.terminate();
    await _db.clearPersistence();
  }
}

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);

final authRepositoryProvider =
    Provider<AuthRepository>((ref) => AuthRepository(ref.watch(firebaseAuthProvider), ref.watch(firestoreProvider)));

/// The signed-in Firebase user, or null when signed out.
final authStateProvider =
    StreamProvider<User?>((ref) => ref.watch(authRepositoryProvider).authStateChanges());
