# Creovo Billing — Project Handoff

Last updated: 2026-08-19
Active development branch: `demo-apk-code`  
Product specification: [CODEX_IMPLEMENTATION_PLAN.md](CODEX_IMPLEMENTATION_PLAN.md)
Production roadmap: [PRODUCTION_ROADMAP.md](PRODUCTION_ROADMAP.md)
Licensing and demo APK: [LICENSING_AND_DEMO.md](LICENSING_AND_DEMO.md)

## Purpose

This document records the live application state so development can continue
safely from another computer or Codex session. Update it in the same commit as
every material code change.

## Product boundaries

Creovo Billing is a Flutter Android and iOS app for fast, privacy-first,
offline invoicing. It has no backend, authentication, cloud dependency, ads,
subscriptions, payment gateway, inventory accounting, or multi-user system.
Paid unlock, store billing, and license keys are still design-only in
[LICENSING_AND_DEMO.md](LICENSING_AND_DEMO.md). Client demo APKs use a
compile-time 15-day kill switch (`DEMO_EXPIRES_AT`) that is omitted from
default / Play builds. Entitlement and demo clocks stay out of Drift and
backup ZIPs.

- Flutter and Dart
- GetX for routing, dependency injection, and reactive state
- Drift/SQLite for local business data
- `AppStorage`/SharedPreferences for lightweight settings
- Local PDF generation, preview, save, share, and print

## Current implementation

### Application foundation

- First-launch onboarding and business setup
- One-time onboarding workspace choice between Sales and Purchases. Existing
  installations default safely to Sales; the initial choice and most recently
  active workspace persist locally. Users can switch from the dashboard, the
  isolated Purchase workspace, or the first More tile without converting,
  deleting, or mixing sales records.
- Purchase is a complete, separate offline workspace rather than a placeholder:
  it has a purchase overview, searchable suppliers, searchable purchase bills,
  supplier-bill creation/editing with GST line items, bill details, payable
  balances, supplier-payment history, and its own Home/Bills/Create/Suppliers/
  More navigation. A labelled Sales/Purchases control switches workspaces;
  sales customers/invoices and purchase suppliers/bills use separate tables.
  Supplier creation supports the same native phone-contact import behavior and
  contact validation as customer creation. New purchase bills require supplier
  selection before bill fields are shown, then enforce unique bill number,
  valid date order, required line items, positive quantity/rate, bounded GST,
  and payment-within-balance rules.
  The purchase composer now matches Sales create invoice for catalog work:
  Add item opens Scan barcodes / Choose saved item / Create custom item, saved
  products keep quantity steppers with confirm-before-remove, and Generate PDF
  is available from the composer and bill details. Supplier cards show payable
  status, bill totals, swipe edit/delete, and New bill from a long-press sheet.
  Purchase screens follow the same classic grouped treatment as Sales:
  white overview metrics with icon wells (Paid / Payable / Overdue), AppBar
  search plus All/Unpaid/Overdue/Paid filters on bills, denser supplier and
  bill rows with status pills, an invoice-style bill composer (supplier card,
  date strip, catalog/scan/custom items with quantity steppers, sticky
  Save/Update), PDF preview from composer and details, and bill details with
  a status gradient hero, payment activity, grouped items, and a sticky
  Record payment bar. Long footer labels stay short so they are not truncated.
- Business profile, logo, signature, payment QR, bank, and UPI information
- Responsive phone/tablet layouts and dark mode
- Optional four-digit app lock under Settings > Security. PIN setup requires
  confirmation; changing or disabling requires the current PIN. Enabled locks
  cover cold launch and foreground return, while the stored credential is a
  salted, iterated SHA-256 hash rather than plain PIN text. This is an access
  guard for the local app and does not encrypt SQLite data, exports, or backups.
- Client demo APKs are a compile-time 15-day kill switch, not a first-launch
  timer. `flutter run` / Play / unsigned daily APKs omit `DEMO_EXPIRES_AT`, so
  the lock never arms. A demo APK baked with `--dart-define=DEMO_EXPIRES_AT`
  (last inclusive calendar day) plus optional client name and build day blocks
  every screen after that date, including backup/restore, and shows
  **Please contact your sales person**. Last-seen day is stored on-device only
  and is excluded from backup `settings.json`. Build with
  `flutter build apk --release` plus `DEMO_EXPIRES_AT` /
  `DEMO_BUILD_TIME` / `DEMO_CLIENT_NAME`, or `tool/build_demo_apk.sh
  "Client name"`. Commands are in `docs/LICENSING_AND_DEMO.md`.
- App-wide interface localization with English as the default and selectable
  Hindi or Gujarati under Settings > Appearance. The selected language is
  stored in `AppStorage`, applies immediately, and survives restart. Shared
  text, form fields, validation copy, dropdowns, search, notifications,
  tooltips, dialogs, navigation, and empty states use the localization layer;
  customer, product, business, and invoice values remain unchanged.
- Theme mode is owned by `GetMaterialApp`; the Navigator/Overlay tree remains
  stable when changing appearance while a dialog, sheet, or route is open
- Shared `AppFocus` coordination settles keyboard/caret work before focused
  fields are removed by dialogs, sheets, back actions, saves, or tab navigation
- Create-mode forms use non-destructive hints for example/default text; edit
  mode continues to load actual persisted values
- Reusable fields, dropdown sheets, navigation, and modern notifications
- All app-owned dialogs use the local `pro_dialog` package through Creovo
  aliases (`AppDialog`, `showAppConfirmDialog`). The package lives at
  `packages/pro_dialog` and can be copied into another Flutter app as a path
  dependency. Visual system: centered type-colored circular icon on a
  neutral white card (no tone wash on the surface), typed
  Creovo success/error/warning/info/question action colors,
  bounce/shake/pulse/fade/rotate entry motion, centered title and body, and
  outlined plus filled action buttons. Long labels stack full-width so they
  are not truncated. Filled confirms use a type-tinted gradient (coral-to-plum
  for questions, coral-to-orange for warnings, red for destructive, teal for
  success). Outlined cancel/continue actions stay plum on cream unless the
  button sets a tone such as error. Form dialogs keep the same chrome with
  start-aligned fields.
- Shared unsaved-change protection covers invoice/quotation, customer,
  product/service, and business forms across AppBar back, system back, and iOS
  back gestures. Dirty document composers can save a draft before leaving.
- Shared gradient `AppButton` owns full-width primary actions, including
  loading, disabled, icon, sizing, semantics, and responsive behavior; compact
  selectors, secondary actions, and destructive confirmations remain distinct
- Reusable gradient module banners give catalog, customer, invoice, and
  quotation workspaces distinct task-focused identities
- Shared icon-led filter pills, expressive segmented options, and branded
  AppBar chrome across Sales and Purchases: 18px titles, a hairline under the
  bar, matching 40px plum-outlined action wells, and `AppBarTitle` captions on
  document screens (Invoice, Customer, Purchase bill, Supplier). Nested back
  controls use the same well as PDF, edit, search, and workspace-switch
  actions.
- Expandable AppBar search on the Customers, Invoices/Quotations, and
  Products & services lists; search stays out of the content area until
  requested. The expanded field is a compact 46px contained input with an
  in-field clear control (no sibling close chip) and plum/muted chrome.
  Customer and invoice searches accept partial, case-insensitive words across
  their identifying fields. Their scan-to-search action sits beside Search in
  the collapsed AppBar and never enters the text field; product and line-item
  barcode workflows remain separate.
- More and App Settings use classic grouped settings panels: one bordered
  card per section, inset hairline dividers, compact 14px rows, plum icon
  wells, and a chevron instead of a circular arrow. More leads with a quiet
  business identity card (name plus owner/mobile/GSTIN, tap or Edit to open
  the profile) and a Change workspace list with named Sales and Purchases
  choices (check marks the active mode) that does not leave the screen. The privacy line is a caption, not a
  tinted banner. Secondary tools no longer require horizontal discovery
  scrolling.
- App Settings includes a focused Invoice Defaults workspace for immediate,
  7/15/30-day, or custom due periods; tax mode and GST rate; document notes and
  terms; and payment method. New documents/custom items/payment entries inherit
  the relevant defaults while existing records and saved catalog tax rates stay
  unchanged.
- Offline backup/restore with validation and database rollback; validation
  rejects missing/invalid schema metadata and embedded files without a valid
  SQLite signature before replacing application data
- Backup workspace warns that ZIP exports are sensitive and unencrypted, shows
  the last successful device backup, supports 7/14/30-day or disabled local
  reminders, and moves restore work onto a dedicated database-free status route
  before replacing the Drift database. It rebuilds the database-bound runtime
  after replacement and only then allows navigation to resume, preventing live
  controllers from querying a closed isolate. Restored logo, signature, and QR
  assets are remapped to current-device paths instead of retaining absolute
  paths from the source installation. Due reminders also appear on the dashboard.

### Customers

- Create, search, edit, view, and soft-delete customers. List search matches
  partial words across name, company, mobile, email, and GSTIN.
- Mobile length/format and email regex validation
- Customer name and valid 10-digit Indian mobile number are required
- GSTIN, address, company, and optional notes support
- Essentials-first customer form keeps name/contact visible and progressively
  discloses company/tax, billing address, and private notes
- Create-customer action directly inside invoice customer selection; customers
  saved there are immediately returned to and selected for the invoice
- Customer list rows keep 14px names, company or mobile as caption, a soft
  initial tile, and a bounded billed-amount column, with 10px space between
  cards. Status is caption text (Due / Paid / No invoices). Names ellipsize;
  rupee totals shrink with `AppAmountText`. Aggregates exclude drafts and
  cancelled invoices; create-invoice/edit/delete remain in the row action
  sheet and swipe gestures. The add-customer FAB stays on this screen.

### Products and services

- Create, search, filter, edit, view, and soft-delete products/services
- Price, description, HSN/SAC, GST rate, type, and unit support
- Shared saved-unit picker plus a central manager for add, rename, delete, and
  app-wide default selection; new items prefill the selected default
- Catalog add/edit is a compact catalog form: equal-width Product/Service
  segmented control, a compact purpose guide, card-contained section headings,
  required name and price, visible unit/HSN/GST when those fields are enabled,
  optional product fields with Manage, and a sticky save. The form uses the
  shared app typography scale and responsive padding on Android and iOS.
- Product/service forms keep a live invoice-line preview for name, price, and
  unit. AppBar barcode scan still prefills name, price, tax, and SKU.
- Optional business-category presets recommend useful product fields and units
  for 15 business types without locking the catalog to a template. Category
  can be selected during business setup or changed under Product Settings.
- Product Settings supports independent field toggles, reusable Text/Number
  custom fields, category-aware preferred units, and a preference controlling
  whether attributes appear on invoices. Changing category updates only the
  recommendations; existing product values remain stored.
- Product attributes are searchable and appear as a compact prioritized
  secondary line in catalog/product details.
- Products can be added by scanning barcodes. Invoice/quotation Add item
  opens a live camera with a scanned-items list, quantity steppers, and a
  running total; unknown codes can be saved to the catalog with the barcode
  stored as SKU. The custom-item sheet and catalog Add item form also have a
  scan action that fills name, price, tax, and SKU so values can be edited
  before saving. The catalog list has a scan action to open or create an
  item. Lookup is local-only against SKU/barcode attributes.
- Catalog list rows match invoice/customer density: 14px name, 11px unit/GST
  (plus a quiet Product/Service caption only when All is selected), one
  ellipsized attribute line, and price on the right via `AppAmountText`.
  Search lives in the AppBar. The peach type icon and repeated Product/
  Service pills are gone. Overflow stays as a quiet 20px menu. All /
  Products / Services filters and the add FAB remain.

### Invoices and quotations

- Create, edit, duplicate, list, search, filter, cancel, and delete.
  Invoice/quotation list search matches one or more partial words across
  document number, customer, and company. Quotations opened from More is a
  nested listing: back in the AppBar, no Sales bottom nav, and a create FAB.
  The Invoices tab keeps the main navigation.
- Draft, unpaid, partially paid, paid, overdue, sent, accepted, rejected, and
  cancelled lifecycle states where applicable
- Historical customer and line-item snapshots
- Historical line-item snapshots include configurable product attributes;
  later catalog edits cannot rewrite saved invoice content. Attribute summaries
  appear consistently in invoice editing, details, and every PDF template when
  enabled.
- Saved catalog items and one-time custom items
- An empty invoice shows one add action that opens the scan / saved / custom
  chooser. Tax, discount and notes appear after the first line is added.
- Invoice details reads like an open document: the AppBar shows the invoice
  number, and a compact status-aware hero holds billed-to (tappable), tax
  mode, item count, issued/due dates, and a due countdown. Payment activity
  (Total, Paid, Remaining, and the payment timeline) sits immediately under
  that identity card, then line items with a GST/totals footer. Record
  payment / Share stay pinned in a sticky footer. Share and Share / print open
  native share or print sheets for a saved invoice; they do not open the
  composer preview. The AppBar PDF icon opens a read-only generated PDF with
  share, save, and print. Swipe-to-create/update stays on Review from the
  invoice composer. Edit, duplicate, reverse, cancel, and quotation actions
  stay in the AppBar overflow.
- Line-item edit, duplicate, and remove actions
- Re-selecting the same saved catalog item increases its existing quantity;
  selected-item cards expose direct minus/plus quantity controls and line
  total; the stepper displays quantity only while unit stays with the rate and
  changes its decrement action to a delete icon when quantity reaches one.
  That delete asks for confirmation before the line is removed.
- Populated invoice items use compact numbered rows with scan-friendly
  name/rate and line-total hierarchy, keeping long 20-item invoices manageable
- Decimal quantity, rate, unit, HSN/SAC, GST, item/invoice discounts,
  additional charges, round-off, notes, and terms
- CGST/SGST, IGST, and non-tax modes
- Exact integer minor-unit money and basis-point tax calculations
- Payment recording and balance/status recalculation
- Append-only per-invoice payment activity with amount, date/time, method,
  reference, note, paid progress, and remaining balance. Schema v8 classifies
  payment/opening/imported/reversal entries and links every explicit reversal
  to its immutable original payment; existing invoice edits cannot rewrite the
  ledger, while legacy cumulative payments remain preserved. Schema v9 adds
  backward-compatible JSON attribute columns to products and invoice items.
- Successful ledger payments open an animated receipt-roll experience with a
  stable receipt number and offline A5 PDF preview/save/share/print actions;
  valid historical receipts reopen from payment activity and reversed payments
  are blocked.
- Quotation-to-invoice conversion
- Customer and valid items required before final save, preview, PDF, sharing,
  printing, or payment; incomplete work may be saved as a draft
- New invoices start with an automatic customer picker, then show customer and
  invoice metadata in one compact header with direct saved/custom item actions
- Customer selection uses a focused searchable bottom sheet. Saved catalog
  selection uses a dedicated full-screen workspace designed for 100+ records,
  with debounced search, Product/Service filters, persistent checkboxes,
  tri-state visible selection, editable on-invoice states, create-item access,
  result and selection counts, and one apply-changes action
