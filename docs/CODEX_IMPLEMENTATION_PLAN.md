# Offline Invoice Maker — Codex Implementation Plan

> For current code status, setup, known work, and dated change history, see
> [PROJECT_HANDOFF.md](PROJECT_HANDOFF.md). This file remains the product scope
> and design reference.

> **Project Type:** Flutter mobile app  
> **Core Goal:** Fast, beautiful, privacy-first invoice generation with **100% offline support**  
> **Platforms:** Android + iOS, with responsive phone and tablet layouts  
> **State Management:** GetX  
> **Backend:** None  
> **Authentication:** None  
> **Primary Storage:** Local database only  
> **Scope Rule:** Do not add features that are not explicitly mentioned in this document.

---

## 1. Product Vision

Build a simple and premium offline invoice maker for:

- Freelancers
- Small shops
- Service providers
- Contractors
- Home businesses
- Local sellers
- Small GST / non-GST businesses

The app should allow a user to create a professional invoice in approximately **30 seconds** once the business, customer, and product/service data already exist.

### Core Product Promise

- No login
- No account
- No backend
- No cloud dependency
- Works without internet
- User data stays on device
- Create PDF invoices offline
- Share or print invoices
- Simple enough for non-technical business users

---

# 2. Strict V1 Scope

## Must Implement

1. First-launch onboarding
2. Business setup
3. Business logo
4. Business signature
5. Payment QR image
6. Bank / UPI details
7. Customer management
8. Product & service management
9. GST and non-GST invoice support
10. Invoice creation
11. Invoice editing
12. Invoice duplication
13. Invoice PDF generation
14. Invoice preview
15. Invoice sharing
16. Invoice printing
17. Invoice search
18. Invoice filters
19. Paid / unpaid tracking
20. Partial payment support
21. Estimates / quotations
22. Convert quotation to invoice
23. Basic dashboard
24. Basic reports
25. Multiple invoice templates
26. Backup
27. Restore
28. Local settings
29. Dark mode
30. Responsive phone + tablet UI

---

## Do NOT Implement in V1

Do not add any of these unless explicitly requested later:

- Firebase
- Supabase
- Backend APIs
- Authentication
- OTP
- Google login
- Apple login
- Cloud sync
- Web dashboard
- Inventory stock tracking
- Purchase management
- Supplier management
- Payroll
- CRM
- Full accounting
- Balance sheet
- Profit & loss
- Ledger
- GST return filing
- E-invoice API integration
- E-way bill integration
- Payment gateway
- Subscription system
- Ads
- Multi-user collaboration
- Online invoice links

---

# 3. Design Direction

The UI must feel:

- Premium
- Modern
- Clean
- Spacious
- Professional
- Fast
- Calm
- Minimal

Avoid:

- Heavy gradients
- Excessive shadows
- Overloaded dashboard cards
- Too many colors
- ERP-style UI
- Cluttered accounting screens
- Small tap targets
- Too many permanent form fields

---

# 4. Color System

## Primary

Royal Indigo

```dart
const Color primary = Color(0xFF4F46E5);
```

Use for:

- Primary buttons
- FAB
- Selected navigation
- Main links
- Active controls
- Invoice accents
- Focus states

## Primary Dark

```dart
const Color primaryDark = Color(0xFF3730A3);
```

## Primary Light

```dart
const Color primaryLight = Color(0xFFEEF2FF);
```

## Secondary

Fresh Teal

```dart
const Color secondary = Color(0xFF14B8A6);
```

Use secondary sparingly for:

- Positive highlights
- Small accents
- Selected secondary actions
- Paid-related visual support

## Secondary Light

```dart
const Color secondaryLight = Color(0xFFCCFBF1);
```

---

## Complete Recommended Palette

```dart
class AppColors {
  static const primary = Color(0xFF4F46E5);
  static const primaryDark = Color(0xFF3730A3);
  static const primaryLight = Color(0xFFEEF2FF);

  static const secondary = Color(0xFF14B8A6);
  static const secondaryLight = Color(0xFFCCFBF1);

  static const background = Color(0xFFF8FAFC);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceVariant = Color(0xFFF1F5F9);

  static const textPrimary = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF64748B);
  static const textTertiary = Color(0xFF94A3B8);

  static const border = Color(0xFFE2E8F0);

  static const success = Color(0xFF16A34A);
  static const successLight = Color(0xFFDCFCE7);

  static const warning = Color(0xFFF59E0B);
  static const warningLight = Color(0xFFFEF3C7);

  static const error = Color(0xFFDC2626);
  static const errorLight = Color(0xFFFEE2E2);

  static const info = Color(0xFF0284C7);
}
```

