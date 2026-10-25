/** Egyptian mobile numbers as typed at the desk: 01xxxxxxxxx, +201xxxxxxxxx or 201xxxxxxxxx. */
export function phoneE164(q: string): string | null {
  const digits = q.replace(/\D/g, "");
  if (/^01\d{9}$/.test(digits)) return `+2${digits}`;
  if (/^201\d{9}$/.test(digits)) return `+${digits}`;
  return null;
}
