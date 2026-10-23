# Contract: App Routes (002)

All booking routes are inside the shell and protected by 001's guard (sign-in, registration, consent,
re-check). Nested routes show a back button pointing right; list chevrons point left (RTL rule, 001).

| Route | Screen | Design |
|-------|--------|--------|
| `/booking` | Booking: visit type, day, hour, children, vaccines per child, summary, confirm; top-bar action "حجوزاتي" | `docs/design/figma/booking.jpg` |
| `/booking/done/:id` | Booking success: number, day, hour, visit, children, amount, "الدخول بالأسبقية"; "عرض حجوزاتي", "الرجوع للرئيسية" | `docs/design/figma/booking-success.jpg` |
| `/booking/mine` | My bookings: tabs upcoming / past; cards with status, number, amount; change and cancel before the window, "كلمي العيادة" inside it; "احجزي ميعاد جديد" | `docs/design/figma/my-bookings.jpg` |
| `/booking/change/:id` | Booking screen pre-filled with the booking, confirming a change | `booking.jpg` |

The guardian without linked children sees, on `/booking`, a prompt to add a child (`/children/add`).
"كلمي العيادة" opens WhatsApp with `settings/clinic.whatsappNumber` (001's `ExternalLinks`).
