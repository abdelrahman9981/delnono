import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A boolean that lives only for this app session (never persisted).
class SessionFlag extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool value) => state = value;
}

/// Guardian chose "these aren't my children, add a child" (spec US4 scenario 4).
final linkSkippedProvider = NotifierProvider<SessionFlag, bool>(SessionFlag.new);

/// First-run registration is in progress; guard step 5 applies only while this is set
/// (contracts/routes.md). Set and cleared by the registration controller (T045).
final registrationInProgressProvider = NotifierProvider<SessionFlag, bool>(SessionFlag.new);

/// `touchSession` returned `reverifyRequired: true` (FR-010a). Set by the session controller (T081).
final reverifyRequiredProvider = NotifierProvider<SessionFlag, bool>(SessionFlag.new);
