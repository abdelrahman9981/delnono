# Launch checklist

Items that must be true before the app goes to real families on `dr-elnono-clinic`.

## Demo data gone (after the D-43 client demo)

- [ ] **Wipe the client demo:** `cd functions && npm run seed:demo-prod -- --wipe` (typed confirmation)
      removes every demo family, child, booking, walk-in, package, audit entry, content item and Auth
      account, including anyone who signed in to try the demo ([demo-runbook.md](demo-runbook.md)).
- [ ] Remove the demo test numbers the owner no longer needs from Authentication → Phone (keep the
      ones for store review, D-41/D-52).
- [ ] Staff accounts recreated for the real staff (feature 005), not the demo ones.

## Medical content (Principle II)

- [ ] **No proposed medical content in production.** The researched demo data (vaccines and schedule,
      follow-up milestones, danger signs, tips) is `reviewStatus: "proposed"`. The seed writes it to
      the emulators, and to `dr-elnono-clinic` only for the client demo with `--demo-prod` and a typed
      confirmation (`seed_guard.ts`, tested in `functions/test/lib/seedGuard.test.ts`);
      `functions/test/lib/demoData.test.ts` checks that every item is seeded as proposed with a source.
      Never import `emulator-seed/` into the real project.
- [ ] The doctor approves or removes **every** proposed item in the dashboard: vaccine list and
      schedule («اعتماد»), follow-up lists and danger signs («نشر»), each tip («نشر»). Approving or
      publishing sets `reviewStatus: "approved"` and removes the «مقترح · يراجعه الدكتور» badge. No
      badge may remain at launch.
- [ ] Prices (visit, package, optional vaccines), working hours and holidays set by the clinic.
- [ ] Clinic names, addresses and phone numbers confirmed.

## Legal and accounts

- [ ] Privacy policy and terms approved by the lawyer (D-36, Law 151/2020).
- [ ] Blaze, budget alert and deploys as in [demo-plan.md](demo-plan.md) (with the owner's approval).
