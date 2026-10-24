// T085: every 001 screen in light and dark mode, at 375 pt width and at large system text,
// renders without overflow (no clipped Arabic text). Colours come from the theme, which is built
// from docs/design/tokens.css (lib/app/theme.dart).

import 'package:delnono/app/l10n/app_localizations.dart';
import 'package:delnono/app/theme.dart';
import 'package:delnono/core/launch/external_links.dart';
import 'package:delnono/core/settings/settings_repository.dart';
import 'package:delnono/features/account/presentation/account_screen.dart';
import 'package:delnono/features/account/presentation/change_phone_screen.dart';
import 'package:delnono/features/account/presentation/delete_account_screen.dart';
import 'package:delnono/features/auth/application/otp_controller.dart';
import 'package:delnono/features/auth/data/auth_repository.dart';
import 'package:delnono/features/auth/data/phone_auth_service.dart';
import 'package:delnono/features/auth/presentation/otp_screen.dart';
import 'package:delnono/features/auth/presentation/phone_screen.dart';
import 'package:delnono/features/auth/presentation/reverify_screen.dart';
import 'package:delnono/features/booking/application/booking_form_controller.dart';
import 'package:delnono/features/booking/data/booking_settings.dart';
import 'package:delnono/features/booking/data/packages_repository.dart';
import 'package:delnono/features/booking/data/bookings_repository.dart';
import 'package:delnono/features/booking/data/slots_repository.dart';
import 'package:delnono/features/booking/data/vaccines_repository.dart';
import 'package:delnono/features/booking/domain/booking.dart';
import 'package:delnono/features/booking/domain/price_preview.dart';
import 'package:delnono/features/booking/presentation/booking_screen.dart';
import 'package:delnono/features/booking/presentation/booking_success_screen.dart';
import 'package:delnono/features/booking/presentation/my_bookings_screen.dart';
import 'package:delnono/features/children/data/children_repository.dart';
import 'package:delnono/features/children/presentation/add_child_screen.dart';
import 'package:delnono/features/children/presentation/child_profile_screen.dart';
import 'package:delnono/features/children/presentation/children_list_screen.dart';
import 'package:delnono/features/registration/application/registration_controller.dart';
import 'package:delnono/features/registration/data/guardian_repository.dart';
import 'package:delnono/features/registration/data/registration_api.dart';
import 'package:delnono/features/registration/presentation/consent_screen.dart';
import 'package:delnono/features/registration/presentation/guardian_details_screen.dart';
import 'package:delnono/features/registration/presentation/link_children_screen.dart';
import 'package:delnono/features/shell/shell_scaffold.dart';
import 'package:delnono/features/welcome/welcome_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../features/auth/fakes.dart';
import '../helpers/rtl_icons.dart';
import '../features/registration/fakes.dart';

class _User extends Mock implements User {
  @override
  String get uid => 'u1';
}

class _Links implements ExternalLinks {
  @override
  Future<bool> openWhatsApp(String e164) async => true;
}

const guardian = Guardian(
  uid: 'u1',
  phone: '+201012345678',
  fullName: 'سارة محمود عبد الله الطويل',
  relation: Relation.mother,
  consentVersion: 1,
);
const kids = [
  Child(id: 'a', name: 'يوسف أحمد محمود', birthDate: '2024-03-15', sex: Sex.male, allergies: 'بنسلين', birthWeightKg: 3.2),
  Child(id: 'b', name: 'مريم', birthDate: '2022-07-02', sex: Sex.female),
];

final sampleBooking = Booking(
  id: 'bk',
  number: 248,
  visitType: VisitType.visit,
  children: const [
    BookedChild(childId: 'a', name: 'يوسف أحمد محمود', vaccines: ['v1']),
    BookedChild(childId: 'b', name: 'مريم', vaccines: []),
  ],
  date: '2026-11-16',
  hour: 18,
  startsAt: DateTime.utc(2026, 11, 16, 16),
  status: BookingStatus.confirmed,
  price: const PriceSnapshot(
    visitAmount: 300,
    visitCovered: false,
    vaccines: [VaccineLine(childId: 'a', vaccineId: 'v1', name: '[تطعيم مؤقت ١]', amount: 150, shown: true)],
    total: 450,
    hasHiddenPrices: false,
  ),
);

