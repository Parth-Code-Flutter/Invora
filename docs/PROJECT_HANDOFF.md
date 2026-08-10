# Creovo Invoice — Project Handoff

Last updated: 2026-08-11
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
- Theme mode is owned by `GetMaterialApp`; the Navigator/Overlay tree remains
  stable when changing appearance while a dialog, sheet, or route is open
- Shared `AppFocus` coordination settles keyboard/caret work before focused
  fields are removed by dialogs, sheets, back actions, saves, or tab navigation
- Create-mode forms use non-destructive hints for example/default text; edit
  mode continues to load actual persisted values
- Reusable fields, dropdown sheets, navigation, and modern notifications
- Reusable gradient module banners give catalog, customer, invoice, and
  quotation workspaces distinct task-focused identities
- Shared icon-led filter pills, expressive segmented options, and branded
  rounded back controls across nested routes
- Expandable AppBar search on the Customers and Invoices/Quotations lists;
  search stays out of the content area until requested
- Offline backup/restore with validation and database rollback

### Customers

- Create, search, edit, view, and soft-delete customers
- Mobile length/format and email regex validation
- Customer name and valid 10-digit Indian mobile number are required
- GSTIN, address, company, and optional notes support
- Essentials-first customer form keeps name/contact visible and progressively
  discloses company/tax, billing address, and private notes
- Create-customer action directly inside invoice customer selection; customers
  saved there are immediately returned to and selected for the invoice

### Products and services

- Create, search, filter, edit, view, and soft-delete products/services
- Price, description, HSN/SAC, GST rate, type, and unit support
- Shared saved-unit picker with persistent custom-unit creation
- Catalog-first add/edit flow keeps type, name, price, and description in the
  main path while progressively disclosing unit, tax, and HSN/SAC details

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
- Invoice creation includes a live Customer → Items → Review progress strip,
  equal-width metadata controls, and a compact non-duplicated empty-item flow

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
- Automated suite: all 32 tests passing
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

### 2026-08-11 — Action-focused invoice details

- Reworked invoice details around the next user action: outstanding invoices
  prioritize `Record payment`, with share/print available alongside it; settled
  documents prioritize sharing.
- The summary now highlights balance due (or total), status, issued date, and due
  date in one glanceable hero. Customer details use identity/contact chips,
  items use numbered structured rows, and payment totals end in a highlighted
  due/fully-paid state.
- Preserved PDF preview, editing, duplication, payment updates, cancellation,
  deletion, quotation statuses, conversion, notes, and terms.
- Important file: invoice details screen.
- No database, storage, backup, or migration changes.

### 2026-08-11 — Import customer from phone contacts

- Added a contacts-book action to the required mobile field during customer
  creation. It opens the native Android/iOS contact picker and fills both the
  selected display name and mobile number.
- Imported Indian numbers are normalized from `+91` or leading-zero formats to
  the required 10 digits. Invalid/missing numbers, cancellation, permission
  denial, and platform failures leave the form safe and provide clear feedback.
- Added Android `READ_CONTACTS` and iOS contacts usage descriptions; the import
  action is intentionally hidden while editing an existing customer.
- Important files: customer form/controller, shared text field, platform
  permission files, and `flutter_contacts` dependency.
- No database, backup, or migration changes.

### 2026-08-11 — Branded app-wide button system

- Upgraded shared primary actions to a coral-to-plum brand gradient with white
  icon/text treatment, subtle depth, clipped ink feedback, disabled styling,
  and a high-contrast loading indicator.
- Harmonized Material filled, tonal, outlined, and text buttons with consistent
  52 px sizing, rounded geometry, 19 px icons, brand colors, pressed overlays,
  and accessible disabled states across dialogs and feature screens.
- Important files: shared app button and global app theme.
- No database, storage, backup, or migration changes.

### 2026-08-11 — Unified AppBar and back navigation

- Standardized all themed AppBars to a 64 px toolbar with consistent title
  typography and leading geometry.
