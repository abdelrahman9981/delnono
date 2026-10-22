/**
 * Normalised child name for the duplicate check (FR-022): the same name typed with or without
 * diacritics, hamza forms or extra spaces gives the same key.
 */
export function nameKey(name: string): string {
  return name
    .normalize("NFC")
    .replace(/[ً-ٰٟـ]/g, "") // harakat, superscript alef, tatweel
    .replace(/[أإآٱ]/g, "ا")
    .replace(/ى/g, "ي")
    .replace(/ة/g, "ه")
    .replace(/\s+/g, " ")
    .trim()
    .toLowerCase();
}
