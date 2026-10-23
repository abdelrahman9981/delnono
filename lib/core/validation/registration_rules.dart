// Client-side copies of the data-model.md constraints. The server checks them again
// (functions/src/lib/validation.ts); these only give the guardian an immediate Arabic message.

int _chars(String s) => s.trim().runes.length;

/// fullName: "required, 2–80 chars".
bool validFullName(String s) => _chars(s) >= 2 && _chars(s) <= 80;

final _email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

/// email: "optional, valid email if present".
bool validOptionalEmail(String s) => s.trim().isEmpty || _email.hasMatch(s.trim());

/// child name: "required, 2–60 chars".
bool validChildName(String s) => _chars(s) >= 2 && _chars(s) <= 60;

/// allergies: "≤ 500 chars".
bool validAllergies(String s) => _chars(s) <= 500;

/// birthWeightKg: "0.3–7.0". Empty is allowed (optional).
bool validBirthWeight(double? kg) => kg == null || (kg >= 0.3 && kg <= 7.0);

/// Parses a decimal typed with Western or Arabic-Indic digits and `.`, `,` or `٫`. Null if empty;
/// NaN if not a number.
double? parseDecimal(String input) {
  final s = input.trim();
  if (s.isEmpty) return null;
  final out = StringBuffer();
  for (final r in s.runes) {
    if (r >= 0x0660 && r <= 0x0669) {
      out.writeCharCode(0x30 + r - 0x0660);
    } else if (r >= 0x06F0 && r <= 0x06F9) {
      out.writeCharCode(0x30 + r - 0x06F0);
    } else if (r == 0x066B || r == 0x2C) {
      out.write('.');
    } else {
      out.writeCharCode(r);
    }
  }
  return double.tryParse(out.toString()) ?? double.nan;
}

/// `YYYY-MM-DD` for a calendar date.
String isoDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
