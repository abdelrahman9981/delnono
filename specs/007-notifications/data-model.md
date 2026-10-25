# Data Model: Notifications (device only)

## Reminder (computed)
| Field | Notes |
|---|---|
| key | stable text key (research R2) |
| id | 31-bit hash of key |
| kind | `booking24h`, `booking1h`, `vaccine3d`, `vaccineDay` |
| at | instant (UTC) |
| title, body | Arabic text from the ARB file |
| route | `/bookings` or `/child/{childId}` |

## Feed item (computed)
Reminder with `at ≤ now`, or `confirmed` / `cancelled` booking event: key, time, title, body, route, read (from markers).

## Preferences (shared_preferences)
| Key | Type | Default |
|---|---|---|
| `notif.booking` | bool | true |
| `notif.vaccine` | bool | true |
| `notif.read` | string list (item keys, at most 300, newest kept) | [] |
| `notif.askedPermission` | bool | false |
