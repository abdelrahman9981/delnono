# Launch checklist

Items that must be true before the app goes to real families on `dr-elnono-clinic`.

## Medical content (Principle II)

- [ ] **No proposed medical content in production.** The researched demo data (vaccines and schedule,
      follow-up milestones, danger signs, tips) is `reviewStatus: "proposed"` and lives only in the
      emulator seed. `functions/scripts/seed.ts` refuses any project that is not `demo-*` on the
      emulators (`seed_guard.ts`, tested in `functions/test/lib/seedGuard.test.ts`), and
      `functions/test/lib/demoData.test.ts` checks that every item is seeded as proposed with a source.
      Never import `emulator-seed/` into the real project.
- [ ] The doctor reviews and approves each item in the dashboard: vaccine list and schedule
      («اعتماد»), follow-up lists and danger signs («نشر»), each tip («نشر»). Approving or publishing
      sets `reviewStatus: "approved"` and removes the «مقترح · يراجعه الدكتور» badge.
- [ ] Prices (visit, package, optional vaccines), working hours and holidays set by the clinic.
- [ ] Clinic names, addresses and phone numbers confirmed.

## Legal and accounts

- [ ] Privacy policy and terms approved by the lawyer (D-36, Law 151/2020).
- [ ] Blaze, budget alert and deploys as in [demo-plan.md](demo-plan.md) (with the owner's approval).
