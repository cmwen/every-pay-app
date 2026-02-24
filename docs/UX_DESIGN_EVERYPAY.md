---
title: Every-Pay — UX Design Specification
version: 1.0.0
created: 2026-02-24
owner: UX Designer
status: Final
references:
  - docs/REQUIREMENTS_EVERYPAY.md
  - docs/PERSONAS_EVERYPAY.md
  - docs/USER_STORIES_EVERYPAY.md
---

# Every-Pay — UX Design Specification

## 1. Design Principles

1. **Clarity over cleverness** — every screen answers one question
2. **3-tap rule** — any primary action reachable within 3 taps from home
3. **Glanceable** — key numbers visible without scrolling
4. **Forgiving** — undo > confirm dialogs; smart defaults > empty forms
5. **Inclusive** — WCAG AA contrast, large touch targets (48dp), screen reader labels

---

## 2. Design System

### Theme

| Token | Light | Dark |
|-------|-------|------|
| Primary | `#1565C0` (Blue 800) | `#64B5F6` (Blue 300) |
| Secondary | `#00897B` (Teal 600) | `#4DB6AC` (Teal 300) |
| Surface | `#FFFFFF` | `#1E1E1E` |
| Background | `#F5F5F5` | `#121212` |
| Error | `#D32F2F` | `#EF5350` |
| On Primary | `#FFFFFF` | `#000000` |

Uses **Material Design 3** with `ColorScheme.fromSeed(seedColor: Color(0xFF1565C0))`.

### Typography

| Role | Style | Usage |
|------|-------|-------|
| Display Large | 36sp Bold | Monthly total amount |
| Title Large | 22sp SemiBold | Screen titles |
| Title Medium | 16sp SemiBold | Card headers, section titles |
| Body Large | 16sp Regular | Expense names, primary text |
| Body Medium | 14sp Regular | Secondary info, descriptions |
| Label Large | 14sp Medium | Buttons, chips, labels |
| Label Small | 11sp Medium | Badges, timestamps |

### Iconography

Material Symbols (Outlined, weight 400). Category icons use filled variants for visual distinction.

### Spacing & Layout

- Screen padding: 16dp horizontal
- Card padding: 16dp all sides
- List item height: 72dp (two-line with leading icon)
- FAB position: bottom-right, 16dp margin
- Bottom nav bar height: 80dp (with labels)

---

## 3. Information Architecture

### Navigation Structure

```
Bottom Navigation Bar (3 tabs)
├── 🏠 Home
│   ├── Summary card (monthly total, active count)
│   ├── Expense list (filterable, searchable)
│   └── FAB → Add Expense
├── 📊 Stats
│   ├── Tab bar: Monthly | Yearly | Upcoming
│   ├── Chart area
│   └── Detail breakdown
└── ⚙️ Settings
    ├── General (currency, theme)
    ├── Categories
    ├── Devices & Sync
    ├── Security (app lock)
    ├── Data (export/import)
    └── About
```

### Screen Inventory (MVP — V0.1)

| Screen | Route | Purpose |
|--------|-------|---------|
| Home | `/` | Expense list with summary |
| Add Expense | `/expense/add` | New expense form |
| Service Library | `/expense/add/library` | Pick from templates |
| Expense Detail | `/expense/:id` | View full expense info |
| Edit Expense | `/expense/:id/edit` | Modify expense |
| Settings | `/settings` | App preferences |
| Categories | `/settings/categories` | Manage categories |

### Additional Screens (V0.5)

| Screen | Route | Purpose |
|--------|-------|---------|
| Stats — Monthly | `/stats` | Monthly summary + pie chart |
| Stats — Yearly | `/stats/yearly` | 12-month bar chart |
| Stats — Upcoming | `/stats/upcoming` | Next 30 days timeline |

### Additional Screens (V1.0)

