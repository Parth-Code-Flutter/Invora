# Creovo Billing — Production Roadmap

Last reviewed: 2026-08-27  
Target: Public Android and iOS release for real end-users  
Product boundary: Fast, private, offline GST invoicing—not full accounting

## Purpose

This document defines what remains before Creovo Billing is safe and complete
for public use. It separates launch requirements from later competitive
features so the product stays simple.

The live implementation status remains in [PROJECT_HANDOFF.md](PROJECT_HANDOFF.md).
The fixed V1 scope remains in
[CODEX_IMPLEMENTATION_PLAN.md](CODEX_IMPLEMENTATION_PLAN.md).
The approved post-foundation market priorities and their offline behavior are
defined in
[OFFLINE_MARKET_EXPANSION_ROADMAP.md](OFFLINE_MARKET_EXPANSION_ROADMAP.md).

## First feature we are picking

### Payment-ledger integrity and payment workflow

This is the first priority because payment data affects invoice status,
outstanding balances, customer accounts, reports, receipts, and user trust.

Current concern:

- A payment can be entered while creating/editing an invoice.
- Payments can also be recorded from Invoice Details.
- Editing the cumulative paid amount can create positive or negative
  `Adjustment` rows, mixing actual payments with reconciliation events.

Required final behaviour:

1. A new invoice may optionally include one clearly labelled opening payment.
2. After an invoice is created, payments are recorded only from Invoice
   Details.
3. A payment record is immutable after it is saved.
4. Incorrect payments use an explicit `Reverse payment` action.
5. Reversal requires confirmation and a reason and creates an auditable linked
   reversal entry; it never silently deletes history.
6. Invoice paid amount, balance, and status are derived from the ledger.
7. Payment history clearly distinguishes payment, opening payment, and
   reversal.
8. Quotations cannot receive payments.
9. Cancelled invoices cannot receive payments.
10. Editing invoice items/totals after payments requires a clear warning and
    must never produce an impossible paid balance.

Acceptance criteria:

- Partial and full payments produce the correct balance and status.
- Overpayment is impossible.
- Payment history always reconciles exactly to the invoice paid amount.
- Reversal restores the correct balance/status and remains visible in history.
- Existing schema-v7 payments migrate without loss.
- Repository, controller, widget, migration, and integration tests cover the
  complete flow.

Follow-up enabled by this work:

- Payment receipt PDF
- Customer statement
- Reliable outstanding reports
- Payment export

## Public-launch requirements

### P0 — Financial and data safety

#### 1. Payment-ledger integrity

Status: **Implemented, including V5/V6/V7 migration fixtures through schema v8**
Scope: Defined above.

#### 2. Database migration verification

Status: **Implemented for every historical launch schema through v8**

- Realistic V5 plus targeted V6 and V7 fixtures exercise direct upgrades to v8.
- Unpaid, partially paid, and fully paid totals, imported opening payments,
  invoice items, and additional charges are verified after migration.
- A deliberately invalid legacy schema verifies that a migration failure is
  surfaced while preserving the source version and user row for recovery.

#### 3. Backup safety

Status: **Implemented for V1 launch safety**

- Warn before export that backups contain customer, invoice, bank, signature,
  and QR information and require a password to open.
- Show the last successful backup date and whether a backup is due.
- Provide configurable 7/14/30-day local reminders, surfaced on the dashboard.
- Cover damaged, incomplete, old-version, newer-version, successful restore,
  and failed database-replacement rollback behaviour with automated tests.
- Password-protected backups (AES-256-GCM) with verify-without-restore, restore
  preview, five local generations, and legacy unencrypted ZIP restore.
- Restore completion now provides explicit, non-dismissible restart guidance.

#### 4. Unsaved-change protection

Status: **Implemented for all data-entry routes**

- Invoice, customer, product/service, and business forms compare their current
  state with the loaded/saved baseline.
- Back buttons, Android system back, and iOS back gestures use one consistent
  `Continue editing` / `Discard` confirmation.
- Invoice and quotation composers additionally offer `Save draft` before
  leaving, and clean or successfully saved forms exit without a warning.
- Data-entry routes do not expose the main bottom navigation, preventing an
  unguarded tab switch while editing.

### P0 — Release engineering and compliance

#### 5. Production signing and artifacts

