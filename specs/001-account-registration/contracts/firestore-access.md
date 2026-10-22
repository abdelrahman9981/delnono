# Contract: Firestore Security Rules (001)

Each row is a rules test case in `functions/test/rules/`. "Guardian" = signed-in user with a guardian
doc whose `consentVersion` equals `settings/policy.currentVersion`. Staff roles arrive in 004; all
staff access is denied in 001.

| Path | Operation | Allowed when | Must be denied (test) |
|------|-----------|--------------|------------------------|
| `settings/{doc}` | read | anyone | — |
| `settings/{doc}` | write | never (004 adds doctor) | guardian, unauthenticated |
| `guardians/{uid}` | read | `request.auth.uid == uid` | other signed-in user |
| `guardians/{uid}` | create, delete | never (functions only) | owner |
| `guardians/{uid}` | update | owner, and only `fullName`, `relation`, `email`, `updatedAt` change, values valid | changing `phone`, `consentVersion`, `clinicChildrenPending` or `lastActiveAt` |
| `guardians/{uid}/consents/{id}` | read | owner | other user |
| `guardians/{uid}/consents/{id}` | write | never | owner |
| `children/{id}` | read, list | guardian and `resource.data.guardianUid == request.auth.uid` and guardian `lastActiveAt` newer than `request.time` minus `settings/auth.reverifyAfterDays` | other guardian; unlinked clinic child on same phone; guardian with outdated consent; guardian inactive beyond `reverifyAfterDays` (FR-010a) |
| `children/{id}` | create, delete | never (functions only) | guardian |
| `children/{id}` | update | guardian is linked and active (same `lastActiveAt` condition as read); changed keys ⊆ {`name`, `allergies`, `updatedAt`, `updatedBy`}; `updatedBy == request.auth.uid`; `updatedAt == request.time`; values valid | changing `birthDate`, `sex`, `guardianUid`, `guardianPhone` |
| `children/{id}/history/{h}` | read | guardian linked to the child and active (same `lastActiveAt` condition) | other guardian; inactive guardian |
| `children/{id}/history/{h}` | write | never | guardian |
| `clinicGuardians`, `linkAttempts`, `reverifyAttempts`, `smsCounters`, `auditLog`, `deletedGuardians` | any | never | guardian, unauthenticated |

Default: deny everything not listed.
