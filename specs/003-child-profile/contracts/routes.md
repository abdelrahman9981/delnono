# Contract: App Routes (003)

All routes are inside the shell and behind 001's guard (sign-in, registration, consent, re-check).
Nested routes show a back button pointing right; list chevrons point left (RTL rule, 001).

| Route | Screen | Design |
|-------|--------|--------|
| `/children` | My child: child switcher, package card, latest measurements, growth chart, entries to vaccines, visits and follow-up, "تعديل البيانات" and "إضافة طفل". Without children: the add-child prompt (001) | `docs/design/figma/child-profile.jpg` |
| `/children/add` | Add child (001) | `screens/AddChild.dc.html` |
| `/children/:id` | Edit name and allergies (001's child details) | — |
| `/children/:id/vaccines` | Vaccine schedule: source and review date, basic doses by age with state, additional vaccines marked "إضافي" | — (cards and pills from `tokens.css`) |
| `/children/:id/visits` | Visit history, newest first (prescription photos in Phase 2, D-39) | — |
| `/children/:id/follow-up` | Age follow-up and "متى تتصلين بالدكتور" with clinic and 123 buttons | `screens/FollowUp.dc.html` |

"اتصلي بالعيادة" opens `tel:` with `settings/clinic.phoneNumber`; "الإسعاف ١٢٣" opens `tel:123`.
