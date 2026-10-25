# Design reference — Dr. El Nono (Phase 1, guardian app)

Use these files as the visual source of truth when building Flutter screens.
Match colors, radii, spacing and component shapes; build the layout in Flutter (do not embed HTML).

## Sources

| Source | What it covers | Link / path |
|---|---|---|
| Figma Make prototype | Home, booking, booking success, my bookings, child profile | https://www.figma.com/make/mintJglNIs1vTGfqOAKt56/%D8%AA%D8%B7%D8%A8%D9%8A%D9%82-%D8%AF%D9%83%D8%AA%D9%88%D8%B1-%D8%A7%D9%84%D9%86%D9%88%D9%86%D9%88 |
| Figma screenshots (375 pt wide, 2x) | Home, booking, booking success, my bookings, child profile | `figma/home.jpg`, `figma/booking.jpg`, `figma/booking-success.jpg`, `figma/my-bookings.jpg`, `figma/child-profile.jpg` |
| Design canvas (same style, made after Figma) | The remaining 11 screens | `screens/*.dc.html` (HTML mockups; open in a browser with `tokens.css` beside them) |
| Tokens and components | Colors (light and dark), radii, buttons, cards, pills, forms, bottom nav | `tokens.css` |

## Screen map

| # | Screen | File | Feature |
|---|---|---|---|
| 1 | Welcome (browse without login) | `screens/Main.dc.html` | 001 |
| 2 | Mobile number | `screens/Phone.dc.html` | 001 |
| 3 | OTP code (6 digits, 60 s resend, attempts left) | `screens/Otp.dc.html` | 001 |
| 4 | Guardian details | `screens/Guardian.dc.html` | 001 |
| 5 | Privacy consent (two explicit checkboxes, policy version) | `screens/Consent.dc.html` | 001 |
| 6 | Add child (duplicate warning) | `screens/AddChild.dc.html` | 001 |
| 7 | Link clinic-registered children (birth-date check, 3 tries) | `screens/LinkChildren.dc.html` | 001 |
| 8 | Age follow-up + "when to call" with clinic and 123 buttons | `screens/FollowUp.dc.html` | 003 / 005 |
| 9 | Content library | `screens/Content.dc.html` | 005 |
| 10 | Notifications page + settings | `screens/Notifications.dc.html` | 007 |
| 11 | Account (change number, delete account) | `screens/Account.dc.html` | 001 |
| — | Home | `figma/home.jpg` | 002 |
| — | Booking | `figma/booking.jpg` | 002 |
| — | Booking success | `figma/booking-success.jpg` | 002 |
| — | My bookings (upcoming and past, cancel/change window) | `figma/my-bookings.jpg` | 002 |
| — | Child profile | `figma/child-profile.jpg` | 003 |

## Rules from the constitution that show in the design

- Arabic RTL everywhere; Readex Pro; light and dark (dark variables in `tokens.css` under `.dark` in Figma; keep the same pairs).
- Text sizes: Figma's prototype uses 7–9 px labels, which are too small on a phone. Use the BRD scale: body 13–15, small 11, titles 20–30.
- No automatic medical judgments ("normal", "on track"). Show values and charts only.
- Any medical text (danger signs, follow-up items, video titles) is placeholder in brackets until the doctor approves it from the dashboard.
- Bottom nav: Home, Booking, My child, Content; leave room for the Phase 2 "Ask" tab, but build nothing behind it.
- The doctor's photo is real (no longer a placeholder); see Photos and icon below.

## Known issues in Figma

- List chevrons point right (›) in the Figma screens. In RTL they must point left (‹), as fixed in the app.

- Fixed: on the home hero card the photo placeholder's caption overlapped the "موجودين عشان نطمنك" pill. The real photo has no caption; the pill sits alone in the top corner over the wall, the name and title at the bottom.

## Photos and icon

| Asset | Where |
|---|---|
| `assets/images/doctor_hero.jpg` | Home hero card and Welcome hero, cropped to keep the face in frame, under a dark bottom gradient so the white text stays readable |
| `assets/images/doctor_avatar.jpg` | Round, on each clinic card on Home and on the dashboard sign-in |
| `assets/images/clinic_waiting_room.jpg` | Top of the main clinic's card on Home (it is that clinic's room) and a card on Welcome |
| `assets/icon/app_icon_1024.png`, `app_icon_foreground.png` | App icon: Android adaptive (background `#CBE7EE`), iOS and web; the web favicon is also the dashboard's. Regenerate with `dart run flutter_launcher_icons` (`flutter_launcher_icons.yaml`) |

## Clinic dashboard (web, desktop first)

Redesign of the dashboard. Follow these over the current dashboard screens.

| Screen | Mockup | Image |
|---|---|---|
| Today (hour strip, arrival queue, KPIs, walk-in, stop walk-ins) | `dashboard/Today.dc.html` | `dashboard/Today.png` |
| Clinic settings (cards, hour ranges picked from a list, vaccine-day switches, holidays as date chips, vaccine prices with one "shown to guardian" switch, sticky save bar) | `dashboard/Clinic.dc.html` | `dashboard/Clinic.png` |
| Child file (header card, tabs, new-measurement form, history table with clinic, recorder and correction log) | `dashboard/ChildFile.dc.html` | `dashboard/ChildFile.png` |

Shared styles: `dashboard/dash.css` (same colour tokens as the app, plus a navy sidebar `#16324B`, white active nav item, cards with 18 px radius, 12 px inputs, status pills: confirmed blue, arrived yellow, done green, no-show red, walk-in purple).

Rules:
- Section titles never overlap fields: each section is a card with its own header row.
- Working hours are chosen as ranges from a time picker (start → end), never typed as text; a day can have more than one range; empty = closed.
- Holidays are picked from a calendar and shown as removable chips; saving warns about bookings on those days.
- One switch per vaccine for "price shown to guardian"; when off, show «بالسعر في العيادة».
- The save bar is sticky at the bottom and shows unsaved changes; the Save button is never clipped.
- Clinic switcher in the top bar for the doctor; a secretary sees only her clinic (no switcher).
