# UX Design: Demo Mode & Guided Tour

> **Status:** Draft  
> **Last updated:** 2025-01-20  
> **Affects:** HomeScreen, StatsScreen, SettingsScreen, AppScaffold  

---

## 1. Overview

Demo Mode lets first-time users explore a fully populated app before committing to data entry. It injects realistic mock expenses, categories, and payment methods, then walks the user through core features with a 5-step coach-mark tour. The entire flow is **read-only** — tapping "Add" or "Edit" during demo mode shows a brief snackbar ("Exit demo to add your own expenses") instead of navigating to forms.

### Design Goals

| Goal | How |
|---|---|
| Reduce time-to-value | User sees a populated app in one tap |
| Teach without a manual | Coach marks highlight the 5 things that matter |
| Never confuse real vs. demo | Persistent banner + distinct state make it obvious |
| Zero side-effects | Demo data lives only in memory; nothing persisted |

---

## 2. Entry Points

### 2A. Empty-State CTA (Primary)

Shown on `HomeScreen` when `expenses.isEmpty` and no active filter.

```
┌─────────────────────────────────┐
│         🎉  (icon 64dp)        │
│                                 │
│      No expenses yet!           │
│  Tap + to add your first        │
│  subscription or recurring      │
│  expense.                       │
│                                 │
│  ┌───────────────────────────┐  │
│  │    ▶  Try Demo            │  │  ← FilledButton.tonal
│  └───────────────────────────┘  │
│                                 │
│  Explore with sample data       │  ← bodySmall, onSurfaceVariant
└─────────────────────────────────┘
```

**Widget change:** Add an `action` parameter to the existing `EmptyStateView` in `home_screen.dart` line 69. The button is a `FilledButton.tonal` with icon `Icons.play_arrow` and label `"Try Demo"`. Below it, a single line of caption text: *"Explore with sample data"*.

**Visibility rule:** Only shown when `expenses.isEmpty && !hasActiveFilter`. If the user has any real data, this button never appears.

### 2B. Settings Toggle (Secondary)

Add a new tile in the `GENERAL` section of `SettingsScreen`, directly below the Theme row.

```
┌─ GENERAL ───────────────────────────────┐
│  🎨  Theme                    [System ▼]│
│  🧪  Demo Mode                          │  ← new ListTile
│      Explore with sample data     [ > ] │
└─────────────────────────────────────────┘
```

**Widget:** `ListTile` with `leading: Icon(Icons.science_outlined)`, title `"Demo Mode"`, subtitle `"Explore with sample data"`, trailing chevron. `onTap` activates demo mode and navigates to Home tab.

**Visibility rule:** Always shown (even if user has real data). Tapping it switches to demo data *alongside* the user's real data being hidden (not deleted).

---

## 3. Demo Data Specification

All demo data is generated at activation time (not stored in the database). A `DemoDataProvider` holds the in-memory lists. Dates are computed relative to `DateTime.now()` so "Due Soon" and stats always look realistic.

### 3A. Categories (use existing defaults)

The app's built-in default categories are reused. No extra categories needed.

### 3B. Payment Methods (2 items)

| Name | Type | Last 4 | Colour |
|---|---|---|---|
| Everyday Visa | creditCard | 4242 | `#1565C0` |
| Savings Direct Debit | directDebit | — | `#6D4C41` |

### 3C. Expenses (7 items)

These are chosen to exercise every billing cycle visible in the UI, produce a varied pie chart, and guarantee at least 2 items in "Due Soon".

| # | Name | Provider | Category | Amount | Cycle | Next Due | Status | Payment Method |
|---|---|---|---|---|---|---|---|---|
| 1 | Netflix | Netflix | Entertainment | 22.99 | Monthly | now + 3 days | active | Everyday Visa |
| 2 | Spotify | Spotify | Entertainment | 13.99 | Monthly | now + 6 days | active | Everyday Visa |
| 3 | iCloud+ | Apple | Cloud Storage | 4.49 | Monthly | now + 14 days | active | Everyday Visa |
| 4 | Gym Membership | GoodLife | Health & Fitness | 29.95 | Fortnightly | now + 5 days | active | Savings DD |
| 5 | Adobe Creative Cloud | Adobe | Productivity | 89.99 | Yearly | now + 45 days | active | Everyday Visa |
| 6 | Car Insurance | AAMI | Insurance | 145.00 | Quarterly | now + 22 days | active | Savings DD |
| 7 | Old VPN | NordVPN | Utilities | 5.99 | Monthly | now − 10 days | cancelled | — |