---

# 5. Typography

Use **Inter** as the primary font.

Recommended sizing:

```text
Display Amount     32sp / Bold
Page Title         24sp / Bold
Section Title      18sp / SemiBold
Card Title         16sp / SemiBold
Body               14-15sp / Regular
Small              12sp / Medium
Button             14-15sp / SemiBold
```

Important monetary values should use bold typography.

Example:

```text
₹42,540
```

---

# 6. User's Preferred Flutter Code Structure

Follow this project organization.

```text
lib/
│
├── app/
│   │
│   ├── constants/
│   │   ├── app_colors.dart
│   │   ├── app_constants.dart
│   │   ├── app_storage_key_const.dart
│   │   ├── asset_constants.dart
│   │   └── db_constants.dart
│   │
│   ├── controllers/
│   │   └── app_controller.dart
│   │
│   ├── enums/
│   │   ├── invoice_status.dart
│   │   ├── quotation_status.dart
│   │   ├── discount_type.dart
│   │   ├── item_type.dart
│   │   └── tax_type.dart
│   │
│   ├── routes/
│   │   ├── app_routes.dart
│   │   └── route_generator.dart
│   │
│   ├── shared/
│   │   ├── dialogs/
│   │   ├── bottom_sheets/
│   │   └── components/
│   │
│   ├── themes/
│   │   ├── app_theme.dart
│   │   ├── app_text_styles.dart
│   │   └── dark_theme.dart
│   │
│   ├── utils/
│   │   ├── currency_utils.dart
│   │   ├── date_utils.dart
│   │   ├── invoice_utils.dart
│   │   ├── validation_utils.dart
│   │   ├── responsive_utils.dart
│   │   └── file_utils.dart
│   │
│   └── widgets/
│       ├── app_button.dart
│       ├── app_text_field.dart
│       ├── app_dropdown.dart
│       ├── app_empty_state.dart
│       ├── app_section_header.dart
│       ├── app_card.dart
│       ├── app_loading.dart
│       └── app_widgets.dart
│
├── data/
│   │
│   ├── models/
│   │   ├── business_profile_model.dart
│   │   ├── customer_model.dart
│   │   ├── product_service_model.dart
│   │   ├── invoice_model.dart
│   │   ├── invoice_item_model.dart
│   │   ├── invoice_charge_model.dart
│   │   ├── payment_model.dart
│   │   ├── quotation_model.dart
│   │   └── app_settings_model.dart
│   │
│   ├── repositories/
│   │   ├── business_repository.dart
│   │   ├── customer_repository.dart
│   │   ├── product_repository.dart
│   │   ├── invoice_repository.dart
│   │   ├── quotation_repository.dart
│   │   └── settings_repository.dart
│   │
│   └── services/
│       ├── local_database_service.dart
│       ├── app_storage.dart
│       ├── pdf_service.dart
│       ├── backup_service.dart
│       ├── share_service.dart
│       ├── print_service.dart
│       └── invoice_calculation_service.dart
│
├── modules/
│   │
│   ├── splash/
│   ├── onboarding/
│   ├── business_setup/
│   ├── dashboard/
│   ├── customers/
│   ├── products/
│   ├── invoices/
│   ├── quotations/
│   ├── reports/
│   ├── settings/
│   └── backup_restore/
│
└── main.dart
```

Each feature module should follow this pattern whenever relevant:

```text
modules/
└── invoices/
    │
    ├── bindings/
    │   └── invoice_binding.dart
    │
    ├── controllers/
    │   ├── invoice_controller.dart
    │   └── create_invoice_controller.dart
    │
    ├── screens/
    │   ├── invoice_list_screen.dart
    │   ├── create_invoice_screen.dart
    │   ├── invoice_details_screen.dart
    │   └── invoice_preview_screen.dart
    │
    └── widgets/
        ├── invoice_card.dart
        ├── invoice_item_tile.dart
        ├── invoice_total_section.dart
        ├── invoice_customer_section.dart
        └── invoice_status_chip.dart
```

---

# 7. Architecture Rules

Follow:

```text
UI
 ↓
GetX Controller
 ↓
Repository
 ↓
Local Service / Database
```

Do not directly access the database from widgets.

Do not put business logic inside screens.

Controllers should manage:

- Loading state
- Screen state
- Validation coordination
- Navigation coordination
- Repository calls
- Reactive UI data

Repositories should manage:

- CRUD
- Database queries
- Entity persistence
- Mapping / snapshot persistence
- Search/filter data operations

Services should manage isolated technical responsibilities such as:

- Database initialization
- PDF generation
- Backup
- Restore
- Sharing
- Printing
- Invoice calculations

---

# 8. GetX Rules

Use GetX consistently.

Recommended patterns:

```dart
final isLoading = false.obs;
final invoices = <InvoiceModel>[].obs;
final selectedCustomer = Rxn<CustomerModel>();
```

Bindings should register dependencies.

Example:

```dart
class InvoiceBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => InvoiceRepository());
    Get.lazyPut(() => InvoiceController(Get.find()));
  }
}
```

Do not create duplicate controller instances unnecessarily.

Prefer dependency injection from bindings rather than repeated `Get.put()` in screens.

---

# 9. Local Database

Use a local database suitable for structured offline data.

Preferred options:

1. Isar
2. Drift / SQLite

Choose one and use it consistently.

Database must support:

- Relationships or relation-friendly identifiers
- Filtering
- Sorting
- Search
- Transactions
- Migration/versioning
- Large invoice history
- Backup/export

Do not use SharedPreferences as the main database.

SharedPreferences or the existing `AppStorage` abstraction may be used only for lightweight app preferences.

Examples:

- onboarding completed
- dark mode
- selected invoice template
- default due date
- selected currency
- optional UI preferences

---

# 10. Main Data Models

## BusinessProfileModel

Fields:

```text
id
businessName
ownerName
logoPath
mobile
email
address
city
state
pinCode
gstRegistered
gstin
pan
invoicePrefix
startingInvoiceNumber
currencyCode
currencySymbol
bankName
accountHolderName
accountNumber
ifsc
upiId
paymentQrPath
signaturePath
createdAt
updatedAt
```

---

## CustomerModel

```text
id
name
companyName
mobile
email
address
city
state
pinCode
gstin
notes
isDeleted
createdAt
updatedAt
```

---

## ProductServiceModel

```text
id
name
type
description
unit
salePriceMinor
hsnSac
taxPercent
isDeleted
createdAt
updatedAt
```

`type`:

```text
product
service
```

Do NOT add stock quantity in V1.

---

# 11. Money Storage Rule

Never store monetary values as unreliable floating-point values.

Store money as integer minor units.

Example:

```text
₹120.50
```

Store:

```text
12050
```

Example names:

```text
rateMinor
subtotalMinor
discountMinor
taxMinor
grandTotalMinor
paidAmountMinor
balanceDueMinor
```

Provide common conversion helpers.

---

# 12. InvoiceModel

Suggested fields:

```text
id

invoiceNumber

customerId
customerSnapshot

invoiceDate
dueDate

status

items

subtotalMinor
itemDiscountTotalMinor
invoiceDiscountMinor
taxTotalMinor
additionalChargeTotalMinor
roundOffMinor
grandTotalMinor
paidAmountMinor
balanceDueMinor

notes
terms

templateId

createdAt
updatedAt
```

---

# 13. Critical Snapshot Rule

Historical invoices MUST NOT depend on live customer or product records.

When creating an invoice, persist customer information inside the invoice snapshot.

Example:

```text
customerName
customerCompanyName
customerMobile
customerEmail
customerAddress
customerCity
customerState
customerPinCode
customerGstin
```

Each invoice item should also contain its own snapshot:

```text
productId nullable
name
description
quantity
unit
rateMinor
hsnSac
taxPercent
discount
taxAmountMinor
totalMinor
```

Reason:

If a customer changes their address later, old invoices must still show the original address.

If a product rate changes later, old invoices must still show the original rate.

---

# 14. Invoice Status

Use:

```text
draft
unpaid
partiallyPaid
paid
overdue
cancelled
```

Overdue may be calculated from:

```text
status != paid
AND
dueDate < today
```

Do not rely only on colors.

Show status text with color.

---

# 15. Quotation Status

Use:

```text
draft
sent
accepted
rejected
expired
```

Quotation number format:

```text
EST-001
EST-002
```

Allow:

```text
Convert to Invoice
```

Conversion should copy:

- Customer snapshot
- Items
- Discounts
- Taxes
- Additional charges
- Notes
- Terms

but generate:

- New invoice ID
- New invoice number
- New invoice date

---

# 16. Onboarding Flow

First app launch:

```text
Splash
↓
Onboarding
↓
Business Setup
↓
Dashboard
```

Returning user:

```text
Splash
↓
Dashboard
```

Store:

```text
isOnboardingCompleted
isBusinessSetupCompleted
```

---

# 17. Business Setup Screen

Fields:

```text
Business Logo

Business Name *
Owner Name

Mobile
Email

Address
City
State
PIN Code

GST Registered
  Yes
  No

GSTIN

PAN

Invoice Prefix
Starting Invoice Number

Currency

Bank Name
Account Holder
Account Number
IFSC
UPI ID

Payment QR

Signature
```

Required minimum:

```text
Business Name
```

GSTIN required only when GST registration is enabled.

---

# 18. Navigation

## Phone

Use bottom navigation:

```text
Home
Invoices
+
Customers
More
```

Center `+` button should open a bottom sheet:

```text
Create Invoice
Create Estimate
Add Customer
Add Product / Service
```

---

## Tablet

Use:

```text
NavigationRail
```

Breakpoints:

```text
< 600       phone
600 - 1024  tablet
> 1024      large tablet
```

Do not create separate business logic for tablet.

Only adapt presentation.

---

# 19. Dashboard

Keep dashboard lightweight.

Header:

```text
Good Morning
Business Name
Settings/Profile icon
```

Primary card:

```text
Total Received
₹XX,XXX
This Month
```

Secondary metrics:

```text
Outstanding
Invoices
```

Quick actions:

```text
Invoice
Estimate
Customer
Product
```

Recent invoices:

Show maximum 5.

Card example:

```text
INV-0024
Raj Enterprise
₹2,540
Paid
Today
```

---

# 20. Customer Module

## Customer List

Features:

- Search
- Add customer
- Edit customer
- Soft delete customer
- Open customer details

Search by:

```text
name
company
mobile
GSTIN
```

---

## Customer Details

Display:

```text
Customer information

Total invoices
Outstanding amount

Recent invoices
```

---

# 21. Products / Services Module

List should support:

- Search
- Add
- Edit
- Soft delete
- Filter by Product / Service

Card:

```text
Logo Design
Service

₹5,000
GST 18%
```

---

# 22. Create Invoice — Main UX

This is the most important screen.

Prioritize minimal taps.

Main structure:

```text
Invoice Details

Customer

Items / Services

Discount

Tax

Additional Charges

Payment

Notes & Terms

Totals

Preview Invoice
```

Do NOT show every advanced option permanently.

Use progressive disclosure.

Example:

```text
+ Add Discount
+ Add Additional Charge
+ Add Notes
```

---

# 23. Invoice Header

Display:

```text
Invoice #
INV-0025

Invoice Date
09 Aug 2026

Due Date
Optional
```

Invoice number should auto-generate.

Manual editing may be allowed.

Duplicate invoice numbers must never be saved.

---

# 24. Customer Selection

Invoice customer section:

```text
Bill To

+ Select Customer
```

On tap:

Open bottom sheet.

Features:

- Search
- Recently used customers
- Customer list
- Add new customer

The user must be able to create a customer without losing the current invoice draft.

---

# 25. Add Item / Service

Items section:

```text
Items

+ Add Item
```

Open bottom sheet with:

```text
Search Product / Service
Recently Used
Saved Products
Saved Services
Create Custom Item
```

Custom item should not be permanently saved unless user chooses to save it.

---

# 26. Supported Units

Initial units:

```text
pcs
box
kg
g
ltr
ml
hour
day
service
set
pair
custom
```

Allow custom unit entry.

---

# 27. GST Rates

Initial GST options:

```text
0
5
12
18
28
custom
```

Support:

```text
CGST
SGST
IGST
```

General default:

Same state:

```text
CGST + SGST
```

Different state:

```text
IGST
```

Allow manual override.

If business is not GST registered:

Hide GST sections by default.

---

# 28. Discounts

Support:

```text
percentage
fixed
```

Allow:

1. Item-level discount
2. Invoice-level discount

Ensure clear calculation order.

---

# 29. Additional Charges

Support custom charges.

Examples:

```text
Shipping
Delivery
Packaging
Handling
Other
```

Data:

```text
title
amountMinor
```

Allow multiple charges.

---

# 30. Invoice Calculation Service

All calculations must live inside:

```text
invoice_calculation_service.dart
```

Do not scatter calculation logic through widgets/controllers.

Recommended flow per item:

```text
base = quantity × rate

itemDiscount = calculate discount

taxableAmount = base - itemDiscount

tax = taxableAmount × taxPercentage

itemTotal = taxableAmount + tax
```

Invoice:

```text
subtotal
- item discounts
- invoice discount
+ tax
+ additional charges
+ round off
= grand total
```

Then:

```text
grand total
- amount paid
= balance due
```

Add unit tests for this service.

---

# 31. Payment Tracking

Invoice should support:

```text
Amount Paid
Balance Due
```

Automatically set:

```text
paidAmount == 0
→ unpaid

0 < paidAmount < grandTotal
→ partiallyPaid

paidAmount >= grandTotal
→ paid
```

Do not implement payment gateway.

Payment is manually recorded by the user.

---

# 32. Invoice Preview

Provide full invoice preview before final share/print.

Bottom actions:

```text
Template
Save
Share
Print
```

Tablet:

Use two-column layout where practical:

```text
LEFT
Invoice form

RIGHT
Live preview
```

---

# 33. PDF Generation

Use Flutter PDF generation libraries.

Suggested:

```text
pdf
printing
```

PDF generation must work completely offline.

A4 layout.

Include:

- Business logo
- Business details
- GSTIN if applicable
- Invoice title
- Invoice number
- Invoice date
- Due date
- Customer snapshot
- GSTIN
- Item table
- HSN/SAC
- Qty
- Rate
- Tax
- Amount
- Subtotal
- Discounts
- Additional charges
- Tax breakdown
- Grand total
- Amount paid
- Balance due
- Bank details
- UPI
- Payment QR
- Notes
- Terms
- Signature

---

# 34. PDF File Naming

Use safe filenames.

Example:

```text
Invoice_INV-0025_Raj-Enterprise.pdf
```

Sanitize illegal file characters.

---

# 35. Invoice Templates

Implement 5 templates in V1.

## Template 1 — Minimal

- White
- Black text
- Minimal separators
- Good for freelancers

## Template 2 — Professional

- Primary Indigo header
- Strong company branding
- Suitable for businesses

## Template 3 — Modern

- Modern blocks
- Indigo accents
- Contemporary typography

## Template 4 — Elegant

- Minimal lines
- Spacious
- Premium feel

## Template 5 — Compact

- Reduced spacing
- Suitable for many line items

Architecture:

```text
pdf/templates/
```

Suggested structure:

```text
pdf/
├── invoice_pdf_builder.dart
├── pdf_theme.dart
└── templates/
    ├── minimal_invoice_template.dart
    ├── professional_invoice_template.dart
    ├── modern_invoice_template.dart
    ├── elegant_invoice_template.dart
    └── compact_invoice_template.dart
```

All templates must consume the same normalized invoice data.

Do not duplicate invoice business logic inside templates.

---

# 36. Invoice List

Tabs / filter chips:

```text
All
Draft
Unpaid
Paid
Overdue
```

Search by:

```text
invoice number
customer name
company name
```

Sort:

```text
Newest
Oldest
Highest Amount
Lowest Amount
```

---

# 37. Invoice Details

Display:

```text
Invoice Number
Status
Grand Total

Customer

Invoice Items

Payment Summary

Notes

Terms
```

Actions:

```text
Share
Print
Edit
```

More actions:

```text
Duplicate
Mark Payment
Export PDF
Cancel Invoice
Delete
```

---

# 38. Invoice Duplication

Duplicate should copy:

- Customer snapshot
- Items
- Discounts
- Taxes
- Additional charges
- Notes
- Terms

Do not copy:

- ID
- Invoice number
- Payment status
- Payment history
- Created date

Generate a fresh invoice number.

---

# 39. Quotations

Quotation creation should reuse invoice components.

Do not duplicate UI unnecessarily.

Create reusable editor components.

Quotation differs mainly by:

```text
document number
status
title
expiry date
conversion flow
```

Button:

```text
Convert to Invoice
```

---

# 40. Reports

V1 only needs lightweight reports.

Current month:

```text
Total Sales
Total Received
Outstanding
Invoices Created
Paid Invoices
Pending Invoices
```

Optional:

```text
Monthly sales chart
Top customers
```

Do NOT implement:

- Balance sheet
- Profit & loss
- Cash flow
- Ledger

---

# 41. Backup & Restore

Backup is mandatory because the app is offline-only.

Backup should include:

- Database
- Business logo
- Signature
- Payment QR
- App settings
- Any locally managed media needed by invoices

Create:

```text
invoice_backup_YYYY_MM_DD.zip
```

