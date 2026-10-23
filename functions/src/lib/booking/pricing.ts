/** Price snapshots (research R4, data-model.md). */

export type VisitType = "visit" | "vaccine_only";

export interface Vaccine {
  id: string;
  name: string;
  price: number;
  showPrice: boolean;
  active: boolean;
}

export interface VaccineLine {
  childId: string;
  vaccineId: string;
  name: string;
  /** The real price, charged at the clinic. */
  amount: number;
  /** False when the clinic hides this vaccine's price: the app shows "بالسعر في العيادة". */
  shown: boolean;
}

export interface PriceSnapshot {
  visit: { amount: number; covered: boolean } | null;
  vaccines: VaccineLine[];
  /** What the app shows: visit plus shown vaccine prices. */
  total: number;
  hasHiddenPrices: boolean;
  packageId: string | null;
}

export interface PricedChild {
  childId: string;
  vaccines: string[];
}

/**
 * Prices a selection. For a change, [previous] keeps the amounts already fixed for lines that stay
 * and for a visit that was already charged; only new lines use current prices (FR-023, FR-047).
 */
export function priceSelection(input: {
  visitType: VisitType;
  children: PricedChild[];
  visitPrice: number;
  vaccines: Map<string, Vaccine>;
  packageId: string | null;
  previous?: PriceSnapshot | null;
}): PriceSnapshot {
  const { visitType, children, visitPrice, vaccines, packageId, previous } = input;

  let visit: PriceSnapshot["visit"] = null;
  if (visitType === "visit") {
    if (packageId) visit = { amount: 0, covered: true };
    else if (previous?.visit && !previous.visit.covered) visit = { amount: previous.visit.amount, covered: false };
    else visit = { amount: visitPrice, covered: false };
  }

  const lines: VaccineLine[] = [];
  for (const child of children) {
    for (const vaccineId of child.vaccines) {
      const kept = previous?.vaccines.find((l) => l.childId === child.childId && l.vaccineId === vaccineId);
      if (kept) {
        lines.push({ ...kept });
        continue;
      }
      const v = vaccines.get(vaccineId);
      if (!v) throw new Error(`unknown vaccine ${vaccineId}`);
      lines.push({ childId: child.childId, vaccineId, name: v.name, amount: v.price, shown: v.showPrice });
    }
  }

  const total = (visit?.amount ?? 0) + lines.filter((l) => l.shown).reduce((sum, l) => sum + l.amount, 0);
  return { visit, vaccines: lines, total, hasHiddenPrices: lines.some((l) => !l.shown), packageId };
}