- Customer details is a compact account workspace. The customer name sits in
  the AppBar so it does not truncate in the hero. The status-aware plum hero
  shows an initial, one-line company or invoice count, and billed/paid/due
  amounts that shrink to fit. Phone appears only in Contact & billing. Due
  customers get a Collect outstanding primary action to the statement;
  paid-in-full accounts use View customer statement; empty accounts use New
  invoice. History reuses the invoice list card without repeating the customer
  name. Edit, statement, new invoice, and invoice-details navigation are
  unchanged.
- Customer Details opens a date-range statement workspace. The customer name
  sits in the AppBar with a Statement caption. A compact status-aware hero
  shows the selected period, then Closing / Invoiced / Received cards (Opening
  as a quiet caption) sit immediately underneath. Period is one calendar-style
  row (From → To) that opens a native date-range picker. Activity uses
  accent-grouped ledger tiles, and Preview statement PDF stays pinned in a
  sticky footer. Save and print remain in the AppBar overflow.
- Invoice creation uses a focused composer hierarchy: compact customer/invoice
  header, equal-width metadata controls, count-labelled line items, secondary
  tax/discount disclosure, and a non-duplicated empty-item flow. Phone layouts
  avoid repeating the full totals card because the fixed footer already keeps
  total and Review visible; tablets retain the live summary side panel.
- Customer and invoice lists replace blocking spinners with reusable animated
  skeleton rows and apply a subtle staggered fade/translate/scale entrance as
  rows are built during initial display and scrolling. System reduced-motion
  settings bypass the entrance animation.
- The invoice list begins with a responsive, theme-aware business summary for
  received, pending, overdue, and current-month invoice totals. Summary values
  always use the complete invoice collection and remain stable while users
  search or filter the visible list. Compact customer-led invoice cards use an
  initial avatar, invoice/customer/date hierarchy, a status badge and colored
  edge, with billed and due amounts aligned on the right. The customer name
  keeps about 70% of the text row so longer names stay readable; amounts use
  the remaining 30% and still shrink to fit. Date-sorted lists still group
  under This month / Last month / August 2026. The Invoice list has a dedicated
  create `+` FAB in addition to the center dock. Amounts shrink to fit narrow
  phones and large rupee values.

### Documents and reporting

- Five selectable invoice PDF styles
- Professional PDF uses its own editorial A4 layout with a business/logo
  identity header, full Bill To and invoice metadata, description-friendly
  item table, payment instructions beside totals, amount-due emphasis, and an
  authorization/signature finish
- PDFs embed the bundled Plus Jakarta Sans TrueType font for Unicode currency glyphs and
  use explicit responsive table columns/alignment so real invoice values wrap
  predictably without overlapping
- Offline PDF preview, save, share, and print
- A centralized Export Data workspace saves or shares Excel-friendly UTF-8 CSV
  for active customers, products/services, invoices, and immutable payment
  ledger entries. Financial exports use a configurable date range (invoice date
  for invoices; paid-at date for payments) with ISO dates, decimal major-unit
  amounts, and explicit status/tax/payment fields. Date-range sales summaries
  export as CSV or a Unicode A4 PDF and are also reachable from Reports.
- Dashboard totals and basic reports
- Dashboard Home is an action surface: a compact this-month Invoiced /
  Received / Outstanding card, overdue and due-this-week follow-up rows
  instead of repeating the outstanding rupee amount, backup when due, quick
  create actions, and either invoices that need collection or the latest five.
  Tapping overdue/outstanding opens the invoice list on the matching filter.
  Phone Home omits the duplicate full-width Create invoice button because the
  center dock already creates invoices; tablets keep the button because they
  use a navigation rail.
- Automated whole-flow QA covers the offline GST lifecycle from business,
  customer, and catalog data through invoice payments/reversal, quotation
  conversion, PDF generation, and backup validation. Native picker/share/print
  and physical-device cases are tracked in `docs/QA_CHECKLIST.md`.
- Customer and product detail history links

## Persisted data notes

- Database schema version 9 includes product/invoice attribute snapshots; its
  version 8 migration classifies `invoice_payments` entries and links
  reversals to original payments. The v7 migration preserves every older
  non-zero cumulative payment as a dated `Previous payment` entry.
- Invoice numbers have a unique database index.
- Historical documents use snapshots so later catalog edits do not alter them.
- Managed units and the default selection use
  `AppStorageKeyConst.managedUnits/defaultUnit`; legacy `customUnits` values are
  imported into the initial list, and all unit preferences are backed up.
- Invoice defaults use SharedPreferences keys for due days, tax mode, GST basis
  points, notes, terms, and payment method. All are included in ZIP settings
  backup/restore; no database migration is required.
- Evaluate every new `AppStorage` value for inclusion in `BackupService`.
- `last_backup_at` records device-local export history and is intentionally not
  restored. `backup_reminder_days` is included in settings backup/restore;
  `restore_completed` records that the app must reload restored state.

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

As of 2026-08-15:

- Flutter analysis: no issues
- Automated suite: all 146 tests passing
- Android debug APK builds successfully
- Full release builds and physical-device end-to-end testing remain required

## Known issues / next work

1. Add purchase-specific reporting/export after the core supplier/bill/payment
   workflow has been field tested. Purchase bills now generate, preview, share,
   save, and print their own PDFs.
2. Configure secure Android release signing; release still references debug
   signing.
3. Verify Android AAB and iOS archive release builds.
4. Complete native Android/iOS picker, share, print, restore/restart, gesture,
   and high-volume checks in `docs/QA_CHECKLIST.md`.
5. Consider password-encrypted backup exports after V1; core compatibility,
   database rollback, and corruption coverage are implemented.
6. Complete store privacy declarations and iOS privacy-manifest review.
7. Test all PDFs with long, multi-page, and Unicode content.
8. Complete accessibility, tablet, landscape, and physical-device QA.
9. Add CI for formatting, analysis, tests, and release validation.
10. Store billing / license keys remain design-only. Client demo APKs now use
    a dated kill switch (`DEMO_EXPIRES_AT`); default builds stay unlimited.
    Follow [LICENSING_AND_DEMO.md](LICENSING_AND_DEMO.md) for Play/App Store
    billing and GSTIN-bound keys. Do not put Pro or demo expiry in the backup
    ZIP.

Do not add cloud sync, authentication, inventory, full accounting, e-invoice,
e-way bill, online payments, or multi-user features without changing V1 scope.
Store/IAP and signed license keys for selling the app itself are the exception
documented in LICENSING_AND_DEMO.md; they must not upload invoice data.

## Implementation log

### 2026-08-19 — Documented demo APK Flutter command

- `docs/LICENSING_AND_DEMO.md` now includes the exact
  `flutter build apk --release` `--dart-define` command (15-day example:
  `DEMO_EXPIRES_AT=2026-09-03`) as well as `tool/build_demo_apk.sh`.
- Important files: `LICENSING_AND_DEMO.md`, this handoff.
- Verification: documentation only.

### 2026-08-19 — Client demo window set to 15 days

- Client demo APKs now expire 15 calendar days after the build date
  (`tool/build_demo_apk.sh` uses `date +15 days`). Default/Play builds still
  omit `DEMO_EXPIRES_AT` and never lock.
- Important files: `tool/build_demo_apk.sh`, `LICENSING_AND_DEMO.md`, this
  handoff.
- Verification: documentation and script only; kill-switch tests are date-based
  and unchanged.

### 2026-08-19 — Client demo APK 7-day kill switch

- Demo APKs expire on a calendar date compiled with `--dart-define`, not a
  first-open timer. After that date the app is fully blocked with
  “Please contact your sales person.” Default `flutter run` / Play builds omit
  the define and never lock. Last-seen day is kept out of backup ZIP.
- Important files: `demo_build_config.dart`, `demo_access_service.dart`,
  `demo_expired_gate.dart`, `main.dart`, `tool/build_demo_apk.sh`,
  `LICENSING_AND_DEMO.md`, this handoff.
- Verification: demo access and gate tests, backup ZIP exclusion test,
  existing first-launch widget test, Dart formatting, `flutter analyze`.

### 2026-08-18 — Purchase composer uses catalog items and PDF

- New purchase bills can add saved products or services the same way as Sales:
  scan, choose from the catalog, or enter a custom item. Item cards use the
  quantity stepper and confirm before removing the last unit. Composer and
  bill details both offer Generate PDF (preview, share, save, print). Supplier
  list cards now show payable/paid status, totals, swipe actions, and New bill.
- Important files: `purchase_screens.dart`, `purchase_bill_pdf_service.dart`,
  `purchase_bill_pdf_screen.dart`, `purchase_models.dart`, this handoff.
- Verification: purchase widget/PDF/repository tests, Dart formatting,
  `flutter analyze`.

### 2026-08-18 — Purchase module UI matches Sales

- Restyled the whole Purchase workspace: home overview uses the same white
  metric card as invoice lists; bills listing adds Paid/Payable/Overdue plus
  All/Unpaid/Overdue/Paid filters; supplier rows are denser; the bill composer
  uses a supplier identity card, date strip, numbered item cards, and a sticky
  Save/Update bar; bill details uses a status gradient hero and sticky Record
  payment. Footer actions use short labels so they are not truncated.
- Important files: `purchase_workspace_screen.dart`, `purchase_screens.dart`,
  coverage translations, this handoff.
- Verification: purchase widget tests, Dart formatting, `flutter analyze`.

### 2026-08-18 — Neutral dialog cards and full button labels

- Dialog cards no longer pick up a light red/orange/teal wash from the icon
  glow. The type color stays on the icon and filled button only. Long action
  labels such as Remove item and Keep item stack full-width instead of
  truncating to "Remov...".
- Important files: `packages/pro_dialog/lib/src/pro_dialog.dart`, package
  tests, this handoff.
- Verification: package and app dialog widget tests, Dart formatting,
  `flutter analyze`.

### 2026-08-18 — Statement period is a calendar range row

- Customer statement From/To stacked rows are now one calendar-style range:
  From → To in a single tap target that opens the native date-range picker.
- Important files: `customer_statement_screen.dart`,
  `customer_statement_controller.dart`, this handoff.
- Verification: Dart formatting and `flutter analyze`.

### 2026-08-18 — Quotations listing hides the main nav

- The Quotations screen from More is a nested list: AppBar back, no Home/
  Invoices/Customers/More bar, and a create FAB like Products & services.
  Empty copy says quotations, not invoices. The Invoices tab is unchanged.
- Important files: `invoice_list_screen.dart`, this handoff.
- Verification: Dart formatting and `flutter analyze`.

### 2026-08-18 — Dialog actions match Creovo tones

- Shared dialog buttons now use Creovo coral, plum, teal, and error instead of
  generic amber/blue/violet. Filled confirms follow the dialog type (coral-to-
  plum for questions, coral-to-orange for warnings, red for delete, teal for
  success). Outlined cancel/continue stays plum on cream so warning dialogs no
  longer wash secondary actions yellow. Every AppDialog/confirm/notice/form
  surface picks this up from `pro_dialog`.
- Important files: `packages/pro_dialog/lib/src/pro_dialog.dart`, package
  README, this handoff.
- Verification: package and app dialog widget tests, Dart formatting,
  `flutter analyze`.

### 2026-08-18 — Confirm before removing an invoice line

- The quantity-stepper delete icon on New invoice (and the same control on
  scan) now asks "Remove item?" before dropping a line, so a mistaken tap
  does not delete it. Decreasing quantity above 1 is unchanged.
- Important files: `invoice_create_screen.dart`, `product_scan_screen.dart`,
  coverage translations, this handoff.
- Verification: Dart formatting and `flutter analyze`.

### 2026-08-18 — Saved invoices share and print natively

- Share, Share / print, and Print on a generated invoice now use the device
  share sheet or print dialog. They no longer open the preview with
  swipe-to-update. Opening PDF from details is read-only; the composer Review
  flow still uses swipe-to-save for unsaved or in-progress documents.
- Important files: invoice details controller/screen, invoice preview
  controller, coverage translations, this handoff.
- Verification: Dart formatting and `flutter analyze`.

### 2026-08-18 — Fix purchase payment sheet controller dispose

- Recording a supplier payment no longer disposes the amount field while the
  sheet is still animating closed. The payment sheet now owns its
  TextEditingController and disposes it with the widget.
- Important files: `purchase_screens.dart`, this handoff.
- Verification: Dart formatting and `flutter analyze`.

### 2026-08-18 — Invoice details Share sends the PDF

- The sticky Share action on invoice details now opens the native share sheet
  for this invoice's PDF. It no longer routes through the preview template
  picker. The AppBar PDF icon still opens preview, print, and template choice.
- Important files: `invoice_details_controller.dart`, `invoice_details_screen.dart`,
  invoice binding, this handoff.
- Verification: Dart formatting and `flutter analyze`.

### 2026-08-18 — Customer statement classic layout

- Restyled the customer statement to match invoice and bill details: name in
  the AppBar, compact period hero, Closing/Invoiced/Received pastel cards
  directly under that identity, grouped From/To rows, accented activity tiles,
  and a sticky PDF preview. Amounts shrink to fit instead of overlapping.
- Important files: `customer_statement_screen.dart`, coverage translations,
  this handoff.
- Verification: Dart formatting and `flutter analyze`.

### 2026-08-18 — Invoice details shows payment first

- Payment activity (Total, Paid, Remaining, and the ledger) now sits
  directly under the billed-to identity card so outstanding money is visible
  before line items. Quotations still omit this block.
- Important files: `invoice_details_screen.dart`, this handoff.
- Verification: layout reorder only; no data or route changes.

### 2026-08-18 — Unified classic AppBar chrome

- Replaced the heavy 22px AppBar title and unmatched naked action icons with
  shared chrome used on both Sales and Purchases: 18px title, hairline, and
  40px plum-outlined wells for back, search, scan, PDF, edit, and workspace
  switch. Document screens add a caption (Invoice, Customer, Purchase bill,
  Supplier) so the title row is easier to scan.
- Important files: app theme, `app_back_button.dart` (`AppBarIconButton`,
  `AppBarTitle`), search AppBar, invoice/customer/product/purchase details,
  dashboard and purchase home, this handoff.
- Verification: Dart formatting, `flutter analyze`, design-system and
  purchase widget tests.

### 2026-08-17 — Purchase workspace classic UI pass

- Restyled every purchase screen to match Sales: quieter home overview with
  Paid/Payable/Overdue metrics, New bill/Supplier actions, grouped recent
  bills, AppBar search on bill and supplier lists, compact status-accent rows,
  quieter supplier/bill forms, and bill details with number in the AppBar,
  Total/Paid/Remaining cards, grouped items/payments, and a sticky payment
  action. Workspace switch on purchase screens is an icon, like Sales Home.
- Bill details now load once and refresh after edit/payment instead of
  recreating a FutureBuilder on every rebuild. Form fields dispose with their
  screens. The supplier-payment sheet owns its amount controller so the field
  is not disposed during the close animation.
- Important files: `purchase_workspace_screen.dart`, `purchase_screens.dart`,
  workspace widget test, this handoff.
- Verification: Dart formatting, `flutter analyze`, and purchase widget tests.

### 2026-08-17 — More screen classic grouped settings

- Replaced the stacked destination cards and circular arrows on More with
  grouped settings panels, a quieter business identity header, and a
  Change workspace list that names Sales and Purchases with a check on the
  active mode. Switching workspace from More stays on More and only updates
  the bottom navigation. Duplicate
  Business profile row was removed because the identity card already opens it.
