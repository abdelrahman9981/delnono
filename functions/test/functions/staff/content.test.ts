import { strict as assert } from "node:assert";
import { adminDb, callFunction, clearEmulators, seedSettings, signInAsPhoneUser } from "../../helpers/env";
import { doctor, secretary1 } from "../../helpers/staff";

const video = { type: "video", title: "هل ينفع نحط ملح قبل عمر سنه", category: "feeding", url: "https://youtube.com/shorts/WjbDIjEH38U" };
const tip = { type: "tip", title: "[نصيحة عن النوم]", category: "sleep", body: "[نص يكتبه الدكتور]", ageFromMonths: 0, ageToMonths: 12 };

async function auditActions(): Promise<string[]> {
  return (await adminDb().collection("auditLog").get()).docs.map((d) => d.get("action")).sort();
}

describe("content library (006)", () => {
  beforeEach(async () => {
    await clearEmulators();
    await seedSettings();
  });

  it("a secretary saves a video draft with the YouTube id; the doctor publishes (D-19, D-50)", async () => {
    const s = await secretary1();
    const d = await doctor();
    const { result } = await callFunction<{ id: string }>("saveContent", { ...video, status: "published" }, s);
    const doc = await adminDb().doc(`content/${result!.id}`).get();
    assert.equal(doc.get("status"), "draft");
    assert.equal(doc.get("youtubeId"), "WjbDIjEH38U");
    assert.equal(doc.get("order"), 100);
    assert.equal(doc.get("ageFromMonths"), null);
    assert.equal((await callFunction("setContentStatus", { id: result!.id, status: "published" }, s)).error?.details?.reason, "doctor_only");
    assert.ok((await callFunction("setContentStatus", { id: result!.id, status: "published" }, d)).result);
    const published = await adminDb().doc(`content/${result!.id}`).get();
    assert.equal(published.get("status"), "published");
    assert.equal(published.get("publishedBy"), "doc");
    assert.equal((await callFunction("saveContent", { ...video, id: result!.id }, s)).error?.details?.reason, "doctor_only");
  });

  it("publish, unpublish, archive and restore are the doctor's and each is audited", async () => {
    const d = await doctor();
    const { result } = await callFunction<{ id: string }>("saveContent", tip, d);
    const move = (status: string) => callFunction("setContentStatus", { id: result!.id, status }, d);
    assert.ok((await move("published")).result);
    assert.ok((await move("draft")).result);
    assert.ok((await move("archived")).result);
    assert.equal((await move("published")).error?.details?.reason, "invalid_transition");
    assert.ok((await move("draft")).result);
    assert.deepEqual(await auditActions(), ["content.archived", "content.published", "content.restored", "content.unpublished"]);
  });

  it("refuses non-YouTube links, duplicates, tips without text and half age ranges", async () => {
    const s = await secretary1();
    const bad = await callFunction("saveContent", { ...video, url: "https://vimeo.com/1" }, s);
    assert.equal(bad.error?.details?.reason, "invalid_youtube");
    const first = await callFunction<{ id: string }>("saveContent", video, s);
    const again = await callFunction("saveContent", { ...video, url: "https://www.youtube.com/watch?v=WjbDIjEH38U" }, s);
    assert.equal(again.error?.details?.reason, "duplicate");
    assert.equal(again.error?.details?.existingId, first.result!.id);
    assert.ok((await callFunction("saveContent", { ...video, id: first.result!.id, title: "عنوان جديد" }, s)).result);
    assert.equal((await callFunction("saveContent", { ...tip, body: "" }, s)).error?.details?.field, "body");
    assert.equal((await callFunction("saveContent", { ...tip, ageToMonths: null }, s)).error?.details?.field, "ageToMonths");
    assert.equal((await callFunction("saveContent", { ...tip, ageFromMonths: 13 }, s)).error?.details?.field, "ageToMonths");
    assert.equal((await callFunction("saveContent", { ...tip, category: "vaccines" }, s)).error?.details?.field, "category");
  });

  it("the doctor edits categories; one in use cannot be removed", async () => {
    const s = await secretary1();
    const d = await doctor();
    const cats = [{ id: "fever", name: "الحرارة" }, { id: "feeding", name: "الرضاعة" }, { id: "vaccines", name: "التطعيمات" }];
    assert.equal((await callFunction("saveContentCategories", { categories: cats }, s)).error?.status, "PERMISSION_DENIED");
    await callFunction("saveContent", tip, s);
    const res = await callFunction("saveContentCategories", { categories: cats }, d);
    assert.equal(res.error?.details?.reason, "in_use");
    assert.equal(res.error?.details?.category, "sleep");
    assert.ok((await callFunction("saveContentCategories", { categories: [...cats, { id: "sleep", name: "النوم" }] }, d)).result);
    assert.ok((await callFunction("saveContent", { ...tip, category: "vaccines" }, s)).result);
    assert.ok((await auditActions()).includes("content.categories_updated"));
  });

  it("guardians cannot list the channel or save content", async () => {
    const g = await signInAsPhoneUser("+201000000099");
    assert.equal((await callFunction("channelVideos", {}, g)).error?.status, "PERMISSION_DENIED");
    assert.equal((await callFunction("saveContent", tip, g)).error?.status, "PERMISSION_DENIED");
  });
});
