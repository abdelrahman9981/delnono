import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/settings/settings_repository.dart';
import '../../../core/storage/private_files.dart';

class AuthRepository {
  AuthRepository(this._auth, this._db);

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  /// The uid whose account was last checked by [_signOutIfDeleted].
  String? _checkedUid;

  Stream<User?> authStateChanges() => _auth.authStateChanges().map((user) {
    if (user != null && user.uid != _checkedUid) {
      _checkedUid = user.uid;
      unawaited(_signOutIfDeleted(user));
    }
    return user;
  });

  /// A sign-in kept on the phone for an account that no longer exists (deleted on another phone,
  /// disabled, or wiped from the emulator) cannot refresh its token, so every call would fail with
  /// a generic error. Reloading the user reports it; signing out lets the guard send the guardian
  /// to sign-in. Offline and other errors keep the session.
  Future<void> _signOutIfDeleted(User user) async {
    try {
      await user.reload();
    } on FirebaseAuthException catch (e) {
      if (_deletedAccountCodes.contains(e.code)) await signOut();
    } catch (_) {}
  }

  static const _deletedAccountCodes = {'user-not-found', 'user-disabled', 'user-token-expired', 'invalid-user-token'};

  User? get currentUser => _auth.currentUser;

  /// Signs out and clears the offline Firestore cache and the app's private files, so the next person
  /// on this phone cannot read the children's data offline (constitution Principle I).
  Future<void> signOut() async {
    // Files first: the guard moves on as soon as Auth signs out, and the caller's own navigation
    // must not land after it.
    await PrivateFiles.clear();
    await _auth.signOut();
    await _db.terminate();
    await _db.clearPersistence();
  }
}

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(firebaseAuthProvider), ref.watch(firestoreProvider)),
);

/// The signed-in Firebase user, or null when signed out.
final authStateProvider = StreamProvider<User?>((ref) => ref.watch(authRepositoryProvider).authStateChanges());
