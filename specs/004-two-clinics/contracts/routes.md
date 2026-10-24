# Contract: App Routes (004 changes)

| Route | Screen | Change |
|-------|--------|--------|
| `/` | Home | doctor card and one card per active clinic: name, address, hours, call, WhatsApp, "احجزي هنا" |
| `/booking?clinic=<id>` | Booking | clinic step first (skipped with one clinic or when `clinic` is given); then 002's steps for that clinic |
| `/booking/done/:id`, `/booking/mine` | Success, My bookings | clinic name and address on each booking |
| `/booking/change/:id` | Change | clinic fixed to the booking's |
| `/children/:id/visits` | Visit history | clinic name on each visit |