| Screen | Route | Purpose |
|--------|-------|---------|
| Devices | `/settings/devices` | Paired device list |
| Pair Device | `/settings/devices/pair` | QR code pairing flow |
| Export Data | `/settings/export` | CSV/JSON export |
| Security | `/settings/security` | Biometric lock |

---

## 4. Screen Designs

### 4.1 Home Screen (`/`)

```
┌─────────────────────────────────────────┐
│  Every-Pay                    🔍  ⋮     │  ← App bar
├─────────────────────────────────────────┤
│  ┌─────────────────────────────────┐    │
│  │  This Month           $247.94  │    │  ← Summary card
│  │  ▲ 3.2% vs last month         │    │
│  │  12 active subscriptions       │    │
│  └─────────────────────────────────┘    │
├─────────────────────────────────────────┤
│  [All ▼]  [🏷 Entertainment]  [💰 ...]  │  ← Filter chips
├─────────────────────────────────────────┤
│  ┌─────────────────────────────────┐    │
│  │ 🔴 Netflix              $15.49 │    │
│  │    Entertainment · Monthly      │    │
│  │    Due in 5 days               │    │  ← Expense item
│  ├─────────────────────────────────┤    │
│  │ ⚡ Electricity           $89.00 │    │
│  │    Utilities · Monthly          │    │
│  │    Due in 12 days              │    │
│  ├─────────────────────────────────┤    │
│  │ 🛡 Car Insurance        $142.00 │    │
│  │    Insurance · Monthly          │    │
│  │    Due in 18 days              │    │
│  ├─────────────────────────────────┤    │
│  │ ☁ iCloud+                $2.99 │    │
│  │    Software · Monthly           │    │
│  │    Due in 23 days              │    │
│  └─────────────────────────────────┘    │
│                                         │
│                              [+ FAB]    │  ← Floating action button
├─────────────────────────────────────────┤
│  🏠 Home    📊 Stats    ⚙️ Settings     │  ← Bottom nav
└─────────────────────────────────────────┘
```

**Interactions:**
- Tap expense → Expense Detail screen
- Long-press expense → Quick actions (edit, cancel, delete)
- Tap filter chip → Filter list by category
- Tap FAB → Add Expense screen
- Pull down → Refresh (recalculate due dates)
- Search icon → Search expenses by name/provider
- Swipe left on expense → Quick cancel/delete

**List sorting:**
- Default: by `next_due_date` (soonest first)
- Options: by name (A–Z), by amount (high–low), by category

---

### 4.2 Add Expense Screen (`/expense/add`)

```
┌─────────────────────────────────────────┐
│  ← Add Expense                         │
├─────────────────────────────────────────┤
│                                         │
│  ┌─────────────────────────────────┐    │
│  │ 📚 Choose from library          │    │  ← Library shortcut
│  └─────────────────────────────────┘    │
│                                         │
│  ─── or enter manually ───              │
│                                         │
│  Name *                                 │
│  ┌─────────────────────────────────┐    │
│  │ Netflix                        │    │
│  └─────────────────────────────────┘    │
│                                         │
│  Provider                               │
│  ┌─────────────────────────────────┐    │
│  │ Netflix Inc.                   │    │
│  └─────────────────────────────────┘    │
│                                         │
│  Category *                             │
│  ┌─────────────────────────────────┐    │
│  │ 🔴 Entertainment & Streaming ▼ │    │
│  └─────────────────────────────────┘    │
│                                         │
│  Amount *               Currency        │
│  ┌──────────────────┐  ┌──────────┐    │
│  │ 15.49            │  │ USD ▼    │    │
│  └──────────────────┘  └──────────┘    │
│                                         │
│  Billing Cycle *                        │
│  [Weekly] [Monthly✓] [Quarterly]        │
│  [Yearly] [Custom]                      │
│                                         │
│  Start Date *           End Date        │
│  ┌──────────────────┐  ┌──────────┐    │
│  │ 2026-01-15       │  │ Optional │    │
│  └──────────────────┘  └──────────┘    │
│                                         │
│  Notes                                  │
│  ┌─────────────────────────────────┐    │
│  │ Family plan, shared with...    │    │
│  └─────────────────────────────────┘    │
│                                         │
│  Tags                                   │
│  [family] [streaming] [+ Add tag]       │
│                                         │
│         [ Save Expense ]                │  ← Primary button
│                                         │
└─────────────────────────────────────────┘
```

