/// Shows Western digits as Arabic-Indic digits (٠–٩), as in the design mockups.
String arabicDigits(Object value) {
  final out = StringBuffer();
  for (final rune in value.toString().runes) {
    out.writeCharCode(rune >= 0x30 && rune <= 0x39 ? 0x0660 + rune - 0x30 : rune);
  }
  return out.toString();
}

/// A decimal in Arabic-Indic digits with the Arabic decimal mark, e.g. ٣٫٢.
String arabicDecimal(num value) => arabicDigits(value.toString().replaceAll('.', '\u066B'));

/// `m:ss` in Arabic-Indic digits, e.g. ٠:٤٢.
String arabicCountdown(Duration d) {
  final seconds = d.inSeconds < 0 ? 0 : d.inSeconds;
  return arabicDigits('${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}');
}
