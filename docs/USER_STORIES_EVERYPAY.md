---
title: Every-Pay — User Story Backlog
version: 1.0.0
created: 2026-02-24
owner: Product
status: Draft
---

# Every-Pay — User Story Backlog

Stories are organised by Epic and prioritised with MoSCoW: **M** = Must Have, **S** = Should Have, **C** = Could Have, **W** = Won't Have (V1).

---

## Epic 1: Expense Management

### US-001 — Add Expense from Library (M)
**As a** user,  
**I want to** select a service from a pre-defined library (e.g., Netflix),  
**so that** I can add it quickly without typing all the details.

**Acceptance Criteria:**
- [ ] A searchable service library is accessible when adding a new expense
- [ ] Selecting a template auto-fills: name, provider, default category, default billing cycle
- [ ] All auto-filled fields are editable before saving
- [ ] Library contains at minimum 30 pre-defined services across 5+ categories
- [ ] User can proceed to add a custom service if it's not in the library

---

### US-002 — Add Custom Expense (M)
**As a** user,  
**I want to** manually enter a recurring expense not in the library,  
**so that** I can track any service or bill.

**Acceptance Criteria:**
- [ ] Form includes: name, provider (optional), category, amount, currency, billing cycle, start date
- [ ] Optional fields: end date, notes, tags
- [ ] Form validates required fields before saving
- [ ] Currency defaults to device locale
- [ ] Billing cycle options: Weekly, Fortnightly, Monthly, Quarterly, Bi-annual, Yearly, Custom (N days)
- [ ] Expense is saved and immediately visible in the list

---

### US-003 — Edit Expense (M)
**As a** user,  
**I want to** edit any field of an existing expense,  
**so that** I can keep records accurate as things change.

**Acceptance Criteria:**
- [ ] All fields from creation are editable
- [ ] Changes are saved immediately
- [ ] Editing an amount does not retroactively change historical stats (future amounts only)
- [ ] `updated_at` timestamp is updated on save

---

### US-004 — Mark Expense as Cancelled (M)
**As a** user,  
**I want to** mark a subscription as cancelled with a cancellation date,  
**so that** I can keep the history while knowing it's no longer active.

**Acceptance Criteria:**
- [ ] Status can be set to: Active, Paused, Cancelled
- [ ] Setting "Cancelled" prompts for cancellation date (defaults to today)
- [ ] Cancelled expenses are hidden from active list by default
- [ ] A toggle allows viewing cancelled expenses
- [ ] Cancelled expenses are excluded from monthly/yearly totals (from cancellation date)

---

### US-005 — Delete Expense (M)
**As a** user,  
**I want to** permanently delete an expense,  
**so that** I can remove test entries or duplicates.

**Acceptance Criteria:**
- [ ] Delete requires a confirmation prompt ("Are you sure?")
- [ ] Deleted items are not recoverable (no recycle bin in V1)
- [ ] Deletion is propagated to synced devices

---

### US-006 — Add Notes and Tags to Expense (S)
**As a** user,  
**I want to** add notes and tags to an expense,  
**so that** I can record context like renewal date, login, or tax status.

**Acceptance Criteria:**
- [ ] Notes field accepts multi-line plain text (no character limit in V1)
- [ ] Tags are free-form, comma-separated strings
- [ ] Tags are filterable from the expense list
- [ ] Notes are visible on the expense detail screen

---

### US-007 — Track Start and End Dates (M)
**As a** user,  
**I want to** record the start and end dates for a subscription,  
**so that** I know when it started and when it will expire.

**Acceptance Criteria:**
- [ ] Start date is required; defaults to today
- [ ] End date is optional
- [ ] Expenses with a past end date display a "Expired" badge
- [ ] Expenses expiring within 30 days display a "Expiring Soon" badge
- [ ] Stats calculations respect active date range

---

## Epic 2: Categories

### US-010 — Assign Category to Expense (M)
**As a** user,  
**I want to** assign a category to each expense,  
**so that** I can group and understand my spending.

**Acceptance Criteria:**
- [ ] Category picker shows default + custom categories
- [ ] Each expense has exactly one category
- [ ] Default categories are pre-populated on first launch
- [ ] Category is required (cannot save without one)

---