- Shared `AppMenuGroup`/`AppMenuTile` now render as a single bordered panel
  with inset dividers, so App Settings matches the same quieter treatment.
- Important files: `app_menu_group.dart`, `more_screen.dart`, this handoff.
- Verification: Dart formatting and `flutter analyze`; widget tests that
  cover settings destinations still apply.

### 2026-08-17 — Licensing and demo APK design captured

- Wrote the planned paid-unlock and client-demo design so later sessions can
  implement it after other app work. No runtime license, flavor, or kill
  switch was added.
- Agreed constraints: entitlement must not live in Drift or backup
  `settings.json`; Play/App Store builds use store billing (RevenueCat);
  WhatsApp/direct APKs use GSTIN-bound keys; demo APKs expire on a baked-in
  calendar date and then block all features with “Please contact sales
  person.”
- Important files: `docs/LICENSING_AND_DEMO.md` and this handoff document.
- Verification: documentation only.

### 2026-08-15 — Purchase internal-screen UX alignment

- Replaced the framework-default purchased-item dialog with a responsive 72%
  branded editor, clearer field grouping, sticky primary action, and the shared
  saved/custom unit selector.
- Added in-place purchase item editing plus compact edit/remove action sheets;
  purchase-bill edit/delete and supplier-payment entry now use consistent app
  sheets instead of popup menus and raw alerts.
- Payment entry validates positive values and the current payable balance before
  closing, while repository validation remains the final data-integrity guard.
- Important files: `purchase_screens.dart` and this handoff document.
- Verification: Dart formatting and `flutter analyze` complete with no issues;
  the full automated suite passes (146/146).

### 2026-08-15 — Supplier-first purchasing and shared safeguards

- Added create-only native phone-contact import to Add supplier, including
  permission, Indian-mobile normalization, loading state, and modern success/
  warning/error feedback matching customer import.
- New purchase bills now begin with a dedicated supplier-selection step. Bill
  fields are revealed only after selection; users can create a supplier from
  the same step.
- Added optional mobile/email/GSTIN validation for suppliers; unique required
  bill number, due-date ordering, required items, positive quantity/price,
  0–100 GST, payment balance limits, and a destructive delete confirmation.
- Important files: `purchase_screens.dart`, `purchase_repository.dart`,
  purchase tests, localization coverage, and this handoff.
- Verification covers supplier-first responsive flow, duplicate bill-number
  protection, excessive-payment rejection, clean analysis, full tests, and an
  Android debug build.

### 2026-08-15 — Complete offline Purchase workspace

- Replaced the purchase placeholder with a full Purchase Home, purchase-bill
  list/detail/create/edit flow, supplier list/create/edit flow, payable totals,
  supplier-payment recording/history, search, empty states, and purchase-aware
  More navigation.
- Added a dedicated purchase bottom navigation matching the Sales interaction
  model, plus a labelled Purchases/Sales switch so the workspace action is
  understandable without guessing an icon.
- Added Drift schema v10 tables for suppliers, purchase bills, purchase items,
  and purchase payments. Purchase data is isolated from customers, sales
  invoices, invoice items, and customer payments; backups continue to include
  the whole local SQLite database and workspace preference.
- Important files: `app_database.dart`, `app_database.g.dart`,
  `purchase_repository.dart`, `purchase_models.dart`,
  `purchase_workspace_screen.dart`, `purchase_screens.dart`,
  `app_purchase_navigation.dart`, routes, initial binding, and More.
- Verification: generated Drift code, clean `flutter analyze`, repository
  lifecycle/isolation coverage, responsive purchase workspace coverage, full
  automated suite, and Android debug build.

### 2026-08-15 — Sales/Purchases workspace foundation

- Added a one-time onboarding choice for the starting Sales or Purchases
  workspace. The choice is stored only after selection; skipping the intro no
  longer bypasses it. Existing users with no preference remain in Sales.
- Added a persisted in-app workspace switch on Sales Home, the Purchase shell,
  and the first More tile. Launch and post-business-setup routing respect the
  last active workspace. Backup/restore includes both workspace preferences and
  refreshes the live service after restore.
- Added an isolated Purchase workspace shell that explicitly does not reuse
  customers or sales invoices. Supplier and purchase-bill CRUD remains the next
  implementation phase, avoiding premature schema coupling or fake accounting.
- Added Hindi/Gujarati workspace copy and automated persistence/onboarding
  coverage. Important files: workspace service/switch, onboarding controller
  and choice screen, Purchase workspace screen, splash/business routing,
  backup service, route table, tests, and this handoff.
- No database schema or sales-record changes. Verified with clean analysis,
  all 144 automated tests, and an Android debug APK build.

### 2026-08-15 — Separate list scan action

- Restored scan-to-search for Customers and Invoices/Quotations as a separate
  AppBar icon directly beside Search. Scanning applies the decoded value and
  expands the existing search state.
- The expanded field never contains a scanner: its only trailing action is the
  clear cross when text exists. Product and line-item scanning are unchanged.
- Important files: shared search AppBar, customer/invoice list screens,
  design-system test, and this handoff. No schema or storage changes.
- Verification: formatting, analysis, search widget tests, and full suite.

### 2026-08-15 — Focused customer and invoice search

- Removed barcode/QR actions from customer and invoice/quotation search so the
  field keeps one obvious trailing action: a clear cross whenever text exists.
  Product and line-item barcode workflows are unchanged.
- Search now treats space-separated input as partial, case-insensitive terms.
  Invoice terms can match across document number, customer, and company;
  customer terms can match across name, company, mobile, email, and GSTIN.
- Important files: customer/invoice list screens and repositories, repository
  tests, and this handoff. No schema, storage, backup, or migration changes.
- Verification: formatting, clean analysis, repository tests, design-system
  search tests, and the full automated suite.

### 2026-08-15 — Responsive catalog item form hierarchy

- Refined Add/Edit item into three clearly grouped cards: required essentials,
  invoice defaults, and optional product details. Each section now has a compact
  icon-led heading and supporting copy while preserving every existing field.
- Added a concise create/edit purpose guide, shortened the optional-fields
  action, and retained the existing Product/Service selector, barcode scan,
  field manager, invoice preview, validation, unsaved-change protection, and
  sticky save behavior.
- Typography exclusively uses the shared Plus Jakarta Sans style scale; spacing
  and width continue through the responsive helpers for Android, iOS, and
  tablet layouts.
- Important file: `product_form_screen.dart`; no database, storage, backup, or
  migration changes.
- Verification: formatting, static analysis, focused responsive/design tests,
  and product settings/form tests.

### 2026-08-15 — Proper list search field and scan-to-search

- Customers and Invoices/Quotations expandable search is now one compact
  contained field: search icon, input, in-field clear when text is present,
  and an optional scan control. The coral halo, oversized pill, and sibling
  circular close chip are gone. Sort remains a separate AppBar action.
- Scan opens the existing barcode capture screen and applies the decoded
  value to the current list query (customers: name/mobile/GSTIN; invoices:
  number/customer). Product catalog scan stays on Products & services via
  its own AppBar action; shared `AppSearchAppBar` scan is opt-in (`onScan`).
- Important files: search AppBar, customer/invoice lists, barcode capture
  screen, coverage translation maps, design-system tests, and this handoff.
  No schema or storage changes. Product list was not rewritten.
- Verification: formatting, static analysis, and AppSearchAppBar widget
  tests.

### 2026-08-15 — Compact catalog Add item form

- Replaced the promotional “Build it once” banner and large Product/Service
  tiles with a professional catalog form. Type is an equal-width segmented
  control. Name and price stay required and always visible. Unit, HSN/SAC, and
  GST sit in a visible Invoice essentials card instead of a collapsed mystery
  section. Optional product fields keep Manage fields and category
  recommendations behind a tighter header.
- Create mode keeps one caption line. Edit mode has no “build it once” copy.
  AppBar scan, sticky Save product/service, unsaved-change protection, and
  type-specific fields are unchanged. Prefix icons were omitted on this form
  only; shared text fields were not restyled.
- Important files: product form screen, coverage translation maps, and this
  handoff. No schema or storage changes. Product list was not rewritten.
- Verification: formatting and static analysis on touched files; existing
  product-form controller tests.

### 2026-08-15 — Compact customer account workspace

- Redesigned Customer details as an account workspace: name in the AppBar,
  compact status-aware hero (due / paid / default), shrink-to-fit billed /
  paid / due metrics, phone listed once in Contact & billing, and a strong
  primary action (collect outstanding, statement, or new invoice). Invoice
  history now uses the shared invoice summary card.
- Important files: customer details screen/controller, invoice summary card,
  localization maps, customer details tests, and this handoff. No schema or
  storage changes.
- Verification: formatting, static analysis, customer details tests, and
  invoice summary card tests.

### 2026-08-15 — Compact professional catalog list

- Products & services listing is now a dense catalog, not tall marketing
  cards. Rows use `AppGroupedTile` with list-scale type, price on the right,
  and no repeating peach icon or Product/Service badge. Type appears as a
  small caption only on the All filter. Search moved into the shared
  expandable AppBar; scan and add stay available.
- Important files: product list screen and this handoff. No schema, storage,
  or shared-widget API changes.
- Verification: formatting and static analysis on touched files. No existing
  product-list widget tests asserted the old badge layout.

### 2026-08-15 — Action-first dashboard Home

- Replaced the large month overview and duplicate outstanding reminder with a
  compact this-month Invoiced / Received / Outstanding card. Overdue and
  due-this-week counts open the invoice list on the matching filter, and the
  list below shows invoices to collect when any are waiting.
- Important files: dashboard controller/screen, invoice list filter handoff,
  overview tests, localization maps, and this handoff. No schema changes.
- Verification: formatting, static analysis, and dashboard/responsive tests.

### 2026-08-15 — Compact invoice details identity

- Invoice and quotation numbers now sit in the AppBar. The hero is tighter,
  with billed-to name, phone, and status on the gradient card; tapping the
  customer still opens the customer workspace. Fonts and padding follow the
  same list-scale sizes used elsewhere in the app.
- Important files: invoice details screen and this handoff. No schema or
  storage changes.
- Verification: formatting and static analysis.

### 2026-08-15 — Invoice details payment cards and identity hero

- Moved Total, Paid, and Remaining off the invoice hero and into Payment
  activity, using the soft teal/orange summary cards. Unpaid invoices now
  show this section even before the first payment is recorded.
- The hero is document identity only: number, status, tax mode, item count,
  frosted issued/due chips, and a due countdown. No paid/balance amounts.
- Important files: invoice details screen, localization maps, and this
  handoff. No schema or storage changes.
- Verification: formatting and static analysis.

### 2026-08-15 — Invoice details as a document, not a stack of boxes

- Reworked invoice and quotation details so the screen feels like an open
  bill: a quieter status-aware hero, billed-to and line-item sections, a real
  GST/totals footer, and payment/share actions in the thumb-zone footer.
  Payment activity no longer repeats paid/remaining amounts already shown in
  the hero. Saved customer snapshots still open the customer workspace.
- Important files: invoice details screen, localization maps, and this
  handoff. No schema or storage changes.
- Verification: formatting and static analysis.

### 2026-08-15 — Quieter empty invoice item state

- The empty invoice composer now has one add path instead of four competing
  buttons. A short empty card explains the next step and opens the existing
  add-item sheet; the sticky footer uses the same chooser. Tax, discount and
  notes stay hidden until the first line exists.
- Important files: invoice composer empty card, add-item helpers,
  localization maps, and this handoff.
- Verification: formatting, static analysis, and invoice create tests.

### 2026-08-15 — Give invoice customer names more width

- Invoice list cards now give the customer name about 70% of the text row and
  keep billed/due amounts in the remaining 30%. Names were truncating early
  because the amount column was a fixed 132px.
- Important files: invoice summary card, card tests, and this handoff.
- Verification: invoice summary card tests, formatting, and static analysis.

### 2026-08-15 — Smooth post-restore dashboard handoff

- Removed the post-restore zero-value flash shown in the supplied recording.
  Dashboard report and recent-invoice surfaces now retain an explicit loading
  state until their first restored-database stream values arrive instead of
  presenting temporary `₹0` totals and “No invoices” as real data.
- Runtime rebinding now explicitly disposes any surviving dashboard controller
  and the permanent invoice-list controller (including its quotation tag)
  before replacing repositories. This prevents controllers from retaining
  subscriptions to the closed pre-restore Drift connection.
- The dashboard is now a persistent main-tab controller like the invoice list,
  so returning from Invoices or switching tabs reuses its already-loaded report
  streams instead of replaying the loading surface for several seconds. Restore
  remains the deliberate exception and replaces that controller exactly once.
- Added runtime regression coverage proving that a permanent invoice-list
  controller is removed during restore reconnection. No schema, storage, or
  backup-format changes.
- Important files: initial binding, dashboard controller/screen, runtime reload
  test, and this handoff.
- Verification: recording review, formatting, static analysis, focused restore
  and dashboard tests, and the full automated suite.

### 2026-08-15 — Portable restored business media

- Fixed restored profiles retaining absolute logo, signature, and payment-QR
  paths from the device or simulator that created the backup. Media entries are
  now extracted into the current installation's `business_assets` directory,
  and the restored business profile is updated with those new local paths after
  the database runtime reconnects.
- Missing media entries explicitly clear stale database paths, while business
  setup image widgets also verify file existence before constructing a
  `FileImage`. This prevents `PathNotFoundException` even for older incomplete
  backups.
- Backup ZIP format and database schema are unchanged; existing backups remain
  compatible.
- Important files: backup service, restore status screen, business repository,
  business setup screen, backup tests, and this handoff.
- Verification: formatting, static analysis, focused media/restore tests, and
  the full automated suite.

### 2026-08-15 — In-app restore completion

- Replaced the ineffective iOS `Close app` action with a working `Continue`
  flow. iOS does not permit an app to terminate itself, so successful restore
  now rebuilds the Drift database connection, repositories, export service,
  and backup service before returning through startup routing.
- Restore failures also attempt to reload the current or rolled-back database;
  navigation is only enabled when that recovery succeeds. This keeps users off
  data-driven screens whenever no usable database connection is available.
- Updated English/Hindi/Gujarati completion and recovery copy and expanded the
  restore status regression to verify runtime reload and the Continue action.
- No schema or backup archive changes; the device-local restart marker is
  cleared after the replacement runtime opens successfully.
- Important files: initial binding, restore status screen/tests, localization
  maps, and this handoff.
- Verification: formatting, static analysis, focused restore/runtime tests,
  and the full automated suite.

### 2026-08-15 — App-lock cold-start overlay fix

- Fixed the PIN keypad throwing `No Overlay widget found` after an enabled app
  lock was restored on cold start. The lock gate intentionally renders above
  the root Navigator, so its delete control now uses a direct semantics label
  instead of constructing a Navigator-dependent tooltip.
- Added a widget regression that recreates the production builder hierarchy,
  starts with the PIN lock enabled and locked, verifies the unlock screen and
  accessible delete action, and asserts that rendering raises no exception.
