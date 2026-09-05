# Creovo Billing — Whole-Flow QA Checklist

Last updated: 2026-09-05

This checklist separates repeatable automated coverage from native operations
that still require an Android/iOS device. Release signing and store submission
remain intentionally out of scope until explicitly requested.

## Automated and passing

- Documents, Parties, and catalog filters use the same cream segmented control
  with a sliding white pill. Icon and label sit on the pill midline. Filter-chip
  counts line up with their labels. Phone-dock icons share one baseline. Tap or
  horizontal swipe preserves the active list state without a travelling tab bar.
- Online splash re-reads Firestore `status` and `trialEndsAt`. An expired trial
  opens Creovo Yearly as the selected plan with Subscribe. The last trial day
  while offline asks to turn on internet. Entitlement prefs are not restored
  from a backup ZIP.

- Forward/proceed arrows in branded buttons appear after their text; semantic
  action icons remain before their text.
- Business-category pickers use a searchable 75%-height sheet in setup and
  Product Settings, including filtered and empty-result states.
- Product Settings uses its premium overview/field hierarchy without overflow
  on narrow phones; locally bundled Plus Jakarta Sans renders consistently
  offline across the screen, its dialogs/sheets, and the wider app.
- Product fields are grouped into essentials, identity, specifications, and
  variant/date chips; selection remains readable without divider-heavy rows.
- Selected field chips have clearly visible text/checkmarks in light and dark
  modes; the catalog header and category action remain readable on narrow phones.
- Add/Edit Item exposes Manage fields, returns with updated standard/custom
  fields immediately, and preserves already typed item values.
- Unit Settings has one labeled Add action, a compact responsive selection grid,
  visible default state, and per-unit Default/Edit/Delete bottom-sheet actions.
- Returning from invoice creation/preview immediately refreshes Invoice List;
  the loading skeleton settles without requiring a tab change.
- Repeated root-route replacement keeps the primary Invoice live query active;
  quotation history uses an isolated tagged controller.
- Invoice ledger rows keep customer, short issued/due dates, status, and amount
  readable at 320px without duplicate full-balance text or a redundant list FAB.
- At narrow Android widths, Dashboard metric labels and Invoice List issue/due
  dates remain complete; Product search copy and Payment Receipt title do not
  truncate. Product and Invoice actions open mobile bottom sheets.
- The Material Symbols navigation dock displays all destination/Create labels
  without overlap and remains overflow-free at 320px in light and dark themes.
- Invoice create/edit quantity values open a direct-entry sheet, accept whole or
  three-decimal quantities, reject zero/invalid input, and update totals.
- Existing Business Profile opens with edit-specific copy, a first-step back
  action, Save changes, and returns to the previous screen after saving; only
  first-time setup uses onboarding language and dashboard completion routing.
- Plus Jakarta Sans is the only bundled UI/PDF font; invoice, receipt,
  statement, and report PDFs retain Unicode and Indian-rupee rendering.
- Opening, typing in, cancelling, or saving the custom-field dialog completes
  its close animation without disposed-controller or cascading overflow errors.

- First launch reaches account OTP, then onboarding, then business setup. OTP
  shows the hero, then number/OTP card, then benefit pills (no brand AppBar
  or Welcome title), with a country picker (India +91), plan-only helper copy,
  and numbers saved on this phone.
  Indian account mobiles must start with 6–9. Tap Use a number from this
  phone to pick from a sheet. Invoice mobile is local letterhead only.
  Account mobile is not printed on invoices. If Firestore is off, Verify
  shows a create-database or deploy-rules error instead of crashing.
  Shop setup must not open until Verify succeeds; a restart with a Phone
  session but no entitlement returns to OTP. Publish the full
  `firestore.rules` file starting with `rules_version`.
- Business profile persists with GST identity and invoice defaults.
- Customer create, search, edit, validation, and soft delete.
- Product/service create, filter, edit, units, GST presets, and soft delete.
- Complete GST lifecycle: business → customer → product → invoice → partial
  payment → reversal → full payment.
