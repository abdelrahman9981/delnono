# Contract: Firestore Security Rules (004 changes)

| Path | Operation | Allowed when | Must be denied (test) |
|------|-----------|--------------|------------------------|
| `clinics/{id}` | read | anyone (Home is public) | — |
| `clinics/{id}` | write | never (staff in 005) | guardian |
| `slots/{id}` | read | signed in (as 002) | anonymous |

Other rows as 001–003.