---

## Backup Flow

```text
Settings
↓
Backup & Restore
↓
Create Backup
↓
Generate file
↓
Share / Save using native file sheet
```

---

## Restore Flow

```text
Select backup file
↓
Validate backup structure
↓
Show confirmation
↓
Restore data
↓
Reinitialize local database
↓
Verify success
```

Do not partially restore corrupted backups.

Validate version before restore.

---

# 42. Offline Data Warning

Display a clear message in backup settings:

```text
Your business data is stored only on this device.

Create backups regularly to protect your invoices if the
device is lost, reset, or the app is uninstalled.
```

---

# 43. Settings

Suggested sections:

```text
BUSINESS
Business Profile
Logo
GST Details
Bank Details
Payment QR
Signature

INVOICE
Invoice Prefix
Starting Number
Default Due Date
Default Notes
Default Terms
Default Template

APPEARANCE
Theme
Dark Mode

DATA
Backup & Restore
Export Data

ABOUT
Privacy Policy
Terms
App Version
```

---

# 44. Responsive UI Rules

Create common responsive helpers.

Do not hardcode screen widths everywhere.

Example helper:

```text
isPhone
isTablet
isLargeTablet
```

Use:

```text
LayoutBuilder
MediaQuery
NavigationRail
Flexible
Expanded
ConstrainedBox
```

Phone horizontal padding:

```text
16-20
```

Tablet:

```text
24-32
```

Content max width where suitable.

---

# 45. UI Spacing & Components

Recommended:

```text
Card radius              16
Input radius             12
Button radius            12-14
Bottom sheet top radius  24
Screen padding           20
Card internal padding    16
Section gap              20-24
Small gap                8
Normal gap               12-16
```

Prefer:

```text
white surface
soft border
very subtle shadow
```

instead of strong elevation.

---

# 46. Bottom Sheets

Use reusable bottom sheets for:

- Customer selection
- Product selection
- Tax selection
- Discount
- Additional charge
- Invoice actions
- Template selection
- Payment entry

Keep invoice creation on one main workflow instead of opening many screens.

---

# 47. Empty States

Every main list must have a proper empty state.

Invoice example:

```text
No invoices yet

Create your first invoice and start keeping
your billing organized.

[Create Invoice]
```

Customer example:

```text
No customers yet

Add customers to create invoices faster.

[Add Customer]
```

---

# 48. Error Handling

Repositories should throw or return typed failures.

Controllers should map them to user-friendly messages.

Do not expose:

- stack traces
- database exceptions
- package-specific errors

Example:

Bad:

```text
SqliteException: UNIQUE constraint failed...
```

Good:

```text
Invoice number INV-0025 already exists.
Please choose another invoice number.
```

---

# 49. Deletion Rules

Invoice deletion:

Always show confirmation.

Customer / product deletion:

Prefer soft delete if already used by an invoice.

Historical documents must still render correctly.

---

# 50. Search

Search should debounce around:

```text
250-350ms
```

Do not issue expensive queries on every keystroke without debounce.

Since data is local, keep searches responsive.

---

# 51. App Start Performance

Splash should initialize:

1. Storage
2. Database
3. App settings
4. Theme
5. Business profile status

Then route appropriately.

Do not keep splash visible longer than required.

---

# 52. Reusable Widgets

Codex should prioritize reusable widgets.

Examples:

```text
AppButton
AppTextField
AppDropdown
AppCard
AppSectionHeader
AppEmptyState
StatusChip
AmountText
ResponsiveScaffold
SearchField
ConfirmDialog
AppBottomSheet
```

Invoice-specific reusable widgets:

```text
InvoiceCustomerSection
InvoiceItemTile
InvoiceSummaryCard
InvoiceTaxBreakdown
InvoicePaymentSection
InvoiceNotesSection
InvoiceStatusChip
```

---

# 53. Route Naming

Example route names:

```text
/splash
/onboarding
/business-setup
/dashboard

/customers
/customer/add
/customer/edit
/customer/details

/products
/product/add
/product/edit

/invoices
/invoice/create
/invoice/edit
/invoice/details
/invoice/preview

/quotations
/quotation/create
/quotation/details

/reports
/settings
/backup
```

Use existing project route-generation style.

---

# 54. Naming Conventions

Files:

```text
snake_case.dart
```

Classes:

```text
PascalCase
```

Examples:

```text
invoice_controller.dart
InvoiceController

invoice_repository.dart
InvoiceRepository

invoice_model.dart
InvoiceModel

create_invoice_screen.dart
CreateInvoiceScreen

invoice_binding.dart
InvoiceBinding
```