- No database, storage, PIN format, hashing, or backup changes.
- Important files: app-lock screen, app-lock tests, and this handoff.
- Verification: formatting, static analysis, focused app-lock tests, and the
  full automated suite.

### 2026-08-15 — Restart-safe database restore

- Fixed restore closing/replacing the Drift database while invoice, customer,
  dashboard, or other live controllers could still query its isolate, which
  produced `Tried to send Request ... but connection was closed` exceptions.
- Restore confirmation now removes all data-backed routes first and opens a
  dedicated non-dismissible status screen. After route disposal, that screen
  validates and restores the backup, then rebuilds all database-bound services
  before allowing the user to continue.
- Added localized restoring, completion, failure, and close-app states plus
  widget coverage for successful and failed restore handoffs. Existing backup
  archives, validation, rollback, schema, and storage formats are unchanged.
- Important files: backup screen/controller, restore status screen, app routes,
  localization coverage maps, restore status tests, and this handoff.
- Verification: formatting, static analysis, focused backup/restore tests, and
  the full automated suite.

### 2026-08-15 — Explicitly optional business email

- Clarified business setup and profile editing with an “Email address
  (optional)” label. Empty email values continue to save as null, while entered
  values retain format validation.
- Fixed the shared localized `AppTextField` validator adapter converting a
  successful null result into an empty-string error. Flutter treated that as an
  invisible validation failure, causing optional email/mobile and other
  optional validated fields to show a red border and block submission.
- Added Hindi/Gujarati copy and a controller regression assertion covering both
  empty and malformed values, plus a shared-field widget regression. No storage
  or database changes.
- Important files: shared text field, business setup screen/controller test,
  shared validation test, localization maps, and this handoff.
- Verification: formatting, static analysis, focused business-setup test, and
  the full automated suite.

### 2026-08-14 — Creovo Billing application identity

- Renamed the customer-facing application from Creovo Invoice to Creovo
  Billing across Android/iOS launcher metadata, in-app brand copy, permissions,
  PDFs, backup messages, and English/Hindi/Gujarati localization keys.
- Changed Android namespace/application ID and iOS app/test bundle identifiers
  from `com.creovo.invoice` to `com.creovo.billing`. This creates a new native
  app identity, so an installed old build is not upgraded in place and its
  sandboxed data does not automatically transfer.
- New backup filenames use `creovo_billing_backup_...`; the internal SQLite
  archive path remains unchanged so existing backups stay restore-compatible.
- The Dart package name remains `creovo_invoice` to avoid a needless source
  import migration; this is internal and does not affect store identity.
- Important files: Android/iOS platform configuration, app constants, branded
  screens/services, localization maps, package description, and this handoff.
- Verification: formatting, static analysis, automated tests, Android debug
  build, and native bundle-identifier audit.

### 2026-08-14 — Optional four-digit app lock

- Added a localized Settings > Security workspace where users can create and
  confirm a four-digit PIN, change it after verification, or disable the lock
  after entering the current PIN.
- Added a full-screen numeric unlock gate over the existing navigator. It locks
  on cold launch when enabled and whenever the app returns after being paused
  or hidden, without changing onboarding, business setup, or business records.
- Security storage uses a random per-device salt, 12,000 SHA-256 rounds and a
  constant-time comparison; raw PIN digits are never persisted. The lock is an
  app access guard and does not claim to encrypt database/export/backup data.
- Storage changes: new SharedPreferences keys for enabled state, PIN salt and
  PIN hash. No Drift schema or data migration changes.
- Important files: app-lock service and tests, root lifecycle gate, security
  settings UI/route, storage keys, localization maps, and this handoff.
- Verification: formatting, static analysis, focused app-lock tests, and the
  full automated suite.

### 2026-08-14 — One-tap invoice line-item actions

- Removed the extra popup/bottom-sheet step from invoice line items. Each card
  now exposes a clear pencil action that opens the existing editor immediately,
  while the quantity control keeps its direct trash action for removal.
- The faster controls preserve all existing item calculations and storage
  behavior, and use compact branded touch targets without crowding item text.
- Important files: invoice composer, Hindi/Gujarati localization maps, and this
  handoff. No database or migration changes.
- Verification: formatting, static analysis, and the full automated suite.

### 2026-08-14 — Purposeful empty invoice composer

- Replaced the small, floating empty line-item control with a complete first
  item workspace: clear illustration and guidance, a primary saved-catalog
  action, secondary custom-item and barcode-scan actions, and automatic-total
  guidance. The layout uses the existing Creovo surfaces and remains compact
  enough for small phones.
- The sticky footer now changes to `Add first item` while the invoice is empty
  and opens the established add-item chooser. Once an item exists it returns
  to Review invoice/estimate, so users no longer hit validation from an
  apparently active review button on an empty document.
- Important files: invoice composer, localization maps, invoice composer
  widget coverage, and this handoff. No persistence or migration changes.
- Verification: formatting, static analysis, focused narrow-phone widget
  tests, and the full automated suite.

### 2026-08-14 — Complete interface-copy localization audit

- Closed the remaining mixed-language gaps across Hindi and Gujarati,
  including dashboard greetings, dashboard helper text, action labels,
  onboarding, business/customer/product/invoice forms, settings, backup,
  barcode flows, validation feedback, dialogs, tooltips, menus, count phrases,
  and interpolated amount text. Invoice numbers, dates, user-entered values,
  and payment-status values remain data rather than translated interface copy.
- Shared ProDialog titles, messages, and action labels now pass through the
  application localization layer. Dynamic count/amount suffixes are localized
  without changing their numeric or currency values.
- Important files: localization maps and parameter handling, shared dialog
  adapter, localization regression tests, and this handoff. No database or
  storage migration was required.
- Verification: source-copy localization audit, formatting, static analysis,
  focused localization tests, and the full automated suite.

### 2026-08-14 — English, Hindi, and Gujarati localization

- Added app-wide localization with English as the default plus Hindi and
  Gujarati. Users can change language from App Settings > Appearance; the UI
  updates immediately and the choice persists across restarts.
- Added localized Material/Cupertino framework copy, a safe text adapter that
  translates known interface phrases while leaving user-entered business data
  untouched, and localization for shared fields, validation messages,
  dropdowns, search, tooltips, notifications, menus, dialogs, navigation, and
  empty states across all modules.
- Important files: `main.dart`, `app_controller.dart`, `app_localization.dart`,
  localization maps, shared UI widgets, module screens, localization tests,
  `pubspec.yaml`, and this handoff. Storage adds only the
  `language_code` preference; there is no database migration.
- Verification: formatting, static analysis, localization unit tests, and the
  full automated suite.

### 2026-08-14 — Zoomable invoice PDF preview

- Replaced the invoice preview's hidden double-tap-only zoom mode with direct
  pinch zoom and pan gestures, plus double-tap zoom/reset and a compact gesture
  hint. Preview pages rasterize at higher resolution so invoice values remain
  legible when enlarged; the generated PDF itself is unchanged.
- Important file: `invoice_preview_screen.dart`; no storage or migration
  changes.
- Verification: formatting, static analysis, and invoice preview widget tests.

### 2026-08-14 — Swipe-to-confirm invoice save

- Replaced the invoice preview's standard save button with a reusable animated
  swipe-to-confirm control. New documents say `Swipe to create invoice`, saved
  documents say `Swipe to update invoice`, incomplete gestures snap back, and
  the thumb locks into a loading state while persistence completes.
- The swipe track uses the same coral-to-plum primary/secondary gradient as the
  Review invoice action for consistent visual branding.
- Validation and duplicate-submit safeguards remain unchanged. Important files:
  `app_swipe_action.dart`, `invoice_preview_screen.dart`; no storage changes.
- Verification: formatting, static analysis, and focused swipe interaction
  widget tests.

### 2026-08-14 — Invoice create/update success dialog

- Successful invoice persistence now opens a non-dismissible modern dialog over
  the existing invoice preview instead of navigating to a separate completion
  screen. A bundled offline Lottie check animation sits over a stable branded
  invoice mockup and supports reduced motion.
- The dialog distinguishes created from updated documents and offers Share PDF,
  View PDF, and Done. View closes the dialog and leaves the already-generated
  PDF visible in read-only pinch-zoom mode on the same screen; Done returns to
  the correct invoice/quotation listing, and Share rebuilds the saved offline
  PDF with the chosen template.
- Reworked the completion UI after device-video review: a dark branded document
  hero, stable Flutter-rendered invoice mockup, compact Lottie success badge,
  explicit local-save confirmation, and richer Share PDF/View PDF action cards
  replace the sparse centered illustration. The Lottie asset was simplified so
  every supported renderer completes the circle and check animation reliably.
- Success-dialog Share PDF and View PDF actions now use compact circular icon
  controls with labels, tooltips, and accessibility semantics. This reduces
  dialog height and leaves Done as the only full-width primary action.
- Important files: invoice success screen, preview controller, routes, widget
  tests, and this handoff; no storage or migration changes.
- Verification: formatting, static analysis, and focused success-screen tests.
- Post-dialog verification: complete Flutter suite passes all 120 tests.

### 2026-08-14 — Responsive invoice list and financial summary

- Rebuilt invoice rows around a compact customer avatar, invoice/customer/date
  hierarchy, theme-colored status treatment, and right-aligned billed/due
  amounts based on the supplied reference.
- Invoice rows now combine their staggered first-load entrance with restrained
  scroll-aware depth motion and platform-style bouncing physics. Cards subtly
  scale and soften near viewport edges, remain fully readable, and respect the
  operating system's reduced-motion preference. Important files:
  `app_list_motion.dart`, `invoice_list_screen.dart`; no storage changes.
  Verified with static analysis and focused motion, invoice-card, and invoice-
  overview widget tests.
- Added a responsive overview showing received, pending, and overdue totals. It
  subscribes to the complete invoice collection so list search and filters do
  not distort the totals. Current and historical section headers carry their
  invoice count in parentheses instead of repeating a fourth summary metric or
  a separate count line below the filters.
- Important files: invoice list controller/screen, invoice overview widget,
  shared invoice summary card, widget tests, and this handoff.
- Verification: formatting, static analysis, narrow-phone overview/card tests,
  and complete Flutter test suite.
- Follow-up polish keeps payment status at the far right of the invoice-number
  row, customer and billed amount on the second row, and moves the date beside
  the outstanding balance on the final row for faster scanning. Fully paid
  cards omit the now-irrelevant date row and remain a compact two-row card.
- Invoice and customer AppBars show their complete active-record count in a
  smaller parenthesized suffix. The headline count stays stable while search or
  status filters narrow the visible list.
- Invoice and customer tabs no longer repeat a floating add button because the
  central Create destination already exposes every creation flow. Its larger
  gradient control sits slightly above the other bottom-navigation destinations
  for a distinct, modern primary-action hierarchy.
- The main bottom navigation uses a floating icon-only pill: destination names
  remain available to accessibility services but are visually removed, while
  the Create action sits in a raised, surface-ringed gradient circle with a
  small active dot below it.
- The customer tab now opens with total-customer, amount-due, and paid-amount
  metrics, then separates balance-bearing accounts under Needs attention from
  settled/new accounts under All customers. Cards use status-colored accents,
  larger initials, concise invoice state, and billed/due amount hierarchy with
  no trailing arrow; tap opens details, swipe edits/deletes, and long-press
  retains the complete action sheet.
- Customer Due/Paid badges are content-sized and right-aligned above their
  amount rather than stretching across the financial column.
- Customer listing cards intentionally omit mobile/company details and use two
  explicitly aligned rows: name with payment status, then invoice information
  with the relevant total. Full contact data remains in customer details.
- Customer-card amounts use a compact 13px treatment and show outstanding due
  balance when present, otherwise the customer's total billed amount.
- Customer list cards no longer expose mobile/company details. Their compact
  second row now pairs invoice status information with the due-or-total amount;
  contact information remains available on the customer details screen. No
  storage or migration changes were required.
- Changing an invoice or quotation issued date now shifts its due date by the
  same payment-term interval in both create and edit flows. Default terms still
  follow Invoice Defaults, while a manually selected 15-day term remains 15
  days after the newly selected issued date.

### 2026-08-13 — Scan into add-item forms

- The invoice custom-item sheet and catalog Add item form now include a
  scan action. A found catalog product fills name, rate, unit, HSN, GST, and
  SKU so the user can edit values before adding or saving. Unknown codes fill
  SKU on the catalog form and leave the invoice sheet for manual entry.
- Important files: barcode capture screen, invoice item prefill, product form
  scan apply, custom item sheet, capture tests, and this handoff.
- Verification: barcode form-fill tests, formatting, and static analysis.

### 2026-08-13 — Scan barcodes to add products

- Added an offline barcode scanner for adding catalog products while creating
  an invoice or quotation. The camera stays open above a scanned-items list
  with quantity steppers and a running total; Add to invoice applies the
  session to the document. Unknown codes offer Save product with the barcode
  prefilled as SKU.
- Catalog Products & services has a matching scan action to open a found item
  or create one. Grocery and pharmacy presets now include SKU so packaged
  goods can be scanned without extra settings.
- Important files: barcode lookup, scan session/controller/screen, catalog
  scan screen, invoice add-item sheet, camera permission strings, scan tests,
  and this handoff.
- Verification: scan session and product barcode lookup tests, formatting,
  and static analysis.

### 2026-08-13 — Invoice card three-row layout

- Invoice cards now read as: number + date, customer + status, billed amount +
  due amount. The status accent is a left vertical bar again instead of a
  status dot.
- Paid invoices omit the due amount. Unpaid and partial invoices show due on
  the right of the amount row. Large rupee values still shrink to fit.
- Important files: invoice summary card, grouped tile accent, list tests, and
  this handoff.
- Verification: 320px/360px invoice row tests, formatting, and static analysis.

### 2026-08-13 — Restore invoice create FAB and list spacing

- Brought the Invoice list `+` create button back. It was removed earlier to
  avoid duplicating the center dock; the list needs its own create action.
- Put 10px space between invoice cards and customer cards so rows are no
  longer packed into one undivided group. Home recent invoices use the same
  gap.
- Important files: invoice list, customer list, dashboard recent block, and
  this handoff.
- Verification: list widget tests, formatting, and static analysis.

### 2026-08-13 — Grouped ledger lists

- Replaced floating invoice/customer cards with a quiet grouped ledger (Stripe
  / iOS Settings density): one inset surface, hairline dividers, 14px names,
  15px amounts, and a single status treatment (dot + caption). Filters are
  text-only chips. Date-sorted invoices group by month. Home recent invoices
  use the same rows.
- Open balances stay prominent; paid totals mute. Partial rows still show
  `₹ due` under the total. Large rupee values still shrink instead of clipping.
- Important files: grouped tile, invoice summary row, customer list, invoice
  list grouping, dashboard recent block, list tests, and this handoff.
- Verification: 320px/360px invoice and customer overflow tests, formatting,
  and static analysis.

### 2026-08-13 — Invoice card overflow and quieter list names

- Invoice list cards no longer report a bottom RenderFlex overflow when
  Issued/Due dates wrap. The status accent is a left border so the card can
  grow with its content instead of measuring dates as a single line.
- Customer names on Invoice and Customer lists use 14px `listName` instead of
  16px card titles, matching denser ledger rows.
