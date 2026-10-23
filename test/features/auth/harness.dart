import 'package:delnono/app/l10n/app_localizations.dart';
import 'package:delnono/app/theme.dart';
import 'package:delnono/core/settings/settings_repository.dart';
import 'package:delnono/features/auth/application/otp_controller.dart';
import 'package:delnono/features/auth/data/phone_auth_service.dart';
import 'package:delnono/features/auth/presentation/otp_screen.dart';
import 'package:delnono/features/auth/presentation/phone_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'fakes.dart';

/// Sign-in screens on their own router, with a fake phone service, clock and settings.
class SignInHarness {
  factory SignInHarness({AuthSettings settings = const AuthSettings()}) {
    final clock = FakeClock();
    final service = FakePhoneAuthService();
    final container = ProviderContainer(overrides: [
      clockProvider.overrideWithValue(clock.call),
      phoneAuthServiceProvider.overrideWithValue(service),
      authSettingsProvider.overrideWith((ref) => Stream.value(settings)),
    ]);
    return SignInHarness._(container, clock, service);
  }

  SignInHarness._(this.container, this.clock, this.service);

  final ProviderContainer container;
  final FakeClock clock;
  final FakePhoneAuthService service;

  late final GoRouter router = GoRouter(
    initialLocation: '/sign-in?from=%2Fbooking',
    routes: [
      GoRoute(path: '/sign-in', builder: (_, s) => PhoneScreen(from: s.uri.queryParameters['from'])),
      GoRoute(path: '/sign-in/code', builder: (_, s) => OtpScreen(from: s.uri.queryParameters['from'])),
      GoRoute(path: '/welcome', builder: (_, _) => const Text('welcome')),
    ],
  );

  OtpController get otp => container.read(otpControllerProvider.notifier);

  String get location => router.routerDelegate.currentConfiguration.uri.toString();

  Future<void> pump(WidgetTester tester, {String? at}) async {
    addTearDown(container.dispose);
    container.listen(authSettingsProvider, (_, _) {});
    await tester.runAsync(() => container.read(authSettingsProvider.future));
    if (at != null) router.go(at);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        locale: const Locale('ar'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: buildTheme(Brightness.light),
        routerConfig: router,
      ),
    ));
    await tester.pumpAndSettle();
  }

  /// Moves the fake clock and lets the screen's one-second ticker repaint.
  Future<void> wait(WidgetTester tester, Duration d) async {
    clock.advance(d);
    await tester.pump(const Duration(seconds: 1));
  }
}