- Payment receipt numbering, INR PDF generation, and reversed-payment receipt
  blocking.
- Date-range customer statements with opening/running/closing balances,
  invoices, payments, reversals, cancelled-invoice exclusion, and PDF output.
- Invoice defaults persist due period, tax mode/rate, notes, terms, and payment
  method; unsupported stored values fall back safely and preferences are part
  of backup/restore.
- CSV export escaping covers commas, quotes, line breaks, Unicode/BOM output,
  and header-only empty datasets; customer, supplier, catalog, invoice,
  purchase-bill, payment-ledger, expense, and date-range report exports share
  one offline export service, including an all-CSV ZIP.
- Bulk import: CSV/Excel templates, column mapping, preview
  valid/warning/rejected rows, GSTIN/HSN/date/money parsing, duplicate
  skip/update, transactional rollback, 10,000-row customer import, and import
  batch audit tables (schema 17).
- Delivery challans: create from customer/quotation/invoice/blank form,
  remaining dispatch from a source quotation or invoice, over-dispatch
  rejection, invoice-sourced convert blocked, quantity tracking, partial
  convert to invoice from items/quotation, non-sale convert blocked,
  cancel-with-reason, unique `DC-0001` numbering, e-way Prepared vs imported
  acknowledgement, PDF bytes, empty-list UI, and schema 17→18 migration.
- Purchase orders: create from a supplier, unique `PO-0001` numbering, ordered /
  received / returned / billed quantity tracking, over-receipt and over-billing
  blocked, partial receive then convert remaining received qty to purchase
  bills, cancel-with-reason until billed, PDF bytes, empty-list UI, and schema
  18→19 migration.
- Optional stock ledger (`P1.1` core): per-product Keep stock (default On for
  new products); invoice sale + cancel reverse-not-edit; purchase bill +
  debit-note stock-out; credit-note restock; custom-line and service skip;
  schema 20→21 copies the old global flag onto products.
- App lock: PIN and Fingerprint options; PIN remains the backup; fingerprint
  enable/unlock uses an injectable biometric gate; PIN keypad still unlocks;
  disable clears the fingerprint flag.
- More tab feature search is an AppBar icon like Invoices; filters by
  name/alias; empty state when nothing matches. Business identity card
  shows logo, name, Active/Trial pill, category, and invoice mobile.
  Plan & billing in Preferences opens Your plan. Search aliases include
  trial, yearly, billing, subscribe, and OTP.
- Documents empty Sales shows Invoices (0), RECEIVED/PENDING/OVERDUE,
  All/Unpaid/Overdue/Draft chips, the receipt hero, and + Create invoice
  without a list FAB. Empty Purchases shows Purchase bills, Paid/Payable/
  Overdue, All/Unpaid/Part paid/Overdue, the box hero, and Create purchase
  bill. Sales | Purchases keeps exported icons and a white active pill.
- Add item catalog form: optional photos (up to 3), compact row with preview
  and remove; classic grouped cards; schema 22 image paths; cover shows on
  catalog list/details. Barcode scan is on the SKU / Code field, not the AppBar.
- Stock reports: on-hand as of a date excludes later movements; movement range
  CSV/PDF; hidden when no product keeps stock.
- About and diagnostics: Settings → About shows version and schema, offline
  help, and a counts-only diagnostics text file (share/save). GitHub CI runs
  format, analyze, and tests.
- Invoice duplicate, cancel, and delete; duplicated documents start unpaid.
- Quotation creation, acceptance, and conversion to invoice.
- Historical customer/product snapshots survive catalog deletion.
- PDF byte generation for every template and a professional lifecycle PDF.
- Backup creation/validation, corrupt/incomplete/newer-version rejection,
  successful restore, failed replacement rollback, and reminder preferences.
- Encrypted backup round-trip, wrong/missing password rejection, verify without
  touching live data, five local generations, and legacy unencrypted ZIP restore.
