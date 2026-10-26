# Feature Specification: Content Library

**Feature Branch**: `006-content-library`

**Created**: 2026-10-26

**Status**: Draft

**Input**: User description: "006 content library. Sources: docs/requirements.md item 9 (follow-up and content), the roles table (secretary drafts, doctor publishes), BRD section 17 including D-50 (videos from the doctor's YouTube channel, Public or Unlisted; Firestore keeps only the video id or link and the title; played inside the app; no Cloud Storage), constitution 1.3.x, docs/design/screens/Content.dc.html and FollowUp.dc.html, dashboard style docs/design/dashboard/. Guardian «محتوى» tab: videos and tips by category, search, filter, 'مناسب لسن <child>', offline for loaded items, Home card. Dashboard «المحتوى والقوائم»: draft → published → archived, secretary drafts, doctor publishes/unpublishes/archives, audit, YouTube link with id extraction and thumbnail, preview, optional channel import. Seed real videos from the channel UC47gpnTXG0ki52IwM85Oqdg."

**Design**: `docs/design/screens/Content.dc.html` (header «مكتبة المحتوى · نصايح الدكتور», category chips «الكل · الحرارة · الرضاعة والهضم · النوم · الحساسية», «مناسب لسن يوسف» featured card, «كل الفيديوهات», cards with category, length and age, footer «كل المحتوى بيراجعه الدكتور قبل النشر»); dashboard pages per `docs/design/dashboard/` (cards, pills, sticky save bar). Arabic RTL; forward chevrons ‹, back ›.

## Clarifications

### Session 2026-10-26

