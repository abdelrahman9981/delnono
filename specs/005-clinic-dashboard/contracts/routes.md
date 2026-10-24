# Contract: Dashboard Routes (005)

| Route | Screen | Who |
|-------|--------|-----|
| `/sign-in` | email and password | — |
| `/password` | set your own password (first sign-in) | staff |
| `/today` | hour calendar, arrival queue, walk-ins, stop walk-ins, payment, package sale | staff |
| `/children` | search; `/children/:id` child file: basics, measurements, doses, visits, notes (doctor) | staff |
| `/clinic` | schedule, prices, package, vaccine offers of the clinic | staff (own), doctor (any) |
| `/vaccines` | vaccine list and schedule, source and review | doctor |
| `/content` | tips and videos; drafts and publishing | staff |
| `/follow-up` | follow-up lists and danger signs; drafts and publishing | staff |
| `/reports` | daily and monthly, CSV | staff |
| `/settings` | app settings and texts | doctor |
| `/staff` | staff accounts | doctor |
| `/audit` | audit log | doctor |

The doctor has a clinic switcher in the top bar; secretaries see their clinic's name.