- Replaced the oversized tinted back control with a compact neutral button,
  balanced 20 px arrow, subtle border, matching light/dark colors, and a safe
  48 px Material touch target.
- Updated searchable AppBars to use the same height and title spacing, covering
  standard, create, detail, list, and report screens through shared components.
- Important files: app theme, shared back button, and searchable AppBar.
- No database, storage, backup, or migration changes.

### 2026-08-11 — Consistent dashboard actions and invoice cards

- Replaced the dashboard's bulky three-icon quick-create panel with compact
  inline action tiles and normalized spacing between hero, actions, and recent
  activity.
- Extracted the invoice summary card into a shared widget now used by both the
  dashboard and invoice list, keeping status rail, dates, totals, balance, and
  visual hierarchy identical.
- Important files: dashboard, invoice list, and shared invoice summary card.
- No database, storage, backup, or migration changes.

### 2026-08-11 — Selectable monthly reports

- Added real month-based reporting with previous/next controls and a 24-month
  selection sheet; future navigation is disabled.
- Report totals, payment status counts, and the six-month trend now recalculate
  from stored invoices for the selected month instead of being fixed to today.
- Replaced tall single-column metric cards with compact received/outstanding
  cards and a grouped invoice-status summary for faster scanning.
- Important files: invoice repository, report controller, and report screen.
- No database, storage, backup, or migration changes.

### 2026-08-11 — Streamlined catalog item form

- Removed the large decorative catalog hero and nested essential-details card
  from product/service creation, bringing required inputs above the fold.
- Added a compact type selector, explicit `2 required` guidance, non-destructive
  price hint, shorter optional description, and a quieter progressive section
  for unit, tax, and HSN/SAC.
- The sticky action now names the selected item type (`Save product` or
  `Save service`) while edit mode continues to use `Save changes`.
- Important file: product form screen.
- No database, storage, backup, or migration changes.

### 2026-08-11 — Instant main-tab switching

- Changed Home, Invoices, Customers, and More to use zero-duration route
  transitions, removing the pushed-screen animation when using bottom
  navigation.
- Main-tab changes still replace the root navigation stack, so repeated tab
  use cannot accumulate duplicate pages; feature/detail routes keep their
  normal transitions.
- Important files: route generator and main navigation widget.
- No database, storage, backup, or migration changes.

### 2026-08-11 — Modern dashboard and tool hub

- Refreshed the dashboard around a branded cash-flow hero, clearer invoice and
  insights actions, a compact quick-create surface, and card-based recent
  invoice activity.
- Reworked More into a lighter horizontally scrollable business-tool launchpad
  and upgraded the business identity header with the app palette gradient.
- Preserved all existing destinations, data behavior, responsive constraints,
  and tablet navigation.
- Important files: dashboard and More screens.
- No database, storage, backup, or migration changes.

### 2026-08-11 — Scannable invoice and customer lists

- Redesigned invoice cards with a status accent rail, compact document/status
  header, stronger customer/amount hierarchy, and issued/due-date context.
- Refined customer cards with branded gradient avatars and a compact action
  control. Customers can swipe right to edit or left to delete, while the action
  sheet keeps both operations visible and accessible without relying on gestures.
- Customer deletion remains protected by confirmation and historical invoices
  remain unchanged.
- Important files: invoice and customer list screens.
- No database, storage, backup, or migration changes.

### 2026-08-11 — Compact list creation actions

- Removed the large promotional/create banners from invoice, quotation,
  customer, and product/service lists to dedicate more screen space to filters
  and saved records.
- Added compact, accessible floating `+` actions to each list, with a
  module-specific tooltip and destination.
- Important files: invoice, customer, and product list screens.
- No database, storage, backup, or migration changes.

### 2026-08-11 — Create catalog items from invoice picker

- Added a prominent `Create product or service` action to the saved-item
  picker used while creating invoices and estimates.
