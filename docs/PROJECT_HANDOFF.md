# Creovo Invoice — Project Handoff

Last updated: 2026-08-10  
Active development branch: `parth-dev`  
Product specification: [CODEX_IMPLEMENTATION_PLAN.md](CODEX_IMPLEMENTATION_PLAN.md)

## Purpose

This document records the live application state so development can continue
safely from another computer or Codex session. Update it in the same commit as
every material code change.

## Product boundaries

Creovo Invoice is a Flutter Android and iOS app for fast, privacy-first,
offline invoicing. It has no backend, authentication, cloud dependency, ads,
subscriptions, payment gateway, inventory accounting, or multi-user system.

- Flutter and Dart
- GetX for routing, dependency injection, and reactive state
- Drift/SQLite for local business data
- `AppStorage`/SharedPreferences for lightweight settings
- Local PDF generation, preview, save, share, and print

## Current implementation

### Application foundation

- First-launch onboarding and business setup
- Business profile, logo, signature, payment QR, bank, and UPI information
- Responsive phone/tablet layouts and dark mode
- Reusable fields, dropdown sheets, navigation, and modern notifications
- Offline backup/restore with validation and database rollback

### Customers

- Create, search, edit, view, and soft-delete customers
- Mobile length/format and email regex validation
- GSTIN, address, company, and optional notes support
- Create-customer action directly inside invoice customer selection

### Products and services

- Create, search, filter, edit, view, and soft-delete products/services
- Price, description, HSN/SAC, GST rate, type, and unit support
- Shared saved-unit picker with persistent custom-unit creation

### Invoices and quotations

- Create, edit, duplicate, list, search, filter, cancel, and delete
- Draft, unpaid, partially paid, paid, overdue, sent, accepted, rejected, and
  cancelled lifecycle states where applicable
- Historical customer and line-item snapshots
- Saved catalog items and one-time custom items
- Line-item edit, duplicate, and remove actions
- Decimal quantity, rate, unit, HSN/SAC, GST, item/invoice discounts,
  additional charges, round-off, notes, and terms
- CGST/SGST, IGST, and non-tax modes
- Exact integer minor-unit money and basis-point tax calculations
- Payment recording and balance/status recalculation
- Quotation-to-invoice conversion
- Customer and valid items required before final save, preview, PDF, sharing,
  printing, or payment; incomplete work may be saved as a draft
- New invoices start with an automatic customer picker, then show customer and
  invoice metadata in one compact header with direct saved/custom item actions

### Documents and reporting

- Five selectable invoice PDF styles
- Offline PDF preview, save, share, and print
- Dashboard totals and basic reports
- Customer and product detail history links

## Persisted data notes

- Check `DbConstants.schemaVersion` before adding a database migration.
- Invoice numbers have a unique database index.
- Historical documents use snapshots so later catalog edits do not alter them.
- Custom units use `AppStorageKeyConst.customUnits` and are included in backup
  and restore.
- Evaluate every new `AppStorage` value for inclusion in `BackupService`.

## Important validation rules

- Customer and at least one valid item are required to finalize an invoice.
- Item name and unit are required; quantity and rate must exceed zero.
- GST and percentage discounts must be between 0 and 100.
- Due date cannot precede invoice date.
- Paid amount cannot exceed the grand total.
- Invoice number must be unique; cancelled invoices cannot be edited.
- Invalid invoices cannot be shared, printed, or recorded as paid.

## Setup on another computer

Use Flutter `3.44.9` or a compatible newer stable release with Dart `3.12.2`
or newer.

```bash
git clone https://github.com/Parth-Code-Flutter/Invora.git
cd Invora
git switch parth-dev
git pull --rebase origin parth-dev
flutter doctor
flutter pub get
flutter analyze
flutter test
flutter run
```

Ensure the IDE and terminal use the same SDK:

```bash
flutter --version
which flutter
```

For iOS, run `pod install` inside `ios/` before `flutter run` when pods change.
Do not commit personal SDK paths, credentials, signing keys, Xcode user data,
Pods, `.dart_tool`, or build output.

## Safe cross-system workflow

Before work:

```bash
git switch parth-dev
git status
git pull --rebase origin parth-dev
flutter pub get
```

After work:

```bash
dart format lib test
flutter analyze
flutter test
git status
git add <only intended files>
git commit -m "type: concise change description"
git push origin parth-dev
```

Before switching computers, confirm `git status` is clean and the latest commit
exists on `origin/parth-dev`. Git synchronizes only committed and pushed files;
local databases, simulator data, signing keys, and uncommitted files do not
transfer automatically.

## Verification baseline

As of 2026-08-10:

- Flutter analysis: no issues
- Automated suite: all 27 tests passing
- Full release builds and physical-device end-to-end testing remain required

## Known issues / next work

1. Configure secure Android release signing; release still references debug
   signing.
2. Verify Android AAB and iOS archive release builds.
3. Add onboarding-to-PDF integration tests.
4. Add database migration fixtures and backup corruption/restore tests.
5. Complete store privacy declarations and iOS privacy-manifest review.
6. Test all PDFs with long, multi-page, and Unicode content.
7. Complete accessibility, tablet, landscape, and physical-device QA.
8. Add CI for formatting, analysis, tests, and release validation.

Do not add cloud sync, authentication, inventory, full accounting, e-invoice,
e-way bill, online payments, or multi-user features without changing V1 scope.

## Implementation log

### 2026-08-10 — Customer-first invoice creation

- New invoices now open the existing-customer picker before the editor flow.
- Combined customer identity, invoice number, invoice date, and due date into a
  compact header after selection; restored drafts and edits are not interrupted.
- Replaced the empty item menu with direct saved-item and custom-item actions.
- Important files: `invoice_create_screen.dart`,
  `invoice_create_controller.dart`.
- No database, storage, backup, or migration changes.
- Verified with formatting, analysis, automated tests, and Android debug build.

### 2026-08-10 — Create-customer navigation result fix

- Fixed the customer picker crash when opening `Create new customer` from a
  new invoice by avoiding a typed cast on GetX's dynamic named route.
- Customer creation now returns a dynamic route result which is checked as a
  `CustomerModel` before the selection sheet closes.
- Important files: `invoice_create_screen.dart`,
  `customer_form_controller.dart`; no storage or migration changes.
- Verified with formatting, analysis, automated tests, and Android debug build.

### 2026-08-10 — Saved units and invoice line-item CRUD

- Added common and persistent custom units through `UnitService`.
- Added a shared unit picker with a create-unit action.
- Used the picker for catalog and one-time invoice items.
- Added line-item edit, duplicate, and remove actions.
- Included custom units in backup/restore and added a unit service test.
- Verified with clean analysis and all 27 tests passing.

### 2026-08-10 — Payment-sheet lifecycle fix

- Fixed `TextEditingController was used after being disposed` during payment.
- Made the sheet scrollable and keyboard-safe.
- Added saving state, clearer guidance, and a full-payment shortcut.
- Verified with clean analysis and all 27 tests passing.

### 2026-08-10 — Invoice safeguards and modern feedback

- Enforced customer/item requirements before customer-facing actions.
- Prevented invalid PDF, share, print, and payment flows.
- Modernized in-app notifications and fixed invoice-detail GetX misuse.

### 2026-08-10 — Invoice creation UX

- Structured creation into details, customer, items, live summary, and optional
  adjustments.
- Improved sheets/dropdowns and added customer creation during invoicing.

### 2026-08-10 — Validation and application foundation

- Added shared mobile/email validation.
- Implemented core offline customer, product, invoice, quotation, PDF, reports,
  settings, and backup/restore workflows.
