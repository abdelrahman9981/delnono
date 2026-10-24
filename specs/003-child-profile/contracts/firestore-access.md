# Contract: Firestore Security Rules (003)

Builds on [001](../../001-account-registration/contracts/firestore-access.md) and
[002](../../002-booking/contracts/firestore-access.md). "Linked guardian" = 001's `linkedGuardian(child)`:
current consent, active session, and `child.guardianUid == request.auth.uid`. Each row is a rules test
in `functions/test/rules/`.

| Path | Operation | Allowed when | Must be denied (test) |
|------|-----------|--------------|------------------------|
| `children/{c}/measurements/{m}` | read, list | linked guardian of `c` | other guardian; outdated consent; inactive guardian; anonymous |
| `children/{c}/measurements/{m}` | write | never (004 adds staff) | linked guardian |
| `children/{c}/measurements/{m}/changes/{x}` | any | never (staff only, 004) | linked guardian |
| `children/{c}/doses/{d}` | read, list | linked guardian of `c` | other guardian |
| `children/{c}/doses/{d}` | write | never | linked guardian |
| `children/{c}/visits/{v}` | read, list | linked guardian of `c` | other guardian |
| `children/{c}/visits/{v}` | write | never | linked guardian |
| `children/{c}/visits/{v}/staff/{doc}` | any | never (doctor in 004) | linked guardian |
| `vaccineSchedule/{e}` | read | signed in | anonymous |
| `vaccineSchedule/{e}` | write | never | guardian |
| `followUp/{b}` | read | signed in | anonymous |
| `followUp/{b}` | write | never | guardian |
| `settings/vaccines`, `settings/followUp` | read | anyone (as other settings) | — |
| `settings/*` | write | never | guardian |