- The action is available for both empty and populated catalogs. After saving,
  the newly created product/service returns directly to the invoice and is
  added as a line item without requiring another search or selection.
- Important file: invoice create screen and its reusable selection sheet flow.
- No database, storage, backup, or migration changes.

### 2026-08-11 — Non-destructive create-form defaults

- Replaced prefilled create-time values with hints so users can type without
  first deleting `0`, `0.00`, `1`, `INV`, or other placeholder content.
- Updated custom invoice items, amount paid, product custom GST, and first-time
  business invoice numbering while preserving real values in edit/restore mode.
- Empty custom-item quantity and GST fields still safely resolve to the hinted
  defaults of 1 and 0; empty business prefix/starting number still save as INV
  and 1.
- Important files: invoice create screen/controller, product form
  screen/controller, and business setup screen/controller.
- No database, storage, backup, or migration changes.
- Verified with formatting, clean analysis, all 32 automated tests, and an
  Android debug APK build.

### 2026-08-10 — App-wide focused-field lifecycle hardening

- Fixed Flutter's scheduler `RenderObject.getTransformTo` / `attached` assertion
  caused when a focused EditableText was removed before its scheduled caret
  visibility callback completed.
- Added shared keyboard/caret coordination that hides the IME, unfocuses the
  field, waits for the frame to settle, and only then pops the route or overlay.
- Audited every module and applied the safe path to invoice item, charge,
  discount and payment editors, custom-unit creation, AppBar search, customer,
  product, business and invoice saves, back navigation, and main-tab changes.
- Rebuilt custom-unit input as a state-owned dialog, removing the remaining
  externally disposed dialog controller pattern.
- Added regression coverage for closing an autofocus text dialog without a
  detached-render-object scheduler exception.
- Important files: `app_focus.dart`, navigation/search/unit widgets, form
  controllers, invoice editor/detail screens, and `design_system_test.dart`.
- No database, storage, backup, or migration changes.
- Verified with formatting, clean analysis, all 32 automated tests, and an
  Android debug APK build.

### 2026-08-10 — Additional-charge dialog lifecycle fix

- Fixed `TextEditingController was used after being disposed` when closing the
  invoice additional-charge dialog; the extreme RenderFlex overflow reported
  afterward was a secondary effect of the same failure.
- Moved title/amount controllers into a stateful dialog so Flutter disposes
  them only after the closing animation and overlay are fully unmounted.
- Made the dialog keyboard-scrollable, added inline validation, and also added
  the missing controller disposal to the discount dialog.
- Important file: `invoice_create_screen.dart`; no database, storage, backup,
  or migration changes.
- Verified with formatting, clean analysis, all 31 automated tests, and an
  Android debug APK build.

### 2026-08-10 — Stable theme changes with active overlays

- Fixed Flutter's `_dependents.isEmpty` assertion caused by reactively replacing
  a root `Theme` wrapper while Navigator overlay entries still depended on it.
- Removed the reactive Theme around the complete navigation tree, initializes
  `GetMaterialApp.themeMode` directly from storage, and uses
  `Get.changeThemeMode` for supported runtime changes.
- Added regression coverage that switches to dark mode while a dialog overlay
  is open and confirms the overlay remains mounted without a framework error.
- Important files: `main.dart`, `app_controller.dart`, and `widget_test.dart`;
  no database, backup, or migration changes.
- Verified with formatting, clean analysis, all 31 automated tests, and an
  Android debug APK build.

### 2026-08-10 — Space-efficient invoice editor

- Rebuilt the phone invoice editor header around a live Customer → Items →
  Review progress strip so users always know the next required action.
- Consolidated customer selection and invoice metadata into a tighter card with
  equal-width invoice number, issued date, and due date controls.
- Removed the duplicate Add item action from the empty state and replaced the
  oversized panel with compact saved-item and one-time-item choices.
