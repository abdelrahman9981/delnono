import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/settings/settings_repository.dart';
import '../features/auth/data/auth_repository.dart';
import '../features/account/presentation/account_screen.dart';
import '../features/account/presentation/change_phone_screen.dart';
import '../features/account/presentation/delete_account_screen.dart';
import '../features/auth/presentation/otp_screen.dart';
import '../features/auth/presentation/reverify_screen.dart';
import '../features/auth/presentation/phone_screen.dart';
import '../features/booking/presentation/booking_screen.dart';
import '../features/booking/presentation/booking_success_screen.dart';
import '../features/booking/presentation/my_bookings_screen.dart';
import '../features/children/data/children_repository.dart';
import '../features/children/presentation/add_child_screen.dart';
import '../features/children/presentation/child_profile_screen.dart';
import '../features/child_profile/presentation/follow_up_screen.dart';
import '../features/child_profile/presentation/my_child_screen.dart';
import '../features/child_profile/presentation/vaccines_screen.dart';
import '../features/child_profile/presentation/visits_screen.dart';
import '../features/registration/data/guardian_repository.dart';
import '../features/registration/presentation/consent_screen.dart';
import '../features/registration/presentation/guardian_details_screen.dart';
import '../features/registration/presentation/link_children_screen.dart';
import '../features/shell/placeholders.dart';
import '../features/shell/shell_scaffold.dart';
import '../features/home/home_screen.dart';
import '../features/welcome/welcome_screen.dart';
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
    // Signed-out visitors start at Welcome; the guard sends signed-in guardians on to home.
    initialLocation: Routes.welcome,
    refreshListenable: guard,
    redirect: (context, state) => guardRedirect(state.uri, guard.value),
    routes: [
      ShellRoute(
        builder: (context, state, child) => ShellScaffold(location: state.uri.path, child: child),
        routes: [
          GoRoute(path: Routes.home, builder: (_, _) => const HomeScreen()),
          GoRoute(
            path: Routes.booking,
            // `?clinic=` from a Home clinic card preselects that clinic (004 FR-013).
            builder: (_, state) {
              final clinic = state.uri.queryParameters['clinic'];
              return BookingScreen(key: ValueKey('booking-$clinic'), initialClinicId: clinic);
            },
            routes: [
              GoRoute(path: 'done/:id', builder: (_, state) => BookingSuccessScreen(bookingId: state.pathParameters['id']!)),
              GoRoute(path: 'mine', builder: (_, _) => const MyBookingsScreen()),
              GoRoute(
                path: 'change/:id',
                builder: (_, state) => BookingScreen(changeBookingId: state.pathParameters['id']!),
              ),
            ],
          ),
          GoRoute(
            path: Routes.children,
            builder: (_, _) => const MyChildScreen(),
            routes: [
              GoRoute(path: 'add', builder: (_, _) => const AddChildScreen()),
              GoRoute(path: ':id', builder: (_, state) => ChildProfileScreen(childId: state.pathParameters['id']!)),
              // Siblings of the details screen, so back returns to My child (contracts/routes.md).
              GoRoute(path: ':id/vaccines', builder: (_, state) => VaccinesScreen(childId: state.pathParameters['id']!)),
              GoRoute(path: ':id/visits', builder: (_, state) => VisitsScreen(childId: state.pathParameters['id']!)),
              GoRoute(path: ':id/follow-up', builder: (_, state) => FollowUpScreen(childId: state.pathParameters['id']!)),
            ],
          ),
          GoRoute(path: Routes.content, builder: (_, _) => const ContentPlaceholder()),
        ],
      ),
      GoRoute(path: Routes.welcome, builder: (_, _) => const WelcomeScreen()),
      GoRoute(
        path: Routes.signIn,
        builder: (_, state) => PhoneScreen(from: state.uri.queryParameters['from']),
      ),
      GoRoute(
        path: Routes.signInCode,
        builder: (_, state) => OtpScreen(from: state.uri.queryParameters['from']),
      ),
      GoRoute(
        path: Routes.registerGuardian,
        builder: (_, state) => GuardianDetailsScreen(from: state.uri.queryParameters['from']),
      ),
      GoRoute(
        path: Routes.registerConsent,
        builder: (_, state) => ConsentScreen(from: state.uri.queryParameters['from']),
      ),
      GoRoute(
        path: Routes.registerLink,
        builder: (_, state) => LinkChildrenScreen(from: state.uri.queryParameters['from']),
      ),
      GoRoute(
        path: Routes.registerChild,
        builder: (_, state) => AddChildScreen(registration: true, from: state.uri.queryParameters['from']),
      ),
      GoRoute(
        path: Routes.reverify,
        builder: (_, state) => ReverifyScreen(from: state.uri.queryParameters['from']),
      ),
      GoRoute(path: Routes.account, builder: (_, _) => const AccountScreen()),
      GoRoute(path: Routes.accountPhone, builder: (_, _) => const ChangePhoneScreen()),
      GoRoute(path: Routes.notifications, builder: (_, _) => const NotificationsPlaceholder()),
      GoRoute(path: Routes.accountDelete, builder: (_, _) => const DeleteAccountScreen()),
    ],
  );

  ref.onDispose(() {
    router.dispose();
    guard.dispose();
  });
  return router;
});
