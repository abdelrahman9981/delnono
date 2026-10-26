# Notes for features not specified yet

Decisions to pick up when each feature is specified (`/speckit-specify`). Numbers follow the
constitution's feature order (1.3.0).

## 007 Notifications

- D-42: Phase 1 appointment and vaccine reminders are **local notifications** scheduled on the phone
  when a booking is made or changed, and cancelled when it is cancelled. Server push (FCM) waits for
  Blaze (D-40).
- D-18, D-34: push plus an in-app notifications page; the guardian turns each type on or off; no
  duplicate sends for the same event.
- Reminder times: booking one day and one hour before (D-18); vaccines 3 days before and on the day
  (D-17), for basic vaccines and the additional ones the family chose (FR-45).

## 008 Packages

- D-14, D-46: package valid in every clinic, revenue to the selling clinic, covered visits recorded
  where they happen; 14-day expiry notice; renewal by cash.

## 006 Content library

- D-50: videos are hosted on YouTube as Unlisted. Staff paste the YouTube link in the dashboard;
  Firestore stores only the video id or link and the title; the app plays it inside the app
  (youtube_player_iframe or similar). No Cloud Storage for videos. Not built yet.
