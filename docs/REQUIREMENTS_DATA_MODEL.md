---
title: Every-Pay — Data Model Specification
version: 1.0.0
created: 2026-02-24
owner: Product
status: Draft
---

# Every-Pay — Data Model Specification

## Database

- **Engine**: SQLite (via `drift` or `sqflite` package)
- **Encryption**: SQLCipher (AES-256)
- **Location**: App-private storage (not accessible to other apps)
- **Schema version**: 1 (migrations handled by drift)

---

## Entity: Expense

Primary table for all recurring expense records.

```sql
CREATE TABLE expenses (
  id              TEXT PRIMARY KEY,        -- UUID v4
  name            TEXT NOT NULL,           -- Display name (e.g., "Netflix")
  provider        TEXT,                    -- Provider name (e.g., "Netflix Inc.")
  category_id     TEXT NOT NULL,           -- FK -> categories.id
  amount          REAL NOT NULL,           -- Cost per billing cycle
  currency        TEXT NOT NULL DEFAULT 'USD',  -- ISO 4217 code
  billing_cycle   TEXT NOT NULL,           -- Enum: weekly|fortnightly|monthly|quarterly|biannual|yearly|custom
  custom_days     INTEGER,                 -- Only if billing_cycle = 'custom'
  start_date      TEXT NOT NULL,           -- ISO 8601 date
  end_date        TEXT,                    -- ISO 8601 date, nullable
  next_due_date   TEXT,                    -- Calculated, cached for performance
  status          TEXT NOT NULL DEFAULT 'active',  -- active|paused|cancelled
  notes           TEXT,                    -- Free-form text
  logo_asset      TEXT,                    -- Asset path or URL for service logo
  created_at      TEXT NOT NULL,           -- ISO 8601 datetime
  updated_at      TEXT NOT NULL,           -- ISO 8601 datetime
  device_id       TEXT NOT NULL,           -- Origin device UUID
  is_deleted      INTEGER NOT NULL DEFAULT 0  -- Soft delete flag (for sync)
);
```

---

## Entity: Category

User-defined and default groupings for expenses.

```sql
CREATE TABLE categories (
  id              TEXT PRIMARY KEY,        -- UUID v4
  name            TEXT NOT NULL UNIQUE,    -- Display name
  icon            TEXT NOT NULL,           -- Material icon name or code point
  colour          TEXT NOT NULL,           -- Hex colour string (#RRGGBB)
  is_default      INTEGER NOT NULL DEFAULT 0,  -- 1 = pre-seeded, 0 = user-created
  sort_order      INTEGER NOT NULL DEFAULT 0,
  created_at      TEXT NOT NULL,
  updated_at      TEXT NOT NULL,
  device_id       TEXT NOT NULL,
  is_deleted      INTEGER NOT NULL DEFAULT 0
);
```

**Default categories (seeded on first launch):**

| ID (stable) | Name | Icon | Colour |
|-------------|------|------|--------|
| `cat-entertainment` | Entertainment & Streaming | play_circle | #E53935 |
| `cat-utilities` | Utilities & Bills | bolt | #1E88E5 |
| `cat-insurance` | Insurance | security | #43A047 |
| `cat-software` | Software & Cloud | cloud | #8E24AA |
| `cat-health` | Health & Fitness | favorite | #F4511E |
| `cat-finance` | Finance & Banking | account_balance | #00897B |
| `cat-food` | Food & Groceries | shopping_cart | #FB8C00 |
| `cat-education` | Education | school | #3949AB |
| `cat-transport` | Transportation | directions_car | #757575 |
| `cat-other` | Other | category | #546E7A |

---

## Entity: Tag

Tags are stored as a join table (many-to-many with expenses).

```sql
CREATE TABLE tags (
  id              TEXT PRIMARY KEY,
  name            TEXT NOT NULL UNIQUE,    -- Tag name (lowercase normalised)
  created_at      TEXT NOT NULL
);

CREATE TABLE expense_tags (
  expense_id      TEXT NOT NULL,           -- FK -> expenses.id
  tag_id          TEXT NOT NULL,           -- FK -> tags.id
  PRIMARY KEY (expense_id, tag_id)
);
```

---

## Entity: Service Template

Pre-defined service library (read-only, bundled with the app).

```dart
// Stored as in-memory/asset data, NOT in the SQLite database
class ServiceTemplate {
  final String id;
  final String name;
  final String provider;
  final String defaultCategoryId;
  final String defaultBillingCycle;
  final double? suggestedAmount;       // null = varies by plan
  final String logoAsset;             // bundled asset path
  final String? websiteUrl;
}
```

**Sample templates:**

