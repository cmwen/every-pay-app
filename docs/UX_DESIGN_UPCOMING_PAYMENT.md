---
title: Every-Pay — UX Design: Due/Upcoming View & Payment Methods
version: 1.0.0
created: 2026-02-24
owner: UX Designer
status: Final
references:
  - docs/UX_DESIGN_EVERYPAY.md
  - docs/REQUIREMENTS_DATA_MODEL.md
  - docs/PERSONAS_EVERYPAY.md
  - lib/features/home/screens/home_screen.dart
  - lib/features/home/widgets/filter_chips.dart
  - lib/features/home/providers/expense_list_provider.dart
  - lib/features/expense/screens/expense_detail_screen.dart
  - lib/features/settings/screens/settings_screen.dart
  - lib/router.dart
---

# Every-Pay — UX Design: Due/Upcoming View & Payment Methods

---

## Overview

This document covers the UX design for two new features:

1. **Feature 1 — Due/Upcoming View**: A glanceable "what's due soon" preview on the
   Home screen with a full upcoming-payments screen supporting 7-day and 30-day views,
   date-grouped listings, and per-item urgency signalling.

2. **Feature 2 — Payment Methods**: An optional payment method entity users can create
   and assign to expenses, with management under Settings, assignment in the expense form,
   display on expense cards and detail screens, and filtering on the Home screen.

Both features are designed to be consistent with the existing Material Design 3 system,
respect the established 3-tap rule, and extend (not replace) existing patterns in the app.

---

## Table of Contents

