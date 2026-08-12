# Creovo Invoice — Whole-Flow QA Checklist

Last updated: 2026-08-12

This checklist separates repeatable automated coverage from native operations
that still require an Android/iOS device. Release signing and store submission
remain intentionally out of scope until explicitly requested.

## Automated and passing

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
  and header-only empty datasets; customer, catalog, invoice, payment-ledger,
  and date-range report exports share one offline export service.
- Invoice duplicate, cancel, and delete; duplicated documents start unpaid.
- Quotation creation, acceptance, and conversion to invoice.
- Historical customer/product snapshots survive catalog deletion.
- PDF byte generation for every template and a professional lifecycle PDF.
- Backup creation/validation, corrupt/incomplete/newer-version rejection,
  successful restore, failed replacement rollback, and reminder preferences.
- Database V5/V6/V7 upgrades through V9 and failed-migration data preservation.
- Required-field, mobile, email, money, quantity, tax, payment, and date rules.
- Unsaved-change clean exit, continue editing, discard, and Save draft.
- Onboarding tablet-landscape layout and dashboard small-phone dark-mode layout.
- Customer and invoice lists use animated skeleton loading and staggered row
  entry; reduced-motion accessibility bypasses list entrance animation.
- All app-owned dialogs use the shared modern modal surface. Recheck unsaved
  changes, destructive delete/cancel, backup/restore, unit editing, invoice
  discount/charge editing, and payment reversal on the smallest phone size.

## Native/manual device pass still required

- Grant/deny Contacts permission and import a real phone contact.
- Pick logo, signature, and payment QR images from Android and iOS libraries.
- Save, share, and print PDFs through native sheets and common printers.
- Save/share each CSV export on Android and iOS, then open it in Excel, Numbers,
  and Google Sheets and verify Unicode text, columns, and decimal amounts.
- Replay the receipt-roll animation and preview/save/share/print partial and
  full-payment receipts on low-end Android and iOS devices.
- Preview/share/print multi-page statements with long customer names and large
  account histories on both platforms.
- Select a backup with the native file picker, restore it, restart the app, and
  compare customer/invoice/media/settings data.
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
