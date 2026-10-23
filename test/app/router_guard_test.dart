import 'package:delnono/app/app.dart';
import 'package:delnono/app/route_guard.dart';
import 'package:delnono/app/router.dart';
import 'package:delnono/core/settings/settings_repository.dart';
import 'package:delnono/features/auth/data/auth_repository.dart';
import 'package:delnono/features/children/data/children_repository.dart';
import 'package:delnono/features/registration/data/guardian_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mocktail/mocktail.dart';
import 'package:delnono/features/shell/shell_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// A registered guardian with current consent and nothing pending.
const ready = GuardState(signedIn: true, hasGuardian: true, consentCurrent: true, hasChildren: true);

GuardState with_({
  bool? signedIn,
  bool? hasGuardian,
  bool? consentCurrent,
  bool? reverifyRequired,
  bool? clinicChildrenPending,
  bool? linkSkipped,
  bool? registrationInProgress,
  bool? hasChildren,
}) =>
    GuardState(
      signedIn: signedIn ?? ready.signedIn,
      hasGuardian: hasGuardian ?? ready.hasGuardian,
      consentCurrent: consentCurrent ?? ready.consentCurrent,
      reverifyRequired: reverifyRequired ?? ready.reverifyRequired,
      clinicChildrenPending: clinicChildrenPending ?? ready.clinicChildrenPending,
      linkSkipped: linkSkipped ?? ready.linkSkipped,
      registrationInProgress: registrationInProgress ?? ready.registrationInProgress,
      hasChildren: hasChildren ?? ready.hasChildren,
    );

String? go(String location, GuardState s) => guardRedirect(Uri.parse(location), s);