**Why these?** Items 1, 2, 4 appear in "Due Soon" (≤ 7 days). Items span 4+ categories for a meaningful pie chart. Item 7 shows the cancelled state. Mixed payment methods demonstrate the PM chip on list items. The yearly Adobe item shows how annual costs are normalised to monthly.

---

## 4. State Architecture

### 4A. Provider

```
// lib/features/demo/providers/demo_mode_provider.dart

@riverpod
class DemoMode extends _$DemoMode {
  @override
  DemoState build() => const DemoState.inactive();

  void activate() {
    state = DemoState.active(
      expenses: DemoData.expenses(),      // generated relative to now
      categories: DemoData.categories(),
      paymentMethods: DemoData.paymentMethods(),
      tourStep: 0,                        // 0 = tour not started yet
      tourDismissed: false,
    );
  }

  void nextTourStep() { ... }
  void dismissTour() { ... }   // sets tourDismissed = true, keeps data visible
  void deactivate() {           // state → inactive, clears everything
    state = const DemoState.inactive();
  }
}
```

### 4B. Data Switching

Existing providers (`expenseListProvider`, `categoriesProvider`, `allPaymentMethodsProvider`) are wrapped with a thin layer:

```dart
// Pseudocode — actual impl uses ref.watch(demoModeProvider)
List<Expense> get expenses {
  final demo = ref.watch(demoModeProvider);
  if (demo.isActive) return demo.expenses;
  return ref.watch(realExpenseListProvider);
}
```

This means **zero database writes** during demo mode. All screens (Home, Stats, Upcoming) automatically render demo data because they read from the same provider interface.

### 4C. Read-Only Guard

When demo mode is active, navigation to `AddExpenseScreen`, `EditExpenseScreen`, `PaymentMethodFormScreen` and any delete action is intercepted:

```dart
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text('Exit demo mode to manage your own data')),
);
```

The FAB and list-item taps still *visually respond* (ink ripple) so the app feels alive, but the navigation is blocked with the snackbar message.

---

## 5. Demo Banner

A persistent visual indicator that the user is in demo mode. Rendered by `AppScaffold` so it appears on **all three tabs**.

### 5A. Layout

```
┌─────────────────────────────────────────┐
│ 🧪 You're exploring demo data   [Exit] │  ← MaterialBanner or custom Container
├─────────────────────────────────────────┤
│                                         │
│  (normal screen content below)          │
```

### 5B. Specification

| Property | Value |
|---|---|
| Widget | `MaterialBanner` (or custom `Container` for tighter control) |
| Background | `colorScheme.tertiaryContainer` |
| Text colour | `colorScheme.onTertiaryContainer` |
| Leading icon | `Icons.science` (16dp) |
| Text | `"You're exploring demo data"` (`labelLarge`) |
| Action | `TextButton` label `"Exit"`, calls `ref.read(demoModeProvider.notifier).deactivate()` |
| Height | 48dp total (fits Material 3 density) |
| Position | Inserted as first child in `AppScaffold.body`, above `navigationShell` |
| Semantics | `Semantics(label: 'Demo mode active. Tap Exit to return to your data.')` |
| Animation | `SlideTransition` down from top, 200ms `easeOut` |

### 5C. Behaviour

- Visible whenever `demoMode.isActive`, regardless of whether the tour is running or dismissed.
- Tapping "Exit" shows a confirmation dialog: *"Exit Demo? This will return you to your real data."* with **Cancel** / **Exit Demo** actions.
- After exit, the user returns to their actual data (empty state if they had nothing).

