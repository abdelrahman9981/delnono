// Bug 0003 (26 Oct 2026): a clinic family (+201000000003) signed in, registered slowly, linked its
// clinic children (عمر، نور) and had added a child before linking, yet «طفلي» stayed blank and
// Booking said "add a child first". The children query had started before registration and
// consent, the rules denied it, and nothing restarted it. Family queries now wait for access.

import 'dart:async';

import 'package:delnono/app/route_guard.dart';
import 'package:delnono/core/settings/settings_repository.dart';
import 'package:delnono/features/auth/data/auth_repository.dart';
import 'package:delnono/features/children/data/children_repository.dart';
import 'package:delnono/features/registration/data/family_access.dart';
import 'package:delnono/features/registration/data/guardian_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _User extends Mock implements User {
  @override
  String get uid => 'g3';
}

/// The rules' decision: denied until the guardian exists with current consent.
class _RulesChildren extends Fake implements ChildrenRepository {
  _RulesChildren(this.allowed);

  final ValueListenable<bool> allowed;
  var subscribedBeforeAccess = 0;

  static const family = [
    Child(id: 'seed-omar', name: 'عمر', birthDate: '2023-05-10', sex: Sex.male),
    Child(id: 'seed-nour', name: 'نور', birthDate: '2021-08-08', sex: Sex.female),
    Child(id: 'added', name: 'سليم', birthDate: '2025-02-02', sex: Sex.male),
  ];

  @override
  Stream<List<Child>> watchLinked(String uid) {
    if (!allowed.value) {
      subscribedBeforeAccess++;
      return Stream.error(FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied'));
    }
    return Stream.value(family);
  }
}

Guardian guardian({int consent = 1, bool pending = false}) => Guardian(
      uid: 'g3',
      phone: '+201000000003',
      fullName: 'محمد عبدالرحمن',
      relation: Relation.mother,
      consentVersion: consent,
      clinicChildrenPending: pending,
    );

void main() {
  test('0003: no children query before registration and consent; the linked and added children after', () async {
    final allowed = ValueNotifier(false);
    final repo = _RulesChildren(allowed);
    // Single-subscription, so an event sent before the provider listens is kept, not dropped.
    final guardianStream = StreamController<Guardian?>();
    Guardian? current;
    final c = ProviderContainer(overrides: [
      authStateProvider.overrideWith((ref) => Stream.value(_User())),
      guardianProvider.overrideWith((ref) async* {
        yield current;
        yield* guardianStream.stream;
      }),
      policySettingsProvider.overrideWith((ref) => Stream.value(const PolicySettings())),
      childrenRepositoryProvider.overrideWithValue(repo),
    ]);
    addTearDown(c.dispose);
    c.listen(childrenProvider, (_, _) {});

    // Signed in, no guardian yet (registration screens, possibly for a long time).
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(c.read(familyAccessProvider), isNull);
    expect(c.read(childrenProvider).value, isEmpty);
    expect(repo.subscribedBeforeAccess, 0, reason: 'the old code subscribed here and was denied for good');

    // Registered with consent, children linked: the rules now allow the read.
    allowed.value = true;
    current = guardian();
    guardianStream.add(current);
    // Wait for the streams rather than a fixed time: a loaded machine can take longer than 50 ms.
    for (var i = 0; i < 100 && (c.read(childrenProvider).value?.length ?? 0) < 3; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
    expect(c.read(familyAccessProvider), 'g3');
    expect(c.read(childrenProvider).value!.map((x) => x.name), ['عمر', 'نور', 'سليم']);
    expect(repo.subscribedBeforeAccess, 0);
    await guardianStream.close();
  });

  test('access needs a guardian doc with the current policy consented', () {
    for (final (g, version, expected) in [
      (null, 1, null),
      (guardian(consent: 1), 2, null),
      (guardian(consent: 2), 2, 'g3'),
    ]) {
      final c = ProviderContainer(overrides: [
        guardianProvider.overrideWithValue(AsyncData(g)),
        policySettingsProvider.overrideWithValue(AsyncData(PolicySettings(currentVersion: version))),
      ]);
      expect(c.read(familyAccessProvider), expected);
      c.dispose();
    }
  });

  test('the guard still sends a clinic family with pending children to linking', () {
    const s = GuardState(signedIn: true, hasGuardian: true, consentCurrent: true, clinicChildrenPending: true);
    expect(guardRedirect(Uri.parse('/booking'), s), startsWith(Routes.registerLink));
  });
}