void main() {
  group('guard steps in order (contracts/routes.md)', () {
    test('1. signed out → sign-in, keeping from', () {
      expect(go('/booking', const GuardState()), '/sign-in?from=%2Fbooking');
    });

    test('2. no guardian doc → guardian details', () {
      expect(go('/booking', with_(hasGuardian: false, consentCurrent: false)),
          '/register/guardian?from=%2Fbooking');
    });

    test('3. consent outdated → consent', () {
      expect(go('/children', with_(consentCurrent: false)), '/register/consent?from=%2Fchildren');
    });

    test('3a. re-check after inactivity → reverify', () {
      expect(go('/children', with_(reverifyRequired: true)), '/reverify?from=%2Fchildren');
    });

    test('4. clinic children pending → link check', () {
      expect(go('/booking', with_(clinicChildrenPending: true)), '/register/link?from=%2Fbooking');
    });

    test('4. skipped this session → not redirected', () {
      expect(go('/booking', with_(clinicChildrenPending: true, linkSkipped: true)), isNull);
    });

    test('5. registration in progress without children → first child', () {
      expect(go('/booking', with_(registrationInProgress: true, hasChildren: false)),
          '/register/child?from=%2Fbooking');
    });

    test('5. /children/add is reachable during registration', () {
      expect(go('/children/add', with_(registrationInProgress: true, hasChildren: false)), isNull);
    });

    test('6. nothing pending → allowed', () {
      for (final path in ['/booking', '/children', '/children/abc', '/account', '/account/phone']) {
        expect(go(path, ready), isNull, reason: path);
      }
    });

    test('earlier steps win over later ones', () {
      const all = GuardState(
        signedIn: true,
        reverifyRequired: true,
        clinicChildrenPending: true,
        registrationInProgress: true,
      );
      expect(go('/booking', all), '/register/guardian?from=%2Fbooking');
    });
  });

  group('no children outside registration', () {
    test('a guardian with no children after a locked link check is not redirected', () {
      final locked = with_(hasChildren: false, clinicChildrenPending: false);
      for (final path in ['/booking', '/children', '/account']) {
        expect(go(path, locked), isNull, reason: path);
      }
    });
  });

  group('public routes (US3)', () {
    test('welcome, home and content are open to a signed-out visitor', () {
      for (final path in ['/welcome', '/', '/content']) {
        expect(go(path, const GuardState()), isNull, reason: path);
      }
    });

    test('home and content stay open to a signed-in guardian', () {
      expect(go('/', ready), isNull);
      expect(go('/content', ready), isNull);
    });

    test('welcome is only for signed-out visitors; a signed-in guardian goes home', () {
      expect(go('/welcome', ready), '/');
      expect(go('/welcome', with_(hasGuardian: false, consentCurrent: false)), '/');
    });

    test('welcome waits while auth is loading', () {
      expect(go('/welcome', GuardState.loadingState), isNull);
    });
  });

  group('from survives the whole chain', () {
    const from = '/children/abc';
    final target = '?from=${Uri.encodeComponent(from)}';

    test('each finished step moves to the next one, keeping from', () {
      expect(go('/children/abc', const GuardState()), '/sign-in$target');
      expect(go('/sign-in/code$target', with_(hasGuardian: false, consentCurrent: false)),
          '/register/guardian$target');
      expect(go('/register/consent$target', with_(clinicChildrenPending: true)),
          '/register/link$target');
      expect(go('/register/link$target', with_(registrationInProgress: true, hasChildren: false)),
          '/register/child$target');
      expect(go('/register/child$target', ready), from);
    });

    test('staying on the current step does not redirect', () {
      expect(go('/sign-in$target', const GuardState()), isNull);
      expect(go('/sign-in/code$target', const GuardState()), isNull);
      expect(go('/register/guardian$target', with_(hasGuardian: false, consentCurrent: false)), isNull);
      expect(go('/register/consent$target', with_(hasGuardian: false, consentCurrent: false)), isNull);
    });

    test('a flow step with no from ends at home', () {
      expect(go('/sign-in', ready), '/');
    });
  });

  group('from is sanitised', () {
    for (final bad in [
      '//evil.com',
      'https://evil.com/x',
      'evil.com',
      r'/\evil.com',
      'javascript:alert(1)',
      '/sign-in',
      '/register/consent',
    ]) {
      test('"$bad" falls back to /', () {
        expect(safeFrom(bad), '/');
        expect(go('/sign-in?from=${Uri.encodeComponent(bad)}', ready), '/');
      });
    }

    test('internal paths with a query are kept', () {
      expect(safeFrom('/children/abc?tab=vaccines'), '/children/abc?tab=vaccines');
    });
  });

  test('no decision while loading', () {
    expect(go('/booking', GuardState.loadingState), isNull);
  });

  group('router with overridden providers', () {
    Future<GoRouter> pumpApp(WidgetTester tester, GuardState state) async {
      // Phone-sized screen, as in the design mockups (390 × 844 pt).
      tester.view.physicalSize = const Size(1170, 2532);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(ProviderScope(
        overrides: [guardStateProvider.overrideWithValue(state)],
        child: const App(),
      ));
      await tester.pumpAndSettle();
      return ProviderScope.containerOf(tester.element(find.byType(App))).read(routerProvider);
    }

    String location(GoRouter router) => router.routerDelegate.currentConfiguration.uri.toString();

    testWidgets('signed out: the app starts at Welcome', (tester) async {
      final router = await pumpApp(tester, const GuardState());
      expect(location(router), '/welcome');
      expect(find.text('سجّلي برقم موبايلك'), findsOneWidget);
      expect(find.byType(ShellScaffold), findsNothing);
    });

    testWidgets('signed in: the app starts at home inside the shell', (tester) async {
      final router = await pumpApp(tester, ready);
      expect(location(router), '/');
      expect(find.byType(ShellScaffold), findsOneWidget);
    });

    testWidgets('signed out: browse content first opens Content inside the shell', (tester) async {
      final router = await pumpApp(tester, const GuardState());
      await tester.tap(find.text('اتفرجي على المحتوى الأول'));
      await tester.pumpAndSettle();
      expect(location(router), '/content');
      expect(find.byType(ShellScaffold), findsOneWidget);
    });

    testWidgets('signed out: register with mobile opens sign-in', (tester) async {
      final router = await pumpApp(tester, const GuardState());
      await tester.tap(find.text('سجّلي برقم موبايلك'));
      await tester.pumpAndSettle();
      expect(location(router), '/sign-in');
    });

    testWidgets('signed out: booking goes to sign-in with from', (tester) async {
      final router = await pumpApp(tester, const GuardState());
      router.go('/booking');
      await tester.pumpAndSettle();
      expect(location(router), '/sign-in?from=%2Fbooking');
    });

    testWidgets('registered: booking opens inside the shell', (tester) async {
      final router = await pumpApp(tester, ready);
      router.go('/booking');
      await tester.pumpAndSettle();
      expect(location(router), '/booking');
      expect(find.byType(ShellScaffold), findsOneWidget);
    });

    testWidgets('bottom navigation fits at the largest system text size', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2.0;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await pumpApp(tester, ready);
      expect(tester.takeException(), isNull);
    });

    testWidgets('shell has four tabs and an empty reserved slot', (tester) async {
      await pumpApp(tester, ready);
      expect(find.text('الرئيسية'), findsWidgets);
      expect(find.text('حجز'), findsOneWidget);
      expect(find.text('طفلي'), findsOneWidget);
      expect(find.text('محتوى'), findsOneWidget);
      final slot = find.byKey(ShellScaffold.reservedSlotKey);
      expect(slot, findsOneWidget);
      expect(find.descendant(of: slot, matching: find.byType(InkWell)), findsNothing);
      expect(Directionality.of(tester.element(slot)), TextDirection.rtl);
    });
  });

  group('guardStateProvider', () {
    ProviderContainer containerWith(Stream<Guardian?> guardian) {
      final container = ProviderContainer(overrides: [
        authStateProvider.overrideWith((ref) => Stream.value(_MockUser())),
        guardianProvider.overrideWith((ref) => guardian),
        policySettingsProvider.overrideWith((ref) => Stream.value(const PolicySettings())),
        childrenProvider.overrideWith((ref) => Stream.value(const [])),
      ]);
      addTearDown(container.dispose);
      container.listen(guardStateProvider, (_, _) {});
      return container;
    }

    Future<GuardState> settled(ProviderContainer c) async {
      for (var i = 0; i < 20 && c.read(guardStateProvider).loading; i++) {
        await Future<void>.delayed(Duration.zero);
      }
      return c.read(guardStateProvider);
    }

    test('a guardian read that fails (e.g. permission denied) is not treated as loading', () async {
      final c = containerWith(Stream.error(FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied')));
      final s = await settled(c);
      expect(s.loading, isFalse, reason: 'Riverpod retries keep isLoading true; the guard must still decide');
      expect(s.signedIn, isTrue);
      expect(s.hasGuardian, isFalse);
      expect(go('/booking', s), '/register/guardian?from=%2Fbooking');
    });

    test('a signed-in user without a guardian doc goes to registration', () async {
      final s = await settled(containerWith(Stream.value(null)));
      expect(s.loading, isFalse);
      expect(s.hasGuardian, isFalse);
    });
  });
}

class _MockUser extends Mock implements User {}