**Interactions:**
- "Choose from library" → navigates to Service Library screen
- Category dropdown → bottom sheet with category list + icons
- Billing cycle → segmented button group
- Date fields → Material date picker
- Tags → chip input with autocomplete from existing tags
- Save → validates required fields, saves, returns to Home

**Smart defaults:**
- Currency: from device locale
- Billing cycle: Monthly (most common)
- Start date: Today
- Status: Active

---

### 4.3 Service Library Screen (`/expense/add/library`)

```
┌─────────────────────────────────────────┐
│  ← Choose a Service                    │
├─────────────────────────────────────────┤
│  ┌─────────────────────────────────┐    │
│  │ 🔍 Search services...          │    │
│  └─────────────────────────────────┘    │
├─────────────────────────────────────────┤
│  ENTERTAINMENT & STREAMING              │
│  ┌─────────────────────────────────┐    │
│  │ 🔴 Netflix              Monthly│    │
│  │ 🟢 Spotify              Monthly│    │
│  │ 🔵 Disney+              Monthly│    │
│  │ 🟡 YouTube Premium      Monthly│    │
│  │ 🟣 HBO Max              Monthly│    │
│  │ 🔵 Amazon Prime         Yearly │    │
│  └─────────────────────────────────┘    │
│  UTILITIES & BILLS                      │
│  ┌─────────────────────────────────┐    │
│  │ ⚡ Electricity          Monthly│    │
│  │ 🔥 Gas                  Monthly│    │
│  │ 💧 Water                Monthly│    │
│  │ 🌐 Internet             Monthly│    │
│  │ 📱 Phone Plan           Monthly│    │
│  └─────────────────────────────────┘    │
│  INSURANCE                              │
│  ┌─────────────────────────────────┐    │
│  │ 🏥 Health Insurance     Monthly│    │
│  │ 🚗 Car Insurance        Yearly │    │
│  │ 🏠 Home Insurance       Yearly │    │
│  └─────────────────────────────────┘    │
│  ... more categories ...                │
└─────────────────────────────────────────┘
```

**Interactions:**
- Search filters list in real-time
- Tap service → navigates to Add Expense with fields pre-filled
- Grouped by category with sticky headers

---

### 4.4 Expense Detail Screen (`/expense/:id`)

```
┌─────────────────────────────────────────┐
│  ←                        ✏️  🗑️      │
├─────────────────────────────────────────┤
│                                         │
│  🔴 Netflix                             │
│  Netflix Inc.                           │
│                                         │
│  ┌─────────────────────────────────┐    │
│  │          $15.49/mo              │    │  ← Amount card
│  │     $185.88 projected/year      │    │
│  │                                 │    │
│  │  ● Active        Due Feb 28    │    │
│  └─────────────────────────────────┘    │
│                                         │
│  Details                                │
│  ┌─────────────────────────────────┐    │
│  │  Category    🔴 Entertainment   │    │
│  │  Cycle       Monthly            │    │
│  │  Start Date  2024-03-15         │    │
│  │  End Date    —                  │    │
│  │  Total Paid  $356.27 (23 mo)   │    │
│  └─────────────────────────────────┘    │
│                                         │
│  Notes                                  │
│  ┌─────────────────────────────────┐    │
│  │  Family plan. Shared with       │    │
│  │  partner. 4K Ultra HD plan.     │    │
│  └─────────────────────────────────┘    │
│                                         │
│  Tags                                   │
│  [family] [streaming] [shared]          │
│                                         │
│  ─── Actions ───                        │
│  [ ⏸ Pause ]  [ ❌ Cancel ]            │
│                                         │
└─────────────────────────────────────────┘
```