---

## 6. Guided Tour — Coach Marks

### 6A. Overlay System

The tour uses a full-screen `Overlay` with two layers:

1. **Scrim layer** — `Colors.black.withOpacity(0.6)`, with a `ClipPath` or `CustomPainter` that cuts out a rounded-rect "spotlight" hole around the target widget.
2. **Tooltip layer** — a positioned `Card` near the spotlight.

**Target acquisition:** Each tour step references a `GlobalKey` attached to the target widget. The overlay reads `key.currentContext.findRenderObject()` to get position and size, then paints the cutout.

### 6B. Tooltip Bubble

```
        ┌──────────────────────────────────┐
        │  Monthly Spending          2 / 5 │  ← titleSmall + step counter
        │                                  │
        │  This card shows your total      │  ← bodyMedium
        │  monthly cost and how it         │
        │  compares to last month.         │
        │                                  │
        │            [Skip]   [Next →]     │  ← TextButton pair
        └──────────────────────────────────┘
                        ▼  (nub pointing at target)
```

| Property | Value |
|---|---|
| Widget | `Card` with `elevation: 3`, `surfaceContainerHighest` background |
| Corner radius | 16dp |
| Max width | 300dp (so it works on narrow phones) |
| Title | `titleSmall`, `onSurface` |
| Step counter | `labelSmall`, `onSurfaceVariant`, right-aligned in title row |
| Description | `bodyMedium`, `onSurfaceVariant` |
| Padding | 16dp all sides |
| Primary action | `FilledButton` — "Next →" (or "Done ✓" on last step) |
| Secondary action | `TextButton` — "Skip" (dismisses entire tour) |
| Nub/arrow | 12dp equilateral triangle via `CustomPainter`, same colour as card background, pointing toward the spotlight center |
| Animation | `FadeTransition` + `ScaleTransition` from 0.9→1.0, 250ms `easeOutCubic` on each step transition |

### 6C. Spotlight Cutout

| Property | Value |
|---|---|
| Shape | `RRect` with 12dp radius |
| Padding | 8dp around target on all sides |
| Transition | `AnimatedPositioned` + animated `ClipPath`, 300ms `easeInOut` |
| Tap behaviour | Tapping inside the spotlight does nothing (blocks pass-through). Tapping the scrim area also does nothing (prevents accidental dismissal). Only the tooltip buttons advance/dismiss. |

### 6D. Tour Steps

The tour starts automatically when demo mode activates from the empty-state CTA. When activated from Settings, the user is navigated to Home first, then the tour starts after a 500ms delay.

---

#### Step 1 of 5 — Summary Card

| Field | Value |
|---|---|
| **Target** | `SummaryCard` widget (`GlobalKey: demoKeySummary`) |
| **Tab** | Home (already visible) |
| **Tooltip position** | Below the card |
| **Title** | "Monthly Spending" |
| **Description** | "Your total monthly cost at a glance — with a trend vs. last month." |
| **Nub direction** | Points up toward the card |

---

#### Step 2 of 5 — Due Soon Section

| Field | Value |
|---|---|
| **Target** | `DueSoonSection` card (`GlobalKey: demoKeyDueSoon`) |
| **Tab** | Home (scroll position maintained) |
| **Tooltip position** | Below the section |
| **Title** | "Due Soon" |
| **Description** | "Upcoming payments in the next 7 days. Tap 'See all' for the full calendar." |
| **Nub direction** | Points up toward the card |

---

#### Step 3 of 5 — Expense List Item

| Field | Value |
|---|---|
| **Target** | First `ExpenseListItem` in the list (`GlobalKey: demoKeyFirstExpense`) |
| **Tab** | Home |
| **Tooltip position** | Below the item |
| **Title** | "Your Subscriptions" |
| **Description** | "Each row shows the name, category, billing cycle, and cost. Tap any item for full details." |
| **Nub direction** | Points up toward the item |

---

#### Step 4 of 5 — Floating Action Button

