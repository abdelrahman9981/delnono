# Contract: App Routes and Guard (001)

## Shell

Bottom navigation, right to left: Home (`/`), Booking (`/booking`), My Child (`/children`),
Content (`/content`), and an empty reserved slot for the Phase 2 "Ask" tab (no route, no screen,
Principle V). In 001, Booking and Content show placeholder screens marked as such; 002 and 005
replace them.

## Routes

| Route | Access | Screen |
|-------|--------|--------|
| `/welcome` | public | Welcome (design screen 1): register with mobile, or browse content first. Shown on launch while not signed in; "browse" goes to `/content` |
| `/` | public | Home (placeholder content; Figma home is built in 002/003) |
| `/content` | public | Content placeholder |
| `/sign-in` | public | Phone entry |
| `/sign-in/code` | public | Code entry, countdown, resend |
| `/register/guardian` | signed in, no guardian doc | Guardian details |
| `/register/consent` | signed in, no guardian doc, or consent outdated | Policy, terms, consent |
| `/register/link` | registered, clinic children pending | Birth-date check |
| `/register/child` | registered, no children | First child |
| `/booking` | protected | Booking placeholder |
| `/children` | protected | Children list |
| `/children/add` | protected | Add child |
| `/children/:id` | protected | Child profile (edit name and allergies) |
| `/account` | protected | Account (design screen 11): guardian, children, policy version, phone change, Notifications placeholder (007), WhatsApp support link (external, from `settings/clinic.whatsappNumber`), sign out, delete |
| `/account/phone` | protected | Change number (new number + code) |
| `/account/delete` | protected | Deletion explanation and confirmation |

## Guard (go_router `redirect`)

Evaluated in this order for protected routes:

1. Not signed in → `/sign-in?from=<requested location>`.
2. Signed in, no guardian doc → `/register/guardian?from=…`.
3. Guardian consent outdated → `/register/consent?from=…`.
4. `guardians/{uid}.clinicChildrenPending` is true and not skipped this session ("these aren't my children", spec US4 scenario 4) → `/register/link?from=…`.
5. No children and route is not `/children/add` → `/register/child?from=…` (first run only).
6. Otherwise allow. After each step completes, navigate to `from` (FR-003), defaulting to `/`.

`from` accepts only internal paths starting with `/`.