| ID | Name | Category | Default Cycle |
|----|------|----------|---------------|
| `tpl-netflix` | Netflix | cat-entertainment | monthly |
| `tpl-spotify` | Spotify | cat-entertainment | monthly |
| `tpl-disney-plus` | Disney+ | cat-entertainment | monthly |
| `tpl-apple-music` | Apple Music | cat-entertainment | monthly |
| `tpl-youtube-premium` | YouTube Premium | cat-entertainment | monthly |
| `tpl-hbo-max` | HBO Max | cat-entertainment | monthly |
| `tpl-amazon-prime` | Amazon Prime | cat-entertainment | yearly |
| `tpl-icloud` | iCloud+ | cat-software | monthly |
| `tpl-google-one` | Google One | cat-software | monthly |
| `tpl-microsoft-365` | Microsoft 365 | cat-software | yearly |
| `tpl-dropbox` | Dropbox | cat-software | monthly |
| `tpl-adobe-cc` | Adobe Creative Cloud | cat-software | monthly |
| `tpl-electricity` | Electricity | cat-utilities | monthly |
| `tpl-gas` | Gas | cat-utilities | monthly |
| `tpl-water` | Water | cat-utilities | monthly |
| `tpl-internet` | Internet | cat-utilities | monthly |
| `tpl-phone-plan` | Phone Plan | cat-utilities | monthly |
| `tpl-health-insurance` | Health Insurance | cat-insurance | monthly |
| `tpl-car-insurance` | Car Insurance | cat-insurance | yearly |
| `tpl-home-insurance` | Home Insurance | cat-insurance | yearly |
| `tpl-life-insurance` | Life Insurance | cat-insurance | monthly |
| `tpl-gym` | Gym Membership | cat-health | monthly |
| `tpl-apple-fitness` | Apple Fitness+ | cat-health | monthly |

---

## Entity: Device (Sync)

Paired devices for household sync.

```sql
CREATE TABLE paired_devices (
  device_id       TEXT PRIMARY KEY,        -- Remote device UUID
  device_name     TEXT NOT NULL,           -- Human-readable name
  paired_at       TEXT NOT NULL,           -- ISO 8601 datetime
  last_sync_at    TEXT,                    -- Last successful sync
  key_alias       TEXT NOT NULL,           -- Android Keystore alias for shared key
  status          TEXT NOT NULL DEFAULT 'active'  -- active|removed
);
```

---

## Entity: Sync State

Tracks sync position per paired device.

```sql
CREATE TABLE sync_state (
  device_id       TEXT PRIMARY KEY,        -- FK -> paired_devices.device_id
  last_sent_at    TEXT,                    -- Timestamp of last change we sent
  last_received_at TEXT                   -- Timestamp of last change we received
);
```

---

## Entity: Sync Conflict Log

Audit log for resolved conflicts (debugging / transparency).

```sql
CREATE TABLE sync_conflict_log (
  id              TEXT PRIMARY KEY,
  entity_type     TEXT NOT NULL,           -- 'expense' | 'category'
  entity_id       TEXT NOT NULL,
  conflict_type   TEXT NOT NULL,           -- 'last_write_wins' | 'delete_vs_edit'
  winning_device  TEXT NOT NULL,
  losing_device   TEXT NOT NULL,
  resolved_at     TEXT NOT NULL
);
```

---

## Entity: User Preferences

App-level settings stored locally.

```sql
CREATE TABLE preferences (
  key             TEXT PRIMARY KEY,
  value           TEXT NOT NULL,
  updated_at      TEXT NOT NULL
);
```

**Preference keys:**

| Key | Default | Description |
|-----|---------|-------------|
| `default_currency` | `USD` (device locale) | Default currency for new expenses |
| `theme_mode` | `system` | `light` / `dark` / `system` |
| `app_lock_enabled` | `false` | Biometric lock on/off |
| `app_lock_timeout` | `immediate` | `immediate` / `1min` / `5min` |
| `sync_enabled` | `false` | Whether sync is turned on |
| `onboarding_complete` | `false` | Has user seen onboarding |
| `stats_default_view` | `monthly` | Default stats tab |

---

## Calculated Fields

These fields are computed at read time (not stored, except `next_due_date` which is cached):

| Field | Formula |
|-------|---------|
| `next_due_date` | `start_date + (N * billing_cycle_days)` where N = next occurrence after today |
| `monthly_cost` | Normalised to monthly: `amount * cycle_multiplier` |
| `yearly_cost` | `monthly_cost * 12` |
| `total_paid` | Sum of all payment occurrences from `start_date` to today |
| `is_expiring_soon` | `end_date` within next 30 days |
| `is_expired` | `end_date` < today |

**Billing cycle multipliers (to monthly):**

| Cycle | Multiplier |
|-------|-----------|
| Weekly | 52/12 ≈ 4.333 |
| Fortnightly | 26/12 ≈ 2.167 |
| Monthly | 1.0 |
| Quarterly | 1/3 ≈ 0.333 |
| Bi-annual | 1/6 ≈ 0.167 |
| Yearly | 1/12 ≈ 0.083 |
| Custom (N days) | 365/(N*12) |

---

## Data Export Schema (CSV)

Columns in order:
```
id, name, provider, category, amount, currency, billing_cycle, start_date, end_date, next_due_date, status, notes, tags, created_at
```

---

## Data Export Schema (JSON)

```json
{
  "export_version": "1",
  "exported_at": "2026-02-24T20:00:00Z",
  "device_id": "<uuid>",
  "expenses": [ { ...expense fields... } ],
  "categories": [ { ...category fields... } ],
  "preferences": { ...key: value... }
}
```