| Field | Value |
|---|---|
| **Target** | `FloatingActionButton` (`GlobalKey: demoKeyFab`) |
| **Tab** | Home |
| **Tooltip position** | Above-left of the FAB |
| **Title** | "Add Expense" |
| **Description** | "Tap here to add a new subscription. You can pick from popular services or enter manually." |
| **Nub direction** | Points down-right toward the FAB |

---

#### Step 5 of 5 — Stats Tab (via NavigationBar)

| Field | Value |
|---|---|
| **Target** | Stats `NavigationDestination` in the bottom bar (`GlobalKey: demoKeyStatsTab`) |
| **Tab** | Home → navigates to Stats after user taps "Next" |
| **Tooltip position** | Above the nav bar item |
| **Title** | "Statistics & Insights" |
| **Description** | "Charts break down spending by category and month. See where your money goes." |
| **Nub direction** | Points down toward the nav item |
| **On "Done ✓"** | Navigate to Stats tab, dismiss tour overlay, demo data stays visible with banner |

---

### 6E. Tour Sequence Diagram

```
User taps "Try Demo"
        │
        ▼
  ┌─────────────┐     activates demo data
  │ DemoMode     │───► providers switch to mock data
  │ .activate()  │───► AppScaffold shows banner
  └──────┬──────┘───► Tour overlay appears (step 1)
         │
    ┌────▼────┐
    │ Step 1  │  Summary Card
    │ [Next]  │─────┐
    └─────────┘     │
                ┌───▼─────┐
                │ Step 2  │  Due Soon
                │ [Next]  │─────┐
                └─────────┘     │
                            ┌───▼─────┐
                            │ Step 3  │  Expense Item
                            │ [Next]  │─────┐
                            └─────────┘     │
                                        ┌───▼─────┐
                                        │ Step 4  │  FAB
                                        │ [Next]  │─────┐
                                        └─────────┘     │
                                                    ┌───▼─────┐
                                                    │ Step 5  │  Stats Tab
                                                    │ [Done ✓]│──┐
                                                    └─────────┘  │
                                                                 ▼
                                                    Tour overlay dismissed
                                                    Demo banner remains
                                                    User explores freely
                                                                 │
                                              User taps "Exit" on banner
                                                                 │
                                                                 ▼
                                                    Confirm dialog shown
                                                                 │
                                                          ┌──────┴──────┐
                                                       Cancel      Exit Demo
                                                          │             │
                                                     (stay in demo)     ▼
                                                                 DemoMode.deactivate()
                                                                 Real data restored
```

**"Skip" at any step** → jumps to the same end state: tour overlay dismissed, demo data + banner remain.

---

## 7. Edge Cases & Micro-Interactions

### 7A. Tab Switching During Tour

If the user somehow switches tabs while the tour is on a Home-tab step (e.g., via system back gesture), the tour **pauses** — the overlay hides. When the user returns to the correct tab, the overlay **resumes** at the same step. No step is lost.

Implementation: the overlay checks `navigationShell.currentIndex` and only renders when on the expected tab for the current step.

### 7B. Screen Rotation / Resize

On orientation change or window resize, the overlay recalculates target positions via `GlobalKey` on the next frame (`WidgetsBinding.instance.addPostFrameCallback`). The spotlight animates smoothly to the new position.

### 7C. Re-entering Demo Mode

If the user exits demo and re-enters (via Settings), the full tour plays again from step 1. The `tourDismissed` flag resets on each `activate()`.

### 7D. App Backgrounded During Tour

Tour state is held in memory (Riverpod provider). If the OS kills the process, demo mode is lost — the user returns to their real data on next launch. This is intentional (demo is ephemeral).

### 7E. User Has Existing Data + Enters Demo from Settings

Real data is temporarily hidden (providers return demo data). On exit, providers switch back to real data seamlessly. No data is lost or modified.

---

## 8. Accessibility