**Interactions:**
- Edit icon → Edit Expense screen (same form, pre-filled)
- Delete icon → confirmation dialog
- Pause → sets status to Paused
- Cancel → prompts for cancellation date, sets status to Cancelled

---

### 4.5 Stats — Monthly Summary (`/stats`)

```
┌─────────────────────────────────────────┐
│  Statistics                             │
├─────────────────────────────────────────┤
│  [Monthly✓] [Yearly] [Upcoming]         │  ← Tab bar
├─────────────────────────────────────────┤
│                                         │
│  February 2026                    ◀ ▶   │
│                                         │
│  ┌─────────────────────────────────┐    │
│  │        $247.94                  │    │
│  │     ▲ 3.2% vs Jan              │    │
│  └─────────────────────────────────┘    │
│                                         │
│  ┌─────────────────────────────────┐    │
│  │         ╭─────╮                 │    │
│  │       ╱    36%  ╲               │    │  ← Donut chart
│  │      │  Utilities │             │    │     by category
│  │      │   $89.00   │             │    │
│  │       ╲          ╱              │    │
│  │         ╰─────╯                 │    │
│  │  🔴 Entertainment  $33.47  14% │    │
│  │  ⚡ Utilities      $89.00  36% │    │
│  │  🛡 Insurance     $142.00  57% │    │
│  │  ☁ Software        $2.99   1% │    │
│  └─────────────────────────────────┘    │
│                                         │
│  Key Insights                           │
│  ┌─────────────────────────────────┐    │
│  │ 💰 Biggest: Car Insurance $142  │    │
│  │ 📊 12 active subscriptions      │    │
│  │ 📅 Avg: $20.66/subscription    │    │
│  └─────────────────────────────────┘    │
│                                         │
├─────────────────────────────────────────┤
│  🏠 Home    📊 Stats    ⚙️ Settings     │
└─────────────────────────────────────────┘
```

**Interactions:**
- Tap donut segment → filters breakdown to that category
- ◀ ▶ → navigate months
- Swipe left/right → navigate months
- Tap insight card → navigates to relevant expense/category

---

### 4.6 Stats — Yearly Overview (`/stats/yearly`)

```
┌─────────────────────────────────────────┐
│  Statistics                             │
├─────────────────────────────────────────┤
│  [Monthly] [Yearly✓] [Upcoming]         │
├─────────────────────────────────────────┤
│                                         │
│  2026                             ◀ ▶   │
│                                         │
│  Projected: $2,975.28                   │
│                                         │
│  ┌─────────────────────────────────┐    │
│  │  $300 ┤                         │    │
│  │       ┤  ██                     │    │
│  │  $250 ┤  ██ ██                  │    │  ← Bar chart
│  │       ┤  ██ ██       ░░ ░░ ░░  │    │     (██ = actual)
│  │  $200 ┤  ██ ██       ░░ ░░ ░░  │    │     (░░ = projected)
│  │       ┤  ██ ██ ██    ░░ ░░ ░░  │    │
│  │  $150 ┤  ██ ██ ██    ░░ ░░ ░░  │    │
│  │       ┼──────────────────────── │    │
│  │        J  F  M  A  M  J  J ... │    │
│  └─────────────────────────────────┘    │
│                                         │
│  Monthly Average: $247.94               │
│  Highest Month: January ($256.12)       │
│  Lowest Month: March ($239.80)          │
│                                         │
├─────────────────────────────────────────┤
│  🏠 Home    📊 Stats    ⚙️ Settings     │
└─────────────────────────────────────────┘
```

---

### 4.7 Stats — Upcoming Payments (`/stats/upcoming`)

