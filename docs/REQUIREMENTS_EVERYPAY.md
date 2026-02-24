---
title: Every-Pay — Product Vision & Requirements
version: 1.0.0
created: 2026-02-24
owner: Product
status: Draft
---

# Every-Pay — Product Requirements Document (PRD)

## 1. Product Vision

**Every-Pay** is a privacy-first, recurring expense tracker designed for individuals and households. It gives users clarity over what they pay for regularly — subscriptions, utilities, insurance, memberships — so they can stay informed, budget confidently, and eliminate forgotten spend.

> "Know every dollar you pay, before you pay it."

---

## 2. Problem Statement

Modern households accumulate dozens of recurring charges across streaming services, utilities, insurances, gym memberships, and SaaS tools. These charges are often scattered across multiple accounts, auto-renewed without review, and difficult to budget for collectively.

**Pain points:**
- Forgotten subscriptions draining bank accounts silently
- No single source of truth for household recurring spend
- Difficulty sharing expense awareness across a household
- Privacy concerns with cloud-synced financial data
- No way to categorise and understand spend patterns over time

---

## 3. Target Users

See `docs/PERSONAS_EVERYPAY.md` for detailed personas.

| Persona | Description |
|---------|-------------|
| **The Household Manager** | Tracks shared expenses for a family or couple; wants visibility across multiple people |
| **The Budget-Conscious Individual** | Single user; wants to audit subscriptions and cut waste |
| **The Privacy-Aware User** | Avoids cloud financial tools; prefers on-device data |
| **The Small Household** | 2–4 people sharing bills/subscriptions; needs sync on same home network |

---

## 4. Core Features

### F1 — Expense Tracking (Core)
Manage a list of recurring expenses with full metadata.

**Data model per expense:**
| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `name` | String | ✅ | Display name |
| `provider` | String | ✅ | Service provider name |
| `category` | Enum/Custom | ✅ | See category list |
| `amount` | Decimal | ✅ | Cost per billing cycle |
| `currency` | String | ✅ | Default: device locale |
| `billing_cycle` | Enum | ✅ | Weekly / Monthly / Quarterly / Yearly / Custom |
| `start_date` | Date | ✅ | When the subscription began |
| `end_date` | Date | ❌ | For fixed-term or cancelled items |
| `next_due_date` | Date | auto | Calculated from start_date + cycle |
| `status` | Enum | ✅ | Active / Paused / Cancelled |
| `notes` | Text | ❌ | Reason, benefits, contract details |
| `tags` | String[] | ❌ | User-defined tags for custom grouping |
| `created_at` | Timestamp | auto | |
| `updated_at` | Timestamp | auto | |

---

### F2 — Pre-defined Service Library
Out-of-the-box service templates to reduce manual entry.

**Bundled service categories (examples):**
- **Streaming**: Netflix, Disney+, Spotify, Apple Music, YouTube Premium, HBO Max, Amazon Prime
- **Utilities**: Electricity, Gas, Water, Internet, Phone Plan
- **Insurance**: Health, Car, Home, Life, Pet
- **Software/Cloud**: iCloud, Google One, Microsoft 365, Dropbox, Adobe CC
- **Finance**: Bank fees, investment platforms
- **Fitness**: Gym membership, Apple Fitness+
- **News/Media**: NYT, Spotify Podcast, newspaper subscriptions

**Template schema:**
```
name, default_category, default_cycle, logo_asset, website_url
```

Users can:
- Select a template and auto-fill fields
- Override any pre-filled value
- Add custom services not in the library
- Request new templates (future roadmap)

---

### F3 — Categories
Group and filter expenses by category for clearer budgeting.

**Default categories:**
- Entertainment & Streaming
- Utilities & Bills
- Insurance
- Software & Cloud
- Health & Fitness
- Finance & Banking
- Food & Groceries
- Education
- Transportation
- Other

**Category rules:**
- Users can create custom categories
- Users can rename default categories
- Each expense belongs to exactly one category
- Category has an optional icon and colour

---

### F4 — Statistics & Analytics
Visual dashboards for understanding spend over time.

**Views:**
| View | Description |
|------|-------------|
| **Monthly Summary** | Total spend this month vs. last month |
| **Yearly Overview** | Month-by-month bar chart for the current year |
| **Weekly Breakdown** | Upcoming 7-day payment schedule |
| **Category Pie Chart** | Proportional breakdown by category |
| **Per-Expense History** | Timeline of payments for a single subscription |
| **Upcoming Payments** | Next 30 days of due dates |

