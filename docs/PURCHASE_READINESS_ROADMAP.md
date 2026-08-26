# Creovo Billing — Purchase Readiness Roadmap

Last reviewed against implementation: 2026-08-26
Target: Client handoff first, then public Google Play release
Product boundary: Fast offline sales and purchase billing, not full accounting

## Decision

Keep Purchase as a focused, separate workspace. Before adding Purchase Orders,
inventory, warehouses, or accounting journals, make the existing supplier bill
and payable workflow reliable enough that a business can trust it every day.

The current Purchase module already has:

- isolated suppliers, purchase bills, purchased items, and supplier payments;
- supplier-first bill creation with validation;
- catalog selection, barcode scan, custom items, quantity controls, and GST;
- bill search, status filters, dashboards, PDF preview/share/save/print;
- partial payments, payable totals, backup/restore inclusion, and localization.

This is a strong client-demo baseline. The following goals close the gap between
"working CRUD" and a production-quality payable ledger.

## P0 — Complete before client acceptance

Implementation status (2026-08-26): Goals 1–4 core workflows are implemented,
including payment reversal, lifecycle controls, GST evidence, supplier GST
registration, and portable original-bill attachments. Goal 5 supplier statement
is implemented while CSV export and ageing remain. Goal 6 purchase-specific
migration fixtures, scale tests, and file splitting remain the next hardening
pass. Shared Purchase dropdowns and bottom navigation now match Sales so future
design-system improvements can be applied consistently.

### Goal 1 — Supplier-payment ledger integrity

Purchase payments must follow the same audit model as Sales payments.

- Treat saved payments as immutable.
- Correct mistakes through **Reverse payment**, with confirmation and reason.
- Store payment method, reference/transaction number, date, and optional note.
- Derive paid, payable, and bill status from payment entries rather than trusting
  an independently editable cumulative value.
- Block overpayment, payment on cancelled bills, and invalid backdated values.
- Warn before editing a bill total below an already-paid amount.
- Show opening payment, regular payment, and reversal distinctly in history.

Acceptance: every bill balance reconciles exactly to its payment history after
create, edit, partial payment, full payment, reversal, backup, and restore.

### Goal 2 — Purchase bill lifecycle and safety

- Add explicit Draft, Unpaid, Partially paid, Paid, Overdue, and Cancelled states.
- Allow Save draft before supplier/items are complete; final Save remains strict.
- Add Duplicate bill for repeated supplier purchases.
- Add cancel-with-reason instead of using delete for real business documents.
- Keep permanent delete only for drafts or clearly confirmed test/mistake records.
- Record created/updated/cancelled timestamps for support and audit diagnosis.
- Confirm supplier deletion behavior when historical bills exist; historical
  bills must remain readable even if the supplier is archived.

### Goal 3 — GST-correct purchase evidence

Creovo records a bill received from a supplier; it must not present a recreated
PDF as though Creovo issued the supplier's legal tax invoice.

- Rename generated output clearly as **Purchase record** or **Bill copy**.
- Capture supplier GSTIN, business address, bill number, bill date, place/state
  of supply, HSN/SAC, taxable value, discount, CGST/SGST or IGST, cess where
  applicable, round-off, reverse-charge flag, and final total.
- Decide intra-state versus inter-state tax from business/supplier state, while
  allowing an explicit correction.
- Validate GSTIN format more strongly than length-only validation.
- Prevent accidental duplicate supplier bill numbers within the same supplier
  and financial year; allow an explicit reviewed override only if necessary.
- Add an **ITC eligibility** flag and notes for accountant review. Do not claim
  automatic GST filing or guaranteed input-tax credit.

CBIC Rule 46 lists the identifying, item, value, tax, place-of-supply, reverse-
charge, and signature particulars expected on GST tax invoices. Creovo should
capture enough of that source evidence without pretending to replace the
supplier's original document.

### Goal 4 — Attach the original supplier document

- Attach one or more camera/gallery/PDF files to a purchase bill.
- Show attachment count and a compact preview from bill details.
- Preserve attachments through backup/restore with portable paths.
- Detect missing/corrupt files and show a useful recovery state.
- Compress images and enforce a documented size limit.
- Require confirmation before removing the last source document from a paid
  bill.

This provides more client value than OCR at this stage. OCR can be added later;
the original evidence and manual verification must remain authoritative.

### Goal 5 — Supplier statement and payable export

- Add supplier statement with opening balance, bills, payments, reversals,
  credits, and running/closing payable balance.
- Provide date range, status, and supplier filters.
- Export supplier, purchase bill, purchase item/tax, and payment-ledger CSVs.
- Add ageing buckets: not due, 1–30, 31–60, 61–90, and 90+ days overdue.
- Dashboard drill-down must open the exact filtered bill set behind each metric.

### Goal 6 — Database, backup, and scale verification

- Add explicit schema v9 → v10 and older-schema → v10 migration fixtures for
  suppliers, bills, items, and payments.
- Test purchase attachments and settings through backup/restore.
- Test 1,000 suppliers, 5,000 bills, and bills with 100 line items.
- Test duplicate bill numbers, archived suppliers, partial payments, reversal,
  and bill editing after payment.
