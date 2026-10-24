import 'package:delnono/core/launch/external_links.dart';
import 'package:delnono/core/settings/settings_repository.dart';
import 'package:delnono/features/clinics/data/clinics_repository.dart';
import 'package:delnono/features/account/presentation/account_screen.dart';
import 'package:delnono/features/auth/data/auth_repository.dart';
import 'package:delnono/features/children/data/children_repository.dart';
import 'package:delnono/features/registration/data/guardian_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/screen_harness.dart';

class _Links implements ExternalLinks {
  final opened = <String>[];

  @override
  Future<bool> openWhatsApp(String e164) async {
    opened.add(e164);
    return true;
  }

  @override
  Future<bool> callNumber(String number) async => true;
}

class _Auth extends Mock implements AuthRepository {
  int signOuts = 0;

  @override
  Future<void> signOut() async => signOuts++;
}

const guardian = Guardian(
  uid: 'u1',
  phone: '+201012345678',
  fullName: 'سارة محمود عبد الله',
  relation: Relation.mother,
  consentVersion: 1,
);

const kids = [
  Child(id: 'a', name: 'يوسف', birthDate: '2024-03-15', sex: Sex.male),
  Child(id: 'b', name: 'مريم', birthDate: '2022-07-02', sex: Sex.female),
];

void main() {
  late _Links links;
  late _Auth auth;

  Future<ScreenHarness> open(WidgetTester tester, {String? whatsapp = '+201000000000'}) async {
    links = _Links();
    auth = _Auth();
    final h = ScreenHarness(
      initial: '/account',
      routes: [GoRoute(path: '/account', builder: (_, _) => const AccountScreen())],
      overrides: [
        guardianProvider.overrideWith((ref) => Stream.value(guardian)),
        childrenProvider.overrideWith((ref) => Stream.value(kids)),
        policySettingsProvider.overrideWith((ref) => Stream.value(const PolicySettings(privacyPolicyText: 'سياسة'))),
        allClinicsProvider.overrideWith(
          (ref) => Stream.value([Clinic(id: 'clinic-1', name: '[عيادة]', area: 'س', address: '[عنوان]', active: true, whatsapp: whatsapp)]),
        ),
        externalLinksProvider.overrideWithValue(links),
        authRepositoryProvider.overrideWithValue(auth),
      ],
    );
    await h.pump(tester);
    return h;
  }

  testWidgets('shows guardian, number, relation, children and accepted version (FR-033)', (tester) async {
    await open(tester);
    expect(find.text('سارة محمود عبد الله'), findsOneWidget);
    expect(find.text('+20 10 1234 5678'), findsOneWidget);
    expect(find.text('أم'), findsOneWidget);
    expect(find.text('يوسف · مريم · إضافة طفل'), findsOneWidget);
    expect(find.text('وافقتي على الإصدار ١'), findsOneWidget);
  });

  testWidgets('WhatsApp opens the clinic number and says support only, not booking (FR-034)', (tester) async {
    await open(tester);
    expect(find.text('للاستفسار والدعم، مش للحجز'), findsOneWidget);
    await tapVisible(tester, find.byKey(const Key('account-whatsapp')));
    expect(links.opened, ['+201000000000']);
  });

  testWidgets('without a clinic number, WhatsApp explains instead of failing', (tester) async {
    await open(tester, whatsapp: null);
    await tapVisible(tester, find.byKey(const Key('account-whatsapp')));
    expect(links.opened, isEmpty);
    expect(find.text('رقم واتساب العيادة لسه مش متاح.'), findsOneWidget);
  });

  testWidgets('Notifications opens the placeholder page (FR-035)', (tester) async {
    final h = await open(tester);
    await tapVisible(tester, find.byKey(const Key('account-notifications')));
    expect(h.location, '/notifications');
  });

  testWidgets('change number, children and delete go to their screens', (tester) async {
    final h = await open(tester);
    await tapVisible(tester, find.byKey(const Key('account-change-phone')));
    expect(h.location, '/account/phone');
    h.router.go('/account');
    await tester.pumpAndSettle();
    await tapVisible(tester, find.byKey(const Key('account-delete')));
    expect(h.location, '/account/delete');
  });

  testWidgets('the delete card explains what the clinic keeps', (tester) async {
    await open(tester);
    await scrollTo(tester, find.byKey(const Key('account-delete')));
    expect(
      find.text('هنمسح حسابك وبياناتك من التطبيق. ملفات أطفالك الطبية بتفضل عند العيادة للمدة اللي يحددها القانون.'),
      findsOneWidget,
    );
  });

  testWidgets('sign out signs out and returns to Welcome', (tester) async {
    final h = await open(tester);
    await tapVisible(tester, find.byKey(const Key('account-sign-out')));
    expect(auth.signOuts, 1);
    expect(h.location, '/welcome');
  });
}