- Replace Android debug release signing with a secure upload key.
- Keep signing credentials outside Git.
- Generate, install, and test a release AAB.
- Configure iOS distribution signing and archive successfully.
- Upload beta builds to Play closed testing and TestFlight.
- Confirm package/bundle ownership and version/build-number strategy.
- Confirm the final Android artifact meets the current target API requirement.

#### 6. Privacy and store documentation

- Publish a privacy-policy URL.
- Add in-app Privacy, Data & Backup, Help, and Support screens.
- Complete Google Play Data Safety declarations.
- Complete Apple App Privacy declarations.
- Review/add the required iOS privacy manifest.
- Audit every dependency for collection, transmission, permissions, and
  required-reason APIs.
- Explain that app records stay on-device and may be lost after uninstall if
  not backed up.

#### 7. End-to-end release tests

Status: **Automated offline lifecycle active; native device pass remains**

Automate and physically test:

1. Onboarding and business setup
2. Contact import and customer CRUD
3. Product/service and unit CRUD
4. GST and non-GST invoice creation
5. Edit, duplicate, cancel, and delete
6. Partial/full payment and reversal
7. Quotation creation and conversion
8. All PDF templates, save, share, and print
9. Backup and restore
10. App/database upgrade

The repeatable status and remaining physical-device cases are tracked in
[QA_CHECKLIST.md](QA_CHECKLIST.md).

### P1 — Features required for a complete V1 experience

#### 8. Payment receipts

Status: **Implemented**

- Generate an offline A5 receipt PDF after a payment with a stable receipt
  number, invoice/customer/business identity, amount, date, method, reference,
  and remaining balance.
- Show a receipt-roll print animation immediately after payment, matching the
  supplied reference's gold printer, descending paper, success reveal, replay,
  and receipt action feel.
- Preview, save, share, and print from the receipt workspace, and reopen valid
  historical receipts from payment activity.
- Reversed payments are visibly marked and cannot produce active receipts.

#### 9. Customer statements

Status: **Implemented**

- Date-range customer account statement with opening balance, invoices,
  payments, reversals, and running/closing balance.
- Cancelled invoices are excluded; reversals restore debit without erasing the
  original payment history.
- Customer Details opens the account-style statement workspace with date
  controls, totals, chronological activity, and offline PDF preview/save/share/
  print actions.

#### 10. Data export

Status: **Implemented**

- CSV export for customers, products/services, invoices, and payments.
- Date-range CSV/PDF export for reports.
- Clearly document fields and date/currency formats.
- The Export Data workspace provides native save/share actions, Excel-friendly
  UTF-8 CSV, ISO dates, decimal major-unit amounts, tax/status/payment columns,
  and a Unicode A4 report PDF. Invoice ranges use invoice date and payment
  ranges use ledger-entry date.

#### 11. Invoice defaults

Status: **Implemented**

- Default due period: immediate, 7, 15, 30 days, or custom.
- Default GST rate and tax mode.
- Default notes and terms.
- Default payment method.
- Existing default unit and PDF template remain part of this settings group.
- Include every new preference in backup/restore.
- Settings now provides one focused Invoice Defaults workspace. New invoices
  and estimates inherit the due period, tax mode, notes, and terms; custom
  items inherit the GST rate; payment recording inherits the payment method.
  Saved documents and catalog GST rates remain unchanged.

## Existing features that need improvement

### Invoice creation

- Scroll to and highlight the first invalid section instead of relying only on
  a notification.
- Show inline customer/item errors.
- Keep custom-item editing as a sheet only while it remains short; use a
  full-screen route if more fields are added.
- Ensure the opening-payment field is shown only during new invoice creation
  after the payment-ledger redesign.
- Warn before changing totals on an invoice that already has payments.

### Invoice list and details

- Add faster status/date sorting if beta users need it.
- Make overdue state and balance due visually stronger than neutral metadata.
- Keep actions status-aware so invalid operations are not merely hidden in
  menus without explanation.
- Show payment receipt/reversal actions directly in payment history.

### Customers

- Customer list should remain direct and uncluttered after removal of the
  decorative top banner.
- Add customer statement export after ledger integrity is complete.
- Warn before deleting a customer with invoice history while preserving
  historical snapshots.
- Consider duplicate-mobile detection with an intentional override.

### Products, services, units, and GST

