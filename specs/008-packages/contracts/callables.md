# Callables: Packages

## sellPackage (changed)
Request: `{ clinicId, guardianUid, renew?: boolean }`.
- Without `renew`: as before; refused `has_package` when a package covers today or a later one exists.
- With `renew: true`: needs a package covering today that ends within 14 days and no later package; else `failed-precondition` `{reason: "no_package" | "too_early" | "has_package"}`. Creates `{startsOn: end+1, endsOn: addMonths(startsOn, months), renews: currentId, ...}`; audit `package.sold` with `renew: true`.

Response: `{ packageId, startsOn, endsOn, price }`.
