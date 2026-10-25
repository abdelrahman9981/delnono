import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/application/session_controller.dart';
import '../features/notifications/data/local_notifier.dart';
import '../features/notifications/data/reminder_sync.dart';
import '../features/registration/data/guardian_repository.dart';

import 'l10n/app_localizations.dart';
import 'messenger.dart';
import 'router.dart';
import 'theme.dart';

class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  ConsumerState<App> createState() => _AppState();
}

class _AppState extends ConsumerState<App> {
  @override
  void initState() {
    super.initState();
    // Once per start, check whether the guardian must pass the re-check after inactivity (FR-010a).
    ref.listenManual(guardianProvider, (_, next) {
      final uid = next.value?.uid;
      if (uid != null) ref.read(sessionControllerProvider.notifier).check(uid);
    }, fireImmediately: true);
    // A tapped reminder opens My bookings or the child's vaccines (007 FR-009).
    ref.read(localNotifierProvider).init(onTap: (route) => ref.read(routerProvider).go(route));
  }

  @override
  Widget build(BuildContext context) {
    // Keeps the phone's reminders in step with the family's data (007 FR-003).
    ref.watch(reminderSyncProvider);
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: appMessengerKey,
      // Arabic only, right to left (constitution Principle IV).
      locale: const Locale('ar'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: ThemeMode.system,
      routerConfig: ref.watch(routerProvider),
    );
  }
}
