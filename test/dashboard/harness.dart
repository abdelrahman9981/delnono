import 'package:delnono/app/l10n/app_localizations.dart';
import 'package:delnono/app/messenger.dart';
import 'package:delnono/dashboard/shell.dart';
import 'package:delnono/dashboard/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Pumps [screen] inside the dashboard shell at a desktop size (1440 × 900) unless [size] is given.
Future<GoRouter> pumpDashboard(
  WidgetTester tester,
  Widget screen, {
  required List<Override> overrides,
  String path = '/today',
  Size size = const Size(1440, 900),
  Brightness brightness = Brightness.light,
  double textScale = 1,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final router = GoRouter(initialLocation: path, routes: [
    ShellRoute(
      builder: (_, s, child) => DashboardShell(location: s.uri.path, child: child),
      routes: [
        GoRoute(path: path, builder: (_, _) => screen),
        GoRoute(path: '/:rest(.*)', builder: (_, s) => Text('route:${s.uri.path}')),
      ],
    ),
  ]);
  await tester.pumpWidget(ProviderScope(
    overrides: overrides,
    child: MaterialApp.router(
      locale: const Locale('ar'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: dashboardTheme(brightness),
      scaffoldMessengerKey: appMessengerKey,
      routerConfig: router,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
    ),
  ));
  await tester.pumpAndSettle();
  return router;
}
