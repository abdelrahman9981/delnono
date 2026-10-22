# Design reference — Dr. El Nono (Phase 1, guardian app)

Use these files as the visual source of truth when building Flutter screens.
Match colors, radii, spacing and component shapes; build the layout in Flutter (do not embed HTML).

## Sources

| Source | What it covers | Link / path |
|---|---|---|
| Figma Make prototype | Home, booking, booking success, my bookings, child profile | https://www.figma.com/make/mintJglNIs1vTGfqOAKt56/%D8%AA%D8%B7%D8%A8%D9%8A%D9%82-%D8%AF%D9%83%D8%AA%D9%88%D8%B1-%D8%A7%D9%84%D9%86%D9%88%D9%86%D9%88 |
| Figma screenshots (375 pt wide, 2x) | Home, booking, child profile | `figma/home.jpg`, `figma/booking.jpg`, `figma/child-profile.jpg` |
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
| — | Home, booking, success, my bookings, child profile | Figma link above | 002 / 003 |

## Rules from the constitution that show in the design

- Arabic RTL everywhere; Readex Pro; light and dark (dark variables in `tokens.css` under `.dark` in Figma; keep the same pairs).
- Text sizes: Figma's prototype uses 7–9 px labels, which are too small on a phone. Use the BRD scale: body 13–15, small 11, titles 20–30.
- No automatic medical judgments ("normal", "on track"). Show values and charts only.
- Any medical text (danger signs, follow-up items, video titles) is placeholder in brackets until the doctor approves it from the dashboard.
- Bottom nav: Home, Booking, My child, Content; leave room for the Phase 2 "Ask" tab, but build nothing behind it.
- Doctor photo is a placeholder until the real photo arrives.

## Known issue in Figma

On the home hero card, the photo placeholder's caption overlaps the "موجودين عشان نطمنك" pill. Fix in Flutter: place the caption above the pill or drop it once the real photo is in.