### US-011 — Create Custom Category (S)
**As a** user,  
**I want to** create my own expense categories,  
**so that** I can organise expenses to match my personal or business structure.

**Acceptance Criteria:**
- [ ] User can add a new category with: name, icon (from a preset icon list), colour
- [ ] Custom categories appear alongside default categories everywhere
- [ ] Category name must be unique (case-insensitive)

---

### US-012 — Filter Expense List by Category (M)
**As a** user,  
**I want to** filter the expense list by category,  
**so that** I can focus on one type of spending at a time.

**Acceptance Criteria:**
- [ ] Filter chips or dropdown for category selection
- [ ] "All" shows every expense
- [ ] Filter selection persists during the session
- [ ] Active filter is clearly visible

---

## Epic 3: Statistics & Analytics

### US-020 — Monthly Summary View (M)
**As a** user,  
**I want to** see my total recurring spend for the current month,  
**so that** I know what I'm paying this billing cycle.

**Acceptance Criteria:**
- [ ] Shows total for current calendar month
- [ ] Shows comparison vs. previous month (+ or - %)
- [ ] Breaks down total by category in a pie/donut chart
- [ ] Tapping a category segment drills down to that category's expenses
- [ ] Handles pro-rated amounts for expenses that start/end mid-month

---

### US-021 — Yearly Overview (M)
**As a** user,  
**I want to** see a month-by-month chart of my spending for the year,  
**so that** I can understand seasonal patterns.

**Acceptance Criteria:**
- [ ] Bar chart with 12 months on X axis, total spend on Y axis
- [ ] Current month is highlighted
- [ ] Tapping a bar shows monthly breakdown
- [ ] Can navigate between years (previous/next)
- [ ] Projected values for future months shown in a different shade

---

### US-022 — Upcoming Payments View (M)
**As a** user,  
**I want to** see a timeline of upcoming payment due dates,  
**so that** I can plan my cash flow.

**Acceptance Criteria:**
- [ ] Lists next 30 days of due dates by default
- [ ] Grouped by day
- [ ] Shows expense name, amount, and category icon
- [ ] Can extend view to 60 or 90 days
- [ ] Total amount due for the period shown prominently

---

### US-023 — Per-Expense Payment History (S)
**As a** user,  
**I want to** see a history of past payments for a single subscription,  
**so that** I can verify how much I've paid in total.

**Acceptance Criteria:**
- [ ] Accessible from the expense detail screen
- [ ] Shows all calculated payment dates from start_date to today
- [ ] Shows total paid to date
- [ ] Handles paused periods (if expense was paused, those months not counted)

---

### US-024 — Spending Insights Summary (C)
**As a** user,  
**I want to** see key stats at a glance (biggest expense, most expensive category, etc.),  
**so that** I can quickly identify areas to review.

**Acceptance Criteria:**
- [ ] "Insights" card on home screen or stats screen
- [ ] Shows: top expense, top category, total active subscriptions, monthly total
- [ ] Updates in real-time as expenses change

---

## Epic 4: Device Sync

### US-030 — Pair a Device for Household Sync (M)
**As a** user,  
**I want to** pair my phone with another phone on the same Wi-Fi network,  
**so that** our household sees the same expense data.

**Acceptance Criteria:**
- [ ] Pairing initiated via QR code displayed on one device, scanned by the other
- [ ] Both devices must be on the same Wi-Fi network
- [ ] Pairing confirms both devices' display names
- [ ] Initial sync runs immediately after pairing
- [ ] User is shown a success confirmation with sync status

---

### US-031 — Automatic Background Sync (M)
**As a** user,  
**I want to** have changes sync automatically when I'm on the home network,  
**so that** I don't need to manually trigger updates.

**Acceptance Criteria:**
- [ ] Sync triggers automatically when: app opens and peers are on same network
- [ ] Sync triggers when an expense is added/edited/deleted
- [ ] Last sync time displayed in Settings
- [ ] Sync is silent by default; errors surface as a non-intrusive notification
- [ ] Sync does not block the UI

---

### US-032 — Manual Sync Trigger (S)
**As a** user,  
**I want to** manually trigger a sync,  
**so that** I can force an update when I know changes were made.

**Acceptance Criteria:**
- [ ] "Sync Now" button available in Settings > Devices
- [ ] Shows sync progress spinner
- [ ] Shows result: success, conflicts resolved, or error message

