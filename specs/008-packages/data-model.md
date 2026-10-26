# Data Model: Packages

## packages/{id} (existing)
`guardianUid`, `soldAtClinicId`, `price`, `startsOn`, `endsOn`, `active`, `soldBy`, `soldOn`, `soldAt`; new optional `renews` (id of the package it follows).

## clinics/{id} (existing fields, now read by the app)
`packagePrice` (EGP), `packageMonths` (default 12).

## FamilyPackageView (computed)
`current` (covers today) · `next` (starts after today) · `lastEnded` · `renewableFrom` (= current.endsOn − 14 days).
