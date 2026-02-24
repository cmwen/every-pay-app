---
title: Every-Pay — Product Roadmap
version: 1.0.0
created: 2026-02-24
owner: Product
status: Draft
---

# Every-Pay — Product Roadmap

## Vision
Build the most trusted, privacy-first recurring expense tracker for households — simple enough for anyone, powerful enough for the detail-oriented.

---

## Milestone Overview

```
V0.1 MVP ──► V0.5 Stats ──► V1.0 Sync ──► V1.5 Notifications ──► V2.0 iOS + Cloud
```

---

## V0.1 — MVP: Core Expense Tracking

**Goal:** Prove core value. Users can track all recurring expenses, use the service library, and organise by category.

**Must-Have (M) Stories:**
- US-001 Add expense from library
- US-002 Add custom expense
- US-003 Edit expense
- US-004 Mark expense as cancelled
- US-005 Delete expense
- US-007 Track start and end dates
- US-010 Assign category to expense
- US-012 Filter expense list by category
- US-051 Set default currency

**Should-Have (S) Stories:**
- US-006 Notes and tags
- US-011 Create custom category

**Definition of Done:**
- [ ] App runs on Android 8.0+
- [ ] 30+ service templates available in library
- [ ] All 10 default categories seeded
- [ ] Expense CRUD operations work reliably
- [ ] Data persists across app restarts
- [ ] No crashes on happy path (0 P0 bugs)
- [ ] Flutter analyzer passes with 0 errors

---

## V0.5 — Statistics & Analytics

**Goal:** Help users understand and visualise their spend.

**Must-Have Stories:**
- US-020 Monthly summary view
- US-021 Yearly overview chart
- US-022 Upcoming payments view

**Should-Have Stories:**
- US-023 Per-expense payment history
- US-050 First-launch onboarding
- US-052 Dark mode support

**Could-Have Stories:**
- US-024 Spending insights summary

**Definition of Done:**
- [ ] All chart views render correctly
- [ ] Charts handle edge cases (0 expenses, single expense, 5+ years of data)
- [ ] Onboarding completes without error
- [ ] Dark/light mode both pass visual QA

---

## V1.0 — Privacy Hardening + Household Sync

**Goal:** Production-ready security and multi-device household sync.

**Must-Have Stories:**
- US-030 Pair device for household sync
- US-031 Automatic background sync
- US-033 Manage paired devices
- US-034 Conflict resolution

**Should-Have Stories:**
- US-032 Manual sync trigger
- US-040 Export to CSV
- US-043 App lock with biometrics

**Could-Have Stories:**
- US-041 Export to JSON
- US-042 Import from JSON backup

**Definition of Done:**
- [ ] P2P sync works on same Wi-Fi between 2 Android devices
- [ ] QR pairing flow completes end-to-end
- [ ] Conflicts resolved correctly per spec (REQUIREMENTS_SYNC.md)
- [ ] All data encrypted at rest (SQLCipher)
- [ ] All sync payloads encrypted in transit (TLS + AES-256-GCM)
- [ ] Security review completed
- [ ] No sync causes data loss (regression test suite)

---

## V1.5 — Notifications & Multi-Currency

**Goal:** Proactive alerts and broader currency support.

**Planned Features:**
- Payment due date notifications (1 day, 3 days before)
- Subscription expiry reminders ("ends in 7 days")
- Monthly spend summary notification
- Multi-currency: track expenses in different currencies
- Exchange rate support (device-local, not real-time)
- iOS port (architecture already cross-platform from V1.0)

---

## V2.0 — iOS + Optional Cloud Backup

**Goal:** Full cross-platform support and an opt-in cloud backup for power users.

**Planned Features:**
- iOS app (SwiftUI or Flutter iOS target)
- Optional encrypted cloud backup (user-owned: iCloud / Google Drive)
- Cloud sync across devices (opt-in, user controls the key)
- Shared household "vaults" (named groups of expenses)
- Budget goals per category
- Subscription price change detection (if integrations available)

---

## Backlog (Not Yet Scheduled)

| Feature | Notes |
|---------|-------|
| Receipt/statement import | OCR or CSV bank import |
| Browser extension | Auto-detect subscriptions from emails |
| Widget (home screen) | Upcoming payments at a glance |
| Apple Watch companion | Quick view of monthly total |
| Recurring income tracking | To calculate net monthly position |
| Financial year mode | For tax-year-aligned reporting |
| Shared expense splitting | Track who owes what in household |
| API / webhooks | For power users and integrations |
| WhatsApp/email export | Quick share of monthly report |

---

## Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|-----------|
| P2P sync complexity delays V1.0 | High | High | Keep sync protocol minimal; defer advanced conflict UI |
| iOS port delays V2.0 | Medium | Medium | Flutter cross-platform from day 1; avoid platform-specific APIs |
| Service library goes stale | Low | Medium | Asset-based library + community contribution model planned |
| SQLCipher performance on older devices | Low | Medium | Benchmark on API 26 (Android 8) device |
| mDNS unreliable on some routers | Medium | Medium | Provide manual IP entry fallback |

---

## Related Documents

- `docs/REQUIREMENTS_EVERYPAY.md` — Full PRD
- `docs/USER_STORIES_EVERYPAY.md` — Story backlog
- `docs/REQUIREMENTS_SYNC.md` — Sync protocol
- `docs/REQUIREMENTS_DATA_MODEL.md` — Data model
- `docs/PERSONAS_EVERYPAY.md` — User personas