```
┌─────────────────────────────────────────┐
│  Statistics                             │
├─────────────────────────────────────────┤
│  [Monthly] [Yearly] [Upcoming✓]         │
├─────────────────────────────────────────┤
│                                         │
│  Next 30 Days: $247.94                  │
│  [30 days ▼]                            │
│                                         │
│  ─── Tomorrow, Feb 25 ───              │
│  ┌─────────────────────────────────┐    │
│  │ ☁ iCloud+                $2.99 │    │
│  └─────────────────────────────────┘    │
│                                         │
│  ─── Friday, Feb 28 ───                │
│  ┌─────────────────────────────────┐    │
│  │ 🔴 Netflix              $15.49 │    │
│  │ 🟢 Spotify               $9.99 │    │
│  └─────────────────────────────────┘    │
│                                         │
│  ─── March 5 ───                        │
│  ┌─────────────────────────────────┐    │
│  │ ⚡ Electricity           $89.00 │    │
│  └─────────────────────────────────┘    │
│                                         │
│  ─── March 12 ───                       │
│  ┌─────────────────────────────────┐    │
│  │ 🛡 Car Insurance        $142.00 │    │
│  └─────────────────────────────────┘    │
│                                         │
├─────────────────────────────────────────┤
│  🏠 Home    📊 Stats    ⚙️ Settings     │
└─────────────────────────────────────────┘
```

---

### 4.8 Settings Screen (`/settings`)

```
┌─────────────────────────────────────────┐
│  Settings                               │
├─────────────────────────────────────────┤
│                                         │
│  GENERAL                                │
│  ┌─────────────────────────────────┐    │
│  │ 💰 Default Currency      USD ▶ │    │
│  │ 🎨 Theme            System  ▶ │    │
│  └─────────────────────────────────┘    │
│                                         │
│  ORGANISATION                           │
│  ┌─────────────────────────────────┐    │
│  │ 🏷 Categories              10 ▶ │    │
│  └─────────────────────────────────┘    │
│                                         │
│  SYNC & DEVICES                         │
│  ┌─────────────────────────────────┐    │
│  │ 📱 Devices & Sync          0 ▶ │    │
│  │    Last sync: Never             │    │
│  └─────────────────────────────────┘    │
│                                         │
│  PRIVACY & SECURITY                     │
│  ┌─────────────────────────────────┐    │
│  │ 🔒 App Lock              Off ▶ │    │
│  └─────────────────────────────────┘    │
│                                         │
│  DATA                                   │
│  ┌─────────────────────────────────┐    │
│  │ 📤 Export Data                ▶ │    │
│  │ 📥 Import Data                ▶ │    │
│  └─────────────────────────────────┘    │
│                                         │
│  ABOUT                                  │
│  ┌─────────────────────────────────┐    │
│  │ ℹ️ About Every-Pay        v1.0 ▶ │    │
│  └─────────────────────────────────┘    │
│                                         │
├─────────────────────────────────────────┤
│  🏠 Home    📊 Stats    ⚙️ Settings     │
└─────────────────────────────────────────┘
```

---

## 5. User Flows

### Flow 1: Add Expense from Library (Happy Path)

```
Home → Tap FAB (+) → Add Expense Screen
  → Tap "Choose from library"
  → Service Library Screen
  → Search "Netflix" → Tap Netflix
  → Add Expense (pre-filled: name, category, cycle)
  → Enter amount: $15.49
  → Enter start date (or keep today)
  → Tap "Save Expense"
  → ✅ Returns to Home with Netflix visible in list
```

**Taps:** Home (1) → FAB (2) → Library (3) → Netflix (4) → Save (5) = **5 taps** + amount entry

### Flow 2: Add Custom Expense (Happy Path)

