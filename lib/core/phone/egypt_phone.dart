/// Egyptian mobile numbers in E.164: +20 then 1, then 0/1/2/5, then 8 digits.
final _e164 = RegExp(r'^\+201[0125]\d{8}$');

/// Normalises what a guardian types (`010…`, `10…`, `+2010…`, `002010…`, with spaces, dashes or
/// Arabic-Indic digits) to E.164. Returns null when the result is not a valid Egyptian mobile number.
String? normalizeEgyptMobile(String input) {
  final digits = StringBuffer();
  var hasPlus = false;
  for (final rune in input.trim().runes) {
    if (rune >= 0x30 && rune <= 0x39) {
      digits.writeCharCode(rune);
    } else if (rune >= 0x0660 && rune <= 0x0669) {
      digits.writeCharCode(0x30 + rune - 0x0660); // Arabic-Indic ٠–٩
    } else if (rune >= 0x06F0 && rune <= 0x06F9) {
      digits.writeCharCode(0x30 + rune - 0x06F0); // Extended Arabic-Indic ۰–۹
    } else if (rune == 0x2B && digits.isEmpty && !hasPlus) {
      hasPlus = true;
    } else if (!' -() '.runes.contains(rune)) {
      return null;
    }
  }

  var n = digits.toString();
  if (hasPlus) {
    if (!n.startsWith('20')) return null;
    n = n.substring(2);
  } else if (n.startsWith('0020')) {
    n = n.substring(4);
  } else if (n.startsWith('20') && n.length == 12) {
    n = n.substring(2);
  }
  if (n.startsWith('0')) n = n.substring(1);

  final e164 = '+20$n';
  return isValidEgyptMobile(e164) ? e164 : null;
}

bool isValidEgyptMobile(String e164) => _e164.hasMatch(e164);
