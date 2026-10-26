import 'package:delnono/app/l10n/app_localizations.dart';
import 'package:delnono/app/theme.dart';
import 'package:delnono/core/clock.dart';
import 'package:delnono/features/auth/data/auth_repository.dart';
import 'package:delnono/features/content/presentation/library_screen.dart';
import 'package:delnono/features/content/presentation/tip_screen.dart';
import 'package:delnono/features/content/presentation/video_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../child_profile/fakes.dart' show today;
import 'fakes.dart';

/// Content screens on a small phone, light and dark, at normal and large text (FR-012).
void main() {
  for (final path in ['/content', '/content/tip/tip-fever', '/content/video/salt']) {
    for (final brightness in Brightness.values) {
      for (final scale in [1.0, 1.6]) {
        testWidgets('$path · ${brightness.name} · ×$scale', (tester) async {
          tester.view.physicalSize = const Size(360 * 3, 640 * 3);
          tester.view.devicePixelRatio = 3;
          addTearDown(tester.view.reset);
          await tester.pumpWidget(ProviderScope(
            overrides: [
              ...contentOverrides(items: sampleContent),
              clockProvider.overrideWithValue(() => today),
              authStateProvider.overrideWith((ref) => Stream.value(null)),
            ],
            child: MaterialApp.router(
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
              routerConfig: GoRouter(initialLocation: path, routes: [
                GoRoute(path: '/content', builder: (_, _) => const LibraryScreen()),
                GoRoute(path: '/content/tip/:id', builder: (_, s) => TipScreen(id: s.pathParameters['id']!)),
                GoRoute(path: '/content/video/:id', builder: (_, s) => VideoScreen(id: s.pathParameters['id']!)),
              ]),
            ),
          ));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        });
      }
    }
  }
}
