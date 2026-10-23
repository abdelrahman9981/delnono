import 'package:delnono/app/l10n/app_localizations_ar.dart';
import 'package:delnono/core/format/age.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final l10n = AppLocalizationsAr();
  final today = DateTime(2026, 10, 23);
  String age(String birth) => arabicAge(birth, l10n, today: today);

  test('Arabic ages with plurals and Arabic-Indic digits', () {
    expect(age('2026-10-10'), 'أقل من شهر');
    expect(age('2026-09-23'), 'شهر');
    expect(age('2026-08-23'), 'شهرين');
    expect(age('2026-05-23'), '٥ شهور');
    expect(age('2025-10-23'), 'سنة');
    expect(age('2024-10-23'), 'سنتين');
    expect(age('2024-07-23'), 'سنتين و٣ شهور');
    expect(age('2020-01-01'), '٦ سنين و٩ شهور');
    expect(age('2014-10-23'), '١٢ سنة');
  });

  test('a birthday later this month does not count the month yet', () {
    expect(age('2026-09-24'), 'أقل من شهر');
  });
}