- Important files: invoice summary card, customer summary card, text styles,
  list widget tests, and this handoff.
- Verification: 360px overflow regression for a paid invoice with wrapping
  dates, 320px name-size and amount tests, formatting, and static analysis.

### 2026-08-13 — Amount-safe premium list and Home refresh

- Refreshed Invoice, Customer, and Home presentation so lakh/crore rupee
  values stay readable on 320–360px phones: names ellipsize, amounts shrink
  with shared `AppAmountText` / `AppAmountColumn`, and dates wrap instead of
  truncating ("Due 13...").
- Invoice rows keep ledger density with quieter ID/status, a dedicated amount
  column, and a wrapping Issued/Due line. Customer rows bound the billed
  column so totals cannot overlap identity. Home places the cash-flow
  sparkline in a reserved box below the hero amount and drops the duplicate
  Create invoice button on phones (center dock already creates invoices;
  tablets keep the button).
- Important files: `app_amount_text.dart`, invoice summary card, customer
  list, dashboard overview card, amount/list widget tests, and this handoff.
- Verification: 320px invoice/customer/dashboard overflow tests with
  ₹2,305,800 and ₹99,999,999, existing small-phone dashboard coverage,
  formatting, and static analysis.

### 2026-08-13 — Extracted ProDialog into a reusable package

- Moved the shared dialog surface into `packages/pro_dialog`, a standalone
  Flutter package with no GetX or Creovo dependencies. Creovo keeps
  `AppDialog` aliases and `showAppConfirmDialog` wrappers.
- Copy `packages/pro_dialog` into another repo and add
  `pro_dialog: path: packages/pro_dialog` to use `ProDialog.confirm`,
  `ProDialog.notice`, and the `ProDialog` widget.
- Important files: package sources and README, Creovo path dependency,
  thin `app_dialog.dart` wrapper, package widget tests.
- Verification: package tests, Creovo dialog/unsaved/backup tests,
  formatting, and static analysis.

### 2026-08-13 — ProDialog-style app dialogs

- Rebuilt the shared dialog surface to match the referenced ProDialog clip:
  centered 72px glow icon, 28px card radius, semantic tone colors, typed entry
  motion, and outlined/filled action buttons used everywhere dialogs appear.
- Confirm, notice, delete, backup, unsaved-change, payment reversal, and form
  dialogs now share `AppDialogTone` plus `AppDialogButton` instead of mixed
  Material `TextButton`/`FilledButton` actions.
- Important files: `app_dialog.dart`, confirm/notice helpers, unsaved-change
  scope, invoice/customer/product/backup/settings dialog call sites, and
  dialog widget tests.
- Verification: dialog, unsaved-change, backup, and unit-editor widget tests,
  formatting, and static analysis.

### 2026-08-13 — Compact Invoice ledger rows

- Reworked Invoice List cards into compact ledger rows: document/customer/date
  hierarchy stays on the left while status and amount align on the right.
- Dates now use readable short-month formatting in one metadata line. Fully
  unpaid invoices no longer repeat the same value as both total and balance due;
  a separate due value remains visible for partial payments.
- Removed the Invoice List floating + because the persistent center Create action
  already provides invoice creation, eliminating duplicate controls and list
  obstruction. Quotation history retains its dedicated create FAB.
- Reduced card padding and row gaps without removing invoice information.
- Important files: shared invoice summary card, Invoice List, narrow-card test,
  QA checklist, and this handoff.
- Verification: 320px invoice metadata rendering, formatting, static analysis,
  and responsive regressions.

### 2026-08-13 — Persistent Invoice tab live query

- Fixed the remaining intermittent Invoice List skeleton after create/preview
  navigation by correcting controller ownership rather than only refreshing the
  screen. The primary Invoice tab now keeps one app-lifetime live controller, so
  GetX root-route cleanup cannot cancel its Drift subscription behind the newly
  displayed list.
- Quotation history now uses a separate tagged list controller, preventing the
  permanent Invoice tab controller from being reused for quotation filters.
- Refreshes now await prior subscription cancellation and use generation checks,
  preventing overlapping rebinds from cancelling or overwriting the newest one.
- No invoice storage, list filters, sorting, calculations, or status behavior
  changed.
- Important files: Invoice List binding/controller/screen, lifecycle regression
  tests, QA checklist, and this handoff.
- Verification: repeated query rebinding, invoice/quotation controller isolation,
  formatting, static analysis, and invoice regressions.

### 2026-08-13 — Direct invoice item quantity entry

- Invoice create/edit line-item steppers use the quantity number itself as a
  clean tap target. Tapping it opens a keyboard-focused bottom sheet where
  users can enter values such as 50 directly instead of tapping + repeatedly.
- Entry supports up to three decimal places, rejects zero/invalid quantities,
  shows the item unit, and recalculates totals immediately after confirmation.
- Existing −/+, remove-at-one behavior, pricing, taxes, and persistence remain
  unchanged.
- Important files: invoice composer/controller, controller regression test,
  QA checklist, and this handoff.
- Verification: direct 50-unit calculation, formatting, static analysis, and
  invoice regression tests.

### 2026-08-13 — Material Symbols and signature navigation dock

- Added `material_symbols_icons` 4.2960.0 and adopted its latest Google Material
  Symbols variable icons for primary navigation and quick-create actions.
- Rebuilt bottom navigation as a stable five-slot floating dock with modern
  Material Symbols, complete labels, compact selected-icon treatment, and a
  circular gradient Create control. Fixed widths prevent destinations or the
  create surface from overlapping on real Android devices.
- The dock remains readable at 320 logical pixels, supports light/dark borders,
  preserves all existing root-route behavior, and keeps the create destinations
  unchanged.
- Storage and database schemas are unchanged. Dependency files changed only for
  the new icon-font package.
- Important files: pubspec/lockfile, main navigation, narrow-phone widget test,
  QA checklist, and this handoff.
- Verification: dependency resolution, 320px dock/create-sheet rendering,
  formatting, static analysis, and full regression suite.

### 2026-08-13 — Responsive mobile UI/UX refinement pass

- Refined the Product catalog, Dashboard overview, Invoice list/details,
  Invoice Defaults, and Payment Receipt based on narrow Android screenshots.
- Product search now uses concise mobile copy, cards use tighter spacing, and
  item management moved from a desktop popup to a descriptive bottom sheet.
- Dashboard metrics now stack icon, complete label, and value vertically so
  Received, Outstanding, and Collected remain readable without ellipses.
- Invoice summary dates moved to their own wrapping metadata row; Invoice Detail
  document actions now use a mobile bottom sheet and payment-row actions no
  longer squeeze payment notes or amounts.
- Invoice Defaults uses compact card/text-area spacing. Payment Receipt keeps its
  full AppBar title, groups save/share/print in a bottom sheet, and replaces the
  placeholder “Receipt print / Animation” copy with customer-facing status text.
- No persistence, calculations, PDF generation, or business rules changed.
- Important files: shared invoice summary card; product, dashboard, invoice
  detail, defaults, and receipt screens; responsive tests; QA checklist; handoff.
- Verification: narrow-phone rendering, action-sheet behavior, formatting,
  static analysis, and focused widget regressions.

### 2026-08-13 — Invoice list refresh after creation

- Fixed an intermittent stale Invoice List after saving from the create/preview
  flow. Whenever the list screen mounts it now explicitly rebinds its live Drift
  query, so a GetX controller reused during root-route replacement cannot retain
  a cancelled subscription and remain on skeleton rows until another tab change.
- Query bindings now ignore stale subscription callbacks and leave loading state
  safely if the stream reports an error.
- Invoice persistence, filters, sorting, calculations, and navigation outcomes
  remain unchanged.
- Important files: Invoice List controller/screen, regression coverage, and this
  handoff.
- Verification: repository/live-list refresh, formatting, and static analysis.

### 2026-08-13 — Business edit back-action lifecycle fix

- Fixed the missing back arrow when an existing business profile finishes
  loading after the setup screen's AppBar has already built. The leading action
  now reacts to loading completion and displays the back control on edit step 1.
- First-time setup still hides the step-1 back action, while step 2 continues to
  return to the identity step.
- Important files: business setup screen, edit-mode regression test, and this
  handoff.
- Verification: edit-mode header rendering, formatting, and static analysis.

### 2026-08-13 — Stable compact overflow menus

- Fixed the invoice line-item overflow menu crash caused by applying a tiny
  button-sized constraint to the popup route itself. Item actions now open in a
  properly sized compact menu while the trigger remains visually small.
- Applied the same safe menu constraint to Unit Settings so its compact action
  trigger cannot reproduce the gesture hit-test failure.
- No invoice calculation, item editing, deletion, unit persistence, or storage
  behavior changed.
- Important files: invoice composer, Unit Settings, popup regression test, and
  this handoff.
- Verification: popup open/dismiss regression, formatting, and static analysis.

### 2026-08-13 — Existing-business edit mode

- Business Profile now distinguishes first-time setup from editing an existing
  business. Existing users see Edit business identity / Update business details
  copy instead of onboarding language such as “Let’s make it yours”.
- Edit mode exposes a back button on the first step, retains the step-back action
  on the second, labels the final action Save changes, and returns to the prior
  screen after saving. First-time setup still completes into the dashboard.
- Identity guidance now says it is used across invoices rather than implying the
  user has not yet created their first invoice.
- No schema, storage, profile-field, validation, or setup-completion changes.
- Important files: business setup controller/screen, edit-mode widget test, QA
  checklist, and this handoff.
- Verification: edit/first-time conditional rendering, back-action presence,
  save navigation behavior, formatting, and static analysis.

### 2026-08-13 — Compact Unit Settings workspace

- Redesigned Set default unit to match the grouped field-selection experience:
  concise usage guidance and a compact two-column phone grid that scales
  responsively on larger widths instead of a long one-row-per-unit list. The
  original explanatory header was retained to clearly explain data safety.
- Removed the duplicate Add icon from the AppBar; the labeled Add action beside
  Available units is now the single clear creation entry point.
- Selecting a unit uses the same high-contrast coral/white treatment as product
  field selection. The overflow popup was replaced with a modern bottom action
  sheet containing Set as default, Edit unit, and Delete unit.
- Reduced each picker tile to a single-line 56px control and removed its repeated
  Default unit caption. The selected tile and bottom sheet communicate default
  status clearly while keeping full unit names readable.
- Existing optimistic default persistence, rename/delete safety, and historical
  invoice/product behavior remain unchanged.
- Important files: Unit Settings screen, focused narrow-phone/widget tests, QA
  checklist, and this handoff.
- Verification: formatting, static analysis, compact-grid overflow coverage,
  default repaint tests, and unit editor lifecycle regression.

### 2026-08-13 — Manage product fields from Add/Edit Item

- Added a visible Manage fields action to the Product details section in both
  Add item and Edit item. It opens Product Settings directly, avoiding a detour
  through More or App Settings.
- Returning to the item form immediately refreshes enabled and custom fields;
  newly enabled fields appear in place, hidden fields disappear, and all typed
  item/attribute values remain preserved in their existing controllers.
- The Product details card remains visible even when no optional fields are
  enabled and provides a focused empty-state explanation linking the user to
  Manage fields.
- No schema, storage, backup, invoice snapshot, or validation changes occurred.
- Important files: product form controller/screen, tests, QA checklist, and
  this handoff.
- Verification: formatting, static analysis, field-refresh preservation tests,
  product form rendering, and existing Product Settings regressions.

### 2026-08-13 — Clean grouped Product Settings UX

- Replaced the visually heavy gradient header and long divider checklist with
  a neutral catalog-configuration card, compact category row, active-field
  count, and four task-oriented field groups: Invoice essentials, Identity,
  Product specifications, and Variants & dates.
- Field selection now uses concise add/check chips, making enabled state
  immediately visible while reducing scrolling and removing repetitive
  “Shown/Hidden” labels. Invoice visibility and custom fields remain separate,
  focused controls.
- Selected chips now use a solid coral surface with white text and checkmark for
  accessible contrast. The top panel uses a soft light/dark-aware gradient,
  generous title spacing, subtle active-count badge, and a nested category
  control with a clear Change affordance instead of a harsh divider row.
- Existing category recommendations, field persistence, custom field behavior,
  invoice snapshots, and PDF behavior are unchanged.
- Important files: Product Settings screen, narrow-phone widget coverage, QA
  checklist, and this handoff.
- Verification: formatting, static analysis, narrow-phone overflow test,
  selection/dialog regressions, and responsive design tests.

### 2026-08-13 — Plus Jakarta Sans application typography

- Replaced DM Sans with official Google Fonts Plus Jakarta Sans Regular,
  Medium, SemiBold, and Bold weights to give the app a friendlier premium
  finance-product character while keeping dense invoice information readable.
- Plus Jakarta Sans is now the sole bundled text family across application UI,
  Product Settings, dialogs, bottom sheets, invoices, payment receipts,
  customer statements, and report PDFs. The official SIL license is included.
- Removed all DM Sans assets and active references. No schema, storage, backup,
  validation, calculation, or document-content behavior changed.
- Important files: font assets/license, pubspec, application typography,
  Product Settings, all PDF font loaders, tests, plan, QA checklist, and this
  handoff.
- Verification: font-file validation, no stale DM Sans references/assets,
  static analysis, responsive UI tests, and Unicode PDF generation tests.

### 2026-08-13 — Single bundled font family

- Removed the superseded Inter font declaration, variable font asset, and
  license after DM Sans became the application type family.
- Invoice, payment-receipt, customer-statement, and report PDF generators now
  load DM Sans Regular for offline Unicode output, leaving DM Sans as the only
  bundled text font family.
- The official DM Sans SIL Open Font License remains packaged beside its four
  font weights. No schema, storage, or business behavior changed.
- Important files: font assets, pubspec, all PDF font loaders, product plan,
  QA checklist, and this handoff.
- Verification: no remaining Inter references/assets, static analysis, font
  registration test, and Unicode PDF-generation tests.

### 2026-08-13 — Custom-field dialog controller lifecycle fix

- Fixed Product Settings throwing “A TextEditingController was used after
  being disposed” when closing the Add custom field dialog. The dialog future
  completes as its reverse animation starts, so controller disposal now waits
  until the TextField route transition has fully unmounted.
- The accompanying extreme dialog-column overflow was a cascading render error
  from the disposed controller and is resolved by the same lifecycle fix.
- No schema, storage, backup-format, validation, or field behavior changed.
- Important files: Product Settings screen, focused widget regression test,
  QA checklist, and this handoff.
- Verification: close/cancel dialog regression, formatting, static analysis,
  and Product Settings widget tests.

### 2026-08-13 — Premium Product Settings redesign and DM Sans typography

- Rebuilt Product Settings to match the app’s newer premium workspace style:
  a branded configuration overview, embedded category action, enabled-count
  badge, clear invoice-display preference, concise section guidance, compact
  divided field rows, visible Shown/Hidden states, and a separate custom-field
  section with deletion controls.
- Bundled the official Google Fonts DM Sans Regular, Medium, SemiBold, and Bold
  files plus their SIL Open Font License. DM Sans now provides the clean,
  modern Codex-like sans-serif treatment consistently across Product Settings,
  shared dialogs/sheets, and the rest of the application while remaining fully
  offline on Android and iOS.