- Keep one centralized GST preset list across all forms.
- Preserve `Custom rate` for notified exceptions.
- Add optional default GST rate in Settings.
- Warn when renaming/deleting a unit that catalog records still use; historical
  invoices must remain unchanged.
- Consider duplicate product-name detection without blocking legitimate
  variants.

### PDF documents

- Visually test all five templates, not only byte generation.
- Cover 1, 20, and 100 line items; multi-page breaks; long names; long
  addresses; discounts; charges; GST/non-GST; Unicode; logos; signatures; and
  payment QR images.
- Verify A4 printing on Android/iOS and common printers.
- Ensure quotation, invoice, receipt, and statement document labels cannot be
  confused.

### Reports and dashboard

- Derive received/outstanding totals from the finalized payment ledger.
- Add date-range filters and export.
- Show meaningful empty states instead of zero-heavy dashboards.
- Avoid adding full accounting, profit/loss, inventory, or GST filing reports
  during V1.

### Backup and restore

- Make the last-backup state visible in Settings/dashboard.
- Add a prominent sensitive-data warning before sharing.
- Verify settings, managed units, template choice, and media restore together.
- Add automated compatibility tests for every released backup version.

## UI/UX production checklist

### Visual hierarchy

- Use one consistent primary treatment for final actions.
- Reserve teal for paid/success, red for errors/destructive actions, and
  gradients for limited identity surfaces.
- Avoid duplicate headers, summary banners, or two equal create actions on one
  screen.
- Keep list screens dense enough for business data without becoming ERP-like.

### Navigation and actions

- Central dock `+` should act as the global quick-create action.
- Use a screen FAB only when that screen's primary create action needs constant
  reachability.
- Avoid stacking nested sheet → dialog → sheet flows where a route is clearer.
- Keep back behaviour predictable and protect unsaved work.

### Forms and validation

- Required fields show `*` consistently.
- Errors appear under the relevant field/section.
- Final validation scrolls to the first problem.
- Numeric fields use appropriate keyboard, formatting, limits, and examples.
- Destructive confirmations explain exactly what remains and what is removed.

### Accessibility and responsive QA

- Test TalkBack and VoiceOver.
- Test 100%, 150%, and 200% text scale.
- Maintain minimum touch targets and sufficient contrast.
- Test small Android phones, large iPhones, tablets, and landscape.
- Test long customer/item/business names and translated-length labels.
- Ensure keyboard opening and sheet dismissal never overflow or use disposed
  controllers.

### First-use experience

- Use contextual empty states for the first customer, item, invoice, payment,
  and backup.
- Keep onboarding short and show an early backup warning.
- Provide sample guidance as hints—not persisted placeholder data.

## Post-launch candidates

Prioritize only after public V1 is stable:

- Recurring invoices
- Local due-date notifications
- One-tap WhatsApp/email reminder templates
- Sales credit notes shipped 2026-08-27 (see PROJECT_HANDOFF.md); purchase
  returns/debit notes and restock remain later work
- Proforma invoice and delivery challan
- Multiple businesses
- Additional languages
- Thermal receipt layouts
- Expense tracking if validated by real users

## Explicitly out of V1 scope

- Inventory/warehouse management
- Purchases and suppliers
- Payroll
- Full bookkeeping/accounting
- GST return filing
- E-invoice and e-way bill integration
- Online payment gateway
- Mandatory cloud account/sync
- Multi-user roles and web dashboard

## Recommended execution order

1. Payment-ledger integrity and reversal workflow
2. Migration fixtures and financial-data tests
3. Unsaved-change protection
4. Payment receipts
5. Customer statements
6. Backup warning, last-backup state, and compatibility tests
7. Invoice defaults and CSV/report export
8. Privacy/help/support surfaces
9. Release signing and release artifacts
10. End-to-end, PDF visual, accessibility, and physical-device QA
11. Closed beta with 10–20 real businesses
12. Fix beta findings and submit public V1

## Definition of ready for public launch

Creovo Billing is ready when:

- Financial totals and payment ledger always reconcile.
- Every database/backup migration path is tested.
- Users cannot accidentally lose unsaved or unbacked-up work without warning.
- Android and iOS release builds are signed, installable, and beta-tested.
- Privacy/store declarations are complete and accurate.
- Main flows pass automated end-to-end and physical-device tests.
- PDFs pass visual QA for realistic edge cases.
- Accessibility and responsive layouts pass the production checklist.
- No P0 issue remains open after the closed beta.
