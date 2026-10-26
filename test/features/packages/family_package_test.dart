import 'package:delnono/features/packages/domain/family_package.dart';
import 'package:flutter_test/flutter_test.dart';

FamilyPackage p(String id, String from, String to, {bool active = true}) =>
    FamilyPackage(id: id, active: active, startsOn: from, endsOn: to, soldAtClinicId: 'clinic-1');

void main() {
  const today = '2026-11-15';

  test('the package covering today is current; none when none covers today', () {
    final v = familyPackageView([p('a', '2026-01-10', '2027-01-09')], today);
    expect(v.current?.id, 'a');
    expect(v.next, isNull);
    expect(familyPackageView(const [], today).current, isNull);
  });

  test('a renewal starting after today is next', () {
    final v = familyPackageView([p('a', '2025-11-26', '2026-11-25'), p('b', '2026-11-26', '2027-11-25')], today);
    expect(v.current?.id, 'a');
    expect(v.next?.id, 'b');
  });

  test('the latest ended one is kept for «خلصت»; inactive ones never cover', () {
    final v = familyPackageView([p('old', '2024-01-01', '2024-12-31'), p('x', '2026-01-01', '2026-12-31', active: false)], today);
    expect(v.current, isNull);
    expect(v.lastEnded?.id, 'old');
  });

  test('renewable in the last 14 days of the current package, if no renewal yet (D-14)', () {
    expect(familyPackageView([p('a', '2025-12-01', '2026-11-29')], today).renewable, isTrue, reason: '14 days left');
    expect(familyPackageView([p('a', '2025-12-02', '2026-11-30')], today).renewable, isFalse, reason: '15 days left');
    expect(
      familyPackageView([p('a', '2025-12-01', '2026-11-29'), p('b', '2026-11-30', '2027-11-29')], today).renewable,
      isFalse,
      reason: 'already renewed',
    );
    expect(familyPackageView([p('a', '2025-12-01', '2026-11-29')], today).renewableFrom, '2026-11-15');
  });
}
