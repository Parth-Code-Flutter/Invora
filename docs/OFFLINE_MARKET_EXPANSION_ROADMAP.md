# Creovo Billing — Offline Market Expansion Roadmap

Last reviewed: 2026-08-26  
Status: Approved product direction  
Goal: Capture a broad Indian small-business market without losing Creovo's
fast, private, offline-first invoicing experience.

## Product contract

Every core create, edit, calculate, search, report, PDF, print, export, backup,
and restore workflow must work in airplane mode. Internet is never required to
open the app or read business data.

External actions have a clear boundary:

- WhatsApp/SMS/email text is prepared offline and handed to the selected app;
  delivery may need that service's network.
- GST, e-invoice IRN, and e-way-bill files can be prepared and validated
  offline, but government submission/acknowledgement requires an official
  portal or API. Creovo must never label an offline draft as submitted.
- Cloud sync, customer portals, payment gateways, live bank feeds, and
  simultaneous multi-user editing are outside the offline guarantee.

All major capabilities are optional modules. Disabling a module hides its UI
without deleting its data. The saved-customer/saved-item invoice path must stay
fast and must not gain inventory or accounting fields unless enabled.

## Definition of done for every feature

1. English, Hindi, and Gujarati UI/PDF coverage.
2. Validation plus loading, empty, error, permission-denied, and recovery states.
3. Small Android phone, iPhone, tablet, dark mode, large text, and accessibility.
4. Schema migration, backup/restore, and portable export coverage.
5. Repository/controller/widget tests and an airplane-mode lifecycle test.
6. Posted financial records are reversed/cancelled with reason, never silently
   rewritten or deleted.
7. `PROJECT_HANDOFF.md` and QA documentation updated in the same commit.
8. Performance verified with realistic high-volume fixtures.

## Priority overview

| Priority | Outcome | Included work |
|---|---|---|
| P0 | Market-ready trust and complete transaction lifecycle | secure recovery, migration/import, returns/notes, challans, purchase orders, expenses, ageing/reminders, accounts, GST exports, release hardening |
| P1 | Retail and trading market | optional stock ledger, barcode scan/labels, batch/expiry/serial, POS/thermal print, locations |
| P2 | Automation and wider segments | recurring drafts, payment schedules, multi-business, projects/time, template customization, offline OCR |
| P3 | Specialist scale | job cards, light assembly, advanced local analytics, accountant closing, controlled device transfer |

P0 is required before broad public marketing. P1 features must not start with
POS or barcode quantity changes until the stock-ledger foundation is complete.

---

# P0 — Professional trust and lifecycle completeness

## P0.1 Secure backup and recovery

### Workflow

1. **Create secure backup** asks for a password/device-secured encryption.
2. The versioned archive contains database, media, attachments, preferences,
   manifest, record counts, schema/app versions, and checksums.
3. **Verify backup** decrypts into temporary storage and validates checksums and
   SQLite structure without touching live data.
4. Restore preview shows business, date, version and record/attachment counts.
5. Restore is transactional and keeps the old database until the replacement
   opens successfully.

### Requirements

- Use reviewed authenticated encryption; never custom cryptography.
- Keep 3–5 named generations in a user-selected folder.
- Cover wrong password, corruption, missing asset, interrupted restore, old/new
  schema, rollback, and cross-device path remapping.
- Restore all Sales/Purchase records, modules, numbering, assets and settings.