final screens = <String, Widget Function()>{
  'booking': () => const ShellScaffold(location: '/booking', child: BookingScreen()),
  'booking success': () => const BookingSuccessScreen(bookingId: 'bk'),
  'my bookings': () => const MyBookingsScreen(),
  'change booking': () => const BookingScreen(changeBookingId: 'bk'),
  'welcome': () => const WelcomeScreen(),
  'phone': () => const PhoneScreen(),
  'otp': () => const OtpScreen(),
  'guardian': () => const GuardianDetailsScreen(),
  'consent': () => const ConsentScreen(),
  'add child': () => const AddChildScreen(registration: true),
  'link children': () => const LinkChildrenScreen(),
  'reverify': () => const ReverifyScreen(),
  'children list': () => const ShellScaffold(location: '/children', child: ChildrenListScreen()),
  'child profile': () => const ChildProfileScreen(childId: 'a'),
  'account': () => const AccountScreen(),
  'change phone': () => const ChangePhoneScreen(),
  'delete account': () => const DeleteAccountScreen(),
};

void main() {
  for (final brightness in Brightness.values) {
    for (final scale in [1.0, 2.0]) {
      for (final MapEntry(key: name, value: build) in screens.entries) {
        testWidgets('$name · ${brightness.name} · text ×$scale · 375 pt', (tester) async {
          tester.view.physicalSize = const Size(1125, 2001); // 375 × 667 pt at 3×
          tester.view.devicePixelRatio = 3;
          addTearDown(tester.view.reset);

          final clock = FakeClock();
          final container = ProviderContainer(overrides: [
            authStateProvider.overrideWith((ref) => Stream.value(_User())),
            guardianProvider.overrideWith((ref) => Stream.value(guardian)),
            childrenProvider.overrideWith((ref) => Stream.value(kids)),
            authSettingsProvider.overrideWith((ref) => Stream.value(const AuthSettings())),
            policySettingsProvider.overrideWith(
              (ref) => Stream.value(PolicySettings(privacyPolicyText: '[نص مؤقت]', updatedAt: DateTime(2026, 10, 22))),
            ),
            clinicSettingsProvider.overrideWith((ref) => Stream.value(const ClinicSettings(whatsappNumber: '+201000000000'))),
            phoneAuthServiceProvider.overrideWithValue(FakePhoneAuthService()),
            registrationApiProvider.overrideWithValue(FakeRegistrationApi()),
            externalLinksProvider.overrideWithValue(_Links()),
            clockProvider.overrideWithValue(clock.call),
            bookingSettingsProvider.overrideWith((ref) => Stream.value(const BookingSettings())),
            vaccinesProvider.overrideWith((ref) => Stream.value(const [
                  Vaccine(id: 'v1', name: '[تطعيم مؤقت ١]', price: 150, showPrice: true),
                  Vaccine(id: 'v3', name: '[تطعيم مؤقت ٣]', price: 450, showPrice: false),
                ])),
            slotsTakenProvider.overrideWith((ref, date) => Stream.value(const {17: 6, 18: 2})),
            myBookingsProvider.overrideWith((ref) => Stream.value([sampleBooking])),
            activePackageProvider.overrideWith((ref, date) => Stream.value(null)),
          ]);
          addTearDown(container.dispose);
          container.read(registrationControllerProvider.notifier).setDetails(
                const GuardianDetails(fullName: 'سارة', relation: Relation.mother),
              );
          await tester.runAsync(() => container.read(otpControllerProvider.notifier).sendCode('+201012345678'));
          // A full booking selection, so the booking summary is laid out too (Mon 26 Oct is a vaccine day).
          container.listen(bookingFormProvider, (_, _) {});
          container.read(bookingFormProvider.notifier)
            ..setDate('2026-10-26', const BookingSettings())
            ..setHour(18)
            ..toggleChild('a')
            ..toggleChild('b')
            ..toggleVaccine('a', 'v1');

          await tester.pumpWidget(UncontrolledProviderScope(
            container: container,
            child: MaterialApp.router(
              routerConfig: GoRouter(routes: [GoRoute(path: '/', builder: (_, _) => build())]),
              locale: const Locale('ar'),
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              theme: buildTheme(brightness),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
                child: child!,
              ),
            ),
          ));
          await tester.pump(const Duration(milliseconds: 500));
          expect(tester.takeException(), isNull);
          expect(wrongWayIcons(tester), isEmpty, reason: 'chevrons and back icons must follow RTL');

          // Scroll to the end too, so content below the fold is laid out and checked.
          final lists = find.byType(Scrollable);
          if (lists.evaluate().isNotEmpty) {
            await tester.drag(lists.first, const Offset(0, -3000), warnIfMissed: false);
            await tester.pump(const Duration(milliseconds: 300));
            expect(tester.takeException(), isNull);
          }
        });
      }
    }
  }
}