1. [Design Context & Principles](#1-design-context--principles)
2. [Feature 1: Due/Upcoming View](#2-feature-1-dueupcoming-view)
   - 2.1 Surfacing Strategy
   - 2.2 Home Screen: "Due Soon" Preview Section
   - 2.3 Upcoming Payments Screen (`/upcoming`)
   - 2.4 Stats > Upcoming Tab Enhancement
   - 2.5 Empty States
   - 2.6 Urgency System
   - 2.7 User Flows
3. [Feature 2: Payment Methods](#3-feature-2-payment-methods)
   - 3.1 PaymentMethod Data Model
   - 3.2 Settings — Payment Methods List Screen
   - 3.3 Create / Edit Payment Method Screen
   - 3.4 Assigning a Payment Method in the Expense Form
   - 3.5 Expense List Item — Payment Method Display
   - 3.6 Expense Detail Screen — Payment Method Row
   - 3.7 Filtering by Payment Method on Home
   - 3.8 Empty States
   - 3.9 User Flows
4. [Navigation & Routing Changes](#4-navigation--routing-changes)
5. [Data Model Changes](#5-data-model-changes)
6. [Accessibility Notes](#6-accessibility-notes)
7. [Animation & Micro-interaction Specs](#7-animation--micro-interaction-specs)
8. [Cross-Platform Considerations](#8-cross-platform-considerations)
9. [Component Inventory](#9-component-inventory)

---

## 1. Design Context & Principles

### Existing App Summary (as-built)

| Element | Current State |
|---------|--------------|
| Navigation | Bottom nav: Home / Stats / Settings |
| Home screen | Summary card → FilterChips (category) → expense list → FAB |
| Stats screen | TabBar: Monthly / Yearly / Upcoming (30-day) |
| Filter model | `ExpenseFilter { categoryId, status, searchQuery }` |
| Expense list item | 3 lines: name+amount / category·cycle / due-in-X-days |
| Settings | General, Organisation (Categories), Data, Security, Sync, About |

### Design Principles Observed (from existing spec)

- **Clarity over cleverness** — every screen answers one question
- **3-tap rule** — any primary action within 3 taps of Home
- **Glanceable** — key numbers visible without scrolling
- **Forgiving** — smart defaults, undo over confirmation dialogs
- **Inclusive** — WCAG AA contrast, 48dp touch targets, screen reader labels

### Personas Most Affected by These Features

| Persona | Feature 1 Priority | Feature 2 Priority |
|---------|-------------------|-------------------|
| Maya (Household Manager) | ★★★★★ Needs weekly bill alerts | ★★★★☆ Tracks which card pays what |
| Kenji (Budget-Conscious) | ★★★★★ Trial-end tracking critical | ★★★☆☆ Prefers simplicity |
| Barbara & Tom (Retired) | ★★★★★ "What do we pay this week?" | ★★☆☆☆ Optional complexity |
| Priya (Small Business) | ★★★★☆ Monthly SaaS planning | ★★★★★ Business card vs personal |

---

## 2. Feature 1: Due/Upcoming View

### 2.1 Surfacing Strategy

#### The Problem with the Current State

The Stats > Upcoming tab (`_UpcomingTab`) already exists as a 30-day listing. However,
it has two structural problems for the "what do I pay this week?" use case:

1. **Wrong mental model**: Users navigate to "Stats" for analysis, not for action.
   When Barbara wants to know "what bills are coming up?", she looks at Home, not Stats.
2. **No week view**: The existing tab only shows 30 days. A 7-day view is essential
   for the week-to-week planning that all four personas perform.

#### Design Decision: Dual-Surface Approach

Rather than choosing between a new tab or a home section, we use **both**:

| Surface | Purpose | Tap Count from Home |
|---------|---------|-------------------|
| **"Due Soon" preview section** on Home | Glanceable alert; 3 items max; always visible when due items exist | 0 taps (inline) |
| **Full Upcoming Payments screen** (`/upcoming`) | Full week/month view with date grouping and totals | 1 tap from "See all" |
| **Stats > Upcoming tab** (enhanced) | Analytics context; now navigates to `/upcoming` or embeds the same view | 2 taps |

This satisfies the **3-tap rule** (the full view is 1 tap from Home) while keeping the
Home screen glanceable. The existing Stats tab continues to serve its role, now enriched.

#### When the Due Soon Section is Visible

| Condition | Section Behaviour |
|-----------|------------------|
| 1+ items due in next 7 days | Shown; up to 3 items listed |
| 0 items in 7 days, 1+ in next 30 days | Shown as collapsed hint: "Nothing due this week — N due this month →" |
| 0 items due at all (e.g. all paused/cancelled) | Hidden entirely — no empty card cluttering home |
| Home list is empty (no expenses) | Hidden |

---

### 2.2 Home Screen: "Due Soon" Preview Section

The Due Soon section is inserted **between the Summary Card and the FilterChips row**.
It is a non-scrolling inline component, not a navigable section header.

#### Layout

```
┌─────────────────────────────────────────┐
│  Every-Pay                    🔍  ⋮     │  ← AppBar (unchanged)
├─────────────────────────────────────────┤
│                                         │
│  ┌─────────────────────────────────┐    │
│  │  This Month           $247.94  │    │  ← SummaryCard (unchanged)
│  │  ▲ 3.2% vs last month         │    │
│  │  12 active subscriptions       │    │
│  └─────────────────────────────────┘    │
│                                         │
│  ┌─────────────────────────────────┐    │  ← DueSoonSection (NEW)
│  │  📅 Due Soon        See all →  │    │  ← Header row (16dp padding)
│  │  ─────────────────────────────  │    │
│  │  🔴  Netflix         $15.49    │    │  ← Item (no tap nav — row acts
│  │      Due tomorrow              │    │      as visual only; full detail
│  │  ─────────────────────────────  │    │      via tapping "See all")
│  │  ☁   iCloud+          $2.99   │    │
│  │      Due in 3 days             │    │
│  │  ─────────────────────────────  │    │
│  │  ⚡  Electricity      $89.00   │    │
│  │      Due in 7 days             │    │
│  └─────────────────────────────────┘    │
│                                         │
│  [All]  [Entertainment]  [Software] ↔  │  ← FilterChips (unchanged)
│                                         │
│  ┌─────────────────────────────────┐    │
│  │ [expense list...]               │    │  ← ExpenseList (unchanged)
│  └─────────────────────────────────┘    │
│                                    [+]  │
├─────────────────────────────────────────┤
│  🏠 Home    📊 Stats    ⚙️ Settings     │
└─────────────────────────────────────────┘
```

#### DueSoonSection Widget Spec

**Component**: `DueSoonSection` (new widget in `lib/features/home/widgets/`)

**Card styling**:
- `Card` with `elevation: 0` and `color: colorScheme.surfaceContainerLow`
- `BorderRadius.circular(12)` (consistent with SummaryCard)
- Horizontal margin: 16dp (matches screen padding)
- Vertical margin: 0dp top (8dp below SummaryCard), 8dp bottom

**Header row** (inside card, 16dp padding):
- Left: `Icon(Icons.calendar_today_outlined, size: 18)` + `Text("Due Soon", style: titleSmall, fontWeight: w600)`
- Right: `TextButton("See all →")` navigates to `/upcoming`
- Row height: 44dp

**Item row** (12dp horizontal padding, 8dp vertical):
- Leading: `CircleAvatar(r=16)` with category icon (20dp, category color, matching ExpenseListItem style)
- Title: expense name (`bodyMedium, w500`)
- Trailing amount: `amount.formatCurrency(currency)` (`bodyMedium, w600`)
- Subtitle: urgency-colored date label (see §2.6)
- Divider between items: `Divider(height: 1, indent: 44)` (indented to align with text)
- **Each item is tappable** → navigates to `/expense/:id` (same as main list)

**"Nothing due this week" collapsed variant**:
```
┌─────────────────────────────────────────┐
│  📅 Due Soon         See all →          │
│  ─────────────────────────────────────  │
│  ✓ Nothing due this week               │
│    2 payments due this month            │
└─────────────────────────────────────────┘
```
- Uses `Icons.check_circle_outline` in `colorScheme.secondary`
- "2 payments due this month" in `bodySmall, onSurfaceVariant`
- Entire section still tappable via "See all"

**Maximum items shown**: 3 (items beyond 3 are indicated by "See all →" count):
e.g., "See all (5) →" when more than 3 items exist in the 7-day window.

---

### 2.3 Upcoming Payments Screen (`/upcoming`)

This is a new, full-screen destination accessible from the Due Soon section on Home
and from the Stats > Upcoming tab.

```
┌─────────────────────────────────────────┐
│  ←  Upcoming Payments                  │  ← AppBar, back to home
├─────────────────────────────────────────┤
│                                         │
│  ┌───────────────────────────────────┐  │
│  │  [   This Week   ] [ This Month ] │  │  ← SegmentedButton toggle
│  └───────────────────────────────────┘  │    (16dp h-padding, 8dp v-margin)
│                                         │
│  ┌───────────────────────────────────┐  │  ← Period Summary Card
│  │  3 payments due in next 7 days    │  │
│  │         $107.47                   │  │  ← Total: headlineMedium, primary
│  └───────────────────────────────────┘  │
│                                         │
│  ── TODAY, Mon Mar 14 ──────────────    │  ← Date group header
│                                         │
│  (empty — nothing due today)            │
│                                         │
│  ── TOMORROW, Tue Mar 15 ───────────    │
│                                         │
│  ┌───────────────────────────────────┐  │
│  │ 🔴  Netflix              $15.49  │  │  ← UpcomingListItem
│  │     Entertainment · Monthly      │  │
│  │     [🔴 Tomorrow] [💳 ••4242]    │  │  ← Urgency chip + PM chip
│  └───────────────────────────────────┘  │
│                                         │
│  ── Wed Mar 18 ─────────────────────    │
│                                         │
│  ┌───────────────────────────────────┐  │
│  │ ☁   iCloud+               $2.99  │  │
│  │     Software · Monthly           │  │
│  │     [🟡 In 4 days]               │  │
│  └───────────────────────────────────┘  │
│                                         │
│  ── Sun Mar 21 ─────────────────────    │
│                                         │
│  ┌───────────────────────────────────┐  │
│  │ ⚡  Electricity          $89.00  │  │
│  │     Utilities · Monthly          │  │
│  │     [⚪ In 7 days] [🏦 Direct Debit ANZ] │
│  └───────────────────────────────────┘  │
│                                         │
└─────────────────────────────────────────┘
```

#### Toggle Behaviour

| Toggle State | Time window | Label on summary card |
|-------------|------------|----------------------|
| "This Week"  | Next 7 days from today (inclusive of today) | "N payments due in next 7 days" |
| "This Month" | Next 30 days from today | "N payments due in next 30 days" |

- Toggle state is persisted in-memory for the session (not in preferences)
- Default: "This Week" (most immediately actionable)
- Switching toggle animates the list with a cross-fade (200ms)

#### Date Group Headers

Date groups use `titleSmall, w600, primary` colour, left-aligned, above each group.

| Date | Display Format |
|------|---------------|
| Today | `TODAY, Mon Mar 14` |
| Tomorrow | `TOMORROW, Tue Mar 15` |
| Within 7 days | `Wed Mar 18` |
| Beyond 7 days (month view) | `Fri Mar 29` |

Empty today/tomorrow groups are **skipped entirely** (no "nothing today" placeholder —
this reduces cognitive load and scrolling distance).

#### UpcomingListItem Widget Spec

**Component**: `UpcomingListItem` (new widget, reuses `ExpenseListItem` as base)

Structure (three-line ListTile):
- **Leading**: `CircleAvatar(r=20)` with category icon — same as ExpenseListItem
- **Title**: expense name (`bodyLarge, w500`) — amount on trailing (`titleMedium, w600`)
- **Subtitle line 1**: `category.name · billingCycle.displayName` (`bodySmall, onSurfaceVariant`)
- **Subtitle line 2**: Row of chips:
  - **Urgency chip** (always present): color-coded, see §2.6
  - **Payment method chip** (if assigned): `💳 ••4242` or `🏦 Direct Debit`, `outlinedChip` style

Chip style for subtitle chips:
- Height: 20dp
- Font: `labelSmall` (11sp, medium weight)
- Horizontal padding: 8dp
- Shape: `StadiumBorder`
- Urgency chip uses filled background; PM chip uses outlined border

**Tap behaviour**: navigates to `/expense/:id`

---

### 2.4 Stats > Upcoming Tab Enhancement

The existing `_UpcomingTab` in `stats_screen.dart` is enhanced to:
1. Add the 7-day / 30-day `SegmentedButton` toggle (same as the standalone screen)
2. Reuse `UpcomingListItem` widget (no duplication)
3. Show the period total card at the top
4. Optionally: add a `TextButton("Open in full view →")` linking to `/upcoming` for
   users who want the standalone screen with back-navigation

This means the Stats > Upcoming tab and the `/upcoming` screen share the same
underlying content, but the Stats tab lives within the tabbed Stats chrome while
`/upcoming` is a full-screen push from Home. Both show the same data.

---

### 2.5 Empty States

#### Empty: No expenses due this week (full screen — "This Week" toggle)

```
┌───────────────────────────────────────────┐
│                                           │
│              🎊                           │
│                                           │
│      Nothing due this week!               │  ← titleMedium
│                                           │
│  Your next 7 days are expense-free.       │  ← bodyMedium, onSurfaceVariant
│  Tap "This Month" to see what's ahead.   │
│                                           │
│          [ View This Month ]              │  ← FilledTonalButton
│                                           │
└───────────────────────────────────────────┘
```

#### Empty: No expenses due this month (full screen — "This Month" toggle)

```
┌───────────────────────────────────────────┐
│                                           │
│              ✅                           │
│                                           │
│     All clear for the next 30 days!       │
│                                           │
│  No recurring expenses are due            │
│  in the coming month.                     │
│                                           │
└───────────────────────────────────────────┘
```

#### Empty: No active expenses at all

```
┌───────────────────────────────────────────┐
│                                           │
│              📋                           │
│                                           │
│     No active expenses tracked.           │
│                                           │
│  Add your first expense to start          │
│  tracking upcoming payments.              │
│                                           │
│          [ + Add Expense ]                │  ← FilledButton, navigates to /expense/add
│                                           │
└───────────────────────────────────────────┘
```

---

### 2.6 Urgency System

Every upcoming item carries a visual urgency signal on the `UpcomingListItem` and in
the Due Soon preview on Home. This helps Barbara and Tom immediately understand
what needs attention without reading dates.

#### Urgency Chip Spec

| Days Until Due | Chip Label | Chip Colour | Icon |
|---------------|-----------|------------|------|
| 0 (today) | `Today` | `error` (red) | `●` filled |
| 1 (tomorrow) | `Tomorrow` | `errorContainer` / orange | `!` |
| 2–3 days | `In N days` | `tertiaryContainer` / amber | none |
| 4–7 days | `In N days` | `surfaceContainerHighest` / neutral | none |
| 8–30 days (month view only) | `MMM dd` (date only) | none / neutral label | none |

The urgency chip background uses `withAlpha(40)` for the filled style, with the full
colour for the label text, meeting WCAG AA contrast ratios.

#### Due Soon Section on Home — Urgency Signal

In the Due Soon section, urgency is shown as a **coloured subtitle** (not a chip, to
conserve space):
- "Due today" → `error` colour text, `w600`
- "Due tomorrow" → `tertiary` / orange colour text
- "Due in N days" → `onSurfaceVariant` standard text

---

### 2.7 User Flows — Feature 1

#### Flow A: Glance at upcoming from Home (0 taps)

```
Open app → Home screen
  → "Due Soon" section visible below summary card
  → User sees: Netflix due tomorrow, Electricity due in 7 days
  → No action required — goal achieved
```

**Taps**: 0 (instant awareness on app open)

#### Flow B: View full upcoming week (1 tap from Home)

```
Home → Tap "See all →" in Due Soon section
  → Upcoming Payments screen opens (push route)
  → Default view: "This Week" toggle selected
  → User sees date-grouped list with urgency chips
  → Tap individual item → Expense Detail screen
```

**Taps**: 1 to reach full view, 2 to reach individual expense detail

#### Flow C: Switch to monthly view (2 taps from Home)

```
Home → Tap "See all →"
  → Upcoming Payments screen
  → Tap "This Month" toggle
  → 30-day grouped list animates in
```

**Taps**: 2

#### Flow D: Navigate from Stats (2 taps)

```
Tap "Stats" bottom nav → Tap "Upcoming" tab
  → Enhanced Upcoming tab with 7/30-day toggle
```

**Taps**: 2

---

## 3. Feature 2: Payment Methods

### 3.1 PaymentMethod Data Model

#### Entity Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | `TEXT` (UUID v4) | ✓ | Primary key |
| `name` | `TEXT` | ✓ | User-defined display name, e.g. "ANZ Visa Credit", "PayPal Personal" |
| `type` | `TEXT` (enum) | ✓ | See type enum below |
| `last4Digits` | `TEXT` (4 chars) | ✗ | Last 4 digits of card number; only relevant for `credit_card` / `debit_card` types |
| `bankName` | `TEXT` | ✗ | Institution name, e.g. "ANZ", "CommBank", "PayPal"; shown as secondary label |
| `colourHex` | `TEXT` | ✓ | User-chosen display colour (`#RRGGBB`); defaults per type (see below) |
| `isDefault` | `INTEGER` (0/1) | ✓ | One payment method may be marked default; auto-selected in expense form |
| `sortOrder` | `INTEGER` | ✓ | Controls display order in lists; user-reorderable via long-press drag |
| `notes` | `TEXT` | ✗ | Free-form, e.g. "Used for all streaming subscriptions" |
| `createdAt` | `TEXT` (ISO 8601) | ✓ | Creation timestamp |
| `updatedAt` | `TEXT` (ISO 8601) | ✓ | Last modification timestamp |
| `deviceId` | `TEXT` | ✓ | Origin device UUID (for sync) |
| `isDeleted` | `INTEGER` (0/1) | ✓ | Soft-delete flag (for sync conflict resolution) |

#### Type Enum

| Value | Display Name | Material Icon | Default Colour |
|-------|-------------|--------------|---------------|
| `credit_card` | Credit Card | `credit_card` | `#1565C0` (Blue 800) |
| `debit_card` | Debit Card | `payment` | `#00897B` (Teal 600) |
| `direct_debit` | Direct Debit | `account_balance` | `#5E35B1` (Deep Purple 600) |
| `bank_transfer` | Bank Transfer | `swap_horiz` | `#2E7D32` (Green 800) |
| `paypal` | PayPal | `account_balance_wallet` | `#0070BA` (PayPal Blue) |
| `apple_pay` | Apple Pay | `phone_iphone` | `#1C1C1E` (near-black) |
| `google_pay` | Google Pay | `smartphone` | `#4285F4` (Google Blue) |
| `cash` | Cash | `payments` | `#558B2F` (Light Green 800) |
| `other` | Other | `wallet` | `#546E7A` (Blue Grey 600) |

#### Display Name Format

The `name` field is user-defined and is the primary display label. For list items,
the **secondary label** is derived as:
- If `last4Digits` present: `••${last4Digits}` (e.g., `••4242`)
- If `bankName` present (without last4): `bankName`
- If neither: show `type.displayName` as secondary
- Full combo: `"ANZ Visa Credit"` (name) + `"••4242"` (secondary pill)

#### SQL Schema Addition

```sql
CREATE TABLE payment_methods (
  id              TEXT PRIMARY KEY,
  name            TEXT NOT NULL,
  type            TEXT NOT NULL,
  last4_digits    TEXT,
  bank_name       TEXT,
  colour_hex      TEXT NOT NULL DEFAULT '#1565C0',
  is_default      INTEGER NOT NULL DEFAULT 0,
  sort_order      INTEGER NOT NULL DEFAULT 0,
  notes           TEXT,
  created_at      TEXT NOT NULL,
  updated_at      TEXT NOT NULL,
  device_id       TEXT NOT NULL,
  is_deleted      INTEGER NOT NULL DEFAULT 0
);

-- Add to existing expenses table (migration):
ALTER TABLE expenses ADD COLUMN payment_method_id TEXT REFERENCES payment_methods(id);
```

---

### 3.2 Settings — Payment Methods List Screen

**Route**: `/settings/payment-methods`
**Access**: Settings screen → ORGANISATION section → "Payment Methods" tile

#### Settings Screen Update

Add a new tile in the ORGANISATION section immediately after the existing "Categories"
tile. The section now reads:

```
ORGANISATION
┌─────────────────────────────────────────┐
│ 🏷  Categories                    10  ▶ │  ← existing
│ 💳  Payment Methods                3  ▶ │  ← NEW tile
└─────────────────────────────────────────┘
```

The badge count shows the number of non-deleted payment methods (0 shown as blank, not
as a number, to avoid appearing broken before first use).

#### Payment Methods List Screen Layout

```
┌─────────────────────────────────────────┐
│  ←  Payment Methods               [+]   │  ← AppBar; [+] = IconButton(Icons.add)
├─────────────────────────────────────────┤
│                                         │
│  CARDS                                  │  ← Section header (labelSmall, primary, tracking 1.2)
│  ┌─────────────────────────────────┐    │
│  │  ■ Visa Credit Card       ⭐  ▶│    │  ← ■ = coloured square avatar
│  │    ANZ · ••4242               │    │  ← secondary: bankName · ••last4
│  ├─────────────────────────────────┤    │
│  │  ■ Debit Mastercard          ▶│    │
│  │    CommBank · ••8801          │    │
│  └─────────────────────────────────┘    │
│                                         │
│  DIGITAL WALLETS                        │
│  ┌─────────────────────────────────┐    │
│  │  ■ PayPal Personal           ▶│    │
│  │    PayPal                     │    │
│  └─────────────────────────────────┘    │
│                                         │
│  OTHER                                  │
│  ┌─────────────────────────────────┐    │
│  │  ■ Direct Debit - ANZ        ▶│    │
│  │    ANZ                        │    │
│  └─────────────────────────────────┘    │
│                                         │
│  ─────────────────────────────────      │
│                                         │
│       [ + Add Payment Method ]          │  ← OutlinedButton, centred
│                                         │
└─────────────────────────────────────────┘
```

#### Grouping Logic

Payment methods are grouped by type family:

| Group Heading | Types Included |
|--------------|---------------|
| CARDS | `credit_card`, `debit_card` |
| DIGITAL WALLETS | `paypal`, `apple_pay`, `google_pay` |
| BANK ACCOUNTS | `direct_debit`, `bank_transfer` |
| OTHER | `cash`, `other` |

Groups with zero items are hidden entirely.

#### List Item Widget Spec

**Leading**: Rounded square avatar (32×32dp, `BorderRadius.circular(6)`)
- Background: `colourHex` colour at full opacity
- Icon: type-mapped Material icon, 18dp, `Colors.white`

**Title**: `name` field (`bodyLarge, w500`)

**Subtitle**: derived secondary label (`bodySmall, onSurfaceVariant`)

**Trailing row** (right-aligned, vertical center):
- If `isDefault`: `Icon(Icons.star_rounded, size: 16, color: tertiary)` — default badge
- `Icon(Icons.chevron_right, color: onSurfaceVariant)` — navigation indicator

**Height**: minimum 72dp (two-line ListTile)

**Interactions**:
- Tap → navigates to Edit Payment Method screen (`/settings/payment-methods/:id/edit`)
- Swipe left → delete action (red background, `Icons.delete`, label "Delete")
  - On swipe complete: shows `SnackBar("Payment Method deleted. [Undo]")` (4s)
  - Undo restores the method and re-inserts at original position
  - If method is assigned to any expense: confirmation dialog first:
    `"This payment method is assigned to N expense(s). Removing it will clear those assignments. Continue?"`
- Long-press → enters reorder mode (shows drag handles `Icons.drag_handle` on trailing;
  drag to reorder updates `sortOrder`)

#### AppBar `[+]` Button

Navigates to `/settings/payment-methods/add` (create new payment method).

---

### 3.3 Create / Edit Payment Method Screen

**Routes**:
- Create: `/settings/payment-methods/add`
- Edit: `/settings/payment-methods/:id/edit`

#### Screen Layout

```
┌─────────────────────────────────────────┐
│  ←  Add Payment Method                 │  (or "Edit Payment Method")
├─────────────────────────────────────────┤
│                                         │
│  ┌─────────────────────────────────┐    │
│  │  Preview                        │    │  ← Live preview card (updates as user types)
│  │  ┌──────────────────────────┐   │    │
│  │  │  ■  ANZ Visa Credit      │   │    │  ← coloured icon + name
│  │  │     ••4242               │   │    │  ← last4 or bankName
│  │  └──────────────────────────┘   │    │
│  └─────────────────────────────────┘    │
│                                         │
│  Type *                                 │
│  ┌─────────────────────────────────┐    │
│  │  💳  Credit Card            ▼  │    │  ← DropdownButtonFormField
│  └─────────────────────────────────┘    │
│                                         │
│  Name *                                 │
│  ┌─────────────────────────────────┐    │
│  │  ANZ Visa Credit               │    │  ← TextFormField
│  └─────────────────────────────────┘    │
│  * Changes as user edits Type/Bank      │  ← Helper text (subtle, bodySmall)
│                                         │
│  Bank / Provider  (optional)            │
│  ┌─────────────────────────────────┐    │
│  │  e.g. ANZ, CommBank, PayPal    │    │
│  └─────────────────────────────────┘    │
│                                         │
│  Last 4 Digits  (optional)             │  ← Only shown when type = credit_card
│  ┌─────────────────────────────────┐    │    or debit_card; hidden otherwise
│  │  4242                          │    │
│  └─────────────────────────────────┘    │
│  Keyboard: numeric; max 4 characters   │
│                                         │
│  Colour                                 │
│  ┌─────────────────────────────────┐    │  ← 8 coloured circle swatches
│  │  ●  ●  ●  ●  ●  ●  ●  ●       │    │    (40dp tap target each)
│  └─────────────────────────────────┘    │    Selected swatch has check overlay
│                                         │    Default: type's default colour
│  Set as default payment method          │
│  ─────────────────────────  [  ◯  ]   │  ← Switch
│  Expenses with no payment method        │
│  assigned will suggest this one first.  │  ← Helper text (only when switching ON)
│                                         │
│  Notes  (optional)                      │
│  ┌─────────────────────────────────┐    │
│  │  e.g. Family card, used for    │    │  ← Multiline TextFormField, maxLines: 3
│  │  streaming subscriptions       │    │
│  └─────────────────────────────────┘    │
│                                         │
│       [ Save Payment Method ]           │  ← FilledButton, full-width
│                                         │
│  ── (Edit mode only) ──────────────     │
│       [ Delete Payment Method ]         │  ← TextButton, error colour
│                                         │
└─────────────────────────────────────────┘
```

#### Form Behaviour

**Type field**:
- Dropdown options listed in the order defined in §3.1 type enum table
- Each option shows: icon (16dp) + display name
- Changing type: (a) updates the preview avatar icon, (b) resets colour to type default,
  (c) hides/shows Last 4 Digits field, (d) provides auto-suggested name if Name is still empty

**Auto-suggested name** (assistive, not forced):
If the Name field is empty when the user selects a type or enters a bank name,
the field is auto-populated with a smart suggestion:
- `credit_card` + bank "ANZ" → suggests "ANZ Credit Card"
- `direct_debit` + bank "CommBank" → suggests "CommBank Direct Debit"
- `paypal` → suggests "PayPal"
The user can override freely; the suggestion only fires when Name is empty.

**Colour swatches**:
Eight preset colours in a row (use `GridView` or `Wrap` with `RunSpacing: 8`):

| Swatch | Hex | Label (screen reader) |
|--------|-----|-----------------------|
| Blue | `#1565C0` | Blue |
| Teal | `#00897B` | Teal |
| Purple | `#5E35B1` | Purple |
| Green | `#2E7D32` | Green |
| Orange | `#E65100` | Orange |
| Red | `#B71C1C` | Red |
| Dark | `#263238` | Charcoal |
| Grey | `#546E7A` | Slate |

Each swatch: 40dp circle, border when unselected, `Icons.check` overlay (white, 20dp)
when selected.

**Last 4 Digits field**:
- Visible only when `type == credit_card || type == debit_card`
- Animated show/hide with `AnimatedSize` (200ms) when type changes
- Input type: `TextInputType.number`, max length: 4
- Validation: must be exactly 4 numeric digits if non-empty

**Default toggle behaviour**:
- If toggled ON: show helper text "Expenses with no payment method will suggest this one"
- If there was a previous default, it is silently unset (only one default allowed at a time)
- Setting the only payment method as default is pre-toggled ON automatically

**Validation on Save**:

| Field | Rule |
|-------|------|
| Type | Required; must be a valid enum value |
| Name | Required; 1–100 characters; must be unique (case-insensitive) |
| Last 4 Digits | If present: exactly 4 numeric digits |

On validation failure: inline field errors (below field, `errorStyle`, `bodySmall`)

**Edit mode extras**:
- "Delete Payment Method" text button at the bottom (error/destructive colour)
- Tapping: shows `AlertDialog` confirming deletion, with warning if assigned to expenses
- On confirm: soft-deletes the record, clears `payment_method_id` on all assigned expenses

---

### 3.4 Assigning a Payment Method in the Expense Form

The expense form (`ExpenseForm` widget used in both `AddExpenseScreen` and
`EditExpenseScreen`) gains an optional Payment Method field.

#### Position in Form

The Payment Method field is inserted **after the Notes field and before the Tags field**:

```
...
│  Notes  (optional)                      │
│  ┌─────────────────────────────────┐    │
│  │  Family plan, shared with...   │    │
│  └─────────────────────────────────┘    │
│                                         │
│  Payment Method  (optional)             │  ← NEW section
│  ┌─────────────────────────────────┐    │
│  │  💳  ANZ Visa Credit  ••4242 ▼ │    │  ← Tappable OutlinedButton-style field
│  └─────────────────────────────────┘    │
│                                         │
│  Tags                                   │
│  [family] [streaming] [+ Add tag]       │
...
```

**When no payment methods exist**: the field shows "No payment methods — Add one" as
a `TextButton` navigating to `/settings/payment-methods/add`. On return, the form
retains all previously entered data and auto-selects the newly created method.

**When user has a default payment method**: the field is pre-populated with the default
method but remains editable. If no default is set, the field starts empty ("None").

#### Payment Method Picker (Bottom Sheet)

Tapping the field opens a `DraggableScrollableSheet` modal bottom sheet:

```
╔═══════════════════════════════════════════╗
║  ▬  (drag handle)                         ║
║                                           ║
║  Payment Method                           ║  ← titleLarge
║                                           ║
║  ○  None  (clear selection)               ║  ← "None" option, always first
║  ──────────────────────────────────────   ║
║  ◉  💳  ANZ Visa Credit                  ║  ← current selection has filled radio
║       ••4242                              ║
║  ○  💳  Debit Mastercard                 ║
║       ••8801                              ║
║  ○  🏦  Direct Debit - ANZ              ║
║       ANZ                                ║
║  ○  🅿  PayPal Personal                  ║
║  ──────────────────────────────────────   ║
║  [+ Create new payment method]            ║  ← TextButton, navigates to add screen
║                                           ║
╚═══════════════════════════════════════════╝
```

**Interaction details**:
- Sheet opens with initial snap at ~50% screen height; expandable to full
- Selecting a method instantly updates the field and closes the sheet (no confirm needed)
- "None" clears any existing selection and closes
- "Create new payment method" pushes `/settings/payment-methods/add` over the
  existing stack; when the user saves the new method, the sheet re-opens with the
  new method pre-selected
- List items use the same leading avatar (coloured square, 32×32dp) from §3.2

---

### 3.5 Expense List Item — Payment Method Display

`ExpenseListItem` currently shows:
- Line 1: expense name (+ trailing amount)
- Line 2: category · billingCycle
- Line 3: "Due in X days" (when `nextDueDate` is set)

#### Updated Layout (when payment method is assigned)

Line 3 is extended to show **both** the due-date text and a compact payment method
indicator, space-permitting:

```
│ 🔴  Netflix                $15.49  │
│     Entertainment · Monthly        │
│     Due in 5 days  ·  [💳 ••4242] │  ← Line 3: due date + PM chip
```

Implementation:
- Line 3 is a `Row` with `mainAxisSize: MainAxisSize.min` and `Wrap` fallback
- Due date text: `bodySmall, onSurfaceVariant` (existing style)
- Separator: ` · ` (middle dot, same style)
- PM chip: `Container` with `outlinedChip` styling:
  - Height: 18dp
  - Padding: `EdgeInsets.symmetric(horizontal: 6)`
  - Border: `Border.all(color: pm.colour.withAlpha(128), width: 1)`
  - Background: `pm.colour.withAlpha(15)`
  - Content: `Icon(typeIcon, size: 10)` + `Text(compactLabel, style: labelSmall)`
  - Compact label: `••4242` if last4 exists, else first 8 chars of name

**When no due date**: show only the PM chip on line 3 (no " · " separator)

**When no payment method**: behaviour unchanged from current (just the due date)

The `isThreeLine` property remains `true` when either due date or payment method is
present, maintaining consistent list item heights.

---

### 3.6 Expense Detail Screen — Payment Method Row

The Detail screen's "Details" `Card` gains one new row inserted between "End Date"
and "Total Paid":

#### Updated Details Card

```
┌─────────────────────────────────────────┐
│  Category    🔴 Entertainment           │
│  Cycle       Monthly                    │
│  Start Date  2024-03-15                 │
│  End Date    —                          │
│  Payment     💳 ANZ Visa Credit ••4242 │  ← NEW row
│  Total Paid  $356.27 (23 payments)     │
└─────────────────────────────────────────┘
```

**"Payment" row spec**:
- Label: `"Payment"` (`bodyMedium, w500`)
- Value: leading icon (type icon, 16dp, pm.colour) + `" "` + name + if last4 `" ••XXXX"`
  all in `bodyMedium`
- The value is **tappable** (if user wants to reassign from Detail screen):
  tapping the value row launches the same Payment Method picker bottom sheet from §3.4,
  and on selection saves the change immediately (no edit screen required)
- If no payment method assigned: show `"—"` with a `TextButton.icon("Assign", Icons.add)`
  in-line at the right, which opens the picker

---

### 3.7 Filtering by Payment Method on Home

#### Design Decision: Two-Row Filter System

The existing `FilterChips` widget (a single horizontally scrollable row of category
chips) is extended with a **second, optional chip row** for payment method filters.
The second row:
- Is only rendered if the user has ≥1 payment method defined
- Shares the same visual chip style as category chips
- Can be scrolled independently

This keeps the filter UI immediately visible without requiring a modal, matching the
existing interaction model users already know.

```
┌─────────────────────────────────────────┐
│  [All] [Entertainment] [Software] [...]  │  ← Row 1: Category chips (unchanged)
│  [💳 All] [Visa ••4242] [Direct Debit]  │  ← Row 2: Payment method chips (NEW)
└─────────────────────────────────────────┘
```

#### Row 2 Chip Spec

- First chip: "💳 All" — clears any payment method filter (always present in row 2)
- Per-method chips: leading avatar (coloured square, 16×16dp, `BorderRadius.circular(3)`)
  + compact label (`name` truncated to 12 chars, or `••XXXX` if has last4)
- Selected chip: standard `FilterChip` selected state (filled background, check icon)
- Chip height and style consistent with Row 1
- Row height: 48dp (same as Row 1, 4dp vertical padding)

#### ExpenseFilter Model Update

```dart
class ExpenseFilter {
  final String? categoryId;
  final String status;
  final String? searchQuery;
  final String? paymentMethodId;   // NEW field

  // copyWith updated to include clearPaymentMethod flag
}
```

The `watchExpenses` repository method gains an optional `paymentMethodId` parameter.

#### Visual Distinction Between Rows

To avoid the two rows looking like one continuous chip list, the second row uses:
- Slightly smaller chips (labelMedium instead of labelLarge text) — a subtle size diff
- The leading avatar (coloured square) makes payment method chips visually distinct
  from plain-text category chips

#### Responsiveness

On wider screens (tablets / landscape / desktop):
- Both chip rows may fit on a single horizontal line with a `|` vertical divider separator
- Filter layout adapts using `LayoutBuilder` with breakpoint at 600dp width

---

### 3.8 Empty States — Feature 2

#### Payment Methods List: No Methods Created

```
┌───────────────────────────────────────────┐
│  ←  Payment Methods               [+]     │
├───────────────────────────────────────────┤
│                                           │
│               💳                          │  ← Icon, 64dp, onSurfaceVariant
│                                           │
│     No payment methods yet.              │  ← titleMedium
│                                           │
│   Assign a card, account, or wallet      │  ← bodyMedium, onSurfaceVariant
│   to your expenses to track how          │
│   you pay for each subscription.         │
│                                           │
│       [ + Add Payment Method ]           │  ← FilledButton
│                                           │
└───────────────────────────────────────────┘
```

#### Expense Form: No Payment Methods Exist

Within the form, when tapping the payment method field:
```
╔═══════════════════════════════════════════╗
║  Payment Method                           ║
║                                           ║
║       💳                                  ║
║  No payment methods set up yet.           ║
║  Add one in Settings to assign it         ║
║  to your expenses.                        ║
║                                           ║
║     [ Go to Settings → Payment Methods ] ║  ← TextButton
║     [ Not now ]                          ║  ← TextButton, closes sheet
║                                           ║
╚═══════════════════════════════════════════╝
```

#### Filter Row 2: Visible Only When Methods Exist

If the user has 0 payment methods, Row 2 is completely absent from the Home screen
(no "empty state" needed for the row — it simply doesn't appear). This keeps the
home screen clean for new or minimal users.

---

### 3.9 User Flows — Feature 2

#### Flow A: Create first payment method

```
Settings → Tap "Payment Methods"
  → Empty state screen → Tap "+ Add Payment Method"
  → Create screen: select type "Credit Card"
  → Name auto-suggests "" — user types "ANZ Visa Credit"
  → Enters bank "ANZ", last4 "4242"
  → Colour auto-set to Blue (credit card default)
  → Toggle "Set as default" ON
  → Tap "Save Payment Method"
  → ✅ Returns to Payment Methods list; new method appears; ⭐ default badge shown
```

**Taps**: 4 + 4 field entries

#### Flow B: Assign payment method to a new expense

```
Home → Tap [+] FAB
  → Add Expense screen: fills in name, category, amount, cycle
  → Scrolls to "Payment Method" field
  → Field shows pre-filled default "ANZ Visa Credit ••4242" (auto-populated)
  → User accepts it (no change needed)
  → Tap "Save Expense"
  → ✅ Expense saved with payment method assigned
```

**Taps**: 3 + field entries (payment method assignment was 0 additional taps via default)

#### Flow C: Assign payment method to an existing expense

```
Home → Tap existing expense → Expense Detail screen
  → In Details card: "Payment  —  [Assign]"
  → Tap "[Assign]"
  → Payment Method picker bottom sheet opens
  → Tap "ANZ Visa Credit ••4242"
  → Sheet closes; detail row updates instantly to "Payment  💳 ANZ Visa ••4242"
```

**Taps**: 3 (Home → Detail → picker item = 3 taps + 0 typing)

#### Flow D: Filter expenses by payment method on Home

```
Home → Scroll chip filter Row 2 → Tap "Visa ••4242"
  → Expense list filters to show only expenses assigned to that payment method
  → "Visa ••4242" chip shows selected state
  → Tap "💳 All" to clear filter
```

**Taps**: 1 to filter, 1 to clear

#### Flow E: Delete a payment method with assigned expenses

```
Settings → Payment Methods → Swipe left on "Visa ••4242"
  → Confirmation dialog appears:
    "This payment method is assigned to 3 expense(s).
     Removing it will clear those assignments.
     [Cancel]  [Delete]"
  → Tap "Delete"
  → ✅ Method removed; affected expenses now show "Payment — —"
  → Undo snackbar: "Payment method deleted. [Undo]" (4 seconds)
```

---

## 4. Navigation & Routing Changes

### New Routes

| Route | Screen | Access Point |
|-------|--------|-------------|
| `/upcoming` | Upcoming Payments Screen | Home "Due Soon → See all" button |
| `/settings/payment-methods` | Payment Methods List | Settings → ORGANISATION |
| `/settings/payment-methods/add` | Create Payment Method | List [+] or Expense Form picker |
| `/settings/payment-methods/:id/edit` | Edit Payment Method | List item tap |

### Updated Routes (no path change)

| Route | Change |
|-------|--------|
| `/expense/add` | Form gains Payment Method field |
| `/expense/:id/edit` | Form gains Payment Method field |
| `/expense/:id` | Detail gains Payment Method row in Details card |
| `/stats` (Upcoming tab) | Tab enhanced with 7/30-day toggle; reuses UpcomingListItem |

### GoRouter Branch Assignment

- `/upcoming` → placed as a child of the `_homeNavigatorKey` branch (keeping it
  visually "from Home"), using `parentNavigatorKey: _rootNavigatorKey` so it
  appears as a full-screen push over the shell (no bottom nav visible)
- `/settings/payment-methods` and sub-routes → placed under the `_settingsNavigatorKey`
  branch as children of `/settings`, following the existing pattern for
  `/settings/categories`, `/settings/export`, etc.

```dart
// Home branch additions:
GoRoute(
  path: 'upcoming',
  parentNavigatorKey: _rootNavigatorKey,
  builder: (context, state) => const UpcomingPaymentsScreen(),
),

// Settings branch additions:
GoRoute(
  path: 'payment-methods',
  parentNavigatorKey: _rootNavigatorKey,
  builder: (context, state) => const PaymentMethodsScreen(),
  routes: [
    GoRoute(
      path: 'add',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const PaymentMethodFormScreen(),
    ),
    GoRoute(
      path: ':pmId/edit',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => PaymentMethodFormScreen(
        id: state.pathParameters['pmId'],
      ),
    ),
  ],
),
```

---

## 5. Data Model Changes

### Summary of Changes

| Table | Change |
|-------|--------|
| `payment_methods` | **New table** — full schema in §3.1 |
| `expenses` | **New column**: `payment_method_id TEXT` (nullable FK, schema migration v2) |
| `preferences` | **New key**: `upcoming_default_view` (`week` / `month`, default `week`) — optional, for persisting toggle state across sessions |

### Dart Entity Classes

#### New: `PaymentMethod`

```dart
class PaymentMethod {
  final String id;
  final String name;
  final PaymentMethodType type;    // enum matching type values in §3.1
  final String? last4Digits;
  final String? bankName;
  final String colourHex;
  final bool isDefault;
  final int sortOrder;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String deviceId;
  final bool isDeleted;

  // Computed display helpers:
  String get compactLabel =>
      last4Digits != null ? '••$last4Digits' : (bankName ?? type.displayName);

  String get fullLabel =>
      last4Digits != null ? '$name  ••$last4Digits' : name;
}

enum PaymentMethodType {
  creditCard, debitCard, directDebit, bankTransfer,
  paypal, applePay, googlePay, cash, other;

  String get displayName { ... }
  IconData get icon { ... }
  String get defaultColour { ... }
}
```

#### Updated: `Expense`

```dart
class Expense {
  // ... existing fields unchanged ...
  final String? paymentMethodId;   // NEW — nullable
}
```

#### Updated: `ExpenseFilter`

```dart
class ExpenseFilter {
  final String? categoryId;
  final String status;
  final String? searchQuery;
  final String? paymentMethodId;   // NEW — nullable
}
```

---

## 6. Accessibility Notes

### Feature 1: Upcoming View

| Element | Accessibility Requirement |
|---------|--------------------------|
| Due Soon section header | `Semantics(label: "Due soon — N expenses due in the next 7 days", child: ...)` |
| "See all" button | `Tooltip("View all upcoming payments")` + min 48dp tap target |
| Urgency chips | Semantic label includes full text: `"Due today"`, `"Due in 3 days"` (not just colour) |
| Date group headers | `Semantics(header: true)` for screen reader navigation between groups |
| Period total card | `Semantics(label: "Total due in next N days: \$XXX")` |
| Toggle | `SegmentedButton` provides built-in semantics; label: `"View 7 days"` / `"View 30 days"` |
| Empty state | Role: `region`; describedBy: empty state message |

**Colour-blind consideration**: Urgency is never conveyed by colour alone. The chip
always includes a text label ("Today", "Tomorrow", "In N days"). The colour is
additive (not the sole indicator).

### Feature 2: Payment Methods

| Element | Accessibility Requirement |
|---------|--------------------------|
| Payment method list item | Full semantic: `"ANZ Visa Credit, last 4 digits 4242, credit card, default"` |
| Colour swatches | Each swatch: `Semantics(label: "Blue", selected: true/false, button: true)` |
| Type icon in list | `ExcludeSemantics` — type is conveyed in the semantic label, not the icon |
| PM chip in expense list | `Semantics(label: "Paid with ANZ Visa Credit, ending 4242")` |
| "Assign" link in detail | `Tooltip("Assign payment method to this expense")` |
| Delete swipe | Also accessible via long-press → context menu → "Delete" (keyboard/accessibility users) |
| Payment method picker | Bottom sheet announces with `"Payment Method selector, dialog"` role |

**Screen reader navigation**: All form fields in the payment method form have
`TextFormField` with explicit `decoration.labelText` and `decoration.helperText` for
clear narration. The Last 4 Digits field conditionally announces whether it is currently
shown or hidden based on type selection.

### General Accessibility Requirements (Both Features)

- All new touch targets: **minimum 48×48dp**
- Text contrast: all text must meet **WCAG AA (4.5:1)** against backgrounds
- Dynamic text: all new text elements must respect system font scale (use `sp` units)
- No information conveyed by colour alone
- All interactive elements respond to keyboard navigation (Tab key on desktop/web)
- Focus management: when bottom sheets open/close, focus returns to the triggering element

---

## 7. Animation & Micro-interaction Specs

### Feature 1: Upcoming View

| Interaction | Animation |
|------------|-----------|
| Due Soon section appears on Home | `AnimatedOpacity` + vertical slide-in (200ms, `easeOut`) on first load |
| Toggle between Week / Month | List cross-fades (`AnimatedSwitcher`, 250ms `easeInOut`) |
| Date group headers | Rendered statically (no stagger — keeps perceived performance high) |
| Navigating to `/upcoming` | Standard `GoRouter` push slide (platform default) |
| Empty state swap (week→month) | Same cross-fade as toggle (250ms) |

### Feature 2: Payment Methods

| Interaction | Animation |
|------------|-----------|
| Payment method row in expense form | `AnimatedSize` + `AnimatedOpacity` on show/hide (200ms) |
| Last 4 digits field show/hide | `AnimatedSize` (200ms `easeInOut`) when type changes |
| Colour swatch selection | Scale bounce (1.0→1.15→1.0, 150ms) on the selected swatch |
| Preview card in form | Rebuilds on field change with `AnimatedSwitcher` (150ms) |
| List item delete swipe | `Dismissible` widget: red background slides in; item slides out (200ms) |
| Bottom sheet open | `DraggableScrollableSheet` default spring animation |
| PM chip appearing in expense list | `AnimatedOpacity` on initial render (150ms) |
| Row 2 filter chips appearing | `AnimatedSize` on parent container; chips fade in (200ms) when first PM created |

---

## 8. Cross-Platform Considerations

### Android (Primary Platform)

- Bottom sheet uses `DraggableScrollableSheet` with `showModalBottomSheet`
- Swipe-to-delete on `Dismissible` (standard Android gesture)
- `SnackBar` for undo (Material pattern)
- Haptic feedback: `HapticFeedback.lightImpact()` on chip selection
- `SegmentedButton` requires Material 3 (confirmed in existing app)

### iOS (If Compiled)

- Consider `CupertinoActionSheet` vs `showModalBottomSheet` for payment method picker
  (use adaptive: `showModalBottomSheet` is acceptable on iOS with Material shell)
- Swipe-to-delete: iOS uses leading/trailing action buttons on `Dismissible` — same implementation
- No bottom navigation visible on `/upcoming` push (consistent with existing push routes)

### Web / Desktop

- `/upcoming` accessible via direct URL navigation
- Settings > Payment Methods accessible via direct URL `/settings/payment-methods`
- Filter chips Row 2: on wide screens (>600dp), consider showing both rows in a single
  `Wrap` layout with the `|` separator visual divider
- Mouse hover states on all interactive elements: `InkWell` ripple + cursor change
- Keyboard navigation: Tab order for payment method form follows visual reading order
  (top-to-bottom, left-to-right)
- `SegmentedButton` toggle on Upcoming screen: responds to keyboard `←` `→` arrow keys
- No swipe gestures needed — delete accessible via context menu / delete key

### Adaptive Layout (Breakpoints)

| Breakpoint | Layout Adaptation |
|-----------|------------------|
| < 600dp (phone) | Single column; all screens as designed |
| 600–900dp (tablet portrait) | Due Soon section: grid 2-column; Upcoming list: constrained to 560dp max |
| > 900dp (tablet landscape / desktop) | Two-panel: payment method list + detail side by side (master-detail) |

---

## 9. Component Inventory

### New Widgets

| Widget | File Path | Description |
|--------|-----------|-------------|
| `DueSoonSection` | `lib/features/home/widgets/due_soon_section.dart` | Inline preview of next 7 days on Home |
| `UpcomingListItem` | `lib/features/upcoming/widgets/upcoming_list_item.dart` | Expense item with urgency chip and PM chip |
| `UrgencyChip` | `lib/features/upcoming/widgets/urgency_chip.dart` | Colour-coded days-until chip |
| `PaymentMethodChip` | `lib/shared/widgets/payment_method_chip.dart` | Compact PM indicator (used in list + detail) |
| `PaymentMethodAvatar` | `lib/shared/widgets/payment_method_avatar.dart` | Coloured square with type icon (reused in list, form, picker) |
| `ColourSwatch` | `lib/shared/widgets/colour_swatch.dart` | Circular colour picker swatch |
| `PaymentMethodPicker` | `lib/features/expense/widgets/payment_method_picker.dart` | Bottom sheet for method selection in expense form |

### New Screens

| Screen | File Path | Route |
|--------|-----------|-------|
| `UpcomingPaymentsScreen` | `lib/features/upcoming/screens/upcoming_payments_screen.dart` | `/upcoming` |
| `PaymentMethodsScreen` | `lib/features/settings/screens/payment_methods_screen.dart` | `/settings/payment-methods` |
| `PaymentMethodFormScreen` | `lib/features/settings/screens/payment_method_form_screen.dart` | `/settings/payment-methods/add`, `/settings/payment-methods/:pmId/edit` |

### New Providers

| Provider | File Path | Description |
|----------|-----------|-------------|
| `upcomingPaymentsProvider(int days)` | `lib/features/upcoming/providers/upcoming_provider.dart` | Family provider; extends existing `UpcomingStats` |
| `paymentMethodsProvider` | `lib/features/settings/providers/payment_methods_provider.dart` | Stream of all non-deleted payment methods |
| `paymentMethodFormProvider` | `lib/features/settings/providers/payment_method_form_provider.dart` | Form state for create/edit |
| `expenseFilterProvider` (updated) | `lib/features/home/providers/expense_list_provider.dart` | Adds `paymentMethodId` to existing filter |

### Modified Widgets / Files

| File | Change |
|------|--------|
| `lib/features/home/screens/home_screen.dart` | Insert `DueSoonSection` between `SummaryCard` and `FilterChips` |
| `lib/features/home/widgets/filter_chips.dart` | Add Row 2 for payment method chips (wrapped in `Column`) |
| `lib/features/home/providers/expense_list_provider.dart` | Add `paymentMethodId` to `ExpenseFilter` |
| `lib/features/home/widgets/expense_list_item.dart` | Extend line 3 to include PM chip |
| `lib/features/expense/widgets/expense_form.dart` | Add Payment Method field + picker |
| `lib/features/expense/screens/expense_detail_screen.dart` | Add Payment row to Details card |
| `lib/features/settings/screens/settings_screen.dart` | Add "Payment Methods" tile to ORGANISATION section |
| `lib/features/stats/screens/stats_screen.dart` | Enhance `_UpcomingTab` with 7/30-day toggle; reuse `UpcomingListItem` |
| `lib/router.dart` | Add `/upcoming`, `/settings/payment-methods` routes and children |
| `lib/domain/entities/expense.dart` | Add `paymentMethodId` field |

---

## Appendix A: Screen Inventory Update

The following rows are added to the existing screen inventory tables in
`docs/UX_DESIGN_EVERYPAY.md`:

### V0.5 Additions

| Screen | Route | Purpose |
|--------|-------|---------|
| Upcoming Payments | `/upcoming` | 7-day / 30-day due date view |
| Payment Methods | `/settings/payment-methods` | Manage payment methods |
| Add Payment Method | `/settings/payment-methods/add` | Create new method |
| Edit Payment Method | `/settings/payment-methods/:id/edit` | Edit/delete method |

---

## Appendix B: Design Rationale Summary

| Decision | Rationale |
|----------|-----------|
| Dual-surface for upcoming (Home preview + dedicated screen) | Satisfies both Barbara's "glance at home" need and Kenji's "full planning view" need without forcing navigation |
| "Due Soon" hidden when no upcoming items | Avoids persistent empty card cluttering Home; home stays clean for users with no near-term items |
| "This Week" as default toggle (not 30 days) | 7-day view is more actionable; users take week-by-week financial action. 30 days available but secondary |
| Stats > Upcoming enhanced not replaced | Existing users who rely on Stats > Upcoming tab are not disrupted |
| Payment method as optional field | Avoids friction for new users; respects "forgiving" principle. Not every expense needs a payment method. |
| User-defined name (not auto-generated) | "ANZ Visa Credit" is more meaningful than "Credit Card ••4242"; users name their own financial tools differently |
| Two filter rows (not a filter modal) | Matches existing chip pattern users already know; payment method filter is additive, not a replacement for categories |
| Colour swatches (not free colour picker) | 8 curated colours provide sufficient personalisation without introducing a complex colour picker that slows down form completion |
| Auto-suggest name from type+bank | Reduces typing without removing control; suggestion only fires when name is empty, never overrides user input |
| Last 4 digits — display only, not used for any computation | Privacy-conscious: app never stores full card numbers; last4 is display/identification only, consistent with privacy-first design ethos |
| PM chip in expense list: compact inline (not a 4th line) | Adding a full 4th line would make list items too tall; inline chip on line 3 keeps 3-line height consistent |