Reference: [Vyapar backup/offline overview](https://vyapar.com/)

## P0.2 Bulk import, export, and migration from competitors

### Workflow

1. Download CSV templates for parties, products, opening balances/stock, unpaid
   sales invoices, and unpaid purchase bills.
2. Pick CSV/XLSX, map columns, preview valid/warning/rejected rows.
3. Resolve duplicates using Skip, Update matching master, or Import as new.
4. Import in one database transaction with downloadable errors and rollback.

### Requirements

- Parse locally; no upload.
- Record import batch/source for audit and safe pre-dependency reversal.
- Test Unicode, Indian date/number formats, GSTIN, HSN/SAC, duplicates and
  10,000 rows.
- Export every module as documented UTF-8 CSV and complete portable archive.

Reference: [Zoho invoice import workflow](https://www.zoho.com/in/invoice/help/invoice/new-invoice.html)

## P0.3 Sales returns and credit notes

### Workflow

1. From a posted invoice choose **Credit note / Sales return**.
2. Select returned lines/quantities or a value-only adjustment and reason.
3. Choose return date, tax treatment, restock decision, refund or customer
   credit.
4. Review tax/balance impact and issue a separately numbered immutable PDF.
5. Apply customer credit across invoices or record a refund.

### Requirements

- Link each returned line to its original invoice-line snapshot.
- Never reduce the original invoice silently or over-return quantity/value.
- Restock only if Inventory is enabled and goods are marked resellable.
- Reconcile GST/non-GST, partial/full return, statements, refunds, reports,
  backup and restore.

References: [Zoho credit notes/refunds](https://www.zoho.com/in/invoice/features/),
[myBillBook returns](https://knowledge.mybillbook.in/en/help/articles/9141249-how-to-use-the-new-e-way-bill-and-e)

## P0.4 Purchase returns and debit notes

From a purchase bill, select returned items/quantities, reason/date/tax, then
record supplier credit, refund received, or unadjusted amount. Issue a linked
debit-note/purchase-return PDF and include it in the supplier statement.

- Mirror the Sales return ledger while reducing supplier payable.
- Stock-out only when Inventory is enabled and those goods entered stock.
- Prevent over-return and preserve original supplier evidence/attachments.

Reference: [myBillBook return/debit workflows](https://knowledge.mybillbook.in/en/help/articles/9141249-how-to-use-the-new-e-way-bill-and-e)

## P0.5 Delivery challans and conversion

### Workflow

1. Create from customer, quotation, draft invoice, or blank form.
2. Add dispatch/delivery address, movement reason, transporter, vehicle/document,
   items and quantities.
3. Print/share and record delivered/returned quantities.
4. Convert all or remaining quantities into one or multiple invoices.

### Requirements

- Track ordered, dispatched, delivered/returned and invoiced quantities.
- Conversion copies snapshots and maintains source-document history.
- Support partial delivery, multiple invoices, non-sale movement and cancellation.
- Prepare e-way fields offline; mark generated only after official response import.

References: [Zoho delivery challans](https://www.zoho.com/in/invoice/),
[official e-way-bill system](https://docs.ewaybillgst.gov.in/)

## P0.6 Purchase orders and receiving

Create a supplier PO, expected date, terms, tax and items; receive quantities in
one or more deliveries; convert received/all quantities into purchase bills.
States: Open, Part received, Received, Part billed, Billed, Cancelled.

- PO does not change stock or payable.
- Stock posts through either confirmed receipt or bill based on one preference,
  never both.
- Prevent over-receipt/over-billing unless explicitly reviewed.

Reference: [myBillBook purchasing/billing overview](https://mybillbook.in/)

## P0.7 Expenses

Record category, payee, date, amount, GST/ITC, payment account, note,
customer/project link and receipt attachment. Keep simple expenses separate from
item-based purchase bills. Support billable expense → invoice line and recurring
templates that create drafts for review.

Reports cover category, cash impact, tax/ITC, billable status and attachments.
Original evidence remains authoritative even when OCR is added later.

Reference: [Zoho expense features](https://www.zoho.com/in/invoice/features/)

## P0.8 Receivable/payable ageing and reminders

- Buckets: Not due, 1–30, 31–60, 61–90, 90+ days; each drills into exact records.
- Prepare localized reminder messages in bulk or individually.
- Open native share/WhatsApp/SMS; record Prepared/Shared/Skipped, never falsely
  claim Delivered.
- Local notifications before/on/after due date, with Snooze that never changes
  the legal due date.

References: [Zoho reminders/statements](https://www.zoho.com/in/invoice/features/),
[Vyapar reminders](https://vyapar.com/)

## P0.9 Cash, bank, UPI, advances, and settlement book

- Configure Cash, Bank, UPI, Card and Other local accounts.
- Every receipt/payment produces an immutable account movement.
- Record customer/supplier advances and allocate them partially across documents.
- Account transfers, cheque pending/cleared/bounced, refunds, daily cash closing,
  split payments and account statements.
- This is a reliable sub-ledger, not live bank sync or full accounting.

All party, document and account balances must reconcile after allocation,
reversal, refund and transfer.

Reference: [Square deposits/payment schedules](https://squareup.com/us/en/invoices/pricing)

## P0.10 GST reporting and accountant export

Generate period/financial-year sales/purchase registers, B2B/B2C/exempt/export,
HSN/SAC, rate/tax, ITC, reverse charge, credit/debit notes and missing-data
exceptions. Export CSV/XLSX/PDF and supported portal JSON with schema version.

Creovo prepares and validates offline. Filing, OTP/2FA, IRN and e-way generation
occur externally. Import returned signed JSON, QR, IRN and acknowledgement into
the document. Obsolete schemas warn instead of silently exporting bad files.

References: [GST Returns Offline Tool](https://tutorial.gst.gov.in/downloads/invoiceuploadofflineutility.pdf),
[official e-invoice process](https://docs.ewaybillgst.gov.in/Documents/eInvoice_process.pdf),
[e-way bulk schema/tools](https://docs.ewaybillgst.gov.in/html/formatdownloadnew.html)

## P0.11 Release, privacy, support, and performance

- Production Android/iOS signing, repeatable release builds and beta tracks.
- Privacy policy, store declarations, least-privilege permissions, offline help,
  support/diagnostics export and migration/version display.
- Biometric unlock, app-switcher privacy shield, auto-lock, and separately
  reviewed encrypted-database migration.
- Crash-safe drafts and atomic financial transactions.
- Benchmarks: 10,000 parties, 50,000 documents, 20,000 products, 100-line PDFs,
  10,000-row import and large restore on low-end Android.
- Screen reader, contrast, 200% text, keyboard and reduced motion.

---

# P1 — Optional inventory, barcode, and retail

## P1.1 Immutable stock ledger

Settings asks **Track product stock?** Existing businesses default Off.
Enabling captures opening date/quantities. Disabling hides UI but preserves data.

Every change creates a movement: opening, sale/cancellation, purchase receipt/
cancellation, both returns, manual adjustment with reason, damaged/expired/lost/
own-use, transfer, and stock-count variance. Stock on hand is derived; posted
movements are reversed, not edited/deleted.

Features: on-hand/available/committed/incoming, reorder level, low-stock alerts,
movement/as-of/valuation/ageing/dead-stock reports, negative-stock policy, and
base-unit conversion such as box → 12 pcs. Inventory Off must leave current
Sales/Purchase creation unchanged.

References: [Vyapar inventory](https://vyapar.com/),
[myBillBook inventory](https://mybillbook.in/)

## P1.2 Barcode scanner and label system

### Barcode identity

- One primary barcode plus aliases per product/variant; unique per business.
- Support common 1D codes and QR where the selected library supports them.
- Barcode identifies an item; scanning never silently changes price or tax.

### Scan to add

1. Tap Scan beside item search or start continuous scan.
2. Request camera permission only then; provide manual/hardware-scanner fallback.
3. Known code adds item. Repeated intentional scans increase quantity with
   haptic/sound feedback and visible Undo.
4. Unknown code offers Create product, Search manually, or Ignore; Create
   pre-fills the code.
5. Duplicate/ambiguous code opens a resolver—never select arbitrarily.
6. Purchase suggests last cost; Sales uses sale price. Neither overwrites catalog.

### Other scan modes

- Product list: open matching item.
- Stock count: continuously collect counted quantities, then review variances
  before posting one adjustment batch.
- Customer/supplier scan-to-search remains separate from product barcodes.

### Label generation

Select products, copy count, displayed name/price, barcode source, paper/thermal
size and start position. Generate offline PDF or printer commands. System print
is primary; Bluetooth/USB uses a tested printer-adapter layer.

### Reliability

Torch, focus, pause, denied permission, debounce with intentional repeat support,
damaged/rotated/low-light labels, no-camera devices and 200-item sessions.

References: [Vyapar barcode workflow](https://vyapar.com/accounting-software),
[myBillBook billing overview](https://mybillbook.in/)

## P1.3 Batch, expiry, serial, and warranty

Optional per product. Purchase creates batch/serial stock with dates, cost and
location. Sale suggests FEFO for expiry items. Block duplicate active serials
and double sale. Provide near-expiry, expired, recall, warranty and serial
history. Returns restore the exact identity only after condition review.

## P1.4 POS/counter sale and thermal printing

- Dedicated fast UI with Walk-in customer, scan/search/favourites, large quantity,
  authorized discounts, split payment, Paid/Credit, hold/resume cart and change.
- Offline A4 or 58/80mm receipt, reprint, hardware scanner/keyboard and end-of-day.
- POS writes the same invoice/payment/stock ledgers; it is not a second engine.
- Printer failure never rolls back a sale.

Reference: [Vyapar POS/scanner/printer overview](https://vyapar.com/)

## P1.5 Locations and transfers

Optional shops/warehouses with independent balances. Transfer documents use
dispatched, in-transit, part-received, received and variance states. Each Sales/
Purchase document selects one location. Initial scope is one device and does not
claim cloud synchronization.

---

# P2 — Automation and wider segments

## P2.1 Recurring drafts

Daily/weekly/monthly/quarterly/yearly/custom invoice and expense schedules with
start/end, next run, pause and history. Generate a reviewable draft locally;
catch up on next launch if the OS skipped background execution. Never silently
finalize/share a legal document.

References: [Zoho recurring invoices](https://www.zoho.com/in/invoice/features/),
[Square recurring workflow](https://squareup.com/help/us/en/article/8387-create-and-send-invoices)

## P2.2 Deposits, milestones, retainers, and schedules

Fixed/percentage deposits and milestones with due dates. Totals must equal the
invoice; payments settle a stage and overall ledger. Customer advances/retainers
remain visible and allocatable.

Reference: [Square flexible payment schedules](https://squareup.com/us/en/invoices/pricing)

## P2.3 Multi-business

Fully isolated business workspaces with separate GSTIN, logo, numbering,
language, defaults, accounts, modules and reports. Add `businessId` ownership to
every record and attachment. Backup one/all; optional consolidated read-only
report. Never accidentally reuse cross-business parties/items.

Reference: [Zoho multi-business positioning](https://www.zoho.com/in/invoice/)

## P2.4 Projects, time, and service billing

Optional projects with customer, tasks, hourly/fixed rates, timer/manual time,
expenses, estimate and unbilled amount. Convert approved entries to invoice
lines with source links. Timers survive restart through stored timestamps.

Reference: [Zoho projects/timesheets](https://www.zoho.com/in/invoice/features/)

## P2.5 Advanced templates

Multiple templates per document: logo, colors, columns, labels, address format,
bank/UPI/QR, terms, signature, footer and annexures. Per-customer language/
template/terms. Test real Unicode, multi-page, large text and thermal previews.

References: [Zoho customization](https://www.zoho.com/in/invoice/features/),
[Square custom templates](https://squareup.com/us/en/invoices/pricing)

## P2.6 Offline OCR for receipts and supplier bills

Capture/import image/PDF; on-device OCR suggests supplier, GSTIN, bill number/
date, totals and lines. Show uncertain values beside source for correction. User
must confirm before saving; original evidence stays attached. Never auto-post.

Reference: [Zoho receipt auto-scan description](https://www.zoho.com/in/invoice/windows-app/)

---

# P3 — Specialist scale

## P3.1 Job cards

Optional customer asset/equipment, complaint, diagnosis, technician, parts,
labour, photos, status, warranty, delivery and invoice conversion for repair,
garage and field-service businesses.

## P3.2 Light assembly

Bill of materials, assemble/disassemble, component consumption, finished goods
and wastage. Do not expand into production planning, payroll or complex ERP.

## P3.3 Advanced local analytics

Sales/purchase trend, margin estimate, top parties/items, collection efficiency,
inventory ageing, reorder suggestions and cash forecast. Every insight explains
its formula and drills into source records; processing remains on device.

## P3.4 Accountant handoff and period close

Period lock, exception review, read-only closing snapshot, complete registers,
attachment index and export bundle. Unlock requires explicit reason/audit event.

## P3.5 Controlled device transfer

Encrypted handoff through Files, local network or user-controlled media. One
active writer at a time. Do not claim real-time sync or concurrent merge without
a separately designed conflict-resolution system.

---

# Cross-feature professional UX

- Global search across number, party, mobile, GSTIN, item, barcode, amount and
  notes with module-aware results.
- Recent/favourite parties/items, duplicate last document, Save & create another,
  autosaved drafts and crash recovery.
- Contextual dashboards with exact drill-down and hideable modules.
- Audit timeline: create, edit, share, payment, reversal, conversion,
  cancellation and export.
- Financial-year number series, prefix/suffix, duplicate prevention and gap report.
- Offline help, demo business and guided reset.
- Shared Sales/Purchase widgets so common UX fixes apply to both modules.

# Explicitly deferred online/full-ERP scope

- Cloud sync/web dashboard/simultaneous multi-user collaboration.
- Customer portal, live view tracking, payment gateway, card storage, live bank.
- Direct GST/e-invoice/e-way submission claiming offline completion.
- Payroll, HR, CRM pipeline, loans, ads, marketplace, or full double-entry ERP.
- Any AI feature that uploads invoices or business data.

# Research index

Competitor links show market expectations, not designs to copy:

- [Vyapar](https://vyapar.com/)
- [Vyapar accounting/barcode](https://vyapar.com/accounting-software)
- [myBillBook](https://mybillbook.in/)
- [Zoho Invoice features](https://www.zoho.com/in/invoice/features/)
- [Zoho Invoice India](https://www.zoho.com/in/invoice/)
- [Square create/recurring invoices](https://squareup.com/help/us/en/article/8387-create-and-send-invoices)
- [Square invoice capabilities](https://squareup.com/us/en/invoices/pricing)
- [GST Returns Offline Tool](https://tutorial.gst.gov.in/downloads/invoiceuploadofflineutility.pdf)
- [GSTN e-invoice process](https://docs.ewaybillgst.gov.in/Documents/eInvoice_process.pdf)
- [GSTN e-way-bill documentation](https://docs.ewaybillgst.gov.in/)
