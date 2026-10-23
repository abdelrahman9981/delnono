import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:delnono/core/settings/settings_repository.dart';
import 'package:delnono/features/registration/application/registration_controller.dart';
import 'package:delnono/features/registration/data/guardian_repository.dart';
import 'package:delnono/features/registration/data/registration_api.dart';
import 'package:delnono/features/registration/presentation/consent_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../helpers/screen_harness.dart';
import 'fakes.dart';

const details = GuardianDetails(fullName: 'سارة محمود', relation: Relation.mother);

void main() {
  late FakeRegistrationApi api;

  Future<ScreenHarness> open(
    WidgetTester tester, {
    Guardian? guardian,
    PolicySettings policy = const PolicySettings(currentVersion: 1, privacyPolicyText: '[نص مؤقت]'),
    bool withDetails = true,
  }) async {
    api = FakeRegistrationApi();
    final h = ScreenHarness(
      initial: '/register/consent?from=%2Fbooking',
      routes: [
        GoRoute(path: '/register/consent', builder: (_, s) => ConsentScreen(from: s.uri.queryParameters['from'])),
      ],
      overrides: [
        registrationApiProvider.overrideWithValue(api),
        guardianProvider.overrideWith((ref) => Stream.value(guardian)),
        policySettingsProvider.overrideWith((ref) => Stream.value(policy)),
      ],
    );
    if (withDetails) h.container.read(registrationControllerProvider.notifier).setDetails(details);
    await h.pump(tester);
    return h;
  }

  final acceptButton = find.widgetWithText(FilledButton, 'موافقة ومتابعة');
  FilledButton accept(WidgetTester tester) => tester.widget<FilledButton>(acceptButton);

  testWidgets('both consents start unticked and are each required (FR-014)', (tester) async {
    await open(tester);
    await scrollTo(tester, acceptButton);
    expect(tester.widget<Checkbox>(find.descendant(of: find.byKey(const Key('consent-policy')), matching: find.byType(Checkbox))).value, isFalse);
    expect(accept(tester).onPressed, isNull);

    await tapVisible(tester, find.byKey(const Key('consent-policy')));
    expect(accept(tester).onPressed, isNull, reason: 'child data consent still missing');

    await tapVisible(tester, find.byKey(const Key('consent-child-data')));
    expect(accept(tester).onPressed, isNotNull);

    await tapVisible(tester, find.byKey(const Key('consent-policy')));
    expect(accept(tester).onPressed, isNull, reason: 'unticking blocks again');
  });

  testWidgets('accepting sends details with the current version in one call (FR-015)', (tester) async {
    await open(tester, policy: const PolicySettings(currentVersion: 3, privacyPolicyText: 'x', termsText: 'y'));
    await tapVisible(tester, find.byKey(const Key('consent-policy')));
    await tapVisible(tester, find.byKey(const Key('consent-child-data')));
    await tapVisible(tester, find.text('موافقة ومتابعة'));

    final (sent, version) = api.registrations.single;
    expect(sent.fullName, 'سارة محمود');
    expect(version, 3);
  });

  testWidgets('shows the version with its date in Arabic, and the placeholder tag', (tester) async {
    await open(
      tester,
      policy: PolicySettings(
        currentVersion: 1,
        privacyPolicyText: '[نص مؤقت]',
        updatedAt: Timestamp.fromDate(DateTime(2026, 10, 22)).toDate(),
      ),
    );
    expect(find.text('الإصدار ١ · ٢٢ أكتوبر ٢٠٢٦'), findsOneWidget);
    expect(find.text('نص مؤقت · يراجعه المحامي قبل الإطلاق'), findsOneWidget);
  });

  testWidgets('no placeholder tag once real text is loaded', (tester) async {
    await open(tester, policy: const PolicySettings(privacyPolicyText: 'سياسة', termsText: 'شروط'));
    expect(find.text('نص مؤقت · يراجعه المحامي قبل الإطلاق'), findsNothing);
  });

  testWidgets('a server error is shown in Arabic', (tester) async {
    await open(tester);
    api.error = Exception('offline');
    await tapVisible(tester, find.byKey(const Key('consent-policy')));
    await tapVisible(tester, find.byKey(const Key('consent-child-data')));
    await tapVisible(tester, find.text('موافقة ومتابعة'));
    expect(find.text('حصلت مشكلة. جربي تاني.'), findsOneWidget);
  });

  testWidgets('a registered guardian with an outdated version re-consents (FR-017)', (tester) async {
    const g = Guardian(uid: 'u1', phone: '+201000000099', fullName: 'سارة', relation: Relation.mother, consentVersion: 1);
    await open(tester, guardian: g, policy: const PolicySettings(currentVersion: 2, privacyPolicyText: 'x'), withDetails: false);
    expect(find.text('سياسة الخصوصية اتحدثت'), findsOneWidget);
    await tapVisible(tester, find.byKey(const Key('consent-policy')));
    await tapVisible(tester, find.byKey(const Key('consent-child-data')));
    await tapVisible(tester, find.text('موافقة ومتابعة'));
    expect(api.acceptedVersions, [2]);
    expect(api.registrations, isEmpty);
  });

  testWidgets('without details in memory (e.g. after a restart) it goes back to guardian details', (tester) async {
    final h = await open(tester, withDetails: false);
    expect(h.location, '/register/guardian?from=%2Fbooking');
  });
}
