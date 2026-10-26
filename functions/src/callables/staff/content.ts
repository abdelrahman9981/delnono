import { FieldValue } from "firebase-admin/firestore";
import { HttpsError, onCall } from "firebase-functions/https";
import { db } from "../../lib/admin";
import { type AuditAction, writeAudit } from "../../lib/audit";
import { REGION } from "../../lib/region";
import { num, requireStaff, str } from "../../lib/staff";
import { parseChannelFeed, youtubeId } from "../../lib/youtube";

/** The doctor's channel (D-50). */
export const CHANNEL_ID = "UC47gpnTXG0ki52IwM85Oqdg";

/** BRD categories, used until the doctor saves `settings/content` (006 R5). */
export const DEFAULT_CATEGORIES = [
  { id: "fever", name: "الحرارة" },
  { id: "feeding", name: "الرضاعة والهضم" },
  { id: "sleep", name: "النوم" },
  { id: "allergy", name: "الحساسية" },
];

async function categoryIds(): Promise<string[]> {
  const list = (await db.doc("settings/content").get()).get("categories") as { id: string }[] | undefined;
  return (list ?? DEFAULT_CATEGORIES).map((c) => c.id);
}

/**
 * Tips and videos (FR-039, D-19, D-50): any staff member saves drafts; a published or archived
 * item's fields are changed by the doctor only. Status changes go through [setContentStatus].
 * Videos keep only the YouTube id and the pasted link (no files).
 */
export const saveContent = onCall({ region: REGION }, async (request) => {
  const staff = await requireStaff(request);
  const data = (request.data ?? {}) as Record<string, unknown>;
  const id = str(data, "id", { optional: true });
  const ref = id ? db.doc(`content/${id}`) : db.collection("content").doc();
  const current = id ? await ref.get() : null;
  if (id && !current?.exists) throw new HttpsError("not-found", "Content not found.");
  if (current?.exists && current.get("status") !== "draft" && staff.role !== "doctor") {
    throw new HttpsError("permission-denied", "Published items are changed by the doctor.", { reason: "doctor_only" });
  }
  const type = data.type ?? (data.url ? "video" : "tip");
  if (type !== "video" && type !== "tip") throw new HttpsError("invalid-argument", "type", { field: "type" });
  const category = str(data, "category");
  if (!(await categoryIds()).includes(category)) throw new HttpsError("invalid-argument", "category", { field: "category" });
  const body = str(data, "body", { optional: true, max: 4000 });
  if (type === "tip" && !body) throw new HttpsError("invalid-argument", "body is required", { field: "body" });

  let video: { youtubeId: string; url: string } | null = null;
  if (type === "video") {
    const url = str(data, "url", { max: 500 });
    const vid = youtubeId(url);
    if (!vid) throw new HttpsError("invalid-argument", "Not a YouTube link.", { field: "url", reason: "invalid_youtube" });
    const same = await db.collection("content").where("youtubeId", "==", vid).get();
    const other = same.docs.find((d) => d.id !== ref.id);
    if (other) throw new HttpsError("already-exists", "Video already added.", { reason: "duplicate", existingId: other.id });
    video = { youtubeId: vid, url };
  }

  const from = num(data, "ageFromMonths", { optional: true, min: 0, max: 216 });
  const to = num(data, "ageToMonths", { optional: true, min: 0, max: 216 });
  if ((from == null) !== (to == null)) throw new HttpsError("invalid-argument", "age range", { field: from == null ? "ageFromMonths" : "ageToMonths" });
  if (from != null && to != null && from > to) throw new HttpsError("invalid-argument", "age range", { field: "ageToMonths" });

  await ref.set({
    type, title: str(data, "title", { max: 120 }), category, body: body || null,
    youtubeId: video?.youtubeId ?? null, url: video?.url ?? null,
    ageFromMonths: from, ageToMonths: to,
    order: num(data, "order", { optional: true, min: 0, max: 9999 }) ?? 100,
    updatedBy: staff.uid, updatedAt: FieldValue.serverTimestamp(),
    ...(current?.exists ? {} : { status: "draft", createdBy: staff.uid, createdAt: FieldValue.serverTimestamp() }),
  }, { merge: true });
  return { id: ref.id };
});

