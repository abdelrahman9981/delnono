import '../../booking/domain/clinic_time.dart';
import '../../child_profile/domain/child_age.dart';

/// A family package (packages/{id}; 008 data-model.md).
class FamilyPackage {
  const FamilyPackage({
    required this.id,
    required this.active,
    required this.startsOn,
    required this.endsOn,
    required this.soldAtClinicId,
  });

  final String id;
  final bool active;

  /// `YYYY-MM-DD`, Cairo dates.
  final String startsOn;
  final String endsOn;
  final String? soldAtClinicId;
}

/// Renewal opens this many days before the end, with the expiry notice (D-14).
const renewalWindowDays = 14;

/// The family's packages as the app shows them on [today] (008 research R2).
class FamilyPackageView {
  const FamilyPackageView({required this.today, this.current, this.next, this.lastEnded});

  final String today;

  /// Covers [today].
  final FamilyPackage? current;

  /// Starts after [today]: a renewal.
  final FamilyPackage? next;

  /// The most recent one that has ended.
  final FamilyPackage? lastEnded;

  /// First day the current package can be renewed.
  String? get renewableFrom => current == null ? null : ClinicTime.addDays(current!.endsOn, -renewalWindowDays);

  /// Whether staff may renew it today (FR-006, FR-007): in its last 14 days, not yet renewed.
  bool get renewable => current != null && next == null && compareDates(today, renewableFrom!) >= 0;
}

FamilyPackageView familyPackageView(List<FamilyPackage> packages, String today) {
  FamilyPackage? current;
  FamilyPackage? next;
  FamilyPackage? ended;
  for (final p in packages.where((p) => p.active)) {
    if (compareDates(p.startsOn, today) <= 0 && compareDates(today, p.endsOn) <= 0) {
      if (current == null || compareDates(p.endsOn, current.endsOn) > 0) current = p;
    } else if (compareDates(p.startsOn, today) > 0) {
      if (next == null || compareDates(p.startsOn, next.startsOn) < 0) next = p;
    } else if (ended == null || compareDates(p.endsOn, ended.endsOn) > 0) {
      ended = p;
    }
  }
  return FamilyPackageView(today: today, current: current, next: next, lastEnded: ended);
}
