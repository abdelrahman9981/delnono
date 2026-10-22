import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/settings/settings_repository.dart';
import '../features/auth/data/auth_repository.dart';
import '../features/auth/presentation/otp_screen.dart';
import '../features/auth/presentation/phone_screen.dart';
import '../features/children/data/children_repository.dart';
import '../features/registration/data/guardian_repository.dart';
import '../features/shell/placeholders.dart';
import '../features/shell/shell_scaffold.dart';
import 'l10n/app_localizations.dart';
import 'route_guard.dart';
import 'session_flags.dart';

/// Still waiting for a first result. Riverpod 3 retries failed providers and reports them as
/// loading-with-error meanwhile; an error counts as a result, or a denied read would block the guard.
bool _waiting(AsyncValue<Object?> v) => !v.hasValue && !v.hasError;

/// Combines auth, guardian, policy, children and session flags into the guard's input.
final guardStateProvider = Provider<GuardState>((ref) {
  final auth = ref.watch(authStateProvider);
  if (_waiting(auth)) return GuardState.loadingState;
  if (auth.value == null) return const GuardState();

  final guardian = ref.watch(guardianProvider);
  final policy = ref.watch(policySettingsProvider);
  if (_waiting(guardian) || _waiting(policy)) return GuardState.loadingState;

  final g = guardian.value;
  final currentVersion = policy.value?.currentVersion ?? const PolicySettings().currentVersion;

  return GuardState(
    signedIn: true,
    hasGuardian: g != null,
    consentCurrent: g != null && g.consentVersion >= currentVersion,
    reverifyRequired: ref.watch(reverifyRequiredProvider),
    clinicChildrenPending: g?.clinicChildrenPending ?? false,
    linkSkipped: ref.watch(linkSkippedProvider),
    registrationInProgress: ref.watch(registrationInProgressProvider),
    hasChildren: ref.watch(childrenProvider).value?.isNotEmpty ?? false,
  );
});

final routerProvider = Provider<GoRouter>((ref) {
  final guard = ValueNotifier<GuardState>(ref.read(guardStateProvider));
  ref.listen(guardStateProvider, (_, next) => guard.value = next);

  final router = GoRouter(
    initialLocation: Routes.home,
    refreshListenable: guard,
    redirect: (context, state) => guardRedirect(state.uri, guard.value),
    routes: [
      ShellRoute(
        builder: (context, state, child) => ShellScaffold(location: state.uri.path, child: child),
        routes: [
          GoRoute(path: Routes.home, builder: (_, _) => const HomePlaceholder()),
          GoRoute(path: Routes.booking, builder: (_, _) => const BookingPlaceholder()),
          GoRoute(
            path: Routes.children,
            builder: (context, _) => _placeholder(context, (l) => l.screenChildren),
            routes: [
              GoRoute(path: 'add', builder: (context, _) => _placeholder(context, (l) => l.screenAddChild)),
              GoRoute(path: ':id', builder: (context, _) => _placeholder(context, (l) => l.screenChildProfile)),
            ],
          ),
          GoRoute(path: Routes.content, builder: (_, _) => const ContentPlaceholder()),
        ],
      ),
      _screen(Routes.welcome, (l) => l.screenWelcome),
      GoRoute(
        path: Routes.signIn,
        builder: (_, state) => PhoneScreen(from: state.uri.queryParameters['from']),
      ),
      GoRoute(
        path: Routes.signInCode,
        builder: (_, state) => OtpScreen(from: state.uri.queryParameters['from']),
      ),
      _screen(Routes.registerGuardian, (l) => l.screenGuardian),
      _screen(Routes.registerConsent, (l) => l.screenConsent),
      _screen(Routes.registerLink, (l) => l.screenLinkChildren),
      _screen(Routes.registerChild, (l) => l.screenAddChild),
      _screen(Routes.reverify, (l) => l.screenReverify),
      _screen(Routes.account, (l) => l.screenAccount),
      _screen(Routes.accountPhone, (l) => l.screenChangePhone),
      _screen(Routes.accountDelete, (l) => l.screenDeleteAccount),
    ],
  );

  ref.onDispose(() {
    router.dispose();
    guard.dispose();
  });
  return router;
});

/// Placeholder until the user story that builds the screen replaces it.
GoRoute _screen(String path, String Function(AppLocalizations) title) =>
    GoRoute(path: path, builder: (context, _) => _placeholder(context, title));

Widget _placeholder(BuildContext context, String Function(AppLocalizations) title) =>
    PlaceholderScreen(title: title(AppLocalizations.of(context)));
