import 'package:delnono/core/launch/external_links.dart';
import 'package:delnono/core/settings/settings_repository.dart';
import 'package:delnono/features/child_profile/presentation/follow_up_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../helpers/screen_harness.dart';
import 'fakes.dart';

class _Links implements ExternalLinks {
  final called = <String>[];

  @override
  Future<bool> openWhatsApp(String e164) async => true;

  @override
  Future<bool> callNumber(String number) async {
    called.add(number);
    return true;
  }
}

void main() {
  late _Links links;

  Future<void> open(WidgetTester tester, String childId, {String? clinicPhone = '+201000000000'}) async {
    links = _Links();
    final h = ScreenHarness(
      initial: '/children/$childId/follow-up',
      routes: [GoRoute(path: '/children/:id/follow-up', builder: (_, s) => FollowUpScreen(childId: s.pathParameters['id']!))],
      overrides: [
        ...profileOverrides(children: const [youssef, salma, mariam]),
        externalLinksProvider.overrideWithValue(links),
        clinicSettingsProvider.overrideWith((ref) => Stream.value(ClinicSettings(phoneNumber: clinicPhone))),
      ],
    );
    await h.pump(tester);
  }

  testWidgets('the current age band, marked as placeholder, and the danger signs (FR-016, FR-019)', (tester) async {
    await open(tester, 'c2');
    expect(find.text('متابعة الشهر التاسع'), findsOneWidget);
    expect(find.text('[بند متابعة ٢ من قائمة الدكتور]'), findsOneWidget);
    expect(find.text('أمثلة مؤقتة · يعتمدها الدكتور'), findsOneWidget);
    expect(find.text('متى تتصلين بالدكتور'), findsOneWidget);
    expect(find.textContaining('[علامة خطر ١'), findsOneWidget);
    await scrollTo(tester, find.text('القوايم دي للمتابعة بس، ومش بتشخّص حالة طفلك.'));
  });

  testWidgets('call buttons open the dialer with the clinic number and 123 (FR-017, D-33)', (tester) async {
    await open(tester, 'c2');
    await tapVisible(tester, find.byKey(const Key('call-clinic')));
    await tapVisible(tester, find.byKey(const Key('call-ambulance')));
    expect(links.called, ['+201000000000', '123']);
  });

  testWidgets('without a clinic number only the 123 button shows', (tester) async {
    await open(tester, 'c2', clinicPhone: null);
    expect(find.byKey(const Key('call-clinic')), findsNothing);
    expect(find.byKey(const Key('call-ambulance')), findsOneWidget);
  });

  testWidgets('from age 4 the age list is hidden; danger signs and buttons remain (FR-018)', (tester) async {
    await open(tester, 'c3');
    expect(find.byKey(const Key('follow-up-band')), findsNothing);
    expect(find.text('المتابعة حسب العمر بتغطي لحد ٤ سنين.'), findsOneWidget);
    expect(find.byKey(const Key('when-to-call')), findsOneWidget);
    expect(find.byKey(const Key('call-ambulance')), findsOneWidget);
  });
}
