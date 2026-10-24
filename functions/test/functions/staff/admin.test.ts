import { strict as assert } from "node:assert";
import { adminDb, callFunction, clearEmulators, seedSettings } from "../../helpers/env";
import { CLINIC, guardianWithChildren, openNonVaccineDay, seedBookingSettings, visit } from "../../helpers/booking";
import { doctor, secretary1, secretary2 } from "../../helpers/staff";

describe("clinic, catalogue, content, follow-up, settings, reports (005 US5–US8)", () => {
  beforeEach(async () => {
    await clearEmulators();
    await seedSettings();
    await seedBookingSettings();
  });

  it("a secretary edits her clinic's prices and schedule, not another's, not name or active (FR-018)", async () => {
    const s = await secretary1();
    assert.ok((await callFunction("updateClinic", { clinicId: CLINIC, fields: { visitPrice: 320, capacityPerHour: 5 } }, s)).result);
    assert.equal((await adminDb().doc("clinics/clinic-1").get()).get("visitPrice"), 320);
    assert.equal((await callFunction("updateClinic", { clinicId: "clinic-2", fields: { visitPrice: 1 } }, s)).error?.status, "PERMISSION_DENIED");
    assert.equal((await callFunction("updateClinic", { clinicId: CLINIC, fields: { active: false } }, s)).error?.status, "PERMISSION_DENIED");
    const audit = await adminDb().collection("auditLog").where("action", "==", "clinic.updated").get();
    assert.deepEqual(audit.docs[0].get("details.prices"), { visitPrice: { from: 300, to: 320 } });
  });

  it("a price change keeps confirmed bookings' price (FR-020)", async () => {
    const s = await secretary1();
    const g = await guardianWithChildren("+201000000099");
    const { result } = await callFunction<{ bookingId: string }>("createBooking", visit(openNonVaccineDay(), 18, g.childIds), g);
    await callFunction("updateClinic", { clinicId: CLINIC, fields: { visitPrice: 500 } }, s);
    assert.equal((await adminDb().doc(`bookings/${result!.bookingId}`).get()).get("price.total"), 300);
  });

  it("removing hours that hold confirmed bookings is refused, listing them", async () => {
    const s = await secretary1();
    const g = await guardianWithChildren("+201000000099");
    const day = openNonVaccineDay();
    await callFunction("createBooking", visit(day, 18, g.childIds), g);
    const closed = { "1": [], "2": [], "3": [], "4": [], "5": [], "6": [], "7": [] };
    const res = await callFunction("updateClinic", { clinicId: CLINIC, fields: { workingHours: closed } }, s);
    assert.equal(res.error?.details?.reason, "bookings_outside_hours");
    assert.equal((res.error?.details?.bookings as unknown[]).length, 1);
  });

  it("only the doctor edits and approves the vaccine list (FR-019)", async () => {
    const s = await secretary1();
    const d = await doctor();
    assert.equal((await callFunction("updateCatalogue", { vaccines: [{ id: "v1", name: "x" }] }, s)).error?.status, "PERMISSION_DENIED");
    assert.ok((await callFunction("updateCatalogue", { vaccines: [{ id: "v1", name: "BCG" }], source: "وزارة الصحة", approve: true }, d)).result);
    assert.equal((await adminDb().doc("vaccines/v1").get()).get("placeholder"), false);
    assert.ok((await adminDb().doc("settings/vaccines").get()).get("reviewedOn"));
  });

  it("secretaries save drafts; only the doctor publishes (D-19)", async () => {
    const s = await secretary1();
    const d = await doctor();
    const item = { title: "[الحرارة]", category: "fever", url: "https://example.com/v" };
    assert.equal((await callFunction("saveContent", { ...item, status: "published" }, s)).error?.details?.reason, "doctor_only");
    const draft = await callFunction<{ id: string }>("saveContent", item, s);
    assert.equal((await adminDb().doc(`content/${draft.result!.id}`).get()).get("status"), "draft");
    assert.ok((await callFunction("saveContent", { ...item, id: draft.result!.id, status: "published" }, d)).result);
    assert.equal((await callFunction("saveContent", { ...item, id: draft.result!.id }, s)).error?.details?.reason, "doctor_only");
  });

  it("follow-up drafts replace the live lists only when the doctor publishes (FR-021)", async () => {
    const s = await secretary1();
    const d = await doctor();
    await adminDb().doc("followUp/b0").set({ fromMonths: 0, toMonths: 2, title: "قديم", items: [] });
    await callFunction("saveFollowUpDraft", { bands: [{ fromMonths: 0, toMonths: 3, title: "جديد", items: ["أ"] }], dangerSigns: ["خطر"] }, s);
    assert.equal((await adminDb().doc("followUp/b0").get()).get("title"), "قديم");
    assert.equal((await callFunction("publishFollowUp", {}, s)).error?.status, "PERMISSION_DENIED");
    assert.ok((await callFunction("publishFollowUp", {}, d)).result);
    assert.equal((await adminDb().doc("followUp/b0").get()).get("title"), "جديد");
    assert.deepEqual((await adminDb().doc("settings/followUp").get()).get("dangerSigns"), ["خطر"]);
  });

  it("settings: doctor only, whitelisted, policy version only goes up (FR-024)", async () => {
    const s = await secretary1();
    const d = await doctor();
    assert.equal((await callFunction("updateSettings", { doc: "booking", fields: { maxUpcomingPerFamily: 3 } }, s)).error?.status, "PERMISSION_DENIED");
    assert.ok((await callFunction("updateSettings", { doc: "booking", fields: { maxUpcomingPerFamily: 3 } }, d)).result);
    assert.equal((await callFunction("updateSettings", { doc: "booking", fields: { capacityPerHour: 1 } }, d)).error?.status, "INVALID_ARGUMENT");
    assert.equal((await callFunction("updateSettings", { doc: "policy", fields: { currentVersion: 0 } }, d)).error?.details?.field, "currentVersion");
  });

  it("reports count per day and clinic; all clinics for the doctor only (FR-022)", async () => {
    const db = adminDb();
    const day = "2026-11-15";
    await db.doc("bookings/a").set({ clinicId: CLINIC, date: day, status: "done", payment: { cash: 300 } });
    await db.doc("bookings/b").set({ clinicId: CLINIC, date: day, status: "no_show" });
    await db.doc("bookings/c").set({ clinicId: CLINIC, date: day, status: "cancelled" });
    await db.doc("bookings/d").set({ clinicId: "clinic-2", date: day, status: "arrived" });
    await db.doc("bookings/old").set({ date: day, status: "confirmed" }); // before 004: the main clinic
    await db.doc("walkIns/w").set({ clinicId: CLINIC, date: day, payment: { cash: 150 } });
    await db.doc("packages/p").set({ soldAtClinicId: CLINIC, soldOn: day, price: 1500 });
    const s = await secretary1();
    const res = await callFunction<{ rows: Record<string, number | string>[]; total: Record<string, number> }>(
      "report", { clinicId: CLINIC, from: "2026-11-01", to: "2026-11-30", groupBy: "day" }, s,
    );
    assert.ok(res.result, JSON.stringify(res.error));
    assert.deepEqual(res.result.rows, [{ key: day, bookings: 3, arrivals: 1, noShows: 1, walkIns: 1, cash: 1950, packagesSold: 1 }]);
    assert.equal((await callFunction("report", { clinicId: "all", from: "2026-11-01", to: "2026-11-30" }, s)).error?.status, "PERMISSION_DENIED");
    const s2 = await secretary2();
    assert.equal((await callFunction("report", { clinicId: CLINIC, from: "2026-11-01", to: "2026-11-30" }, s2)).error?.status, "PERMISSION_DENIED");
    const d = await doctor();
    const all = await callFunction<{ total: Record<string, number> }>("report", { clinicId: "all", from: "2026-11-01", to: "2026-11-30", groupBy: "month" }, d);
    assert.equal(all.result?.total.bookings, 4);
    assert.equal(all.result?.total.arrivals, 2);
  });
});