- Erase all data: sqlite/media/in-app generation deletion, prefs clear, and
  two-step confirm (warning then type `ERASE`) on Backup & restore.
- Sales credit notes: partial line return, over-return rejection, paid-invoice
  leftover kept as customer credit or refunded, apply leftover to another
  invoice of the same customer, statement credit-note/refund rows, credit-note
  PDF bytes, and invoice lock after a credit note.
- Purchase debit notes: partial line return, over-return rejection, paid-bill
  leftover kept as supplier credit or recorded as refund received, apply leftover
  to another bill of the same supplier, statement debit-note/refund rows,
  debit-note PDF bytes, and bill lock after a debit note.
- GST / CA export: B2B vs B2C, credit notes and debit notes in period, missing
  HSN exception, ITC from eligible purchases net of debit notes, FY helper, CSV
  headers on empty ranges, Prepared never Submitted, and a non-empty ZIP pack.
- Database V5/V6/V7 upgrades through V9 and failed-migration data preservation.
- Required-field, mobile, email, money, quantity, tax, payment, and date rules.
- Unsaved-change clean exit, continue editing, discard, and Save draft.
- Onboarding tablet-landscape layout and dashboard small-phone dark-mode layout.
- Dashboard Home: this-month net sales (received / outstanding), jump strip
  (Products, Estimates, Expenses, Reports).
  To collect shows Overdue/This week filters and up to three people to chase.
  Phone has no extra invoice stack. The center + still creates.
- Customer and invoice lists use animated skeleton loading and staggered row
  entry; reduced-motion accessibility bypasses list entrance animation.
- All app-owned dialogs use the shared modern modal surface. Recheck unsaved
  changes, destructive delete/cancel, backup/restore, unit editing, invoice
  discount/charge editing, and payment reversal on the smallest phone size.

## Native/manual device pass still required

- iOS first launch (after plist + APNs): same OTP UI and gate as Android.
  Confirm Push Notifications + APNs key, then a Firebase test phone, then
  Verify → onboarding. Without APNs, Phone Auth may show reCAPTCHA or fail.
- First launch: no Welcome title or brand AppBar; hero, then mobile/OTP
  field, then benefit pills. Country picker defaults to +91; a 10-digit
  number starting with 1 is rejected; a valid 6–9 number sends OTP (Firebase
  test number or real SMS). Use a number from this phone to pick from a
  sheet. If Firestore rules are comments-only, Verify shows plan-storage
  denied and restart must return to OTP, not shop setup. After real rules
  and `plans/default`, Verify opens onboarding. Confirm Invoice mobile on
  business setup does not change the account number. Do not create
  `entitlements` in the console by hand.
- Plan gate: with internet, an entitlement whose `trialEndsAt` is in the past
  must open the Stitch yearly subscribe page (₹499, SAVE 50%, Refresh plan),
  not Home. There is no close/Restore header. On the last trial date in
  airplane mode, confirm Turn on internet and the warm splash illustration.
  After reconnecting, either continue or show Creovo Yearly with Subscribe.
  Restore a backup and confirm
  the plan is still the Firestore/account one, not a value from the ZIP.
  While the shop is open, More shows the Figma business card (Active/Trial
  pill, category • mobile) and Plan & billing opens Your plan (Figma layout:
  Creovo Yearly card, days remaining, privileges, registered mobile,
  Refresh Plan). Expired accounts must not reach More.
- Pick logo and payment QR images from Android and iOS libraries. Signature
  supports draw-on-pad, gallery, or camera.
- Add item photos: save without photos; add a cover from gallery and up to two
  extras from camera; remove one before save; confirm the cover on catalog list
  and item details; restore a backup and confirm `product_images/` returns;
  confirm invoice PDFs stay text-only.
- Save, share, and print PDFs through native sheets and common printers.
- Save/share each CSV export on Android and iOS, then open it in Excel, Numbers,
  and Google Sheets and verify Unicode text, columns, and decimal amounts.
