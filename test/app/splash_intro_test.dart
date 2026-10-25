import 'package:delnono/app/l10n/app_localizations.dart';
import 'package:delnono/app/splash_intro.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> pump(WidgetTester tester, {bool reduceMotion = false}) => tester.pumpWidget(ProviderScope(
  child: MaterialApp(
    locale: const Locale('ar'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
      child: SplashIntro(child: child!),
    ),
    home: const Scaffold(body: Text('app')),
  ),
));

void main() {
  setUp(() => SplashIntro.shownThisRun = false);

  final intro = find.byKey(const Key('splash-intro'));

  testWidgets('plays once and is gone within 2.2 s (docs/design/README.md "Splash and brand")', (tester) async {
    await pump(tester);
    expect(intro, findsOneWidget);
    expect(find.text('دكتور النونو'), findsOneWidget);
    // Frame by frame, as on a phone: 2.25 s at 60 frames a second.
    for (var i = 0; i < 135; i++) {
      await tester.pump(const Duration(milliseconds: 16, microseconds: 667));
    }
    expect(intro, findsNothing);
    expect(find.text('app'), findsOneWidget);
  });

  testWidgets('a tap skips it', (tester) async {
    await pump(tester);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(intro);
    await tester.pumpAndSettle();
    expect(intro, findsNothing);
  });

  testWidgets('the phone\'s "reduce motion" skips it', (tester) async {
    await pump(tester, reduceMotion: true);
    await tester.pump();
    expect(intro, findsNothing);
  });

  testWidgets('only on a cold start: not again in the same run', (tester) async {
    await pump(tester);
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox());
    await pump(tester);
    expect(intro, findsNothing);
  });
}
