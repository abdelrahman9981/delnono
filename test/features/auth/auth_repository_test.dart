import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:delnono/features/auth/data/auth_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _Auth extends Mock implements FirebaseAuth {}

class _Db extends Mock implements FirebaseFirestore {}

class _User extends Mock implements User {}

void main() {
  late _Auth auth;
  late _Db db;
  late _User user;
  late AuthRepository repo;

  setUp(() {
    auth = _Auth();
    db = _Db();
    user = _User();
    repo = AuthRepository(auth, db);
    when(() => user.uid).thenReturn('u1');
    when(() => auth.authStateChanges()).thenAnswer((_) => Stream.value(user));
    when(() => auth.signOut()).thenAnswer((_) async {});
    when(() => db.terminate()).thenAnswer((_) async {});
    when(() => db.clearPersistence()).thenAnswer((_) async {});
  });

  group('a kept sign-in whose account no longer exists', () {
    for (final code in ['user-not-found', 'user-disabled', 'user-token-expired']) {
      test('is signed out and the cache cleared ($code)', () async {
        when(() => user.reload()).thenThrow(FirebaseAuthException(code: code));
        expect(await repo.authStateChanges().first, user);
        await pumpEventQueue();
        verify(() => auth.signOut()).called(1);
        verify(() => db.clearPersistence()).called(1);
      });
    }

    test('stays signed in when offline', () async {
      when(() => user.reload()).thenThrow(FirebaseAuthException(code: 'network-request-failed'));
      await repo.authStateChanges().first;
      await pumpEventQueue();
      verifyNever(() => auth.signOut());
    });

    test('is checked once per account', () async {
      when(() => user.reload()).thenAnswer((_) async {});
      await repo.authStateChanges().first;
      await repo.authStateChanges().first;
      await pumpEventQueue();
      verify(() => user.reload()).called(1);
    });
  });
}
