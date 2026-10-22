# Contract: Cloud Functions (001)

All callables are 2nd gen, deployed in the same region as Firestore (research R8), require an authenticated caller with a verified
phone number, and return errors as `HttpsError` with the codes below. The app maps each code to an
Arabic message.

## completeRegistration

Writes the guardian and the first consent record in one transaction (FR-012 to FR-016).

```text
in:  { fullName: string, relation: "mother"|"father"|"other", email?: string,
       consent: { policyVersion: number, scopes: ["privacy_policy","terms","child_data"] } }
out: { hasClinicChildren: boolean }
```

| Error | When |
|-------|------|
| `already-exists` | guardian doc already exists for this uid |
| `failed-precondition` | `policyVersion` ≠ `settings/policy.currentVersion`, or a scope is missing |
| `invalid-argument` | field validation fails (see data-model) |

Audit: `account.created`, `consent.accepted`.

## acceptPolicy

Records a new consent after a policy version change (FR-017).

```text
in:  { policyVersion: number, scopes: [...] }
out: {}
```

Errors: `failed-precondition` (version not current), `not-found` (no guardian). Audit:
`consent.accepted`.

## linkClinicChildren

Birth-date check before linking clinic-registered children (FR-021, FR-021a).

```text
in:  { birthDate: "YYYY-MM-DD" }
out: { linked: [{ childId, name }] }
```

| Error | When |
|-------|------|
| `not-found` | no unlinked clinic children on the caller's phone |
| `permission-denied` | birth date does not match any of them; `details.remaining` = attempts left |
| `resource-exhausted` | locked after `settings/auth.maxLinkAttempts` failures |
| `failed-precondition` | no guardian doc or consent not current |

Audit: `children.linked`, `children.link_failed`, `children.link_locked`.

## createChild

Creates a child after the duplicate check (FR-018, FR-022).

```text
in:  { name, birthDate, sex: "male"|"female", birthWeightKg?, allergies? }
out: { childId }
```

| Error | When |
|-------|------|
| `already-exists` | same `nameKey` + `birthDate` on the caller's phone; `details.existingLinked` says whether it is already in the account (if not, the app tells the guardian to contact the clinic) |
| `invalid-argument` | validation fails |
| `failed-precondition` | no guardian doc or consent not current |

## syncPhoneNumber

Called after a successful `updatePhoneNumber` (FR-025, FR-026). Reads the phone from the Auth
record, updates `guardians/{uid}.phone` and `guardianPhone` on linked children.

```text
in:  {}
out: { phone }
```

Audit: `phone.changed` (old and new number). FR-025a conflicts never reach this function:
`updatePhoneNumber` fails first with `credential-already-in-use`.

## deleteAccount

Deletes the app account (FR-027 to FR-030).

```text
in:  { confirm: true }
out: {}
```

Steps, in order: move consents to `deletedGuardians/{uid}`; set `guardianUid = null` on linked
children (records kept); delete `guardians/{uid}`; write audit `account.deleted`; revoke refresh
tokens and delete the Auth user. Booking cancellation is added by 002. Idempotent: a retry after a
partial failure completes the remaining steps.

## beforeSmsSent (blocking, needs Identity Platform)

Increments `smsCounters/{phone}_{YYYYMMDD}`; returns `{ recaptchaActionOverride: "BLOCK" }` when the
count exceeds `settings/auth.dailySmsCapPerNumber` (FR-009). Must answer within 7 s.

## onChildUpdated (Firestore trigger)

On `children/{childId}` update, writes `history/{entryId}` with changed fields, `updatedBy` and time
(FR-023).