```
Home → Tap FAB (+) → Add Expense Screen
  → Enter name: "Gym membership"
  → Select category: Health & Fitness
  → Enter amount: $45.00
  → Select cycle: Monthly
  → Tap "Save Expense"
  → ✅ Returns to Home
```

**Taps:** 2 taps + 4 field entries = efficient

### Flow 3: View Monthly Stats

```
Home → Tap "Stats" tab
  → Monthly summary loads (default tab)
  → See total, pie chart, insights
  → Tap pie segment → drills into category expenses
```

**Taps:** 1 tap to stats, 1 tap to drill down

### Flow 4: Pair Device (V1.0)

```
Settings → Devices & Sync → "Add Device"
  → QR code displayed with countdown timer
  → Partner scans QR on their phone
  → Both devices show "Pairing successful!"
  → Initial sync begins (progress indicator)
  → ✅ "Synced 12 expenses"
```

### Flow 5: Cancel a Subscription

```
Home → Tap expense → Expense Detail
  → Tap "Cancel" button
  → Date picker: "When did you cancel?" (default: today)
  → Confirm
  → ✅ Expense marked as Cancelled, removed from active list
```

---

## 6. Micro-Interactions & Polish

### Animations

| Interaction | Animation |
|-------------|-----------|
| Add expense | List item slides in from bottom with fade |
| Delete expense | Item slides out left, list collapses smoothly |
| Switch stats tab | Cross-fade with chart rebuild animation (300ms) |
| Pie chart load | Segments animate in clockwise (500ms) |
| Bar chart load | Bars grow from bottom (400ms, staggered) |
| Pull to refresh | Standard Material overscroll indicator |
| FAB press | Ripple + haptic feedback |
| Filter chip select | Background fill transition (200ms) |

### Empty States

| Screen | Empty State Message |
|--------|-------------------|
| Home (no expenses) | 🎉 "No expenses yet! Tap + to add your first subscription." |
| Stats (no data) | 📊 "Add some expenses first to see your spending stats." |
| Upcoming (nothing due) | 🎊 "Nothing due in the next 30 days. Nice!" |
| Search (no results) | 🔍 "No expenses match your search." |
| Devices (none paired) | 📱 "No paired devices. Tap Add Device to sync with your household." |

### Status Badges

| Status | Badge | Colour |
|--------|-------|--------|
| Active | `● Active` | Green `#43A047` |
| Paused | `⏸ Paused` | Amber `#F9A825` |
| Cancelled | `✕ Cancelled` | Grey `#757575` |
| Expiring Soon | `⚠ Expiring` | Orange `#F57C00` |
| Expired | `✕ Expired` | Red `#D32F2F` |

---

## 7. Accessibility

| Requirement | Implementation |
|-------------|---------------|
| Contrast | All text meets WCAG AA (4.5:1 for body, 3:1 for large) |
| Touch targets | Minimum 48×48dp for all interactive elements |
| Screen reader | All icons have `semanticLabel`, all images have `alt` |
| Focus order | Logical top-to-bottom, left-to-right |
| Font scaling | Supports system font scale up to 200% |
| Motion | Respect `MediaQuery.reduceMotion` — disable chart animations |
| Colour-blind | Category icons + text labels (not colour alone) |

---

## 8. Responsive Considerations

| Breakpoint | Layout |
|-----------|--------|
| < 360dp | Compact: single column, smaller cards |
| 360–411dp | Standard phone: as designed above |
| 412dp+ | Large phone: wider cards, optional 2-column grid for stats |
| Tablet (600dp+) | Future: master-detail layout for expenses |

---

## 9. Related Documents

- `docs/REQUIREMENTS_EVERYPAY.md` — Product requirements
- `docs/PERSONAS_EVERYPAY.md` — User personas
- `docs/USER_STORIES_EVERYPAY.md` — User story backlog
- `docs/RESEARCH_EVERYPAY.md` — Technology research
- `docs/ARCHITECTURE_EVERYPAY.md` — Architecture specification
