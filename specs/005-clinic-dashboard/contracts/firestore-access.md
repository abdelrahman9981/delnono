# Contract: Firestore Security Rules (005)

"Staff" = signed in, claim `role` in {doctor, secretary}, and `staff/{uid}.active`. "Of the clinic" =
the document's `clinicId` equals the claim `clinicId`, or the caller is the doctor.

| Path | Read | Write |
|------|------|-------|
| `staff/{uid}` | self; doctor all | never (callables) |
| `bookings/{id}` | guardian rules as 002; staff of the clinic | never |
| `walkIns/{id}`, `days/{id}` | staff of the clinic | never |
| `packages/{id}` | guardian as 002; staff | never |
| `content/{id}` | anyone when `published`; staff all | never |
| `followUpDrafts/{id}`, `settings/followUpDraft` | staff | never |
| `auditLog/{id}` | doctor | never |
| `children/**` | guardian rules as 003; staff only through `openChildFile` | never |

Every row has a rules test: a secretary of clinic 1 is refused clinic 2's bookings, walk-ins and day
status; a disabled staff member is refused; a guardian is refused staff data.
