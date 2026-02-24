---
title: Every-Pay — User Personas
version: 1.0.0
created: 2026-02-24
owner: Product
status: Draft
---

# Every-Pay — User Personas

## Persona 1: The Household Manager — "Maya"

**Age:** 34  
**Situation:** Married with two kids; manages family finances  
**Devices:** Android phone, partner has Android phone  
**Technical comfort:** Moderate — uses banking apps, Google Drive, comfortable with apps

### Goals
- Know exactly what the household pays every month
- Avoid bill surprise or forgotten auto-renewals
- Share expense visibility with partner without sharing passwords
- Quickly see if a subscription is worth keeping

### Pain Points
- Has 12+ subscriptions across different accounts
- Partner sometimes signs up for services she doesn't know about
- Has been double-charged for the same service twice
- Spends 30+ minutes each month manually totalling recurring costs

### How She Uses Every-Pay
- Sets up household sync with her partner on home Wi-Fi
- Pre-fills Netflix, Spotify, water bill from the service library
- Adds notes to insurance subscriptions ("up for renewal July 2026")
- Checks monthly stats dashboard weekly to stay on budget
- Uses categories to see "are we spending too much on streaming?"

---

## Persona 2: The Budget-Conscious Individual — "Kenji"

**Age:** 27  
**Situation:** Single, renting, early-career professional  
**Devices:** Android phone  
**Technical comfort:** High — uses budgeting apps, privacy-conscious

### Goals
- Audit and reduce monthly recurring spend
- Track exactly when trials end (to cancel before being charged)
- Never pay for something forgotten and unused
- Keep financial data private, off cloud services

### Pain Points
- Signed up for 3 free trials, forgot to cancel, was charged for all 3
- Doesn't trust cloud-based finance apps with his bank data
- Can't easily see "how much do I actually spend per year on subscriptions?"
- Wants end-date reminders for fixed-term subscriptions

### How He Uses Every-Pay
- Privacy-first: loves that data never leaves the device
- Uses end_date field religiously for trial tracking
- Filters by "Entertainment" to audit streaming spend
- Uses the yearly chart to see seasonal spending patterns
- Exports CSV monthly to compare with bank statements

---

## Persona 3: The Retired Couple — "Barbara & Tom"

**Age:** 68 & 71  
**Situation:** Retired couple on fixed income; very careful about spending  
**Devices:** Each has an Android phone; shares home Wi-Fi  
**Technical comfort:** Low — prefers simple, clear interfaces

### Goals
- Track fixed household bills without complexity
- Share a view of what bills are coming up
- Understand yearly spend for tax / budgeting purposes

### Pain Points
- Overwhelmed by complex budgeting apps
- Need large text and clear visuals
- Finds it hard to remember what services they've subscribed to
- Worried about financial data privacy

### How They Use Every-Pay
- Tom sets up expenses; Barbara can view on her phone
- Mostly uses pre-defined templates (water, electricity, phone plan)
- Relies on "Upcoming Payments" view to know what to budget this week
- Never needs the advanced features — just the basics done clearly

---

## Persona 4: The Small Business Owner — "Priya"

**Age:** 42  
**Situation:** Freelancer / small business; tracks both personal and business subscriptions  
**Devices:** Android phone, wants to share with bookkeeper on same office network  
**Technical comfort:** High

### Goals
- Separate personal vs. business recurring expenses
- Know total business SaaS spend for accounting purposes
- Quickly generate a CSV for her accountant each quarter
- Keep business data local, not in a third-party SaaS

### Pain Points
- SaaS costs have ballooned — needs visibility fast
- Accountant asks for "all your subscriptions" every quarter — painful to compile
- Uses 8+ business tools (Slack, Figma, Notion, Zoom, etc.)
- Can't easily break down which are business vs. personal

### How She Uses Every-Pay
- Creates custom categories: "Business Software", "Personal"
- Tags expenses with `#deductible` for tax filtering
- Uses CSV export for accountant
- Syncs with office laptop via local network
- Uses notes field to track renewal contacts and contract terms

---

## Summary Table

| Attribute | Maya | Kenji | Barbara & Tom | Priya |
|-----------|------|-------|---------------|-------|
| Primary use | Household tracking | Audit & privacy | Simple bill tracking | Business + personal |
| Sync needed | ✅ Yes (partner) | ❌ No | ✅ Yes (couple) | ✅ Yes (bookkeeper) |
| Technical level | Moderate | High | Low | High |
| Most valued feature | Sync + shared view | Privacy + export | Simplicity + upcoming | Categories + export |
| Key concern | Subscription sprawl | Privacy | Simplicity | Accounting accuracy |
