import 'package:delnono/app/session_flags.dart';
import 'package:delnono/core/clock.dart';
import 'package:delnono/core/settings/settings_repository.dart';
import 'package:delnono/features/auth/data/auth_repository.dart';
import 'package:delnono/features/children/data/children_repository.dart';
import 'package:delnono/features/clinics/data/clinics_repository.dart';
import 'package:delnono/features/packages/data/packages_repository.dart';
import 'package:delnono/features/packages/domain/family_package.dart';
import 'package:delnono/features/registration/data/guardian_repository.dart';
import 'package:delnono/features/settings/presentation/me_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../../helpers/clinic_fakes.dart';
import '../../helpers/screen_harness.dart';

class _User extends Mock implements User {}

class _Repo extends Fake implements GuardianRepository {
  final saved = <String?>[];

  @override
  Future<void> setPreferredClinic(String uid, String? clinicId) async => saved.add(clinicId);
}

const guardian = Guardian(uid: 'u1', phone: '+201012345678', fullName: 'سارة محمود', relation: Relation.mother, consentVersion: 1);
const kids = [
  Child(id: 'a', name: 'يوسف', birthDate: '2024-03-15', sex: Sex.male),
  Child(id: 'b', name: 'ليلى', birthDate: '2026-01-02', sex: Sex.female),
];

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance = InMemorySharedPreferencesAsync.empty();
    PackageInfo.setMockInitialValues(appName: 'delnono', packageName: 'eg.drelnono.app', version: '1.0.0', buildNumber: '1', buildSignature: '');
  });

  Future<(ScreenHarness, _Repo)> open(
    WidgetTester tester, {
    bool signedIn = true,
    String? whatsapp = '+201000000000',
    List<FamilyPackage> packages = const [],
    bool clinicChildrenPending = false,
  }) async {
    final repo = _Repo();
    final h = ScreenHarness(
      initial: '/me',
      routes: [GoRoute(path: '/me', builder: (_, _) => const MeScreen())],
      overrides: [
        authStateProvider.overrideWith((ref) => Stream.value(signedIn ? _User() : null)),
        guardianProvider.overrideWith((ref) => Stream.value(!signedIn
            ? null
            : Guardian(
                uid: guardian.uid,
                phone: guardian.phone,
                fullName: guardian.fullName,
                relation: guardian.relation,
                consentVersion: guardian.consentVersion,
                clinicChildrenPending: clinicChildrenPending,
              ))),
        childrenProvider.overrideWith((ref) => Stream.value(kids)),
        guardianRepositoryProvider.overrideWithValue(repo),
        familyPackageListProvider.overrideWith((ref) => Stream.value(packages)),
        clockProvider.overrideWithValue(() => DateTime.utc(2026, 11, 15, 10)),
        policySettingsProvider.overrideWith((ref) => Stream.value(const PolicySettings())),
        ...clinicOverrides(clinics: [
          Clinic(
            id: clinic1.id,
            name: clinic1.name,
            area: clinic1.area,
            address: clinic1.address,
            phone: clinic1.phone,
            whatsapp: whatsapp,
            workingHours: clinic1.workingHours,
          ),
          clinic2,
        ]),
      ],
    );
    await h.pump(tester);
    return (h, repo);
  }

  testWidgets('the guardian card opens Account; children open their profiles; add child (screen 12)', (tester) async {
    final (h, _) = await open(tester);
    expect(find.text('سارة محمود'), findsOneWidget);
    expect(find.byKey(const Key('me-child-a')), findsOneWidget);
    expect(find.byKey(const Key('me-child-b')), findsOneWidget);
    await tester.tap(find.byKey(const Key('me-guardian')));
    await tester.pumpAndSettle();
    expect(h.location, '/account');
  });

  testWidgets('add child goes to the existing flow', (tester) async {
    final (h, _) = await open(tester);
    await tapVisible(tester, find.byKey(const Key('me-add-child')));
    expect(h.location, '/children/add');
  });

  testWidgets('clinic children still waiting: «ربط أطفال العيادة» opens the link step (link later)', (tester) async {
    final (h, _) = await open(tester, clinicChildrenPending: true);
    h.container.read(linkSkippedProvider.notifier).set(true);
    await tapVisible(tester, find.byKey(const Key('me-link-clinic')));
    expect(h.location, '/register/link?from=%2Fme');
    expect(h.container.read(linkSkippedProvider), isFalse, reason: 'skipping at registration no longer hides it');
    expect(find.byKey(const Key('me-add-child')), findsNothing, reason: 'left the screen');
  });

  testWidgets('nothing to link: no link row, add child still there', (tester) async {
    await open(tester);
    expect(find.byKey(const Key('me-link-clinic')), findsNothing);
    expect(find.byKey(const Key('me-add-child')), findsOneWidget);
  });

  testWidgets('«الباقة»: without a package, one line opens the package page (008 FR-001)', (tester) async {
    final (h, _) = await open(tester);
    await tapVisible(tester, find.byKey(const Key('me-package-none')));
    expect(h.location, '/package');
  });

  testWidgets('«الباقة»: each child with the end date, «في العيادتين» and «سارية»', (tester) async {
    await open(tester, packages: const [
      FamilyPackage(id: 'p', active: true, startsOn: '2026-01-13', endsOn: '2027-01-12', soldAtClinicId: 'clinic-1'),
    ]);
    for (final id in ['a', 'b']) {
      final row = find.byKey(Key('me-package-$id'));
      await scrollTo(tester, row);
      expect(find.descendant(of: row, matching: find.textContaining('في العيادتين')), findsOneWidget);
      expect(find.descendant(of: row, matching: find.textContaining('٢٠٢٧')), findsOneWidget);
      expect(find.descendant(of: row, matching: find.text('سارية')), findsOneWidget);
    }
    expect(find.text('باقة يوسف'), findsOneWidget);
  });

  testWidgets('language shows Arabic with "English قريبًا" and does nothing on tap', (tester) async {
    final (h, _) = await open(tester);
    await scrollTo(tester, find.byKey(const Key('me-language')));
    expect(find.text('English قريبًا'), findsOneWidget);
    expect(tester.widget<ListTile>(find.byKey(const Key('me-language'))).onTap, isNull);
    expect(h.location, '/me');
  });

  testWidgets('the preferred clinic is picked from the two clinics and saved on the profile', (tester) async {
    final (_, repo) = await open(tester);
    await tapVisible(tester, find.byKey(const Key('me-preferred-clinic')));
    await tester.tap(find.byKey(const Key('preferred-clinic-2')));
    await tester.pumpAndSettle();
    expect(repo.saved, ['clinic-2']);
  });

  testWidgets('WhatsApp shows only when the clinic has a number; the version is shown', (tester) async {
    await open(tester, whatsapp: null);
    await scrollTo(tester, find.byKey(const Key('me-version')));
    expect(find.byKey(const Key('me-whatsapp')), findsNothing);
    expect(find.text('دكتور النونو · الإصدار ١.٠.٠'), findsOneWidget);
  });

  testWidgets('signed out: a sign-in card, appearance and about, no children or settings that need an account', (tester) async {
    await open(tester, signedIn: false);
    expect(find.byKey(const Key('me-sign-in')), findsOneWidget);
    expect(find.byKey(const Key('me-add-child')), findsNothing);
    expect(find.byKey(const Key('me-preferred-clinic')), findsNothing);
    expect(find.byKey(const Key('me-theme')), findsOneWidget);
  });
}
