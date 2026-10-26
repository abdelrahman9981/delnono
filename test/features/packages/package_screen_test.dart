import 'package:delnono/core/clock.dart';
import 'package:delnono/features/auth/data/auth_repository.dart';
import 'package:delnono/features/clinics/data/clinics_repository.dart';
import 'package:delnono/features/packages/data/packages_repository.dart';
import 'package:delnono/features/packages/domain/family_package.dart';
import 'package:delnono/features/packages/presentation/package_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/clinic_fakes.dart';
import '../../helpers/screen_harness.dart';

class _User extends Mock implements User {}

/// Sunday 15 Nov 2026, 12:00 Cairo.
final now = DateTime.utc(2026, 11, 15, 10);

Clinic withPackage(Clinic c, int price) => Clinic(
      id: c.id,
      name: c.name,
      area: c.area,
      address: c.address,
      phone: c.phone,
      whatsapp: c.whatsapp,
      order: c.order,
      workingHours: c.workingHours,
      packagePrice: price,
      packageMonths: 12,
    );

Future<void> open(WidgetTester tester, {List<FamilyPackage> packages = const [], bool signedIn = true}) async {
  final h = ScreenHarness(
    initial: '/package',
    routes: [GoRoute(path: '/package', builder: (_, _) => const PackageScreen())],
    overrides: [
      clockProvider.overrideWithValue(() => now),
      authStateProvider.overrideWith((ref) => Stream.value(signedIn ? _User() : null)),
      familyPackageListProvider.overrideWith((ref) => Stream.value(packages)),
      ...clinicOverrides(clinics: [withPackage(clinic1, 1500), withPackage(clinic2, 1600)]),
    ],
  );
  await h.pump(tester);
}

void main() {
  testWidgets("each clinic's price and months come from its settings; the rules are listed (FR-002, D-45)", (tester) async {
    await open(tester, signedIn: false);
    expect(find.descendant(of: find.byKey(const Key('pkg-price-clinic-1')), matching: find.text('١٥٠٠ جنيه · ١٢ شهر')), findsOneWidget);
    expect(find.descendant(of: find.byKey(const Key('pkg-price-clinic-2')), matching: find.text('١٦٠٠ جنيه · ١٢ شهر')), findsOneWidget);
    expect(find.text('سارية في العيادتين.'), findsOneWidget);
    expect(find.text('التطعيمات بتتحسب بسعرها المعتاد.'), findsOneWidget);
    expect(find.byKey(const Key('pkg-status')), findsNothing, reason: 'signed out');
  });

  testWidgets("the family's package comes first: active until its end, or the renewal's end (FR-003)", (tester) async {
    await open(tester, packages: const [
      FamilyPackage(id: 'a', active: true, startsOn: '2025-11-26', endsOn: '2026-11-25', soldAtClinicId: 'clinic-1'),
      FamilyPackage(id: 'b', active: true, startsOn: '2026-11-26', endsOn: '2027-11-25', soldAtClinicId: 'clinic-2'),
    ]);
    final status = find.byKey(const Key('pkg-status'));
    expect(find.descendant(of: status, matching: find.text('سارية')), findsOneWidget);
    expect(find.descendant(of: status, matching: find.textContaining('اتجددت لحد')), findsOneWidget);
    expect(find.descendant(of: status, matching: find.textContaining('٢٠٢٧')), findsOneWidget);
  });

  testWidgets('an ended package says when it ended', (tester) async {
    await open(tester, packages: const [
      FamilyPackage(id: 'a', active: true, startsOn: '2025-01-01', endsOn: '2025-12-31', soldAtClinicId: 'clinic-1'),
    ]);
    expect(find.descendant(of: find.byKey(const Key('pkg-status')), matching: find.text('خلصت')), findsOneWidget);
  });
}