- Import data in airplane mode: download a customer template, fill two rows
  (one duplicate GSTIN), pick the CSV, Skip matching, confirm one imported and
  one skipped. Import an unpaid invoice. Share the error CSV for a bad GSTIN.
  Undo the last batch and confirm those rows are gone. Confirm no network is
  used.
- Replay the receipt-roll animation and preview/save/share/print partial and
  full-payment receipts on low-end Android and iOS devices.
- Preview/share/print multi-page statements with long customer names and large
  account histories on both platforms.
- Select a backup with the native file picker, restore it, restart the app, and
  compare customer/invoice/media/settings data.
- Create an encrypted backup with a password of 8+ characters, share it, then
  restore it on the same device with the correct password (airplane mode on).
- Enter the wrong password and confirm live invoices are unchanged.
- Use Verify backup and confirm it reports valid without replacing data.
- Restore an older unencrypted Creovo ZIP without being asked for a password.
- Restore an encrypted backup on a second device and confirm logo, signature,
  and payment QR paths work.
- Erase all data from Backup & restore: read the warning, type `ERASE`, confirm
  first-launch onboarding, empty invoices/catalog, PIN off, and that a ZIP
  already saved in Files still opens while in-app `creovo_backups` copies are
  gone.
- From a posted invoice, issue a partial credit note / sales return. Confirm
  the original invoice total is unchanged and outstanding dropped. Try an
  over-return and confirm it is blocked.
- On a fully paid invoice, issue a full return: keep leftover as customer
  credit, then apply it to another invoice of the same customer. Repeat with
  Refund the remainder and confirm the statement shows both the credit note
  and the refund.
- Share/print the credit-note PDF in airplane mode.
- From a posted purchase bill, issue a partial debit note / purchase return.
  Confirm the original bill total is unchanged and payable dropped. Try an
  over-return and confirm it is blocked.
- On a fully paid purchase bill, issue a full return: keep leftover as supplier
  credit, then apply it to another bill of the same supplier. Repeat with
  Record refund received and confirm the supplier statement shows both the
  debit note and the refund.
- Share/print the debit-note PDF in airplane mode.
- Open Reports. Switch This month / Last month / This FY. Confirm twelve
  months on the chart with a y-axis (empty months are a faint baseline, not a
  filled bar), Line and Bars, collection progress, KPI tiles, and the
  invoice-mix donut. Tap a month on the chart. Tap Paid, Pending, and
  Outstanding.
- Open GST / CA export from More and Reports. Confirm This month,
  This FY, and a custom range. Share the ZIP pack in airplane mode and confirm
  every file says Prepared / Not submitted — never Submitted. Check B2B vs B2C,
  a credit note, a purchase ITC row, a debit note, and the exception list.
- Open Ageing & reminders from More and Reports. Confirm To collect and To pay
  buckets (Not due, 1–30, 90+). Share one reminder and the visible list in
  airplane mode. Confirm status is Prepared / Shared / Skipped — never
  Delivered. Restore a backup and confirm reminder status returns.
- Open Delivery challans from More. Create one from items or a quotation,
  record partial delivery, convert remaining quantity to an invoice, then
  convert the rest into a second invoice. From an active invoice, create a
  delivery for remaining quantity only (convert must stay hidden). Confirm a
  second challan cannot exceed leftover source quantity, and a job-work
  challan cannot convert. Cancel an unused challan with a reason. Prepare
  e-way (label stays Prepared), import an acknowledgement number, share the
  PDF in airplane mode, restore a backup, and confirm the challan returns.
- Open Purchase orders from More, Reports, or the purchase + sheet. Create a
  supplier PO, record a partial receipt (over-receipt blocked), convert remaining
  received quantity to a purchase bill using the supplier's bill number, then
  convert the rest into a second bill. Confirm the PO does not change stock or
  payable until billed. Cancel an unused PO with a reason. Share the PDF in
  airplane mode, restore a backup, and confirm the order returns.
