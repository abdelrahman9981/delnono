# Data Model: Two Clinics (004)

Firestore. Builds on 002 and 003. Dates `YYYY-MM-DD`, hours in Cairo time.

## clinics/{clinicId} (new)

Readable by anyone; written by staff in 005. Seeded for two clinics with `placeholder: true`.

| Field | Type | Rules |
|-------|------|-------|
| name | string | e.g. "[عيادة المقطم · بيانات مؤقتة]" |
| area | string | short name for the clinic step, e.g. "المقطم" |
| address | string | |
| phone, whatsapp | string? (E.164) | button hidden when missing |
| active | boolean | only active clinics are shown and bookable |
| order | number | display order; the lowest active is the main clinic |
| capacityPerHour | number | default 6 |
| workingHours | map weekday ("1"–"7") → list of `{from, to}` | as 002 |
| holidays | list of dates | |
| vaccineWeekdays | list of weekday numbers | |
| cancelWindowHours | number | default 3 |
| visitPrice | number (EGP) | |
| packagePrice | number (EGP) | |
| vaccinePrices | map vaccineId → `{offered: bool, price: number, shown: bool}` | |
| placeholder | boolean | |

## settings/booking (002, reduced)

Family-wide only: `bookingHorizonDays` (14), `maxUpcomingPerFamily` (2). Clinic fields move to
`clinics`.

## vaccines/{id} (002/003)

Name, kind, schedule fields and `active` stay; `price` and `showPrice` move to
`clinics/{c}.vaccinePrices`.

## slots/{clinicId}_{date}_{HH}

`clinicId`, `date`, `hour`, `taken`.

## bookings/{id} (002, extended)

Adds `clinicId`. Price snapshot from the clinic's prices. Missing `clinicId` = main clinic.

## familyQuota/{uid} (002)

Entries `{bookingId, date, startsAt, clinicId}`; limits counted across clinics.

## packages/{id} (read here)

Adds `soldAtClinicId`. Coverage ignores the clinic (D-46).

## children/{id}/visits, measurements, doses (003, extended)

Each adds `clinicId` (D-48). Missing = main clinic.