- All existing category, toggle, custom-field, search-sheet, persistence, and
  invoice behavior remains unchanged.
- Important files: DM Sans assets/license, app typography and theme, pubspec,
  Product Settings screen, QA checklist, and this handoff.
- Verification: formatting, static analysis, category/settings widget tests,
  narrow-screen overflow coverage, and dark-mode visual structure checks.

### 2026-08-13 — Consistent forward-action arrow placement

- Standardized directional arrows in branded actions so forward/proceed arrows
  always appear after the label. This covers onboarding “Show me more” and
  “Set up my business”, business-setup Continue/Save, invoice Review, and the
  invoice-flow “Save & use customer” action.
- Non-directional action icons such as check, save, add, preview, and document
  symbols retain their intentional leading position.
- No schema, storage, backup-format, or behavior changes occurred.
- Important files: onboarding, business setup, customer form, shared button
  usage audit, and this handoff.
- Verification: formatting, static analysis, button/widget tests, and a
  project-wide directional-arrow usage audit.

### 2026-08-13 — Searchable business-category picker

- Business-category selection now opens at 75% of the available screen height
  so its 15 choices remain comfortably scrollable without looking like a
  cramped partial list.
- Added instant case-insensitive category search, drag-to-dismiss keyboard
  behavior, an empty-result message, and retained selected-row highlighting.
- The same picker is used during first business setup and later changes from
  Product Settings; other shared dropdowns retain their content-sized sheets.
- No schema, storage, backup-format, or category behavior changes occurred.
- Important files: shared dropdown field, business setup, Product Settings,
  design-system tests, and this handoff.
- Verification: formatting, static analysis, and searchable fixed-height sheet
  widget coverage.

### 2026-08-12 — Category-based configurable product details

- Added optional category selection during business setup and a dedicated
  Product Settings workspace reachable from both More and App Settings.
  Fifteen category presets recommend product fields and units but never enforce
  a rigid template.
- Added independent product-field toggles, custom Text/Number field creation,
  invoice-display preference, and category-aware unit recommendations while
  preserving the existing create/edit product workflow.
- Product attributes now persist as structured JSON, participate in catalog
  search, and render compactly in product lists/details. Existing values remain
  stored when fields are hidden or the category changes.
- Invoice line items copy attributes into immutable snapshots and show them in
  invoice edit/details and all PDF templates. Product edits therefore cannot
  alter historical documents.
- Storage/schema changes: schema v9 adds non-null `attributes_json` columns
  with `[]` defaults to products and invoice items. SharedPreferences adds the
  business category, enabled fields, custom fields, recommended units, and PDF
  display preference; all are included in backup/restore settings.
- Important files: business/product attribute models, product settings service
  and screens, business setup, product form/list/details, invoice repositories
  and screens, PDF service, database migration/generated schema, backup service,
  tests, QA checklist, plan, and this handoff.
- Verification: code generation, static analysis, all 81 automated tests, and
  focused schema migration, category settings, product repository, invoice
  snapshot, and every-template PDF tests passed.

### 2026-08-12 — Project-wide modern dialog system

- Added a reusable `AppDialog` with a 24px rounded surface, soft icon tile,
  consistent title/body spacing, constrained responsive width, dark-mode
  styling, scroll support, adaptive wrapped actions, and an optional stacked
  action layout for narrow or three-choice flows.
- Migrated every app-owned Material alert: generic confirmations, unsaved
  changes, customer/product/unit deletion, unit editing, invoice discount and
  additional-charge editors, payment reversal and status confirmations, and
  backup create/restore/restart dialogs.
- Destructive and warning flows now use semantic error/warning icon colors;
  unsaved changes uses full-width stacked Continue editing, Discard, and Save
  draft actions so labels never form a cramped or uneven action rail.
- Dialog behavior, returned values, validation, and persistence remain
  unchanged. No schema, storage, backup-format, or user-data changes occurred.
- Important files: shared app dialog/confirmation/unsaved/unit widgets and the
  customer, product, invoice, settings-unit, and backup screens that host modal
  flows, plus QA checklist and this handoff.
- Verified with formatting, focused unsaved/backup/design-system tests, the
  full automated suite, static analysis, and whitespace checks.

### 2026-08-12 — Invoice-default binding type fix

- Fixed a runtime GetX failure when opening `/invoice/create` or the quotation
  composer after invoice defaults were introduced. Dart inferred
  `Get.find<InvoiceDefaultsService?>()` from the controller's optional
  constructor parameter, but the permanent dependency is correctly registered
  as non-null `InvoiceDefaultsService`.
- Both invoice and quotation bindings now request the explicit non-null service
  type. The optional controller parameter remains only to keep isolated unit
  construction lightweight; production routes always receive the service.
- No schema, storage, backup, or user-data changes were required.
- Important files: invoice binding, QA checklist, and this handoff.
- Verified with formatting, focused route/binding coverage, the full automated
  suite, static analysis, and whitespace checks.

### 2026-08-12 — Professional dashboard account overview

- Reworked the dashboard top area to match the supplied modern finance-card
  reference: compact business avatar/greeting header followed by a clean light
  Business overview card with month context and invoice-count badge.
- Replaced the previous full-gradient cash-flow block with a scan-friendly
  current-month amount, a custom-painted six-month sales sparkline and area
  fill, and three icon-led Received, Outstanding, and Collected metrics.
- Removed the header Settings icon to reduce duplicate navigation; Settings
  remains fully available from More. The card adapts its border/chart treatment
  for dark mode and retains safe truncation on narrow phones.
- Gave the overview a restrained warm blush surface in light mode and a lifted
  plum surface in dark mode so it reads as the primary dashboard summary
  without competing with its graph, metrics, or action colors. The final light
  treatment matches the supplied reference's pale lavender (`#FCFAFF`) and soft
  plum border (`#E9DFF0`).
- Restyled the due-backup prompt to the supplied compact peach treatment with
  the direct `Backup due` / `Protect your latest data with a local backup`
  hierarchy, circular cloud icon, and circular forward action.
- Updated responsive dashboard coverage to require the new overview and verify
  the Settings header action is absent. No data, schema, backup, or settings
  changes were required.
- Important files: dashboard screen/custom painter, responsive layout test, QA
  checklist, and this handoff.
- Verified with formatting, focused small-phone dashboard coverage, the full
  automated suite, static analysis, and whitespace checks.

### 2026-08-12 — Account-rich customer rows and animated lists

- Redesigned customer list rows around modern billing-list hierarchy: avatar,
  customer name, creation date and contact context, with lifetime billed value
  and a clear Paid/Due/No invoices indicator aligned on the right.
- Added `customerId` to in-memory invoice summaries and live customer-list
  aggregation for billed, balance, and invoice count. Draft and cancelled
  documents do not affect customer account indicators; persisted database data
  and historical snapshots are unchanged.
- Moved the row-level Create invoice shortcut into the existing action sheet to
  prevent crowded trailing actions while preserving one-tap customer details,
  edit/delete swipe gestures, and explicit actions.
- Added reusable shimmer-style list skeletons plus staggered fade, upward
  motion, and gentle scale for customer and invoice rows as they load/build on
  scroll. Reduced-motion users receive static rows without entrance animation.
- Added widget coverage for normal and reduced-motion list behavior. No schema,
  migration, backup, or settings changes were required.
- Important files: shared list-motion widgets, customer list controller/screen/
  binding, invoice summary/repository mapping, invoice list screen, motion
  tests, QA checklist, and this handoff.
- Verified with formatting, focused motion tests, the full automated suite,
  static analysis, and whitespace checks.

### 2026-08-12 — Portable CSV and date-range report exports

- Added a focused Export Data workspace under Settings with native save/share
  actions for customers, products/services, invoices, and payment-ledger CSVs.
  Reports link directly to the same workspace.
- Added From/To controls for financial data. Invoice exports filter on invoice
  date, payment exports filter immutable ledger entries on paid-at date, and
  sales reports exclude cancelled invoices.
- CSV output uses an Excel-friendly UTF-8 BOM, RFC-style escaping for commas,
  quotes and line breaks, ISO `YYYY-MM-DD` dates, ISO timestamps for payments,
  decimal major-unit money, and explicit GST, status, reversal, and format
  columns. Empty datasets still export useful headers.
- Added date-range report CSV plus a multi-page-ready Unicode A4 PDF containing
  invoiced/received/outstanding totals and invoice activity.
- Added automated coverage for escaping, Unicode/BOM preservation, documented
  customer columns, and empty exports. No database, migration, or settings
  storage changes were required.
- Important files: data-export service/controller/screen, Settings and Reports
  entry points, routes/bindings, export tests, roadmap, QA checklist, and this
  handoff.
- Verified with formatting, focused export tests, the full automated suite,
  static analysis, and whitespace checks.

### 2026-08-12 — Configurable invoice defaults

- Added a professional Invoice Defaults workspace under Settings covering due
  immediately, 7/15/30-day and custom 1–365-day periods, tax mode, current GST
  presets, payment method, default notes, and default terms.
- New invoices and estimates apply the saved due period, tax mode, notes, and
  terms. Changing the invoice date continues to preserve its default due
  interval until the due date is manually overridden. Custom line items start
  with the configured GST rate, while catalog items retain their saved rate;
  payment entry starts with the configured method.
- Added safe fallbacks for absent/unsupported preferences and automated service
  coverage for first-use values, full persistence, and invalid stored values.
- Storage changes: added SharedPreferences keys for due days, tax type, GST
  basis points, notes, terms, and payment method. Backup export/restore now
  includes integer preferences as well as these new fields. No database schema
  migration is required.
- Important files: invoice-defaults service/controller/screen, Settings route
  and menu, invoice composer/custom-item/payment integration, backup service,
  storage constants, and invoice-default tests.
- Verified with formatting, focused defaults/backup tests, the full automated
  suite, static analysis, and whitespace checks.

### 2026-08-12 — Date-range customer statements and PDF export

- Added ledger-derived customer statements with opening balance before the
  selected range, chronological invoices/payments/reversals, running balance,
  period invoiced/received totals, and closing balance.
- Excluded cancelled invoices and represented reversals as linked debit events,
  preserving the original payment rather than silently netting history.
- Added an account-style Customer Statement route from Customer Details with
  From/To date controls, activity rows, totals, and offline PDF preview, save,
  share, and print actions.
- Added a multi-page-ready A4 statement PDF and automated coverage for opening
  balance, date filtering, invoice/payment/reversal ordering, cancelled invoice
  exclusion, closing balance, and PDF rendering.
- Important files: customer statement model/service/PDF service/controller/
  screen, customer routes/bindings/details entry point, and statement tests.
- No database schema, backup format, or storage-key changes; statements are
  calculated from existing immutable invoice/payment data.
- Verified with formatting, focused ledger/PDF tests, the full automated suite,
  static analysis, and whitespace checks.

### 2026-08-12 — Animated payment receipts and offline receipt PDF

- Added payment receipts backed by immutable ledger entry IDs, using stable
  `RCT-{invoiceId}-{paymentId}` numbers and an A5 PDF containing business,
  customer, invoice, amount, date, method, reference, and balance-after-payment
  details.
- Implemented the supplied animation reference's feel: a gold printer roll,
  vertically unrolling receipt paper, delayed payment-success reveal, replay
  action, and direct receipt preview. The workspace also provides native save,
  share, and print actions.
- Recording a payment now returns the exact new ledger entry and opens its
  receipt experience. Payment history exposes receipt access for valid entries;
  reversed payments are marked and receipt generation rejects them.
- Added receipt PDF tests covering Unicode/INR rendering, stable naming, and
  reversed-payment rejection.
- Important files: payment receipt model/PDF service/controller/screen,
  invoice details payment flow, routes/bindings, and receipt PDF tests.
- No database schema, backup format, or storage-key changes; receipt identity is
  derived from existing immutable invoice/payment primary keys.
- Verified with reference-video inspection, formatting, focused receipt tests,
  the full automated suite, static analysis, and whitespace checks.

### 2026-08-12 — Whole-flow QA lifecycle and small-phone dashboard fix

- Added a file-backed offline lifecycle test that creates a GST business,
  customer, and product, then exercises taxed invoice creation, partial
  payment, explicit reversal, full payment, duplicate/cancel/delete,
  quotation conversion, professional PDF generation, backup creation and
  validation, and historical snapshots after catalog deletion.
- Made the backup database and output locations injectable for deterministic
  end-to-end testing while preserving production defaults.
- Added a full-app 320×568 dark-mode dashboard test. It exposed a real overflow
  between the business-overview heading and invoice-count badge; the heading
  is now constrained and ellipsizes safely.
- Added `docs/QA_CHECKLIST.md` to distinguish passing automated coverage from
  native contact/image/file picker, share/print, gesture, high-volume, and
  physical-device checks that cannot be proven by host widget tests.
- Important files: `offline_lifecycle_test.dart`, `responsive_layout_test.dart`,
  dashboard screen, backup service, and QA checklist.
- No database schema, backup format, or storage-key changes.
- Verified with focused lifecycle/responsive tests, formatting, the full
  automated suite, static analysis, and whitespace checks.

### 2026-08-12 — Cross-form unsaved-change protection

- Added one shared PopScope-based guard for AppBar back, Android system back,
  and iOS back gestures, with consistent `Continue editing` and `Discard`
  choices and keyboard-safe confirmation handling.
- Added baseline snapshots to customer, product/service, business profile, and
  invoice/quotation controllers so untouched and successfully saved forms exit
  without unnecessary prompts while all meaningful field, selector, image,
  customer, item, charge, date, tax, discount, note, and payment edits are
  detected.
- Invoice and quotation composers additionally offer `Save draft`; draft save
  must succeed before the route closes, and a successful save refreshes the
  baseline to avoid a second warning.
- Added widget regression tests for clean exit, continue/discard, and save-draft
  exit behaviour.
- Important files: shared `unsaved_changes_scope.dart`, the four form
  controllers/screens, and `unsaved_changes_scope_test.dart`.
- No database, storage, backup, or migration changes.
- Verified with formatting, focused navigation/controller tests, the full
  automated suite, static analysis, and whitespace checks.

### 2026-08-12 — Production backup safety and local reminders

- Added a mandatory privacy confirmation before backup export explaining that
  the ZIP contains customer, invoice, bank, signature, and payment QR data and
  is not encrypted.
- Added last-successful-backup state, due/up-to-date status, configurable
  7/14/30-day or disabled local reminders, and a due reminder on the dashboard.
- Replaced the transient restore message with an explicit non-dismissible
  completion dialog instructing the user to restart the app before continuing.
- Expanded compatibility coverage for incomplete and newer-version archives,
  successful replacement, failed replacement rollback, restart state, and
  reminder validation. The database-file provider is injectable for isolated
  restore testing without changing production behaviour.
- Storage changes: added `last_backup_at`, `backup_reminder_days`, and
  `restore_completed`; the reminder preference is backed up, while last-export
  and restart state remain device-local.
- Important files: backup service/controller/screen, dashboard controller and
  binding/screen, storage-key constants, and backup service/screen tests.
- Verified with formatting, focused backup tests, the full automated suite,
  static analysis, and whitespace checks.

### 2026-08-12 — Professional dashboard hierarchy

