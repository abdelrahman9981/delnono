import 'package:flutter/foundation.dart';

/// Everything the route guard needs to decide (contracts/routes.md, "Guard").
@immutable
class GuardState {
  const GuardState({
    this.loading = false,
    this.signedIn = false,
    this.hasGuardian = false,
    this.consentCurrent = false,
    this.reverifyRequired = false,
    this.clinicChildrenPending = false,
    this.linkSkipped = false,
    this.registrationInProgress = false,
    this.hasChildren = false,
    this.loadError = false,
  });

  /// Auth or guardian data has not arrived yet; the guard makes no decision.
  static const loadingState = GuardState(loading: true);

  /// Signed in, but the guardian or policy could not be read: the guard keeps the guardian where
  /// they are (the code screen shows the error with a retry), never treats it as "no guardian".
  static const loadErrorState = GuardState(signedIn: true, loadError: true);

  final bool loading;
  final bool signedIn;
  final bool hasGuardian;
  final bool consentCurrent;
  final bool reverifyRequired;
  final bool clinicChildrenPending;
  final bool linkSkipped;
  final bool registrationInProgress;
  final bool hasChildren;
  final bool loadError;

  @override
  bool operator ==(Object other) =>
      other is GuardState &&
      other.loading == loading &&
      other.signedIn == signedIn &&
      other.hasGuardian == hasGuardian &&
      other.consentCurrent == consentCurrent &&
      other.reverifyRequired == reverifyRequired &&
      other.clinicChildrenPending == clinicChildrenPending &&
      other.linkSkipped == linkSkipped &&
      other.registrationInProgress == registrationInProgress &&
      other.hasChildren == hasChildren &&
      other.loadError == loadError;

  @override
  int get hashCode => Object.hash(loading, signedIn, hasGuardian, consentCurrent, reverifyRequired,
      clinicChildrenPending, linkSkipped, registrationInProgress, hasChildren, loadError);
}

abstract final class Routes {
  static const welcome = '/welcome';
  static const home = '/';
  static const content = '/content';
  static const signIn = '/sign-in';
  static const signInCode = '/sign-in/code';
  static const registerGuardian = '/register/guardian';
  static const registerConsent = '/register/consent';
  static const registerLink = '/register/link';
  static const registerChild = '/register/child';
  static const reverify = '/reverify';
  static const booking = '/booking';
  static const children = '/children';
  static const childrenAdd = '/children/add';
  static const account = '/account';
  static const accountPhone = '/account/phone';
  static const accountDelete = '/account/delete';
  static const notifications = '/notifications';
  static const me = '/me';
  static const package = '/package';

  static const public = {welcome, home, content, me, package};

  /// Steps of sign-in, registration and re-check. Reaching one when it is no longer needed
  /// continues to `from`.
  static const flow = {
    signIn,
    signInCode,
    registerGuardian,
    registerConsent,
    registerLink,
    registerChild,
    reverify,
  };
}

/// The step a guardian must complete before reaching [target], or null when nothing is pending.
/// Order follows contracts/routes.md: steps 1, 2, 3, 3a, 4, 5.
String? requiredStep(GuardState s, String target) {
  if (!s.signedIn) return Routes.signIn;
  if (!s.hasGuardian) return Routes.registerGuardian;
  if (!s.consentCurrent) return Routes.registerConsent;
  if (s.reverifyRequired) return Routes.reverify;
  if (s.clinicChildrenPending && !s.linkSkipped) return Routes.registerLink;
  if (s.registrationInProgress && !s.hasChildren && target != Routes.childrenAdd) {
    return Routes.registerChild;
  }
  return null;
}

/// `from` is followed only when it is an internal app path; anything else falls back to home.
String safeFrom(String? from) {
  if (from == null || from.isEmpty) return Routes.home;
  if (!from.startsWith('/') || from.startsWith('//') || from.startsWith(r'/\')) return Routes.home;
  final uri = Uri.tryParse(from);
  if (uri == null || uri.hasScheme || uri.hasAuthority) return Routes.home;
  if (Routes.flow.contains(uri.path)) return Routes.home;
  return from;
}

/// go_router `redirect` for [location] (the full requested URI).
String? guardRedirect(Uri location, GuardState s) {
  if (s.loading || s.loadError) return null;
  final path = location.path;
  // Welcome is the signed-out start (US3); a signed-in guardian starts at home.
  if (path == Routes.welcome) return s.signedIn ? Routes.home : null;
  if (Routes.public.contains(path) || path.startsWith('${Routes.content}/')) return null;

  if (Routes.flow.contains(path)) {
    final target = safeFrom(location.queryParameters['from']);
    final step = requiredStep(s, Uri.parse(target).path);
    if (step == null) return target;
    if (_isOnStep(path, step)) return null;
    return _withFrom(step, target);
  }

  final step = requiredStep(s, path);
  return step == null ? null : _withFrom(step, location.toString());
}

/// The code screen belongs to the sign-in step; consent follows guardian details in the same
/// step, because details stay in memory until consent (FR-015).
bool _isOnStep(String path, String step) =>
    path == step ||
    (step == Routes.signIn && path == Routes.signInCode) ||
    (step == Routes.registerGuardian && path == Routes.registerConsent);

String _withFrom(String step, String from) =>
    from == Routes.home ? step : Uri(path: step, queryParameters: {'from': from}).toString();