- Kept Add item available once line items exist, preserved all tax/discount,
  adjustment, draft, tablet summary, and review behavior.
- Important file: `invoice_create_screen.dart`; no database, storage, backup,
  or migration changes.
- Verified with formatting, clean analysis, all 31 automated tests, and an
  Android debug APK build.

### 2026-08-10 — Expandable main-tab search

- Moved customer and invoice/quotation search from permanent page fields into
  their AppBars to return more vertical space to the lists.
- Search now expands in place with autofocus, live filtering, a clear action,
  and a close action that resets the query and restores the normal title.
- Kept invoice sorting accessible alongside search and left Home/More unchanged
  because those tabs do not contain searchable collections.
- Important files: `app_search_app_bar.dart`, `customer_list_screen.dart`,
  `invoice_list_screen.dart`, and `design_system_test.dart`.
- No database, storage, backup, or migration changes.
- Verified with formatting, clean analysis, all 31 automated tests, and an
  Android debug APK build.

### 2026-08-10 — Expressive filters and back navigation

- Added a reusable filter pill with icons, a strong plum selected state, clear
  accessibility semantics, and dark-mode styling.
- Applied the filter system to product/service lists, invoice/quotation status
  filters, and PDF template selection; product filters now scroll safely on
  narrow phones.
- Upgraded global choice chips and segmented controls so GST and product/service
  options share the same clear selected-state language.
- Added a rounded plum-tinted back control to customer/product forms and
  details, invoice creation/details/preview, quotations, reports, settings, and
  backup while leaving root tab screens unchanged.
- Important files: `app_filter_chip.dart`, `app_back_button.dart`,
  `app_theme.dart`, relevant list/form screens, and `design_system_test.dart`.
- No database, storage, backup, or migration changes.
- Verified with formatting, clean analysis, all 30 automated tests, and an
  Android debug APK build.

### 2026-08-10 — Module-specific UI and catalog redesign

- Audited every application module and retained the already distinct
  onboarding, business setup, dashboard, reports, backup, detail, and invoice
  creation experiences.
- Added reusable expressive module banners with different content and color
  direction for products, customers, invoices, and quotations.
- Rebuilt product/service creation around the frequent task: choose type, enter
  name and price, then optionally add unit, GST, and HSN/SAC details.
- Added a branded catalog intro, clearer field guidance, smaller field icons,
  progressive disclosure, responsive layouts, and a sticky save action.
- Important files: `app_module_banner.dart`, `product_form_screen.dart`,
  `product_list_screen.dart`, `customer_list_screen.dart`, and
  `invoice_list_screen.dart`.
- No database, storage, backup, or migration changes.
- Verified with formatting, clean analysis, all 29 automated tests, and an
  Android debug APK build.

### 2026-08-10 — Required customer mobile number

- Made both customer name and mobile number mandatory for customer creation
  and editing, including customers created from the invoice flow.
- Added shared required-mobile validation and automated coverage while keeping
  email and the remaining customer fields optional.
- Important files: `validation_utils.dart`, `customer_form_controller.dart`,
  `customer_form_screen.dart`, and `validation_utils_test.dart`.
- No database, storage, backup, or migration changes.
- Verified with formatting, analysis, automated tests, and Android debug build.

### 2026-08-10 — Faster customer capture

- Reworked customer add/edit into an essentials-first flow with name, mobile,
  and email kept close at hand.
- Moved company/GSTIN, billing address, and private notes into clearly labelled
  optional sections without removing any customer capability.
- Added invoice-aware customer creation with a `Save & use customer` action
  that returns the saved customer directly to the invoice picker.
- Added a sticky save action, responsive form columns, smaller field icons, and
  clearer on-device privacy guidance.
- Important files: `customer_form_screen.dart`,
  `customer_form_controller.dart`, `invoice_create_screen.dart`.
- No database, storage, backup, or migration changes.
- Verified with formatting, clean analysis, all 27 automated tests, and an
  Android debug APK build.

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