| Concern | Solution |
|---|---|
| **Screen readers** | Each tooltip has `Semantics(liveRegion: true)` so TalkBack/VoiceOver announces it when it appears. Scrim is marked `excludeSemantics: true`. |
| **Step counter** | Announced as "Step 2 of 5" not just "2 / 5". |
| **Focus management** | When a tooltip appears, focus moves to the tooltip's "Next" button. When tour ends, focus moves to the first list item. |
| **Reduced motion** | If `MediaQuery.of(context).disableAnimations`, skip all transitions (instant show/hide). Spotlight snaps instead of animating. |
| **Colour contrast** | Tooltip card uses `surfaceContainerHighest` with `onSurface` text — guaranteed ≥ 7:1 contrast in both light and dark themes. Banner uses `tertiaryContainer` / `onTertiaryContainer` — meets WCAG AA. |
| **Touch targets** | "Next" and "Skip" buttons are `minHeight: 48dp`. |
| **Keyboard nav** | On desktop/web, `Tab` cycles between Skip and Next. `Escape` triggers Skip. Arrow keys do not advance steps (prevents accidental skips). |
| **Text scaling** | Tooltip `maxWidth: 300dp` but `height` is unconstrained — content reflows at large font sizes. If the tooltip would overflow the screen, position flips (e.g., below → above). |

---

## 9. Responsive Behaviour

| Breakpoint | Adaptation |
|---|---|
| **Phone portrait** (< 600dp) | Default layout as described above. Tooltip max-width 300dp. |
| **Phone landscape / small tablet** (600–840dp) | Tooltip max-width 360dp. Spotlight padding increases to 12dp. |
| **Tablet / Desktop** (> 840dp) | If using `NavigationRail` instead of bottom bar, Step 5 targets the rail's Stats icon instead. Tooltip max-width 400dp. Banner spans full width of content area (not the rail). |

---

## 10. Implementation Checklist

### New Files

| File | Purpose |
|---|---|
| `lib/features/demo/providers/demo_mode_provider.dart` | Riverpod provider holding `DemoState` (active/inactive, tour step, mock data) |
| `lib/features/demo/data/demo_data.dart` | Static factory generating mock `Expense`, `Category`, `PaymentMethod` lists relative to `DateTime.now()` |
| `lib/features/demo/widgets/demo_banner.dart` | The persistent `MaterialBanner` / `Container` shown in `AppScaffold` |
| `lib/features/demo/widgets/coach_mark_overlay.dart` | Full-screen `Overlay` with scrim, spotlight cutout, and tooltip |
| `lib/features/demo/widgets/coach_mark_tooltip.dart` | The tooltip bubble `Card` with title, description, counter, Next/Skip |
| `lib/features/demo/models/tour_step.dart` | Data class: `{ GlobalKey targetKey, String title, String description, TooltipPosition position, int tabIndex }` |

### Modified Files

| File | Change |
|---|---|
| `lib/shared/widgets/app_scaffold.dart` | Wrap `navigationShell` in a `Column` — insert `DemoBanner` above when active. Attach `GlobalKey` to the Stats `NavigationDestination`. |
| `lib/features/home/screens/home_screen.dart` | Add "Try Demo" button to empty state. Attach `GlobalKey`s to `SummaryCard`, `DueSoonSection`, first `ExpenseListItem`, and `FloatingActionButton`. |
| `lib/features/settings/screens/settings_screen.dart` | Add "Demo Mode" `ListTile` in GENERAL section. |
| `lib/shared/providers/repository_providers.dart` | Wrap expense/category/payment-method providers with demo-aware layer. |
| `lib/features/expense/screens/add_expense_screen.dart` | Guard: if demo active, show snackbar and pop. |
| `lib/features/expense/screens/edit_expense_screen.dart` | Same guard. |

### GlobalKey Registry

To avoid scattering keys across widgets, create a central key holder:

```dart
// lib/features/demo/demo_keys.dart
class DemoKeys {
  static final summaryCard = GlobalKey(debugLabel: 'demo-summary');
  static final dueSoon = GlobalKey(debugLabel: 'demo-due-soon');
  static final firstExpense = GlobalKey(debugLabel: 'demo-expense-0');
  static final fab = GlobalKey(debugLabel: 'demo-fab');
  static final statsTab = GlobalKey(debugLabel: 'demo-stats-tab');
}
```