---

# 55. Model Standards

Models should support clean data conversion based on selected database strategy.

Where relevant, provide:

```text
copyWith
toJson
fromJson
```

If using Isar-specific generated models, keep persistence annotations separate and readable.

Avoid putting UI formatting logic in models.

---

# 56. Tests

At minimum, create unit tests for:

## Invoice Calculation

- basic item
- multiple items
- percentage discount
- fixed discount
- item discount
- invoice discount
- GST
- CGST + SGST split
- IGST
- additional charge
- round off
- partial payment
- paid invoice
- zero tax
- decimal quantities

## Invoice Number

- generation
- increment
- custom prefix
- duplicate prevention

## Backup

- generate
- validate
- restore
- invalid backup

---

# 57. Critical Acceptance Tests

Before considering V1 complete:

### Offline

- Enable airplane mode.
- App must open.
- Customer CRUD must work.
- Product CRUD must work.
- Invoice CRUD must work.
- PDF generation must work.
- Preview must work.
- Backup creation must work.

### Persistence

- Create invoice.
- Force close app.
- Reopen app.
- Invoice must exist.

### Historical Snapshot

1. Create customer with Address A.
2. Create invoice.
3. Change customer to Address B.
4. Open old invoice.
5. Old invoice must still show Address A.

### Product Snapshot

1. Product price = ₹500.
2. Create invoice.
3. Change product price to ₹700.
4. Old invoice must still show ₹500.

### Invoice Number

Duplicate invoice numbers must be blocked.

### Payment

```text
0 paid      → Unpaid
partial     → Partially Paid
full amount → Paid
```

---

# 58. Development Phases

Codex must implement phase by phase.

Do NOT attempt to create the entire app in one giant change.

---

## Phase 1 — Project Foundation

Implement:

- Folder structure
- Theme
- Colors
- Typography
- Routes
- Initial bindings
- Shared widgets
- Responsive helper
- Database service
- App storage
- Base repository pattern

Acceptance:

- App builds Android
- App builds iOS
- Theme works
- Navigation works
- Database initializes

---

## Phase 2 — Onboarding + Business Setup

Implement:

- Splash
- Onboarding
- Business setup
- Logo
- Signature
- QR
- GST details
- Bank details
- Settings persistence

Acceptance:

- First install opens onboarding
- Completing setup routes dashboard
- Relaunch skips onboarding

---

## Phase 3 — Customer Module

Implement:

- Customer model
- Repository
- Controller
- Binding
- List
- Search
- Add
- Edit
- Details
- Delete behavior

Acceptance:

- Full customer CRUD offline

---

## Phase 4 — Product & Service Module

Implement:

- Product/service model
- Repository
- Controller
- List
- Search
- Filter
- Add
- Edit
- Delete

Acceptance:

- Full offline CRUD
- Product/service distinction

---

## Phase 5 — Invoice Calculation Engine

Implement before full invoice UI.

- Integer money handling
- Discounts
- GST
- CGST
- SGST
- IGST
- Additional charges
- Payments
- Totals
- Tests

Acceptance:

All calculation tests pass.

---

## Phase 6 — Create Invoice

Implement:

- Invoice model
- Invoice item model
- Customer selection
- Product selection
- Custom item
- Qty
- Rate
- GST
- Discounts
- Charges
- Notes
- Terms
- Payment amount
- Validation
- Draft save
- Final save

Acceptance:

Invoice can be fully created offline.

---

## Phase 7 — Invoice Management

Implement:

- Invoice list
- Search
- Filters
- Sort
- Details
- Edit
- Duplicate
- Payment update
- Cancel
- Delete

Acceptance:

Full invoice lifecycle works offline.

---

## Phase 8 — PDF + Templates

Implement:

- Common PDF data mapper
- PDF service
- 5 templates
- Preview
- Share
- Print
- File naming

Acceptance:

All templates render same invoice data correctly.

---

## Phase 9 — Quotations

Implement:

- Quotation model
- List
- Create
- Edit
- Preview
- PDF
- Share
- Status
- Convert to invoice

Acceptance:

Accepted quotation can become invoice with a new invoice number.

---

## Phase 10 — Dashboard + Reports

Implement:

- Monthly received
- Outstanding
- Invoice count
- Recent invoices
- Monthly sales
- Basic chart
- Top customers if practical

Acceptance:

Dashboard values match stored invoice data.