- Split the 3,000+ line Purchase screen file into list, supplier, composer,
  details, payment, and shared-widget files before more major features land.

## P0 — Complete before Play Store submission

### Goal 7 — Privacy and permission minimization

- Replace broad contact-library access with Android's system Contact Picker when
  practical. Google Play has announced a contacts-permission policy effective
  2027-01-27 and recommends the picker for apps that do not need broad access.
- Request Camera and Contacts only at the moment the user invokes those actions.
- Explain why each permission is needed before the system prompt.
- Audit `INTERNET` and `ACCESS_NETWORK_STATE`; remove them if the final offline
  feature set and bundled SDKs do not require them.
- Define Android backup/data-extraction rules for invoice, purchase, PIN, and
  attachment data. Sensitive finance data must not be backed up accidentally.
- Complete Google Play Data Safety and publish an accessible privacy policy.

### Goal 8 — Release artifacts and device QA

- Configure a permanent Android upload key; never publish a debug-signed build.
- Build and upload an AAB so Play can deliver ABI/resource splits.
- Keep target API 36: Google Play requires Android 16/API 36 for new apps and
  updates from 2026-08-31.
- Increment build number for every uploaded artifact.
- Test low-end Android, Android 7 minimum, current Android, tablets, Hindi and
  Gujarati, dark mode, large text, keyboard, camera, files, print, and restore.
- Run the complete purchase lifecycle without network access.

## P1 — High-value improvements after P0

### Goal 9 — Purchase returns and supplier credits

- Add Debit note / Purchase return with reason, returned quantities, GST effect,
  and immutable link to the original bill.
- Add supplier credits and allow applying a credit across one or more bills.
- Show credits separately from payments so balances remain understandable.

Vendor credits and applying them to bills are standard purchase workflows in
products such as Zoho Books, but should follow the stable payment ledger rather
than precede it.

### Goal 10 — Expenses separate from item purchases

- Add a lightweight Expense record for rent, electricity, transport, fees, and
  other non-catalog costs.
- Keep Expenses out of purchase-item/catalog flows unless deliberately linked.
- Support category, supplier/payee, date, tax, amount, payment method, note, and
  attachment.
- Clearly label Purchase bills versus Expenses in dashboard and reports.

### Goal 11 — Smarter purchase-to-sale reuse

- Preserve sale price and purchase cost as separate values.
- When a purchased catalog item is selected, suggest the last purchase cost but
  never overwrite sale price silently.
- Show optional margin insight only after cost data is reliable.
- Avoid stock-on-hand promises until inventory movements exist.

### Goal 12 — Due-date productivity

- Add local payable reminders and an upcoming/overdue inbox.
- Support expected payment date and snooze without changing the legal due date.
- Add recurring bill templates only for predictable expenses; require review
  before each actual bill is created.

## P2 — Defer unless the client explicitly needs inventory

- Purchase Orders and PO → bill conversion
- Goods received / partial receipt
- Stock-on-hand and valuation
- Warehouses
- Batch, serial number, and expiry tracking
- Landed-cost allocation and customs duty
- Approval chains
- OCR extraction and automatic GST reconciliation
- GSTR filing, e-invoice, e-way bill, bank feeds, or full accounting journals

These features are useful in accounting/inventory products, but they add states,
reconciliation rules, and setup that conflict with Creovo's fast-invoice goal.
Zoho documents Draft/Open/Partially Billed/Billed/Closed/Cancelled Purchase Order
states and separate receipt-versus-bill handling; implementing only part of that
workflow would be more confusing than leaving it out.

## Recommended delivery order

1. Payment ledger + bill lifecycle
2. GST/tax structure + original bill attachments
3. Supplier statement + exports + ageing
4. Migration/backup/performance tests and Purchase file refactor
5. Permission/privacy/signing/AAB/device release pass
6. Purchase returns and supplier credits
7. Expenses and optional margin insight
8. Purchase Orders/inventory only after an explicit client decision

## Release gates

Client-ready means Goals 1–6 pass acceptance testing with no data-loss or
balance-reconciliation defect. Play-ready additionally requires Goals 7–8,
production signing, store declarations, and physical-device evidence.

## Research references

- [CBIC GST Invoice Rules / Rule 46 particulars](https://cbic-gst.gov.in/gst-invoice-rules.html)
- [Google Play target API requirements](https://support.google.com/googleplay/android-developer/answer/11926878)
- [Google Play policy deadlines, including contacts permission](https://support.google.com/googleplay/android-developer/table/12921780)
- [Android backup security recommendations](https://developer.android.com/privacy-and-security/risks/backup-best-practices)
- [Google Play permissions declaration process](https://support.google.com/googleplay/android-developer/answer/9214102)
- [Zoho Books bill actions and vendor credits](https://www.zoho.com/in/books/help/bills/functions.html)
- [Zoho Books Purchase Order lifecycle](https://www.zoho.com/in/books/help/purchase-order/manage-po.html)
- [Zoho Inventory bill and barcode workflow](https://www.zoho.com/us/inventory/help/purchase-orders/bills.html)