- Q: The channel's videos are Shorts titled only with their upload date; how are seeded videos titled and categorised? → A (owner): use the Arabic text written on each Short (read from its frame) as the title and guess the category from it, marked "Assumption — needs owner review"; a video without readable text gets «[عنوان يكتبه الدكتور · فيديو <date>]». Seed 8 as drafts and publish 2–3 with clear titles for the demo.
- Q: How are Shorts played? → A (owner): vertical, in a 9:16 full-screen style player, not a 16:9 box.
- Q: Two seeded videos are about vaccines and newborns, outside the four BRD categories; where do they go? → A: **Assumption — needs owner review.** The category list is the doctor's to edit (owner's scope); the seed adds «التطعيمات» and «حديثي الولادة» after the four BRD categories.
- Q: Which child does «مناسب لسن …» use when there are several? → A: **Assumption — needs owner review.** The child selected in «طفلي» (or the first), if under 4 years; children over 4 get no age-based section (requirement 3). Items with no age range never appear there, only in the library.
- Q: Can the channel import run on the real project before Blaze? → A: **Assumption — needs owner review.** It runs in a Cloud Function that reads the channel's public feed; on the emulators it works now; on the real project it needs deployed Functions (Blaze, D-40) like every callable. Staff can always paste a link instead.
- Q: Where do video titles come from in normal use? → A (owner): staff type the title themselves in the dashboard and paste the YouTube link. The title is required and is never filled in from YouTube (the channel's titles are dates). Titles read from thumbnails are only for the demo seed.
- Q: How are items ordered, and what does "unpublish" do? → A: **Assumption — needs owner review.** Lower order number first, then newest published first; unpublish returns a published item to draft (hidden from the app, editable again by the secretary); archive hides it for good and only the doctor can bring it back to draft.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - A mother browses the library (Priority: P1)

Anyone, signed in or not, opens «محتوى» and sees published videos and tips, newest first by the doctor's order, filters by category, and searches by title. Tapping a video plays it inside the app in a vertical player; a tip opens as text.

**Why this priority**: The library is the first thing a visitor can use without signing in (requirement 1, item 9).

**Independent Test**: With published items in three categories, a signed-out visitor sees them, filters «الحرارة», searches a word from a title, and plays a video inside the app.

**Acceptance Scenarios**:

1. **Given** published and draft items, **Then** only published ones are listed, by order number then newest; archived and draft never appear in the app.
2. **Given** a category chip, **Then** only that category's items show; «الكل» shows every category.
3. **Given** a search word, **Then** items whose title contains it show (Arabic-normalised: hamza and taa marbuta forms match).
4. **Given** a video, **When** tapped, **Then** it plays inside the app in a 9:16 player; **if** the video does not allow embedding or fails to load, **then** «شوفي الفيديو على يوتيوب» opens it in YouTube.
5. **Given** a tip, **When** tapped, **Then** its title and text show; texts still under review appear in brackets.

---

### User Story 2 - Age-based items for my child (Priority: P2)

A signed-in guardian with a child under 4 years sees «مناسب لسن <name>» above the library: published items whose age range covers the child's age today.

**Why this priority**: Age-appropriate advice is the library's core value (item 9).

**Independent Test**: A child of 7 months sees items for 6–12 months and not for 0–2; a child of 5 years sees no age section.

**Acceptance Scenarios**:

1. **Given** the selected child is 7 months old, **Then** «مناسب لسن يوسف» lists items with age range covering 7 months.
2. **Given** the child is over 48 months, **Then** no age-based section (requirement 3).
3. **Given** signed out or no children, **Then** no age-based section.

---

### User Story 3 - Offline (Priority: P2)

Items already loaded open read-only without internet; videos say clearly that they need internet.

**Acceptance Scenarios**:

1. **Given** the library was loaded once, **When** offline, **Then** the list, search, filters and tips still work.
2. **Given** offline, **When** a video is opened, **Then** «الفيديو محتاج إنترنت» shows instead of a broken player.

---

### User Story 4 - Staff manage content in the dashboard (Priority: P1)

A secretary creates and edits drafts: type (video or tip), title, category, body text, optional age range in months, order. For a video she pastes a YouTube link; the dashboard checks it, extracts the id, shows the thumbnail, and refuses non-YouTube links. She previews the item as a mother will see it. Only the doctor publishes, unpublishes (back to draft) and archives; each is in the audit log. The doctor edits the category list.

**Why this priority**: Without managed content the app has nothing to show (roles table: secretary drafts, doctor publishes).

**Independent Test**: The secretary saves a video draft from `https://youtube.com/shorts/WjbDIjEH38U`; the thumbnail shows; she has no publish button and the server refuses her publishing; the doctor publishes it and it appears in the app; the audit log shows the publish.

**Acceptance Scenarios**:

1. **Given** a pasted link in any YouTube form (watch, youtu.be, shorts, embed, with extra parameters), **Then** the 11-character id is extracted and the thumbnail shown; any other link is refused with a message.
2. **Given** the secretary, **Then** she creates and edits drafts only; publish, unpublish and archive are not offered and are refused by the server.
3. **Given** the doctor publishes, unpublishes or archives, **Then** the change is saved and audited with the doctor, the item and the new state.
4. **Given** the preview, **Then** it shows the card and detail as the app does (title, category, age, thumbnail or text).
5. **Given** the doctor edits the categories (add, rename, reorder; a category in use cannot be removed), **Then** the app's chips follow.
6. **Given** «استيراد من القناة», **Then** the channel's latest videos are listed with thumbnail and title; picking one opens a new video draft with only its link filled; staff type the title.

---

### User Story 5 - Latest content on Home (Priority: P3)

Home shows up to 3 latest published items with a link to the library.

### Edge Cases

- A published video later made private or deleted on YouTube: the player fails → «شوفي الفيديو على يوتيوب».
- The same YouTube id saved twice: refused (`duplicate`) with the existing item named.
- A category renamed: items keep their category id; the new name shows everywhere.
- Long titles and large text sizes: cards wrap, no overflow.
- No published items: the app shows «لسه مفيش محتوى منشور» instead of a blank list.
- Tip text and titles are facts or the doctor's own words; no automatic medical judgement (Principle II).

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The app MUST list published content (videos and tips) to everyone, signed in or not, with category chips (from the doctor's list) and title search, sorted by order number then newest published.
- **FR-002**: Videos MUST play inside the app in a vertical 9:16 player; when embedding fails or is not allowed, the app MUST offer «شوفي الفيديو على يوتيوب» to open YouTube.
- **FR-003**: Content MUST store only the YouTube video id (and the original link) and the title for videos; no video or image files are stored (D-50).
- **FR-004**: For a signed-in guardian whose selected child is under 48 months, the app MUST show «مناسب لسن <name>» with published items whose age range covers the child's age.
- **FR-005**: Loaded content MUST open offline read-only; videos offline MUST show that they need internet.
- **FR-006**: The dashboard MUST let staff create and edit drafts with type, title, category, body, optional age range, and order; the title MUST be typed by staff (required, never filled in from YouTube, including on channel import); for videos, a pasted YouTube link MUST be validated, its id extracted, and its thumbnail shown; non-YouTube links MUST be refused (client and server).
- **FR-007**: Only the doctor MUST be able to publish, unpublish and archive (server and rules), and edit the category list; every state change MUST be audited.
- **FR-008**: The dashboard MUST preview an item as the app shows it.
- **FR-009**: The dashboard SHOULD offer «استيراد من القناة», listing the channel's latest videos to pick from.
- **FR-010**: Home MUST show up to 3 latest published items when any exist.
- **FR-011**: Empty, loading and error states MUST be explicit (never blank).
- **FR-012**: Screens MUST lay out without overflow on phones (light/dark, large text) and on the dashboard sizes.

### Key Entities

- **Content item**: id, type (`video` | `tip`), title, category id, body, ageFromMonths / ageToMonths (optional), order, status (`draft` | `published` | `archived`), youtubeId, youtubeUrl, timestamps and who changed it.
- **Category list**: ordered ids with Arabic names, edited by the doctor.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A visitor finds a published item by category or search in under 10 seconds.
- **SC-002**: 100% of non-YouTube links are refused; 100% of supported YouTube link forms yield the right id.
- **SC-003**: 0 drafts or archived items visible in the app.
- **SC-004**: Every publish, unpublish and archive is in the audit log.

## Assumptions

- Assumptions marked in Clarifications need owner review.
- Thumbnails come from YouTube's public image URLs (no storage).
- No in-app comments, likes or monthly content notifications (Phase 2, requirements item 13).
