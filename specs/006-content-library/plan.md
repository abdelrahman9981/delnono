# Implementation Plan: Content Library

**Branch**: `006-content-library` | **Date**: 2026-10-26 | **Spec**: [spec.md](spec.md)

## Summary

The «محتوى» tab becomes a library of published videos and tips (category chips, title search, «مناسب لسن <child>» for children under 4, offline read for loaded items) with an in-app vertical 9:16 YouTube player and a «شوفي الفيديو على يوتيوب» fallback. Home gets a «جديد من الدكتور» card with up to 3 latest items. On the dashboard, 005's content screen grows: type (video/tip), YouTube link validated client and server side with the id extracted and a thumbnail shown, order, preview as in the app, doctor-only publish / unpublish / archive (audited per action), doctor-edited categories, and «استيراد من القناة» from the channel feed. The seed adds 8 real channel Shorts (3 published) and 3 bracketed tips.

## Technical Context

**Language/Version**: Dart 3.13 / Flutter 3.47 (app and dashboard); TypeScript on Node 22 (Cloud Functions)
**Primary Dependencies**: Riverpod 3, go_router 18, cloud_firestore, cloud_functions, url_launcher; new: `youtube_player_iframe` 6.x (WebView IFrame player, research R1), `connectivity_plus` 7.x (offline message, R4)
**Storage**: Cloud Firestore `content/{id}` (extended) and `settings/content` (categories). No Cloud Storage (D-50).
**Testing**: flutter test (unit, widget, layout), Mocha + Functions/Firestore emulators, rules-unit-testing, one simulator integration test (`integration_test/content_test.dart`), dashboard browser e2e unchanged
**Target Platform**: iOS/Android app; dashboard in a browser; Functions emulator only (deploy is "blocked: Blaze", D-40)
**Project Type**: Mobile app + web dashboard + serverless backend (one repo)
**Performance Goals**: Library list from cache instantly; a visitor finds an item in < 10 s (SC-001)
**Constraints**: Guardians read published items only; staff write only through callables; no medical judgement; Arabic RTL
**Scale/Scope**: Tens of items, 6 categories

## Constitution Check

| Principle | Check |
|---|---|
| I. Privacy and consent first | The library needs no sign-in and reads no personal data; the age section uses the child's birth date already on the phone. ✅ |
| II. Medical safety | Texts are the doctor's; drafts and placeholders are bracketed; nothing published without the doctor; no automatic judgement. ✅ |
| III. Configurable | Categories, order and age ranges are data the doctor edits. ✅ |
| IV. Arabic RTL, accessible | Chips, cards and the player follow the RTL rules (‹ forward, › back); large-text and dark layout tests. ✅ |
| V. Test-first, emulator-tested | Parser unit tests (Dart and TS), callable and rules tests, widget tests, one simulator e2e. ✅ |
| VI. Simple | One collection and one settings doc; the player is a package, not custom code. ✅ |
| VII. Cost | YouTube hosts the videos (D-50); no Storage; channel import is a callable, emulator now, "blocked: Blaze" on the real project. ✅ |
| Roles (D-19, roles table) | Secretary drafts; doctor publishes, unpublishes, archives and edits categories; each audited (D-13). ✅ |

## Project Structure

```text
functions/src/lib/youtube.ts                    # youtubeId(url), parseChannelFeed(xml)
functions/src/callables/staff/content.ts        # saveContent (moved, extended), setContentStatus, saveContentCategories, channelVideos
functions/src/lib/audit.ts                      # content.unpublished, content.archived, content.categories_updated
functions/src/index.ts
functions/scripts/seed.ts                       # 8 videos, 3 tips, settings/content
functions/test/functions/staff/content.test.ts, functions/test/unit/youtube.test.ts
functions/test/rules/staff.test.ts              # content + settings/content
lib/core/content/youtube.dart                   # shared Dart id parser and thumbnail URL
lib/features/content/domain/content_item.dart   # ContentItem, ContentCategory, filters, Arabic normalising search, age match
lib/features/content/data/content_repository.dart  # published items, categories (Firestore cache works offline)
lib/features/content/application/connectivity.dart # onlineProvider
lib/features/content/presentation/library_screen.dart, item_card.dart, tip_screen.dart, video_screen.dart
lib/features/home/home_screen.dart              # latest 3 card
lib/app/router.dart                             # /content, /content/tip/:id, /content/video/:id
lib/dashboard/screens/content_screen.dart       # list, filters, status actions, categories, import
lib/dashboard/screens/content_dialog.dart       # form, link check, thumbnail, preview
test/core/youtube_test.dart, test/features/content/*, test/dashboard/content_test.dart
integration_test/content_test.dart
```

**Structure Decision**: Guardian code follows the feature-folder layout of 007/008; dashboard code stays in `lib/dashboard/screens`; content callables move out of `admin.ts` into their own file (export names unchanged).

## Complexity Tracking

None.
