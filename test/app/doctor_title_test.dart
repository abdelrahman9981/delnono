import 'dart:io';

import 'package:delnono/app/l10n/app_localizations_ar.dart';
import 'package:flutter_test/flutter_test.dart';

/// The owner's correction (BRD D-55): the doctor's title is «أخصائي طب الأطفال وحديثي الولادة».
void main() {
  test("the doctor's title is أخصائي everywhere (D-55)", () {
    final ar = AppLocalizationsAr();
    expect(ar.doctorTitle, 'أخصائي طب الأطفال وحديثي الولادة');
    expect(ar.welcomeDoctorTitle, startsWith('أخصائي طب الأطفال وحديثي الولادة'));
    // The other title is never used, in the strings or the design.
    const wrong = 'استشار' 'ي';
    for (final path in ['l10n/app_ar.arb', 'docs/design/screens/Main.dc.html']) {
      expect(File(path).readAsStringSync(), isNot(contains(wrong)), reason: path);
    }
  });
}
