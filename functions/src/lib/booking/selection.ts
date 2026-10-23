import { HttpsError } from "firebase-functions/https";
import type { PricedChild, VisitType } from "./pricing";
import { DATE_PATTERN } from "./time";

export interface Selection {
  visitType: VisitType;
  date: string;
  hour: number;
  children: PricedChild[];
}

function bad(field: string, rule: string): never {
  throw new HttpsError("invalid-argument", `${field}: ${rule}`, { field });
}

/** Shape checks for create and change (contracts/callables.md). Linked children and vaccines are checked in the transaction. */
export function parseSelection(data: Record<string, unknown>): Selection & { expectedTotal: number } {
  const { visitType, date, hour, children, expectedTotal } = data;
  if (visitType !== "visit" && visitType !== "vaccine_only") bad("visitType", "visit | vaccine_only");
  if (typeof date !== "string" || !DATE_PATTERN.test(date)) bad("date", "YYYY-MM-DD");
  if (typeof hour !== "number" || !Number.isInteger(hour) || hour < 0 || hour > 23) bad("hour", "0–23");
  if (!Array.isArray(children) || children.length === 0) bad("children", "at least one child");
  if (typeof expectedTotal !== "number" || expectedTotal < 0) bad("expectedTotal", "number");

  const seen = new Set<string>();
  const parsed: PricedChild[] = [];
  for (const c of children as unknown[]) {
    const child = c as { childId?: unknown; vaccines?: unknown };
    if (typeof child.childId !== "string" || seen.has(child.childId)) bad("children", "distinct childId");
    seen.add(child.childId);
    const vaccines = child.vaccines ?? [];
    if (!Array.isArray(vaccines) || vaccines.some((v) => typeof v !== "string") || new Set(vaccines).size !== vaccines.length) {
      bad("vaccines", "distinct vaccine ids");
    }
    parsed.push({ childId: child.childId, vaccines: vaccines as string[] });
  }
  const anyVaccine = parsed.some((c) => c.vaccines.length > 0);
  if (visitType === "vaccine_only" && !anyVaccine) bad("vaccines", "vaccine only needs a vaccine");
  return { visitType, date, hour, children: parsed, expectedTotal } as Selection & { expectedTotal: number };
}
