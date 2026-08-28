# Creovo Billing — Whole-Flow QA Checklist

Last updated: 2026-08-28

This checklist separates repeatable automated coverage from native operations
that still require an Android/iOS device. Release signing and store submission
remain intentionally out of scope until explicitly requested.

## Automated and passing

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

- First launch reaches onboarding and continues to business setup.
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
- Invoice duplicate, cancel, and delete; duplicated documents start unpaid.
- Quotation creation, acceptance, and conversion to invoice.
- Historical customer/product snapshots survive catalog deletion.
- PDF byte generation for every template and a professional lifecycle PDF.
- Backup creation/validation, corrupt/incomplete/newer-version rejection,
  successful restore, failed replacement rollback, and reminder preferences.
- Encrypted backup round-trip, wrong/missing password rejection, verify without
  touching live data, five local generations, and legacy unencrypted ZIP restore.
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
- Dashboard Home: snapshot jump strip (Products, Estimates, Expenses, Reports).
  To collect shows Overdue/This week filters and up to three people to chase.
  Phone has no extra invoice stack. The center + still creates.
- Customer and invoice lists use animated skeleton loading and staggered row
  entry; reduced-motion accessibility bypasses list entrance animation.
- All app-owned dialogs use the shared modern modal surface. Recheck unsaved
  changes, destructive delete/cancel, backup/restore, unit editing, invoice
  discount/charge editing, and payment reversal on the smallest phone size.

## Native/manual device pass still required

- Grant/deny Contacts permission and import a real phone contact.
- Pick logo and payment QR images from Android and iOS libraries. Signature
  supports draw-on-pad, gallery, or camera.
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
