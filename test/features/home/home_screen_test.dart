import 'package:delnono/core/launch/external_links.dart';
import 'package:delnono/features/clinics/data/clinics_repository.dart';
import 'package:delnono/features/home/home_screen.dart';
import 'package:delnono/features/registration/data/guardian_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../helpers/clinic_fakes.dart';
import '../../helpers/screen_harness.dart';

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

  Future<ScreenHarness> open(WidgetTester tester, {List<Clinic> clinics = const [clinic1, clinic2], Guardian? guardian}) async {
    links = _Links();
    final h = ScreenHarness(
      initial: '/',
      routes: [GoRoute(path: '/', builder: (_, _) => const HomeScreen())],
      overrides: [
        ...clinicOverrides(clinics: clinics),
        guardianProvider.overrideWith((ref) => Stream.value(guardian)),
        externalLinksProvider.overrideWithValue(links),
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

  testWidgets("the waiting room shows on the main clinic's card only; each card has the doctor's avatar", (tester) async {
    await open(tester);
    expect(find.byKey(const Key('clinic-photo-clinic-1')), findsOneWidget);
    expect(find.byKey(const Key('clinic-photo-clinic-2')), findsNothing);
    await scrollTo(tester, find.byKey(const Key('clinic-card-clinic-2')));
    expect(
      find.descendant(of: find.byKey(const Key('clinic-card-clinic-2')), matching: find.byType(CircleAvatar)),
      findsOneWidget,
    );
  });
}