**Key metrics displayed:**
- Monthly total
- Yearly projected total
- Biggest category by spend
- Most expensive single subscription
- Number of active subscriptions
- Average cost per subscription

---

### F5 — Local-Only Database (Privacy-First)
All data is stored exclusively on-device. No cloud, no third-party servers.

**Requirements:**
- SQLite database on device (via `sqflite` or `drift`)
- No data leaves the device unless explicitly exported by the user
- No analytics/telemetry collection
- No account/login required
- Full offline functionality

---

### F6 — Peer-to-Peer Household Sync
Sync data between devices on the same local network (e.g., home Wi-Fi).

**Sync model:**
- Devices discover each other via mDNS/Bonjour on the same network
- Sync is **opt-in** — user must explicitly pair devices
- **End-to-end encrypted** using a shared pairing key (QR code exchange)
- Conflict resolution: last-write-wins with timestamp + device ID tiebreaker
- No central server; all sync is direct device-to-device (TCP/UDP)
- Sync is incremental (delta sync, not full replication each time)

**Pairing flow:**
1. User A opens "Add Device" on Settings
2. App generates a QR code containing pairing key + device info
3. User B scans QR code on their device
4. Devices exchange public keys for encrypted channel
5. Initial full sync runs; future syncs are incremental

**Security requirements:**
- AES-256 encryption for all sync payloads
- Key exchange via ECDH (Elliptic Curve Diffie-Hellman)
- Pairing keys never stored in plaintext
- Device certificate pinning for peer validation
- Sync session token expires after 24h inactivity

**Supported sync scope:**
- All expense records
- Categories (merged, no delete propagation by default)
- User preferences (optional, user-controlled)

---

## 5. Non-Functional Requirements

### Performance
- App launch: < 2 seconds cold start
- Expense list rendering: < 500ms for up to 500 items
- Statistics computation: < 1 second for 5 years of data
- Sync latency: < 3 seconds for delta sync of < 100 changes

### Usability
- Minimum 3 taps to add a new expense from home screen
- All primary actions accessible without scrolling on standard phone screen
- Support Dark Mode and Light Mode
- Accessible: WCAG AA contrast, screen reader support

### Data Integrity
- Atomic writes for all expense mutations
- Automatic local backup before sync operations
- Data export to JSON and CSV

### Security
- Biometric/PIN lock option for app access
- Encrypted database at rest (SQLCipher or equivalent)
- No plaintext sensitive data in logs

### Compatibility
- Android 8.0+ (API level 26+)
- Future: iOS (architecture must support it)

---

## 6. Out of Scope (V1)

- Cloud backup (e.g., Google Drive, iCloud) — *future roadmap*
- Automatic bank/statement import — *future roadmap*
- Payment reminders/notifications — *V2*
- Receipt scanning / OCR — *future*
- Multi-currency conversion — *V2*
- Public API — *future*
- iOS app — *V2 (architecture must be mobile-ready)*
- Web app — *future*

---

## 7. Success Metrics (V1)

| Metric | Target |
|--------|--------|
| App store rating | ≥ 4.2 stars |
| Crash-free sessions | ≥ 99.5% |
| Average expenses tracked per user | ≥ 8 |
| Users who complete device pairing | ≥ 30% of multi-device installs |
| Retention at 30 days | ≥ 50% |
| Time to add first expense | < 2 minutes |

---

## 8. Release Milestones

| Milestone | Features | Status |
|-----------|----------|--------|
| **MVP (V0.1)** | F1 Core, F2 Library, F3 Categories | 🔲 Planned |
| **V0.5** | F4 Statistics, Data export | 🔲 Planned |
| **V1.0** | F5 Local DB hardening, F6 P2P Sync | 🔲 Planned |
| **V1.5** | Notifications, Multi-currency | 🔲 Planned |
| **V2.0** | iOS, Cloud backup (opt-in) | 🔲 Planned |

---

## 9. Related Documents

- `docs/PERSONAS_EVERYPAY.md` — User personas
- `docs/USER_STORIES_EVERYPAY.md` — Full user story backlog
- `docs/REQUIREMENTS_SYNC.md` — Detailed sync protocol requirements
- `docs/REQUIREMENTS_DATA_MODEL.md` — Full data model specification
- `docs/ROADMAP_EVERYPAY.md` — Prioritized feature roadmap
