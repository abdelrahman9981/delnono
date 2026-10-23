# Contract: Firestore Security Rules (002)

Builds on [001](../../001-account-registration/contracts/firestore-access.md). "Active guardian" =
signed in, guardian doc with current consent and `lastActiveAt` within `reverifyAfterDays` (001's
`consentCurrent()` and `active()`). Each row is a rules test in `functions/test/rules/`.

| Path | Operation | Allowed when | Must be denied (test) |
|------|-----------|--------------|------------------------|
| `settings/booking` | read | anyone (as other settings) | — |
| `settings/booking` | write | never (004 adds doctor) | guardian |
| `vaccines/{id}` | read | signed in | anonymous |
| `vaccines/{id}` | write | never | guardian |
| `slots/{id}` | read | signed in | anonymous |
| `slots/{id}` | write | never (functions only) | guardian |
| `bookings/{id}` | read, list | active guardian and `resource.data.guardianUid == request.auth.uid` | other guardian; outdated consent; inactive guardian; listing without the guardianUid filter |
| `bookings/{id}` | write | never (functions only) | owner (create, cancel by write, change status, change price) |
| `bookings/{id}/events/{e}` | read | as the booking | other guardian |
| `bookings/{id}/events/{e}` | write | never | owner |
| `counters/{id}` | any | never | guardian |
| `packages/{id}` | read | active guardian and `resource.data.guardianUid == request.auth.uid` | other guardian |
| `packages/{id}` | write | never (006) | guardian |
