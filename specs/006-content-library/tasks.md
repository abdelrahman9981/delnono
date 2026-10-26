# Tasks: Content Library

**Input**: specs/006-content-library/ (spec, plan, research, data-model, contracts/callables.md)
**Tests**: requested (unit, rules, widget, one simulator e2e).

## Phase 1: Setup

- [X] T001 Add `youtube_player_iframe: ^6.0.2` and `connectivity_plus: ^7.0.0` to pubspec.yaml; `flutter pub get`; `cd ios && pod install` builds
- [X] T002 [P] Audit actions `content.unpublished`, `content.archived`, `content.restored`, `content.categories_updated` in functions/src/lib/audit.ts

## Phase 2: Foundational

- [X] T003 [P] TS `youtubeId(url)` and `parseChannelFeed(xml)` in functions/src/lib/youtube.ts with unit tests in functions/test/unit/youtube.test.ts (all link forms in R3; vimeo, http-only text, wrong-length ids refused)
- [X] T004 [P] Dart `youtubeIdFrom(String)`, `youtubeThumb(id)`, `youtubeWatchUrl(id)` in lib/core/content/youtube.dart with tests in test/core/youtube_test.dart (same cases as T003)
- [X] T005 Move content callables to functions/src/callables/staff/content.ts: `saveContent` (type, youtubeId from url, `invalid_youtube`, `duplicate`+existingId, categories from settings/content with BRD default, age both-or-neither 0..216, order default 100, tip body required, never changes status; doctor only for non-draft items), `setContentStatus` (doctor, transitions per data-model, audit each), `saveContentCategories` (doctor, `in_use`), `channelVideos` (staff, feed URL from env `CHANNEL_FEED_URL` else the channel, `alreadyAdded`); exports in functions/src/index.ts; remove old saveContent from admin.ts
- [X] T006 Callable tests in functions/test/functions/staff/content.test.ts (secretary draft ok, publish refused `doctor_only`, doctor transitions + audit entries, invalid link, duplicate, categories in_use, channelVideos parses a local feed); update functions/test/functions/staff/admin.test.ts for the new contract
- [X] T007 Rules tests in functions/test/rules/staff.test.ts: published readable by anyone, draft/archived staff only, no client writes to content or settings/content
- [X] T008 Seed in functions/scripts/seed.ts: settings/content categories (6), 8 videos (titles from frames, R8), WjbDIjEH38U/TGzE9d9m44A/KDOV-4nbWqU published, 3 bracketed tips published (fever, sleep, allergy, with age ranges); regenerate emulator-seed/
- [X] T009 Domain in lib/features/content/domain/content_item.dart: `ContentItem.fromMap` (legacy defaults), `ContentCategory`, `normalizeArabic`, `matchesQuery`, `coversAge(months)`, sort by order then publishedAt desc; tests test/features/content/content_item_test.dart
- [X] T010 Repository lib/features/content/data/content_repository.dart: `publishedContentProvider` (where status == published), `contentCategoriesProvider` (settings/content, BRD default when missing)

**Checkpoint**: phase checks green.

## Phase 3: US1 Browse the library (P1) 🎯 MVP

- [X] T011 [US1] Library screen lib/features/content/presentation/library_screen.dart per Content.dc.html: header «مكتبة المحتوى», search field (key 'content-search'), chips «الكل» + categories (keys 'chip-<id>'), list of cards (lib/features/content/presentation/item_card.dart: thumbnail or tip icon, title, category, age), footer «كل المحتوى بيراجعه الدكتور قبل النشر», empty «لسه مفيش محتوى منشور», no-results, loading, LoadErrorView
- [X] T012 [US1] Tip screen lib/features/content/presentation/tip_screen.dart (title, category, age, body; back ›)
- [X] T013 [US1] Video screen lib/features/content/presentation/video_screen.dart: full-screen black, `AspectRatio(9/16)` player behind a `VideoPlayerFactory` provider (tests use a fake), title under, «شوفي الفيديو على يوتيوب» (key 'open-youtube') always; on player error/timeout show «الفيديو مش متاح هنا»
- [X] T014 [US1] Routes /content, /content/tip/:id, /content/video/:id in lib/app/router.dart (outside the auth guard); remove ContentPlaceholder
- [X] T015 [US1] Strings in l10n/app_ar.arb (append) and regenerate
- [X] T016 [US1] Widget tests test/features/content/library_test.dart: only given published items listed, chip filter, search with hamza/taa variants, tap tip → text, tap video → player (fake) and fallback on error, empty and error states

## Phase 4: US2 Age section (P2)

- [X] T017 [US2] «مناسب لسن <name>» in library_screen.dart using `childForProfileProvider`-style selected child (selected or first) when signed in, child < 48 months, items with age range covering today's age; hidden otherwise
- [X] T018 [US2] Tests in test/features/content/library_test.dart: 7-month child sees 6–12 item, not 0–2; 5-year child no section; signed out no section

## Phase 5: US3 Offline (P2)

- [X] T019 [US3] `onlineProvider` (connectivity_plus stream) in lib/features/content/application/connectivity.dart; video screen shows «الفيديو محتاج إنترنت» (key 'video-offline') offline; library keeps working from cache
- [X] T020 [US3] Test: offline → video screen shows the message, list still shows items

## Phase 6: US4 Dashboard (P1)

- [X] T021 [US4] Content dialog lib/dashboard/screens/content_dialog.dart: type segmented (video/tip), title, category (from settings/content), link field with live check (id + thumbnail `Image.network`, error «ده مش رابط يوتيوب»), body, optional age range toggle, order, preview pane (same card + detail as app), save → `saveContent`
- [X] T022 [US4] Content screen lib/dashboard/screens/content_screen.dart: status filter, order then title sort, per-item actions by role: doctor publish / unpublish / archive / restore (`setContentStatus`), secretary edit drafts only; «التصنيفات» dialog (doctor) → `saveContentCategories`; «استيراد من القناة» dialog → `channelVideos`, pick → dialog prefilled
- [X] T023 [US4] Dashboard tests test/dashboard/content_test.dart (+ update test/dashboard/screens_test.dart): secretary has no publish buttons; doctor actions call `setContentStatus`; link check shows id and refuses vimeo; preview shows title; categories dialog; import list fills the form; layout at dashboard sizes

## Phase 7: US5 Home card (P3)

- [X] T024 [US5] «جديد من الدكتور» card in lib/features/home/home_screen.dart: up to 3 latest published (publishedAt desc), tap opens item, «كل المحتوى ‹» to /content; hidden when none
- [X] T025 [US5] Home widget test for the card (3 max, hidden when empty)

## Phase 8: Polish

- [X] T026 Layout tests (large text, dark) for library, tip and video screens in test/features/content/layout_test.dart
- [X] T027 Simulator e2e integration_test/content_test.dart: signed out, open «محتوى», filter, search, open a tip, open a video (player screen and YouTube button present)
- [ ] T028 docs: feature-notes 006 built, quickstart check, dashboard e2e still green, report table (id, date, title, category)
