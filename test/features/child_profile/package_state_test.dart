import 'package:delnono/features/child_profile/domain/package_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const today = '2026-10-24';

  test('active package covering today, with whole months left', () {
    final s = packageStatus([(active: true, startsOn: '2026-01-12', endsOn: '2027-01-12')], today)!;
    expect(s.active, isTrue);
    expect(s.endsOn, '2027-01-12');
    expect(s.monthsLeft, 2);
  });

  test('ended package shows as ended', () {
    final s = packageStatus([(active: true, startsOn: '2025-01-01', endsOn: '2026-01-01')], today)!;
    expect(s.active, isFalse);
    expect(s.monthsLeft, 0);
  });

  test('an active package wins over an ended one', () {
    final s = packageStatus([
      (active: false, startsOn: '2025-01-01', endsOn: '2026-01-01'),
      (active: true, startsOn: '2026-02-01', endsOn: '2027-02-01'),
    ], today)!;
    expect(s.active, isTrue);
  });

  test('no packages: nothing shown', () => expect(packageStatus(const [], today), isNull));
}
