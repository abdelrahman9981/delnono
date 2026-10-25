# Research: Notifications

## R1. Rebuild all instead of tracking events
- **Decision**: On every change of bookings, doses, children, schedule, catalogue or switches, compute the full reminder list and replace the phone's pending notifications (cancel all, schedule the 50 nearest).
- **Rationale**: Covers changes made anywhere (guardian, clinic, another phone) with one code path; stable ids mean a re-run never duplicates (D-18). Cost is a handful of plugin calls.
- **Alternatives**: Scheduling in the booking flow only would miss clinic moves and cancellations (005 staff actions).

## R2. Stable ids
- **Decision**: Each reminder has a text key (`booking:{id}:24h`, `booking:{id}:1h`, `vaccine:{childId}:{scheduleId|vaccineId#dose}:3d|day`); the plugin id is a 31-bit FNV-1a hash of it.

## R3. Times
- **Decision**: Booking times from `startsAt` (UTC instant); vaccine times at 09:00 Africa/Cairo with the `timezone` database; scheduled as `TZDateTime` in Cairo, so the phone's zone does not matter. Android `inexactAllowWhileIdle` (no exact-alarm permission; a few minutes' drift is acceptable for a reminder).

## R4. The page
- **Decision**: Items = planned reminders with time ≤ now (whatever the switches) + confirmations (booking `updatedAt ?? createdAt`, key includes `startsAt` so a change is a new item) + cancellations (`cancelledAt`). Read markers are item keys in shared_preferences. Items older than 60 days are not shown.

## R5. Permission
- **Decision**: Ask on the first booking success screen and when a switch is turned on; iOS and Android 13+ via the plugin's request methods; remember that it was asked; if denied show a note with a button to the phone's settings (app settings URL).

## R6. Tap
- **Decision**: Payload is the route (`/bookings` or `/child/{id}`); handled from `onDidReceiveNotificationResponse` and `getNotificationAppLaunchDetails` at start through the router.