- Add a product (Keep stock on by default). Confirm invoice/bill create screens
  stay unchanged. Enter opening qty (blank = 0), confirm catalog on-hand, sell
  then cancel (on-hand returns; movement rows are reversed, not edited), bill in
  / debit-note out, credit-note restock, custom line and service skip, More →
  Stock adjust with a required reason, import Opening stock, then check on-hand
  in airplane mode. Open Stock reports (Reports, More, or Stock). Confirm On
  hand as of a date before a sale still shows the earlier qty; Movements lists
  the sale after that date; share CSV and preview PDF in airplane mode. Add an
  item with Keep stock off and confirm it does not move. Turn Keep stock off on
  the last tracked product and confirm Stock reports hide while movements remain
  after restore.
- Open Settings → App lock. Confirm PIN and Fingerprint are both listed. Set a
  PIN, then enable fingerprint (or Face ID / Touch ID). Lock the app, unlock
  with fingerprint, then lock again and unlock with PIN after declining
  biometrics. Confirm a device without enrolled biometrics explains that
  fingerprint is unavailable and still allows PIN.
- Open Settings → About. Confirm version and schema, then Share diagnostics in
  airplane mode. Open the file and confirm it has counts/versions only — no
  customer names, GSTIN, or amounts.
- Open Expenses from More and Reports. Record a rent spend with GST and ITC,
  confirm this-month total, edit it, cancel with a reason (row stays, total
  drops), and share the PDF in airplane mode. Restore a backup and confirm
  the expense returns.
- Open Cash book from More and Reports. Confirm Cash/Bank/UPI/Card/Other
  balances. Record an invoice receipt and a supplier payment and check the
  matching account. Transfer cash to bank. Record a cheque, confirm it is
  pending (available excludes it), then Clear. Bounce a cheque and confirm the
  invoice/bill payment reverses. Close cash with a counted difference. Record
  a customer advance, apply it to an invoice (cash must not move again), and
  confirm the customer statement. Restore a backup and confirm the book
  returns.
- Exercise iOS swipe-back and Android system-back on every protected form.
- Run invoice creation with keyboard open on smallest supported phones.
- Check tablet portrait/landscape for all main lists, forms, and PDF preview.
- Test 1, 20, and 100 line-item PDFs with long/Unicode data and page breaks.
- Measure list/search responsiveness with 1,000 customers, products, and
  invoices.

## Defects found and fixed during this pass

- Invoice and quotation creation bindings inferred the nullable generic type
  `InvoiceDefaultsService?` from an optional test-friendly constructor
  parameter, while GetX had registered `InvoiceDefaultsService`. Both bindings
  now request the explicit non-null service type so either creation route opens
  normally.

- Dashboard business-overview title and invoice-count badge overflowed on a
  320-pixel-wide phone. The title region is now width-constrained with safe
  ellipsis, and a permanent dark-mode small-phone test covers it.
- Dashboard identity and overview were visually competing as two promotional
  surfaces. The header is now identity-only without a duplicate Settings icon,
  and the light account card combines monthly invoiced value, real six-month
  trend, received/outstanding/collection metrics, and invoice count.
- Customer rows previously hid useful account context behind the detail route.
  They now show creation date, lifetime billed, and Paid/Due state from real
  non-draft/non-cancelled invoice totals while keeping destructive actions in
  the existing swipe/action-sheet flow.

## How to run

```bash
flutter analyze
flutter test
```

Run the native/manual section on both Android and iOS before any release pass.
# Category-based product customization

- [ ] First business setup can select a category and explains that presets are recommendations.
- [ ] Changing category updates enabled-field and unit recommendations without deleting saved product values.
- [ ] Every standard field can be independently enabled/disabled.
- [ ] Text and Number custom fields can be added, filled, edited through a product, hidden, and removed from settings.
- [ ] Category-recommended units appear first and custom saved units remain available.
- [ ] Product search matches attribute labels and values.
- [ ] Invoice item attributes remain unchanged after editing the source product.
- [ ] Attribute display preference consistently affects invoice edit, details, and all PDF templates.
- [ ] Long attribute values remain compact on phone/tablet and multi-page PDFs.