- Refined the dashboard into a more professional business overview with a
  branded business avatar, clearer month context, invoice-count grammar, and a
  three-part financial summary for received, outstanding, and collection rate.
- Improved information hierarchy with section subtitles, consistent action
  alignment, evenly spaced quick-action cards, and a cleaner payment follow-up
  surface that works with light and dark themes.
- Recent invoices now show useful activity context while retaining the shared
  invoice cards and existing navigation behaviour.
- Important file: `dashboard_screen.dart`; no database, storage, backup, or
  migration changes.
- Verified with formatting, the full automated suite, static analysis, and
  whitespace checks.

### 2026-08-12 — Immediate default-unit selection feedback

- Fixed the Set default unit screen so selecting a unit immediately repaints
  that row with its checkmark, selected styling, and `Default unit` label; the
  user no longer needs to leave and reopen the screen to see the saved choice.
- The cause was the selected observable being read only inside ListView's lazy
  item builder, outside the dependency capture of the surrounding `Obx`.
- Added a widget regression test that selects `6mm` and verifies both immediate
  visual feedback and persisted service state.
- Important files: `unit_settings_screen.dart` and
  `unit_settings_screen_test.dart`; no database, backup, migration, or storage
  format changes.
- Verified with formatting, focused tests, the full automated suite, static
  analysis, and whitespace checks.

### 2026-08-12 — Historical migration and corrupt-backup verification

- Added a realistic schema-v5 fixture that upgrades directly to schema v8 and
  verifies unpaid, partially paid, and paid invoices, imported payment rows,
  line items, additional charges, totals, balances, and document type.
- Retained direct schema-v6 and schema-v7 upgrade coverage and added a
  deliberately malformed v7 fixture proving a failed migration is surfaced
  while preserving its source version and user data for recovery.
- Hardened backup validation by checking the embedded database for the SQLite
  file signature and rejecting missing or invalid schema versions before a
  restore can replace local data. Older valid backup schemas remain eligible
  for normal Drift migration after restore.
- Important files: `app_database_migration_test.dart`, `backup_service.dart`,
  and `backup_service_test.dart`.
- No database schema or preference-storage changes; this adds compatibility
  fixtures and validation around the existing schema-v8/backup formats.
- Verified with formatting, static analysis, focused migration and backup
  tests, the full automated suite, and whitespace checks.

### 2026-08-12 — Auditable payment ledger and explicit reversals

- Upgraded the database to schema v8 with payment entry classification and a
  link from each reversal to its immutable original payment.
- Removed automatic cumulative-payment adjustment behaviour from existing
  invoice edits; only a new invoice may establish an opening payment, and all
  subsequent payments are recorded from Invoice Details.
- Added explicit payment reversal with confirmation, mandatory reason,
  duplicate-reversal protection, visible reversal history, and automatic
  invoice balance/status reconciliation.
- Prevented payments on quotations, drafts, and cancelled invoices, and
  prevented edited invoice totals from falling below money already received.
- Renamed the new-invoice field to `Opening payment`, hid it during edits, and
  added guidance on paid invoice edits.
- Important files: `app_database.dart`, generated Drift database code,
  `invoice_payment_model.dart`, `invoice_repository.dart`, invoice create/detail
  controllers and screens, and `invoice_repository_test.dart`.
- Schema/storage change: v8 adds `entry_type` and `reverses_payment_id` to
  `invoice_payments`; existing rows are classified during migration.
- Verified with formatting, static analysis, focused financial tests, full
  automated tests including direct V6→V8 and V7→V8 migration fixtures, and
  whitespace checks.

### 2026-08-12 — Production feature roadmap

- Added a prioritized public-launch roadmap covering financial/data safety,
  release compliance, required V1 features, existing-module improvements,
  UI/accessibility QA, post-launch candidates, and explicit scope exclusions.
- Selected payment-ledger integrity and explicit payment reversal as the first
  implementation priority because downstream balances, reports, receipts, and
  customer statements depend on it.
- Linked the roadmap from the repository README and project handoff.
- Important files: `docs/PRODUCTION_ROADMAP.md`, `README.md`, and
  `docs/PROJECT_HANDOFF.md`; documentation only, with no code/schema changes.
- Verified with Markdown review and whitespace checks.

### 2026-08-12 — Current Indian GST-rate presets

- Centralized the default GST list as 0%, 0.25%, 3%, 5%, 12%, 18%, and 28%,
  covering the standard slabs plus commonly notified special goods rates.
- Replaced free-text GST entry for custom invoice items with a guided picker;
  uncommon notified rates remain available through `Custom rate`.
- Saved product/service forms use the same centralized list, preventing the two
  item flows from drifting apart.
- Important files: `tax_utils.dart`, `product_form_controller.dart`,
  `invoice_create_screen.dart`, and `money_tax_utils_test.dart`; no
  schema/storage changes.
- Verified with formatting, static analysis, automated tests, and whitespace
  checks.

### 2026-08-12 — Simplified customer list header

- Removed the decorative customer-count/`Ready to bill` banner from the top of
  the Customers screen.
- Customer records now begin directly below the searchable AppBar, reducing
  duplicated hierarchy while preserving search, invoice shortcuts, customer
  actions, the add-customer FAB, and the main navigation dock.
- Important file: `customer_list_screen.dart`; no schema/storage changes.
- Verified with formatting, static analysis, automated tests, and whitespace
  checks.

### 2026-08-12 — Dedicated customer creation FAB

- Restored a dedicated extended floating action button for customer creation,
  positioned above the new floating navigation dock.
- Removed creation from the relationship-summary header so the banner remains
  informational and the primary add action stays reachable while scrolling.
- Replaced the header button with a compact `Ready to bill` state marker.
- Important file: `customer_list_screen.dart`; no schema/storage changes.
- Verified with formatting, static analysis, full automated tests, and
  whitespace checks.

### 2026-08-12 — Floating main dock and relationship-first customers

- Rebuilt the phone bottom navigation as a floating rounded dock with a clearer
  active destination, compact labels, and a raised gradient create control;
  all main destinations continue to replace the root route without transitions.
- Removed the Customers tab's duplicate floating add button because creation is
  now available in the dock and the new branded workspace header.
- Reframed Customers as a billing-relationship workspace with a compact count
  summary, explicit add action, denser customer rows, and a one-tap invoice
  shortcut on every customer.
- Preserved full-card details navigation plus swipe edit/delete and the existing
  action sheet, giving frequent and advanced actions distinct affordances.
- Important files: `app_main_navigation.dart` and
  `customer_list_screen.dart`; no schema/storage changes.
- Verified with formatting, static analysis, full automated tests, and
  whitespace checks.

### 2026-08-12 — Customer account layout consolidation

- Consolidated customer identity and lifetime billed/paid/due metrics into one
  aligned account card, reducing stacked-card noise and keeping related context
  together.
- Rebuilt contact/billing rendering from the visible data set so optional fields
  remain consistently aligned and separators appear only between actual rows.
- Redesigned invoice history as compact ledger rows with a stable left identity
  column and right-aligned status/total column; removed the competing secondary
  `View & manage` action row because the complete card is already tappable.
- Refined the history header and `New invoice` action sizing for a clearer
  section hierarchy on phones and tablets.
- Important file: `customer_details_screen.dart`; no schema/storage changes.
- Verified with formatting, static analysis, full automated tests, and
  whitespace checks.

### 2026-08-12 — Unified modern dropdown controls

- Audited all dropdown-style controls and replaced the final native form
  dropdown—the payment-method selector—with the shared `AppDropdownField`.
- Payment methods now open in the app's rounded, icon-led selection sheet with
  clear selected-state treatment instead of the platform's dated menu overlay.
- Extended the common dropdown with a disabled state so asynchronous forms can
  prevent changes without falling back to a different control.
- Confirmed remaining `PopupMenuButton` usages are contextual action menus, not
  form dropdowns, and therefore remain appropriate.
- Important files: `app_dropdown_field.dart` and
  `invoice_details_screen.dart`; no schema/storage changes.
- Verified with formatting, static analysis, full automated tests, and
  whitespace checks.

### 2026-08-12 — Full invoice operations from customer history

- Changed customer invoice-history navigation to open the standard invoice
  workspace instead of a restricted read-only variant.
- Customer-scoped invoices now support every existing status-appropriate
  operation: full details and payment history, edit, record payment, duplicate,
  cancel/delete, and PDF preview/download/share/print.
- Removed the now-unnecessary read-only navigation models, controller guards,
  hidden action states, and preview restrictions to keep one consistent invoice
  workflow throughout the app.
- Important files: `customer_details_screen.dart`,
  `invoice_details_controller.dart`, `invoice_details_screen.dart`,
  `invoice_preview_controller.dart`, and `invoice_preview_screen.dart`; no
  schema/storage changes.
- Verified with formatting, static analysis, full automated tests, and
  whitespace checks.

### 2026-08-12 — Modern customer account and read-only invoice history

- Rebuilt customer details as a modern account workspace with a branded
  identity hero, lifetime billed/paid/due metrics, and structured contact and
  billing tiles that omit empty values.
- Replaced the five-record recent-invoice preview with the customer's complete
  invoice history, including issue date, status, total, remaining due amount,
  and a clear `View & export` affordance.
- Added typed invoice navigation arguments and strict read-only invoice-detail
  mode. History records expose full invoice/payment details and PDF preview,
  download, sharing, and printing while hiding and guarding every mutation.
- Added read-only PDF preview mode so history exports never show the document
  save action or alter the stored invoice.
- This initial restriction was superseded by the later full-operation customer
  history workflow.
- Important files: `customer_details_screen.dart`,
  `customer_details_controller.dart`, `invoice_navigation_args.dart`,
  `invoice_details_controller.dart`, `invoice_details_screen.dart`,
  `invoice_preview_controller.dart`, and `invoice_preview_screen.dart`; no
  schema/storage changes.
- Verified with formatting, static analysis, full automated tests, and
  whitespace checks.

### 2026-08-12 — Review action uses forward-reading order

- Reordered the fixed composer action to show `Review invoice`/`Review
  estimate` first and the forward arrow on the right.
- Extended the shared `AppButton` with an optional trailing icon so this
  reading order is reusable without duplicating button styling.
- Added widget coverage confirming the trailing icon renders after its label.
- Important files: `app_button.dart`, `invoice_create_screen.dart`, and
  `design_system_test.dart`; no schema/storage changes.
- Verified with formatting, static analysis, full automated tests, and
  whitespace checks.

### 2026-08-12 — Invoice-only customer pricing override

- Made each populated invoice line's rate a compact editable price chip that
  opens a focused price sheet directly from the composer.
- Added explicit copy explaining that an override changes only the current
  invoice snapshot and never writes back to the saved product/service catalog.
- Added controller support for replacing an invoice line rate and immediately
  recalculating line totals, taxes, discounts, and the invoice total.
- Added regression coverage proving a customer-specific invoice price leaves
  the source catalog model unchanged.
- Important files: `invoice_create_screen.dart`,
  `invoice_create_controller.dart`, and `invoice_create_controller_test.dart`;
  no schema/storage changes.
- Verified with formatting, static analysis, full automated tests, and
  whitespace checks.

### 2026-08-11 — Compact invoice line-item composer

- Reworked populated invoice line items into compact two-line rows: item
  identity and actions remain on top, while quantity and the unlabelled line
  amount share one concise bottom row.
- Reduced stepper, menu, card, and section-action dimensions so invoices with
  many items expose more useful content without removing edit, delete, or
  quantity controls.
- Renamed the contextual `Add item` action to `Add` because the surrounding
  `Line items` heading already supplies the object and avoids repeated copy.
- Important file: `invoice_create_screen.dart`; no schema/storage changes.
- Verified with formatting, static analysis, full automated tests, and
  whitespace checks.

### 2026-08-11 — Removed redundant picker Clear action

- Removed the standalone Clear action from the catalog picker filter row.
- The top tri-state checkbox remains the single bulk select/deselect control,
  while each item checkbox supports precise invoice membership changes.
- Removed the state tracking that existed only to conditionally show Clear.
- Important file: `invoice_item_picker_screen.dart`; no schema/storage changes.
- Verified with formatting, static analysis, full automated tests, and
  whitespace checks.

### 2026-08-11 — Non-redundant picker clear action

- Hid the catalog picker's Clear shortcut whenever the top checkbox confirms
  that every currently visible result is selected, avoiding two controls for
  the same deselect-all outcome.
- Clear remains available for partial selections, while the tri-state checkbox
  continues to own visible select/deselect behavior across search and filters.
- This intermediate behavior was superseded by the later removal of Clear.
- Important file: `invoice_item_picker_screen.dart`; no schema/storage changes.
- Verified with formatting, static analysis, full automated tests, and
  whitespace checks.

### 2026-08-11 — Catalog picker adds and removes invoice lines

- Changed the full-screen catalog picker from append-only selection into an
  invoice membership editor: saved items already on the invoice start checked
  and can be unchecked for removal, while unchecked catalog items can be added.
- Replaced the disabled Added badge with an interactive checkbox plus On invoice
  or Will remove context. Apply item changes returns additions and removals in
  one result; leaving an item selected preserves its existing invoice quantity.
- Added a controller batch-sync path that removes deselected product-backed
  lines, adds new selections, and recalculates once. One-time custom lines are
  unaffected because they are not catalog membership records.
- Updated controller regression coverage for simultaneous removal/addition and
  existing-quantity preservation.
- Important files: invoice item picker, invoice create screen/controller, and
  controller test; no schema/storage changes.
- Verified with formatting, static analysis, full automated tests, and
  whitespace checks.

### 2026-08-11 — Compact catalog select-all control

- Replaced the text-heavy Select/Deselect visible action in the invoice item
  picker with one top checkbox aligned to the result count.
- The checkbox communicates unchecked, partially selected, and fully selected
  states for the current search/filter results and toggles only those visible
  selectable records; its tooltip preserves explicit accessibility guidance.
- Important file: `invoice_item_picker_screen.dart`; no schema/storage changes.
- Verified with formatting, static analysis, full automated tests, and
  whitespace checks.

### 2026-08-11 — Scalable multi-item invoice picker

- Replaced the single-select saved-item bottom sheet with a dedicated
  full-screen catalog route suitable for 100+ products and services.
- Added debounced name/description/HSN search, All/Product/Service filters,
  persistent multi-select checkboxes, result and selection counts,
  select/deselect visible, clear selection, distinct empty/no-match states,
  and a sticky bulk-add action.
- Catalog items already on the invoice are recognized by ID so selection can
  be synchronized without duplicate lines; quantity remains controlled from
  the invoice. Users can create a new product/service from the picker and it is
  selected immediately on return. (A later entry adds removal from this view.)
- Added a controller bulk-add path that merges the selected catalog records and
  recalculates the invoice once, avoiding one recalculation per item at scale.
- Important files: invoice item picker screen, invoice create screen/controller,
  app routes/router, and invoice create controller test.
- No schema or storage changes. Verified with formatting, static analysis, full
  automated tests, and whitespace checks.

### 2026-08-11 — Final focused invoice composer

- Removed the redundant Customer/Items/Review wizard strip: customer selection
  already happens first and the persistent footer already owns Review.
- Consolidated customer identity and invoice number/dates into one shorter
  header with a full-row customer affordance and one shared metadata surface.
