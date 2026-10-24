# Contract: Cloud Functions (005)

All callables: caller signed in with an active `staff/{uid}`; `permission-denied` otherwise.
"Own clinic" = the secretary's `clinicId`; the doctor may pass any clinic.

| Callable | Who | In | Effect |
|----------|-----|----|--------|
| `manageStaff` | doctor | `{action: create\|update\|disable\|enable, uid?, name, email, role, clinicId, tempPassword?}` | Auth user, claims, `staff/{uid}`; never disables the last active doctor |
| `staffPasswordChanged` | staff | `{}` | clears `mustChangePassword` |
| `queueAction` | staff, own clinic | `{action: arrive\|done\|noShow\|undo, bookingId?\|walkInId?}` | status, times, visits on done; undo = doctor, same day |
| `addWalkIn` | staff, own clinic | `{clinicId, hour, familyName, phone, children, visitType}` | today's walk-in, slot +1; refused when full or stopped |
| `setWalkInsStopped` | staff, own clinic | `{clinicId, date, stopped}` | `days/{clinic}_{date}` |
| `recordPayment` | staff, own clinic | `{bookingId?\|walkInId?, cash, covered}` | `payment` |
| `sellPackage` | staff, own clinic | `{clinicId, guardianUid}` | `packages/{id}`; refused when an active package exists |
| `staffBookingAction` | staff, own clinic | `{action: cancel\|change, bookingId, selection?}` | 002 rules without the cancel window |
| `searchChildren` | staff | `{query}` | name or phone matches: id, name, birth date, guardian phone |
| `openChildFile` | staff | `{childId}` | child, measurements, doses, visits (+ notes for the doctor); audit `child.opened` |
| `saveMeasurement`, `saveDose` | create: staff at own clinic; update: doctor | record fields + `id?` | record; update writes `changes` and audit |
| `saveVisitNote` | doctor | `{childId, visitId, text}` | `staff/notes` |
| `updateChildBasics` | staff | `{childId, name, birthDate, sex, allergies}` | child; history by trigger |
| `updateClinic` | staff own clinic; doctor any | `{clinicId, fields}` (schedule, prices, contact; secretary cannot change name/active/order) | clinic; audit |
| `updateCatalogue` | doctor | vaccines, schedule entries, `settings/vaccines` | audit |
| `saveContent` | staff (draft); doctor (publish, archive) | `{id?, fields, status}` | `content/{id}` |
| `saveFollowUpDraft`, `publishFollowUp` | staff draft; doctor publish | bands, danger signs | drafts → live |
| `updateSettings` | doctor | `{doc: auth\|policy\|booking\|followUp\|vaccines, fields}` | settings; audit |
| `report` | staff own clinic; doctor any or `all` | `{clinicId, from, to, groupBy: day\|month}` | rows of six numbers and totals |
