import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/l10n/app_localizations.dart';
import '../app/messenger.dart';
import 'router.dart';
import 'theme.dart';

/// The dashboard shares the app's theme (tokens.css) and Arabic strings (FR-026).
class DashboardApp extends ConsumerWidget {
  const DashboardApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp.router(
    onGenerateTitle: (context) => AppLocalizations.of(context).dashTitle,
    debugShowCheckedModeBanner: false,
    scaffoldMessengerKey: appMessengerKey,
    locale: const Locale('ar'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    theme: dashboardTheme(Brightness.light),
    darkTheme: dashboardTheme(Brightness.dark),
    themeMode: ThemeMode.system,
    routerConfig: ref.watch(dashboardRouterProvider),
  );
}