- Replaced the numbered section treatment with a direct Line items heading,
  live count badge, and compact add action so invoice content becomes the
  primary visual focus.
- Removed the duplicate full totals card from phone layouts; the persistent
  footer continues to show the live grand total while tablets retain their
  dedicated live-summary rail. Tax, discounts, charges, paid amount, notes, and
  terms remain available through the secondary disclosure.
- Important file: `invoice_create_screen.dart`; no schema or storage changes.
- Verified with formatting, static analysis, full automated tests, and
  whitespace checks.

### 2026-08-11 — Quantity-one removal affordance

- Updated invoice item steppers so the decrement icon becomes a clearly
  colored delete action when quantity reaches one.
- Tapping that contextual delete action removes the invoice line immediately;
  quantities above one continue to decrement normally and the item action menu
  remains available as a secondary edit/remove path.
- Important file: `invoice_create_screen.dart`; no schema or storage changes.
- Verified with formatting, static analysis, full automated tests, and
  whitespace checks.

### 2026-08-11 — Compact long-invoice item list

- Redesigned populated invoice item cards into compact numbered rows that keep
  name, per-unit price, unit, optional GST, line total, actions, and quantity
  controls visible without the previous divider-heavy vertical footprint.
- Added the live item count to the section heading so users can understand a
  long invoice at a glance; the empty-item onboarding remains unchanged.
- The denser hierarchy substantially reduces scrolling for invoices with 20
  items while preserving edit, remove, increment, and decrement behavior.
- Important file: `invoice_create_screen.dart`; no schema or storage changes.
- Verified with formatting, static analysis, full automated tests, and
  whitespace checks.

### 2026-08-11 — Editorial professional invoice PDF

- Rebuilt the Professional PDF as a distinct document layout instead of a
  color variation of the shared template, taking direction from modern
  business invoice hierarchy without copying the supplied reference.
- Added a logo/business identity header, full customer and invoice metadata,
  alternating description-friendly item rows, payment instructions/QR beside
  totals, highlighted amount due, notes/terms, and authorized signature area.
- Optional business, customer, tax, payment, QR, description, and signature
  content only renders when available, preserving a clean document with sparse
  profiles while supporting complete GST invoices.
- Important file: `invoice_pdf_service.dart`; no schema or storage changes.
- Verified all templates with the existing Unicode PDF regression, rendered
  the Professional A4 output to PNG with Poppler, visually inspected spacing,
  alignment, legibility, footer, and currency glyphs, and ran full project
  formatting, static analysis, tests, and whitespace checks.

### 2026-08-11 — Unambiguous invoice quantity stepper

- Corrected selected invoice item cards so the minus/plus stepper displays
  only the numeric quantity instead of incorrectly joining quantity and unit.
- Kept unit context with the per-unit rate (`price / unit`), preventing values
  such as `2 6 mm` from implying that the unit is part of the quantity.
- Important file: `invoice_create_screen.dart`; no schema or storage changes.
- Verified with formatting, static analysis, full automated tests, and
  whitespace checks.

### 2026-08-11 — Modern catalog item composer

- Redesigned product/service creation and editing as a compact task-focused
  composer with a branded purpose panel and clearer product/service choices.
- Grouped the required name and price with the optional description in one
  cohesive essentials card, reducing visual fragmentation and unused space.
- Added a live invoice-line preview that reflects the entered name, price,
  selected unit, currency, and item type before saving.
- Kept unit, GST, and HSN/SAC details progressively disclosed and retained the
  responsive two-column tablet layout and existing persistence behavior.
- Important file: `product_form_screen.dart`; no schema or storage changes.
- Verified with formatting, static analysis, full automated tests, and
  whitespace checks.

### 2026-08-11 — Cart-like invoice item behavior

- Changed saved catalog selection so choosing the same product/service again
  increments its existing invoice-line quantity instead of appending duplicate
  rows. Identity uses the saved product ID with a safe name/unit/rate fallback.
- Redesigned populated item cards with a product anchor, clearer per-unit price
  and tax metadata, direct minus/plus quantity controls, and a dedicated line
  total. Edit and remove remain in a compact contextual menu.
- Quantity decrement stops at one to avoid accidental deletion; removal remains
  an explicit action. Custom one-time lines remain independent.
- Important files: invoice create controller/screen; added controller regression
  coverage for merge, quantity, totals, and decrement behavior.
- No schema/storage changes. Verification includes analysis and full tests.

### 2026-08-11 — Immediate invoice-details refresh

- Fixed invoice details occasionally showing stale balance, paid amount,
  status, or payment activity until back navigation/hot reload.
- The details controller now pins its invoice ID at initialization instead of
  repeatedly depending on global `Get.arguments` after nested routes, explicitly
  notifies invoice/payment Rx observers after each database read, and exposes a
  shared reload path used by payments, edits, cancellation, and status changes.
- Payment flow performs a final reload after the modal route is completely
  removed, ensuring the visible details route paints the committed values.
- Important files: invoice details controller/screen. No schema changes.
- Verification covers formatting, static analysis, repository payments, full
  tests, and whitespace checks.

### 2026-08-11 — Invoice customer and item picker redesign

- Redesigned the shared create/edit invoice selection sheet for both customers
  and catalog items with a taller safe-area layout, contextual header guidance,
  search labels, clear-search control, and live result counts.
- Replaced plain ListTiles with bordered selection cards, strong identity/type
  icons, two-line metadata, and an explicit add affordance. Customer rows show
  company and mobile together; catalog rows show product/service type, unit,
  and formatted price.
- Reduced the visual dominance of create-new actions by using an outlined
  secondary action, and separated true empty states from no-search-match states.
- Important file: invoice create screen. No schema/storage changes.
- Verification: formatting, analysis, full responsive/widget/unit tests, and
  whitespace checks.

### 2026-08-11 — Dashboard first-screen hierarchy refinement

- Refined the dashboard around cash awareness and frequent actions: the monthly
  overview is more compact, adds received-vs-invoiced collection progress, and
  retains clear received/outstanding values.
- Added an actionable outstanding-payment prompt that shows the exact amount
  waiting to be collected and opens invoices for follow-up.
- Reorganized creation actions under a clear Create quickly heading, promoted
  invoice creation to the single primary action, moved Reports to a lightweight
  header action, and improved secondary action touch targets with icon tiles.
- Preserved the shared invoice summary component for consistent recent-invoice
  behavior and added bottom scroll breathing room above navigation.
- Important file: dashboard screen. No schema/storage changes. Verification:
  formatting, analysis, responsive/widget tests, full suite, and diff checks.

### 2026-08-11 — Immediate default-unit selection feedback

- Changed default-unit selection to update its `Obx` state immediately instead
  of waiting for SharedPreferences I/O, so tapping a unit moves the checkmark
  and Default unit label in the same interaction frame.
- Persistence remains awaited and the previous selection is restored if the
  write fails. `update()` is intentionally not used because this screen is
  reactive with Rx/Obx rather than `GetBuilder`.
- Important file: unit settings controller; added timing regression coverage.
- No schema or storage-format changes. Verification includes full tests.

### 2026-08-11 — Unit-editor controller lifecycle fix

- Fixed the Add/Rename unit dialog crash caused by disposing a locally-owned
  `TextEditingController` before Flutter completed the route exit animation.
- The editor is now a dedicated stateful dialog that owns and disposes its
  controller with the widget lifecycle, prevents duplicate async submissions,
  and keeps validation errors inside the open dialog.
- The subsequent Overlay `_dependents.isEmpty` assertion was cascading from the
  controller failure and is resolved by the same ownership correction.
- Important file: unit settings screen; added a widget regression test that
  creates a unit, completes the dialog animation, and asserts no exception.
- No schema or storage changes. Verification includes analysis and full tests.

### 2026-08-11 — Remaining-balance payment shortcut clarity

- Clarified Record payment so its full-payment shortcut displays and fills the
  exact outstanding balance, never the invoice grand total or cumulative paid
  amount. For example, ₹182 total minus ₹100 already paid fills ₹82.
- The field remains an “Amount received now” entry and repository validation
  rejects values above the current balance before appending to payment history.
- Important file: invoice details payment sheet. No schema/storage changes.
- Verification: formatting, static analysis, full tests, and repository payment
  coverage for successive partial payments and remaining-balance calculation.

### 2026-08-11 — Create-invoice review flow refinement

- Anchored Review invoice/estimate to the far-right edge of the fixed bottom
  action bar with a responsive bounded width, leaving a stable total summary on
  the left and preventing centering or clipping on narrow screens.
- Simplified the long live-summary card into a compact financial snapshot with
  Total, Paid, and Due emphasized together; detailed non-zero discounts, taxes,
  charges, and round-off remain visible above it.
- Refined populated item rows with numbered visual anchors and right-aligned
  line totals, keeping edit/duplicate/remove in the existing contextual menu.
- Important file: invoice create screen. No schema or storage changes.
- Verification: formatting, static analysis, full widget/unit suite, and diff
  whitespace checks.

### 2026-08-11 — Custom units and app-wide default

- Added a top-level Customization section to More with a Set default unit
  destination. Users can add, rename, delete, and select the default unit from
  one focused manager; deleting or renaming never rewrites historical items.
- New product/service forms and one-time invoice items now start with the
  selected default unit. Existing product and invoice values remain unchanged.
- Persisted the managed unit list and default selection in app preferences and
  included both values in backup/restore settings. Older custom-unit values are
  folded into the initial managed list for compatibility.
- Important files: unit service/storage keys, backup service, More/routes,
  unit settings controller/screen, product and invoice item creation, tests.
- Verification covers default selection, rename/delete fallback, and custom
  unit creation.

### 2026-08-11 — Partial-payment ledger and history

- Added an invoice payment ledger containing amount, paid date/time, method,
  optional reference, and optional note. Recording a payment now appends an
  entry and recalculates cumulative paid, remaining balance, and invoice status.
- Invoice Details now shows payment progress, paid and remaining amounts, and a
  newest-first activity history. The payment sheet captures the amount received
  now rather than asking users to overwrite a cumulative total.
- Migrated schema from 6 to 7 with a safe backfill: existing invoices with a
  paid balance receive one `Previous payment` ledger entry dated at their last
  update. Ledger rows cascade when an invoice is deleted and are naturally
  included in full SQLite backups.
- Create/edit flows that supply an initial cumulative paid amount are reconciled
  into an `Opening payment` or `Adjustment` entry so the displayed balance and
  payment activity cannot silently diverge.
- Important files: Drift database/generated schema, payment model, invoice
  repository/controller/details UI, repository tests, and handoff.
- Verification includes cumulative/status calculations and persisted payment
  method/reference history. Backup format remains unchanged; schema metadata is
  now 7.

### 2026-08-11 — Complete PDF party details

- Expanded generated invoice headers to show available business owner, mobile,
  email, complete address, GSTIN, and PAN details beneath the business identity.
- Expanded the full-width Bill To section to conditionally show customer name,
  company, mobile, email, complete address, and GSTIN; blank fields remain
  hidden so sparse invoices stay compact.
- Strengthened the PDF renderer test fixture with full owner/customer details
  and continued rendering all five templates with INR currency.
- Important files: invoice PDF service and invoice repository/PDF tests.
- No database, storage, backup, or migration changes.

### 2026-08-11 — Responsive invoice review action

- Rebalanced the create-invoice footer so the total and review action share the
  available width predictably instead of allowing the CTA to clip at the edge.
- Hardened the shared gradient button with single-line constrained labels and
  added a narrow-width widget regression test for long icon/button text.
- Important files: shared button, invoice create screen, design-system tests.
- No database, storage, backup, or migration changes.

### 2026-08-11 — Accessible invoice hero contrast

- Darkened the invoice summary gradient across plum, coral, and teal stops so
  white text remains legible throughout the surface.
- Increased supporting-label weight/opacity and moved issue/due metadata onto
  darker glass panels with subtle borders and higher-contrast icons.
- Important file: invoice details screen.
- No database, storage, backup, or migration changes.

### 2026-08-11 — Modern secondary navigation tiles

- Replaced the traditional grouped settings-table appearance with individual
  tactile destination tiles: soft icon blocks, compact typography, circular
  forward affordances, subtle card depth, and spacing instead of heavy dividers.
- The shared `AppMenuGroup`/`AppMenuTile` implementation updates both More and
  App Settings consistently, including dark mode and tablet layouts. Tightened
  the More business header and strengthened section-label hierarchy.
- Important files: shared menu group and More screen.
- No database, storage, backup, or migration changes.

### 2026-08-11 — Customer edit GetX scope fix

- Removed an invalid reactive wrapper from the edit-only mobile field branch.
  The contact-import progress remains reactive during creation, while editing
  now renders a normal field because contact import is intentionally absent.
- Updated the sticky form action surface to follow light/dark theme colors.
- Important file: customer form screen.
- No database, storage, backup, or migration changes.

### 2026-08-11 — Focused invoice details hierarchy

- Compressed the invoice hero while keeping number, status, balance, total,
  paid amount, issue date, and due date visible in one glance.
- Removed the duplicate totals card and folded its useful values into the hero,
  bringing customer and line-item content above the fold. Customer identity,
  company, mobile, and GSTIN now share one compact row without decorative empty
  space; items use a count, denser rows, and separators for faster scanning.
- Payment remains the strongest action, with sharing clearly secondary.
- Important file: invoice details screen.
- No database, storage, backup, or migration changes.

### 2026-08-11 — Reliable, template-ready invoice PDFs

- Fixed missing Indian rupee symbols by embedding a bundled Unicode font into
  every generated PDF instead of relying on the limited built-in PDF fonts.
- Rebuilt line-item table sizing around explicit flexible columns, right-aligned
  numeric values, smaller document typography, alternating rows, and wrapping
  so quantity, rate, tax, and amount values no longer collide.
- Kept the current widely adopted `pdf` + `printing` stack at their latest
  configured releases; refreshed professional, modern, and compact templates
  toward the Creovo coral/plum identity while retaining five selectable styles.
- Important files: invoice PDF service and project handoff.
- No database, storage, backup, or migration changes.

### 2026-08-11 — Unified gradient primary actions

- Standardized the coral-to-plum gradient action shown in the customer flow as
  the app-wide primary CTA for create, save, review, share, and continue tasks.
- Replaced remaining one-off screen-level primary buttons in invoice creation,
  invoice preview, item details, backup, and item-entry flows with the shared
  `AppButton`, including consistent loading and disabled states.
- Kept compact selectors, filters, secondary outlined actions, inverse banner
  actions, and destructive confirmations purpose-specific so the primary CTA
  remains clear. Exported the shared menu group through the widget barrel.
- Important files: shared button/widget exports and affected feature screens.
- No database, storage, backup, or migration changes.

### 2026-08-11 — Scannable More and settings navigation

- Replaced the horizontally scrolling More tool carousel with three compact,
  purpose-based groups: Create & manage, Insights & data, and Preferences.
- Every destination is now visible in the normal vertical reading path, with a
  descriptive subtitle and consistent disclosure chevron. App Settings uses
  the same shared grouped-row component for a coherent child-screen experience.
- Important files: shared menu group widget, More screen, App Settings screen.
- No database, storage, backup, or migration changes.

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