/** Allowed moves and their audit action (006 R6). */
const TRANSITIONS: Record<string, Record<string, AuditAction>> = {
  draft: { published: "content.published", archived: "content.archived" },
  published: { draft: "content.unpublished", archived: "content.archived" },
  archived: { draft: "content.restored" },
};

/** Publish, unpublish, archive or restore: the doctor only, each in the audit log. */
export const setContentStatus = onCall({ region: REGION }, async (request) => {
  const staff = await requireStaff(request);
  if (staff.role !== "doctor") throw new HttpsError("permission-denied", "Only the doctor publishes.", { reason: "doctor_only" });
  const data = (request.data ?? {}) as Record<string, unknown>;
  const ref = db.doc(`content/${str(data, "id")}`);
  const status = str(data, "status");
  const snap = await ref.get();
  if (!snap.exists) throw new HttpsError("not-found", "Content not found.");
  const from = String(snap.get("status") ?? "draft");
  const action = TRANSITIONS[from]?.[status];
  if (!action) throw new HttpsError("failed-precondition", `${from} → ${status}`, { reason: "invalid_transition" });
  await ref.update({
    status, updatedBy: staff.uid, updatedAt: FieldValue.serverTimestamp(),
    ...(status === "published" ? { publishedBy: staff.uid, publishedAt: FieldValue.serverTimestamp() } : {}),
  });
  await writeAudit({ action, actorUid: staff.uid, details: { id: ref.id, title: snap.get("title"), from, to: status } });
  return {};
});

/** The doctor's category list (006 R5): rename and reorder; a category in use stays. */
export const saveContentCategories = onCall({ region: REGION }, async (request) => {
  const staff = await requireStaff(request, { doctor: true });
  const raw = (request.data as Record<string, unknown> | undefined)?.categories;
  if (!Array.isArray(raw) || raw.length < 1 || raw.length > 20) throw new HttpsError("invalid-argument", "categories", { field: "categories" });
  const categories = raw.map((c) => {
    const item = (c ?? {}) as Record<string, unknown>;
    const id = str(item, "id", { max: 30 });
    if (!/^[a-z0-9-]+$/.test(id)) throw new HttpsError("invalid-argument", "category id", { field: "id" });
    return { id, name: str(item, "name", { max: 40 }) };
  });
  if (new Set(categories.map((c) => c.id)).size !== categories.length) throw new HttpsError("invalid-argument", "duplicate id", { field: "id" });
  for (const old of await categoryIds()) {
    if (categories.some((c) => c.id === old)) continue;
    const used = await db.collection("content").where("category", "==", old).limit(1).get();
    if (!used.empty) throw new HttpsError("failed-precondition", "Category in use.", { reason: "in_use", category: old });
  }
  await db.doc("settings/content").set({ categories }, { merge: true });
  await writeAudit({ action: "content.categories_updated", actorUid: staff.uid, details: { categories: categories.map((c) => c.id) } });
  return {};
});

/**
 * The channel's latest videos from its public feed (006 R7), for «استيراد من القناة». Shorts are
 * titled by date in the feed, so staff type the title. Needs outbound network: emulator now,
 * deployed Functions on Blaze later.
 */
export const channelVideos = onCall({ region: REGION }, async (request) => {
  await requireStaff(request);
  let xml: string;
  try {
    const res = await fetch(`https://www.youtube.com/feeds/videos.xml?channel_id=${CHANNEL_ID}`, { signal: AbortSignal.timeout(10000) });
    if (!res.ok) throw new Error(String(res.status));
    xml = await res.text();
  } catch {
    throw new HttpsError("unavailable", "Channel feed unavailable.");
  }
  const videos = parseChannelFeed(xml);
  const added = new Set<string>();
  for (let i = 0; i < videos.length; i += 30) {
    const ids = videos.slice(i, i + 30).map((v) => v.id);
    const snap = await db.collection("content").where("youtubeId", "in", ids).get();
    snap.docs.forEach((d) => added.add(d.get("youtubeId")));
  }
  return { videos: videos.map((v) => ({ ...v, alreadyAdded: added.has(v.id) })) };
});
