# Data Model: Account and Registration (001)

Firestore collections. Phone numbers are stored in E.164 (`+201xxxxxxxxx`). Timestamps are
server timestamps. "Server only" means no client read or write; only Cloud Functions touch it.

## guardians/{uid}

Doc ID is the Firebase Auth uid.

| Field | Type | Rules |
|-------|------|-------|
| phone | string | E.164, equals the Auth record's phone; changed only by `syncPhoneNumber` |
| fullName | string | required, 2–80 chars |
| relation | string | `mother` \| `father` \| `other` |
| email | string? | optional, valid email if present |
| consentVersion | number | latest accepted policy version |
| clinicChildrenPending | boolean | server-set: true while unlinked clinic children exist on `phone` and linking is not locked; drives the router's link step (routes guard step 4) |
| createdAt, updatedAt | timestamp | |

Created only by `completeRegistration`. Guardian may update `fullName`, `relation`, `email`.
`clinicChildrenPending` is set by `completeRegistration`, cleared by `linkClinicChildren` on success
or lock, and set again by staff registration in 004.
Deleted by `deleteAccount`.

### guardians/{uid}/consents/{consentId}

Append-only, written only by functions.

| Field | Type |
|-------|------|
| policyVersion | number |
| scopes | array: `privacy_policy`, `terms`, `child_data` |
| acceptedAt | timestamp |

Retained on account deletion: moved to `deletedGuardians/{uid}/consents` (server only) as evidence
of lawful processing for the clinic's retained record.

## children/{childId}

| Field | Type | Rules |
|-------|------|-------|
| name | string | required, 2–60 chars; guardian-editable |
| nameKey | string | normalised name for duplicate check (trimmed, collapsed spaces, Arabic letter variants unified); server-set |
| birthDate | string `YYYY-MM-DD` | required, not in future, within 18 years; staff-only after creation |
| sex | string | `male` \| `female`; staff-only after creation |
| birthWeightKg | number? | 0.3–7.0 |
| allergies | string? | ≤ 500 chars; guardian-editable |
| guardianPhone | string | E.164; the number the child is registered on |
| guardianUid | string? | uid of linked app account; null when unlinked (clinic-registered, or account deleted) |
| registeredBy | string | `guardian` \| `clinic` |
| createdAt | timestamp | |
| updatedAt | timestamp | must equal `request.time` on guardian edit |
| updatedBy | string | must equal `request.auth.uid` on guardian edit |

Uniqueness: no two children with the same `guardianPhone` + `nameKey` + `birthDate` (enforced in
`createChild`; clinic-side creation enforced in 004).

### children/{childId}/history/{entryId}

Written by the `onChildUpdated` trigger. Fields: `changedFields` (map of field → {from, to}),
`changedBy` (uid), `changedAt`. Readable by the linked guardian.

## clinicGuardians/{phone}

Created by staff in 004 (walk-in registration). Server only in 001. Fields: `fullName`, `relation`,
`email?`, `createdAt`. Never returned to the guardian app; the guardian enters their own details
(User Story 4, scenario 3). The clinic's record stays for staff in 004.

## linkAttempts/{phone}

Server only. `failedCount` (number), `lockedAt` (timestamp?). Reset on success; while `lockedAt` is
set, `linkClinicChildren` refuses until staff link the children (004).

## smsCounters/{phone}_{YYYYMMDD}

Server only. `count` (number), `expiresAt` (timestamp, TTL policy deletes after 2 days). Used by
`beforeSmsSent` (R1).

## auditLog/{entryId}

Server only; readable by the doctor in 004. Fields: `action`, `actorUid`, `subjectPhone`,
`childIds?`, `details?`, `at`. Retained 1 year (D-13) via TTL on `expiresAt`.

## settings/auth

Readable by anyone (needed before sign-in); written by the doctor (004).

| Field | Default |
|-------|---------|
| codeValiditySeconds | 300 |
| maxCodeAttempts | 5 |
| resendWaitSeconds | 60 |
| dailySmsCapPerNumber | 5 |
| maxLinkAttempts | 3 |

## settings/policy

Readable by anyone. `currentVersion` (number), `privacyPolicyText`, `termsText` (Arabic; marked
placeholder until supplied, D-36), `updatedAt`.

## settings/clinic

Readable by anyone. `whatsappNumber` (E.164; placeholder until the clinic supplies it, D-36), used
by the account screen's support link (FR-034). Written by the doctor (004).

## State transitions

```text
Guardian account:  (none) --completeRegistration--> active --deleteAccount--> (deleted; doc removed,
                   consents moved to deletedGuardians)

Child link:        unlinked (clinic) --linkClinicChildren ok--> linked
                   linked --deleteAccount--> unlinked (guardianUid = null, guardianPhone kept)

Link attempts:     open --wrong birth date x maxLinkAttempts--> locked --staff link (004)--> open
```