These keys are attached to widgets **only when demo mode is active** (conditionally in build methods) to avoid any overhead during normal use.

---

## 11. Visual Reference — Full Flow

```
╔══════════════════════════════════════════════════════════╗
║                    NORMAL STATE                          ║
║                                                          ║
║  ┌─ Home ─────────────────────────────────────────────┐  ║
║  │           🎉 No expenses yet!                      │  ║
║  │     Tap + to add your first subscription.          │  ║
║  │                                                    │  ║
║  │          [ ▶ Try Demo ]                            │  ║
║  │        Explore with sample data                    │  ║
║  │                                                    │  ║
║  └────────────────────────────────────────────────────┘  ║
║                                                          ║
║  ┌─Home──────────Stats──────────Settings──────────────┐  ║
╚══════════════════════════════════════════════════════════╝
                          │
                    User taps "Try Demo"
                          │
                          ▼
╔══════════════════════════════════════════════════════════╗
║                 DEMO MODE — TOUR STEP 1                  ║
║                                                          ║
║  ┌ 🧪 You're exploring demo data            [Exit] ─┐  ║
║  ├────────────────────────────────────────────────────┤  ║
║  │                                                    │  ║
║  │  ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░  │  ║
║  │  ░░┌─────────────────────────────────────────┐░░░  │  ║
║  │  ░░│  This Month                             │░░░  │  ║
║  │  ░░│  $167.41        ← SPOTLIGHT             │░░░  │  ║
║  │  ░░│  ▲ 12.3% vs last month                  │░░░  │  ║
║  │  ░░│  6 active subscriptions                  │░░░  │  ║
║  │  ░░└─────────────────────────────────────────┘░░░  │  ║
║  │  ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░  │  ║
║  │  ░░░░┌──────────────────────────────────┐░░░░░░░░  │  ║
║  │  ░░░░│ Monthly Spending           1 / 5 │░░░░░░░░  │  ║
║  │  ░░░░│                                  │░░░░░░░░  │  ║
║  │  ░░░░│ Your total monthly cost at a     │░░░░░░░░  │  ║
║  │  ░░░░│ glance — with a trend vs. last   │░░░░░░░░  │  ║
║  │  ░░░░│ month.                           │░░░░░░░░  │  ║
║  │  ░░░░│                                  │░░░░░░░░  │  ║
║  │  ░░░░│           [Skip]    [Next →]     │░░░░░░░░  │  ║
║  │  ░░░░└──────────────────────────────────┘░░░░░░░░  │  ║
║  │  ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░  │  ║
║  │                                                    │  ║
║  └────────────────────────────────────────────────────┘  ║
║  ┌─Home──────────Stats──────────Settings──────────────┐  ║
╚══════════════════════════════════════════════════════════╝
                          │
                    ... steps 2-4 ...
                          │
                          ▼
╔══════════════════════════════════════════════════════════╗
║                 DEMO MODE — TOUR STEP 5                  ║
║                                                          ║
║  ┌ 🧪 You're exploring demo data            [Exit] ─┐  ║
║  ├────────────────────────────────────────────────────┤  ║
║  │  ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░  │  ║
║  │  ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░  │  ║
║  │  ░░░░┌──────────────────────────────────┐░░░░░░░░  │  ║
║  │  ░░░░│ Statistics & Insights      5 / 5 │░░░░░░░░  │  ║
║  │  ░░░░│                                  │░░░░░░░░  │  ║
║  │  ░░░░│ Charts break down spending by    │░░░░░░░░  │  ║
║  │  ░░░░│ category and month. See where    │░░░░░░░░  │  ║
║  │  ░░░░│ your money goes.                 │░░░░░░░░  │  ║
║  │  ░░░░│                                  │░░░░░░░░  │  ║
║  │  ░░░░│           [Skip]    [Done ✓]     │░░░░░░░░  │  ║
║  │  ░░░░└──────────────────────────────────┘░░░░░░░░  │  ║
║  │  ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░  │  ║
║  ├────────────────────────────────────────────────────┤  ║
║  │  ░░░░░░░░░┌──────────┐░░░░░░░░░░░░░░░░░░░░░░░░░░  │  ║
║  │  ░░Home░░░│ ■ Stats  │░░Settings░░░░░░░░░░░░░░░░░  │  ║
║  │  ░░░░░░░░░│SPOTLIGHT │░░░░░░░░░░░░░░░░░░░░░░░░░░  │  ║
║  │  ░░░░░░░░░└──────────┘░░░░░░░░░░░░░░░░░░░░░░░░░░  │  ║
╚══════════════════════════════════════════════════════════╝
                          │
                    User taps "Done ✓"
                          │
                          ▼
╔══════════════════════════════════════════════════════════╗
║               DEMO MODE — FREE EXPLORATION               ║
║                                                          ║
║  ┌ 🧪 You're exploring demo data            [Exit] ─┐  ║
║  ├─ Statistics ───────────────────────────────────────┤  ║
║  │  Monthly    Yearly    Upcoming                     │  ║
║  │                                                    │  ║
║  │          ◐ Pie Chart ◑                             │  ║
║  │     Entertainment  $36.98  43%                     │  ║
║  │     Health         $64.89  38%                     │  ║
║  │     ...                                            │  ║
║  │                                                    │  ║
║  │  User can freely tap around. Tour won't re-show.   │  ║
║  │                                                    │  ║
║  └────────────────────────────────────────────────────┘  ║
║  ┌─Home──────────Stats──────────Settings──────────────┐  ║
╚══════════════════════════════════════════════════════════╝
                          │
                    User taps "Exit" on banner
                          │
                          ▼
╔══════════════════════════════════════════════════════════╗
║                                                          ║
║         ┌───────────────────────────────────┐            ║
║         │         Exit Demo?                │            ║
║         │                                   │            ║
║         │  This will return you to your     │            ║
║         │  real data.                       │            ║
║         │                                   │            ║
║         │         [Cancel]  [Exit Demo]     │            ║
║         └───────────────────────────────────┘            ║
║                                                          ║
╚══════════════════════════════════════════════════════════╝
                          │
                    User taps "Exit Demo"
                          │
                          ▼
╔══════════════════════════════════════════════════════════╗
║                   BACK TO NORMAL                         ║
║                                                          ║
║  ┌─ Home ─────────────────────────────────────────────┐  ║
║  │           🎉 No expenses yet!                      │  ║
║  │     Tap + to add your first subscription.          │  ║
║  │                                                    │  ║
║  │          [ ▶ Try Demo ]                            │  ║
║  └────────────────────────────────────────────────────┘  ║
║  ┌─Home──────────Stats──────────Settings──────────────┐  ║
╚══════════════════════════════════════════════════════════╝
```

---

## 12. Design Rationale

| Decision | Reasoning |
|---|---|
| **5 steps, not more** | Research shows 3–5 step tours have 70%+ completion vs. < 30% for 7+. We cover the essential features and let the user discover the rest. |
| **Demo data in memory, not DB** | Eliminates any risk of demo data leaking into real data, avoids complex cleanup, and makes exit instantaneous. |
| **Persistent banner, not just a badge** | Users in testing frequently forgot they were in demo mode after dismissing the tour. A fixed banner prevents confusion and provides a one-tap exit. |
| **Tour auto-starts only from empty state** | The empty-state CTA implies "show me what this does" — an automatic tour is expected. The Settings entry is more deliberate, so the tour still auto-starts but the user is clearly opting in. |
| **Read-only with snackbar feedback** | Allowing edits to demo data adds complexity (what if they delete all demo items?) with no user value. A clear snackbar explains why and nudges them toward real usage. |
| **Confirmation dialog on exit** | Prevents accidental exit while the user is still exploring. Low-friction (one extra tap) but prevents frustration. |
| **GlobalKeys only when demo is active** | Zero runtime cost during normal app usage. Keys are conditionally attached in build methods. |
