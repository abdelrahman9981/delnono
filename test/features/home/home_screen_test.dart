import 'package:delnono/core/launch/external_links.dart';
import 'package:delnono/features/auth/data/auth_repository.dart';
import 'package:delnono/features/clinics/data/clinics_repository.dart';
import 'package:delnono/features/content/domain/content_item.dart';
import 'package:delnono/features/home/home_screen.dart';
import 'package:delnono/features/registration/data/guardian_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../helpers/clinic_fakes.dart';
import '../../helpers/screen_harness.dart';
import '../content/fakes.dart';

class _Links implements ExternalLinks {
  final opened = <String>[];
  final called = <String>[];

  @override
  Future<bool> openWhatsApp(String e164) async {
    opened.add(e164);
    return true;
  }

  @override
  Future<bool> callNumber(String number) async {
    called.add(number);
    return true;
  }
}

void main() {
  late _Links links;

  Future<ScreenHarness> open(
    WidgetTester tester, {
    List<Clinic> clinics = const [clinic1, clinic2],
    Guardian? guardian,
    List<ContentItem> content = const [],
  }) async {
    links = _Links();
    final h = ScreenHarness(
      initial: '/',
      routes: [GoRoute(path: '/', builder: (_, _) => const HomeScreen())],
      overrides: [
        ...clinicOverrides(clinics: clinics, content: content),
        guardianProvider.overrideWith((ref) => Stream.value(guardian)),
        externalLinksProvider.overrideWithValue(links),
        // Signed out unless a test says otherwise: no bell (007 FR-008).
        authStateProvider.overrideWith((ref) => Stream.value(null)),
      ],
    );
    await h.pump(tester);
    return h;
  }

  testWidgets('the doctor card and both clinic cards with address and hours (FR-013)', (tester) async {
    await open(tester);
    expect(find.byKey(const Key('doctor-card')), findsOneWidget);
    expect(find.text('أهلًا بيكي'), findsOneWidget);
    await scrollTo(tester, find.byKey(const Key('clinic-card-clinic-2')));
    expect(find.text(clinic1.name), findsOneWidget);
    expect(find.text(clinic2.address), findsOneWidget);
    expect(find.textContaining('السبت'), findsOneWidget, reason: 'clinic 1 opens on Saturday');
    expect(find.textContaining('١٠ ص لـ ٢ م'), findsOneWidget, reason: "clinic 2's morning hours");
  });

  testWidgets('a signed-in guardian is greeted by first name', (tester) async {
    await open(
      tester,
      guardian: const Guardian(uid: 'u1', phone: '+201000000099', fullName: 'سارة محمود', relation: Relation.mother, consentVersion: 1),
    );
    expect(find.text('أهلًا يا سارة'), findsOneWidget);
  });

  testWidgets("call and WhatsApp use the card's clinic numbers", (tester) async {
    await open(tester);
    await tapVisible(tester, find.byKey(const Key('call-clinic-2')));
    await tapVisible(tester, find.byKey(const Key('whatsapp-clinic-2')));
    expect(links.called, [clinic2.phone]);
    expect(links.opened, [clinic2.whatsapp]);
  });

  testWidgets('"احجزي هنا" opens booking with that clinic', (tester) async {
    final h = await open(tester);
    await tapVisible(tester, find.byKey(const Key('book-at-clinic-2')));
    expect(h.location, '/booking?clinic=clinic-2');
  });

  testWidgets('a missing number hides its button; an inactive clinic is not shown (FR-003)', (tester) async {
    await open(tester, clinics: const [
      Clinic(id: 'a', name: '[أ]', area: 'أ', address: '[عنوان أ]', active: true, whatsapp: '+201000000005'),
      Clinic(id: 'b', name: '[ب]', area: 'ب', address: '[عنوان ب]', active: false, phone: '+201000000006'),
    ]);
    expect(find.byKey(const Key('call-a')), findsNothing);
    expect(find.byKey(const Key('whatsapp-a')), findsOneWidget);
    expect(find.byKey(const Key('clinic-card-b')), findsNothing);
  });

  testWidgets("the doctor's real photo; the tagline never overlaps the name (docs/design/README.md)", (tester) async {
    await open(tester);
    expect(find.byKey(const Key('doctor-photo')), findsOneWidget);
    expect(find.textContaining('صورة د.'), findsNothing, reason: 'no placeholder caption');
    final tagline = tester.getRect(find.byKey(const Key('doctor-tagline')));
    final name = tester.getRect(find.descendant(of: find.byKey(const Key('doctor-card')), matching: find.text('د. أحمد العبد')));
    expect(tagline.overlaps(name), isFalse);
    expect(tagline.bottom, lessThan(name.top));
  });

  testWidgets('each clinic card shows its picture and the doctor\'s avatar (Moqattam: waiting room; second: illustration)', (tester) async {
    await open(tester);
    final first = tester.widget<Image>(find.byKey(const Key('clinic-photo-clinic-1')));
    expect((first.image as AssetImage).assetName, 'assets/images/clinic_waiting_room.jpg');
    await scrollTo(tester, find.byKey(const Key('clinic-card-clinic-2')));
    final second = tester.widget<Image>(find.byKey(const Key('clinic-photo-clinic-2')));
    expect((second.image as AssetImage).assetName, 'assets/images/clinic2_illustration.jpg');
    expect(
      find.descendant(of: find.byKey(const Key('clinic-card-clinic-2')), matching: find.byType(CircleAvatar)),
      findsOneWidget,
    );
  });

  testWidgets('the annual package card opens the package page (008 FR-002)', (tester) async {
    final h = await open(tester);
    await tapVisible(tester, find.byKey(const Key('home-package')));
    expect(h.location, '/package');
  });

  testWidgets('the latest 3 published items, newest first, and «كل المحتوى» (006 FR-010)', (tester) async {
    final h = await open(tester, content: sampleContent);
    await scrollTo(tester, find.byKey(const Key('home-content')));
    for (final id in ['salt', 'vitd', 'tip-fever']) {
      await scrollTo(tester, find.byKey(Key('home-$id')));
    }
    expect(find.byKey(const Key('home-newborn')), findsNothing, reason: 'the oldest of four');
    final salt = tester.getTopLeft(find.byKey(const Key('home-salt'))).dy;
    final vitd = tester.getTopLeft(find.byKey(const Key('home-vitd'))).dy;
    expect(salt, lessThan(vitd));
    await tapVisible(tester, find.byKey(const Key('home-content-all')));
    expect(h.location, '/content');
  });

  testWidgets('no published content: no content card', (tester) async {
    await open(tester);
    await scrollTo(tester, find.byKey(const Key('clinic-card-clinic-2')));
    expect(find.byKey(const Key('home-content')), findsNothing);
  });
}
