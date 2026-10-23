import 'package:delnono/app/l10n/app_localizations.dart';
import 'package:delnono/app/messenger.dart';
import 'package:delnono/app/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Pumps [routes] in the app's Arabic, RTL theme with [overrides]; other paths show their name.
class ScreenHarness {
  ScreenHarness({required this.initial, required this.routes, List overrides = const []})
      : container = ProviderContainer(overrides: [...overrides]);

  final String initial;
  final List<GoRoute> routes;
  final ProviderContainer container;

  late final GoRouter router = GoRouter(
    initialLocation: initial,
    routes: [
      ...routes,
      GoRoute(path: '/:rest(.*)', builder: (_, s) => Scaffold(body: Text('route:${s.uri.path}'))),
    ],
  );

  String get location => router.routerDelegate.currentConfiguration.uri.toString();

  Future<void> pump(WidgetTester tester) async {
    addTearDown(container.dispose);
    // Phone-sized screen, as in the design mockups (390 × 844 pt).
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
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
        scaffoldMessengerKey: appMessengerKey,
        routerConfig: router,
      ),
    ));
    await tester.pumpAndSettle();
  }
}

/// Scrolls the screen's ListView until [finder] is built and visible.
Future<void> scrollTo(WidgetTester tester, Finder finder) async {
  final list = find.descendant(of: find.byType(ListView), matching: find.byType(Scrollable)).first;
  await tester.scrollUntilVisible(finder, 120, scrollable: list);
  await tester.pumpAndSettle();
}

/// Scrolls [finder] into view in the screen's ListView, then taps it.
Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await scrollTo(tester, finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}