---

## Phase 11 — Backup + Restore

Implement:

- ZIP backup
- Media handling
- Database backup
- Metadata
- Version checking
- Validation
- Restore confirmation
- Restore operation

Acceptance:

Fresh installation can restore a valid backup and reproduce existing records.

---

## Phase 12 — UI Polish

Implement:

- Empty states
- Micro animations
- Dark mode
- Tablet layouts
- NavigationRail
- Live tablet invoice preview
- Accessibility
- Keyboard behavior
- Form focus
- Error states

---

# 59. Codex Working Rules

Use these rules for EVERY task.

```text
1. First inspect the existing project before editing.
2. Follow the existing project naming and folder conventions.
3. Do not restructure unrelated code.
4. Do not change existing reusable components unless necessary.
5. Do not add packages without a clear need.
6. Before adding a package, check whether the project already contains an equivalent.
7. Use GetX for state management, routing and dependency injection.
8. Use repositories between controllers and persistence services.
9. Never access the database directly from UI widgets.
10. Keep business logic out of widgets.
11. Keep invoice calculations in a dedicated service.
12. Store monetary values safely using integer minor units.
13. Preserve historical invoice snapshots.
14. Never add online dependencies to core invoice functionality.
15. Every invoice-related feature must work in airplane mode.
16. Do not implement features outside V1 scope.
17. Keep UI minimal and premium.
18. Make phone and tablet layouts responsive.
19. Reuse widgets rather than duplicating UI.
20. Add comments only where logic is not self-explanatory.
21. Do not overengineer simple features.
22. Run formatting and static analysis after meaningful changes.
23. Fix analyzer errors caused by the implementation.
24. Do not suppress errors simply to make analysis pass.
25. Implement one phase at a time.
```

---

# 60. First Codex Prompt

Use this after placing this file in the project root.

```text
Read CODEX_IMPLEMENTATION_PLAN.md completely before making changes.

This document is the source of truth for the Offline Invoice Maker project.

First inspect the existing Flutter project structure, pubspec.yaml,
routing, themes, reusable widgets, GetX conventions, storage utilities,
controllers, bindings and naming patterns.

Do not start implementing all features.

For the first task, implement only Phase 1 — Project Foundation.

Important:
- preserve the existing project architecture where it already exists;
- follow the folder conventions defined in the implementation plan;
- use GetX;
- do not add Firebase, authentication, APIs or cloud functionality;
- do not implement later phases;
- do not add unnecessary packages;
- create reusable foundation code that later invoice modules can use;
- support phone and tablet layouts from the foundation;
- use the Indigo + Teal design system defined in the plan.

After implementation:
1. run flutter format;
2. run flutter analyze;
3. report files created/changed;
4. report any remaining analyzer issues;
5. briefly describe what is ready for Phase 2.
```

---

# 61. Phase Prompt Template for Codex

For every later phase, use:

```text
Read CODEX_IMPLEMENTATION_PLAN.md again.

Now implement ONLY Phase [NUMBER] — [PHASE NAME].

Before coding:
- inspect existing implementation from previous phases;
- reuse current architecture and widgets;
- do not refactor unrelated features;
- do not implement future phases.

Implementation must follow:
- GetX
- repository-based local persistence
- existing project naming conventions
- 100% offline requirement
- responsive phone/tablet layouts
- design system from CODEX_IMPLEMENTATION_PLAN.md

After implementation:
- format code;
- run flutter analyze;
- fix issues introduced by this phase;
- report changed files;
- report acceptance criteria completed;
- clearly mention anything not completed.
```

---

# 62. Final Product Rule

The app wins by being:

```text
FASTER than accounting apps

SIMPLER than GST ERP apps

MORE BEAUTIFUL than traditional billing apps

PRIVATE because it works offline

USEFUL because professional invoices can be generated in seconds
```

Whenever there is a choice between:

```text
adding another feature
```

and

```text
making invoice creation faster and cleaner
```

choose the second option.

---

# 63. Definition of Done — V1

V1 is complete when a new user can:

```text
Install app
↓
Set up business
↓
Add customer
↓
Add product/service
↓
Create GST or non-GST invoice
↓
Preview professional invoice
↓
Save invoice
↓
Generate PDF offline
↓
Share / Print invoice
↓
Record payment
↓
Search invoice later
↓
Create quotation
↓
Convert quotation to invoice
↓
Create backup
↓
Restore data successfully
```

All of this must work without a backend and without requiring an internet connection.