---

### US-033 — Manage Paired Devices (M)
**As a** user,  
**I want to** see and remove paired devices,  
**so that** I can control who has access to my expense data.

**Acceptance Criteria:**
- [ ] Settings screen shows list of paired devices with: device name, last sync time
- [ ] User can remove/unpair a device
- [ ] Removing a device does not delete data from either device
- [ ] Removed device can no longer sync until re-paired

---

### US-034 — Conflict Resolution (M)
**As a** system,  
**I want to** resolve conflicting changes when two devices edit the same expense,  
**so that** data remains consistent without data loss.

**Acceptance Criteria:**
- [ ] Last-write-wins based on `updated_at` timestamp
- [ ] Device ID used as tiebreaker for same-timestamp conflicts
- [ ] No silent data loss — conflicting changes logged internally
- [ ] User is not required to manually resolve conflicts in V1

---

## Epic 5: Data & Privacy

### US-040 — Export Data to CSV (S)
**As a** user,  
**I want to** export my expense data as a CSV,  
**so that** I can use it in spreadsheets or share with an accountant.

**Acceptance Criteria:**
- [ ] Export available from Settings > Data
- [ ] CSV includes all fields: name, provider, category, amount, cycle, start, end, status, notes, tags
- [ ] User can choose to export: all expenses / active only / by category
- [ ] File is saved to device Downloads folder with filename `everypay_export_YYYY-MM-DD.csv`

---

### US-041 — Export Data to JSON (C)
**As a** user,  
**I want to** export my data as JSON,  
**so that** I can back it up or migrate it.

**Acceptance Criteria:**
- [ ] JSON export mirrors the full data model
- [ ] Exported file is importable back into Every-Pay (round-trip safe)

---

### US-042 — Import Data from JSON Backup (C)
**As a** user,  
**I want to** import a previously exported JSON backup,  
**so that** I can restore my data on a new device.

**Acceptance Criteria:**
- [ ] Import prompts for JSON file
- [ ] Import merges data (no duplicates based on ID)
- [ ] Import previews what will change before applying
- [ ] Import errors are surfaced clearly

---

### US-043 — App Lock with Biometrics (S)
**As a** user,  
**I want to** lock the app with my fingerprint or face,  
**so that** my expense data is private on shared devices.

**Acceptance Criteria:**
- [ ] Biometric lock is opt-in (Settings > Security)
- [ ] Falls back to device PIN/password if biometrics unavailable
- [ ] App locks when sent to background (configurable: immediately / after 1 min / after 5 min)
- [ ] Lock screen does not reveal any expense data

---

## Epic 6: Onboarding & Settings

### US-050 — First Launch Onboarding (S)
**As a** new user,  
**I want to** be guided through setting up my first expenses,  
**so that** I can get value from the app immediately.

**Acceptance Criteria:**
- [ ] 3-screen onboarding walkthrough on first launch
- [ ] Suggests adding first expense from the library
- [ ] Skippable at any point
- [ ] Does not repeat on subsequent launches

---

### US-051 — Set Default Currency (M)
**As a** user,  
**I want to** set my default currency,  
**so that** new expenses are pre-filled with my currency.

**Acceptance Criteria:**
- [ ] Default currency set during onboarding and editable in Settings
- [ ] Supports all ISO 4217 currency codes
- [ ] Currency symbol displayed on all amounts

---

### US-052 — Dark Mode Support (S)
**As a** user,  
**I want to** use the app in dark mode,  
**so that** it matches my phone theme and is easier on the eyes at night.

**Acceptance Criteria:**
- [ ] Follows system dark/light mode by default
- [ ] Manual override available in Settings > Appearance
- [ ] All screens and charts are readable in both modes

---

## Story Point Summary

| Epic | Stories | Priority M | Priority S | Priority C |
|------|---------|-----------|-----------|-----------|
| Expense Management | 7 | 5 | 1 | 1 |
| Categories | 3 | 2 | 1 | 0 |
| Statistics | 5 | 3 | 1 | 1 |
| Device Sync | 5 | 4 | 1 | 0 |
| Data & Privacy | 4 | 0 | 2 | 2 |
| Onboarding & Settings | 3 | 1 | 2 | 0 |
| **Total** | **27** | **15** | **8** | **4** |
