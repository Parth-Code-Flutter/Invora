# Creovo — Play Store and App Store deployment

Status: **Listing names locked. Do not submit until features and the
pre-submit checklist below are complete.**  
Captured: 2026-08-27  
Live app status: [PROJECT_HANDOFF.md](PROJECT_HANDOFF.md)  
Public-launch engineering: [PRODUCTION_ROADMAP.md](PRODUCTION_ROADMAP.md)  
Paid unlock (not implemented): [LICENSING_AND_DEMO.md](LICENSING_AND_DEMO.md)

## How to use this file

When you are ready to publish, give this command:

> Read `docs/STORE_DEPLOYMENT.md` completely. Follow the locked names, IDs,
> listing copy, and pre-submit checklist. Do not invent a new brand. Do not
> change `com.creovo.billing`. Do not submit until every blocker in this file
> is done.

Use this file for store identity, listing text, and the upload sequence.
Do not use it as a feature backlog. Build remaining product work from
[OFFLINE_MARKET_EXPANSION_ROADMAP.md](OFFLINE_MARKET_EXPANSION_ROADMAP.md).

## Locked names

These are the launch names. Do not reopen the brand debate at submit time.

| Place | Locked value | Limit |
|---|---|---|
| Brand (speak, remember, trademark) | **Creovo** | — |
| Pronunciation | **Kree-oh-vo** | — |
| Home-screen / in-app / PDFs / WhatsApp (today) | Creovo Billing | — |
| Home-screen label at launch (preferred) | **Creovo** | short; long names truncate |
| Google Play title | **Creovo: GST Invoice Billing** | 30 characters (this is 27) |
| Apple App Store name | **Creovo: GST Invoice Billing** | 30 characters |
| Apple subtitle | **Offline GST invoices** | 30 characters (this is 20) |

**Why the store title is not “Creovo Billing”:** shop owners search GST,
invoice, and billing, not Creovo. Indian listing winners put Brand + GST +
Invoice + Billing in the 30-character title. Creovo stays the brand; the
functional words exist so the store can find the app.

Do not ship the Play or App Store title as only `Creovo Billing`.
Do not add Best, #1, Free, emoji, or ALL CAPS to any store title.

### What stays in the binary today

Do not change these at listing-copy time unless a dedicated identity pass is
requested:

- Android launcher label: `Creovo Billing` (`AndroidManifest.xml`)
- iOS display name: `Creovo Billing` (`CFBundleDisplayName`)
- Dart package name: `creovo_invoice` (internal only)

At launch, shorten the home-screen label to **Creovo** so the icon is readable.
Keep “Creovo Billing” in longer in-app sentences if it still reads naturally.

## Locked technical IDs

These must not change after the first public listing. Changing them creates a
new app; existing installs and reviews do not transfer.

| Platform | ID |
|---|---|
| Android application ID / namespace | `com.creovo.billing` |
| iOS bundle ID | `com.creovo.billing` |
| iOS test bundle | `com.creovo.billing.RunnerTests` |
| Current version in `pubspec.yaml` | `1.0.0+1` |

Every uploaded artifact must bump the build number (`+N`). Play and App Store
reject reused build numbers.

## Do not submit yet if

Stop. Finish product and release engineering first.

1. P0 expansion work that we still intend for V1 is incomplete. Current next
   product items are purchase debit notes, then cash/bank book, then the
   immutable stock ledger. See the expansion roadmap and handoff.
2. Android release still signs with the debug key
   (`android/app/build.gradle.kts`). Play will not accept that as production.
3. There is no public privacy-policy URL.
4. Google Play Data Safety and Apple App Privacy forms are not filled from an
   actual permission/SDK audit.
5. Physical-device QA in [QA_CHECKLIST.md](QA_CHECKLIST.md) is not done.
6. Closed testing (Play) and TestFlight have not been used with real shops.
7. Store billing / Pro unlock is still design-only. First public build can be
   fully usable without IAP, but if Pro is in the binary it must follow
   [LICENSING_AND_DEMO.md](LICENSING_AND_DEMO.md): Play Billing / App Store IAP
   only inside store flavors. No in-app UPI unlock in those builds.

## Brand and legal before ads

Do these once, before spending on store ads or a custom domain campaign:

1. Search **CREOVO**, **CREVO**, and **CREO** on
   [ipindia.gov.in](https://ipindia.gov.in) (Class 9, software). Nearby names
   exist in design/CAD, not GST billing, but a lawyer should confirm.
2. File an Indian trademark for **Creovo** if the search is clear.
3. Register a domain if still free: prefer `creovo.in` or `creovo.app`.
   Fallback: `creovobilling.in`. Host the privacy policy on that domain.
4. Reserve handles: Play developer name, Apple seller name, Instagram,
   YouTube, and WhatsApp Business as **Creovo**, not Creovo Billing.

## Store listing copy (ready to paste)

Copy is honest to the current product: offline GST invoices, estimates,
customers, catalog, purchases, expenses, reports, PDFs, local backup.
It does **not** claim e-invoice, e-way bill, GST filing, cloud sync, or
online payment collection.

### Google Play — short description (80 characters)

```
Offline GST invoices for Indian shops. Data stays on your phone.
```

(64 characters. Room to add Hindi later as a localized listing.)

### Google Play / App Store — full description

```
Creovo is an offline GST billing app for Indian shops, traders, and small
service businesses.

Create GST invoices, estimates, purchase bills, and expenses on the phone.
Share a PDF on WhatsApp. Keep a local backup. There is no Creovo cloud,
no login, and no account.

Why Creovo
• Works in airplane mode. Records, GST math, PDFs, reports, and restore
  do not need the internet.
• GST invoices with CGST, SGST, or IGST, HSN/SAC, and your business details.
• Estimates that convert to invoices without retyping.
• Customers, products, and services saved on the device.
• Record payments, reverse a mistake with a reason, and keep the history.
• Purchase bills and supplier payables in a separate workspace.
• Expenses for rent, transport, and other costs — not mixed into stock.
• Reports, ageing, and a GST pack you can share with your CA.
• Password-protected backup on the phone. If you uninstall without a
  backup, the records are gone.

Creovo prepares GST documents on the device. It does not file returns,
generate IRN, or create e-way bills. Never treat a Creovo export as
submitted to the government.

Languages: English, Hindi, and Gujarati.
```

Trim line wraps when pasting into Play Console; keep the meaning.

### Apple — keywords (100 characters, no spaces after commas)

```
gst,invoice,billing,bill book,offline,pdf,whatsapp,estimate,expense,hindi,gujarati
```

Count before paste. Apple ignores words already in the name/subtitle, so do
not repeat `Creovo`, `GST`, `invoice`, or `offline`.

Adjusted keyword line if the name/subtitle already cover those words:

```
bill book,billing,pdf,whatsapp,estimate,expense,purchase,hindi,gujarati,ca
```

### Category, rating, contacts

| Field | Value |
|---|---|
| Play category | Business |
| Play tags | Invoicing, Accounting, Small Business (pick available Console tags) |
| App Store category | Business (primary), Finance (secondary, optional) |
| Content rating | Everyone / 4+ |
| Support URL | Your domain contact or WhatsApp landing page |
| Privacy policy URL | Required. Must match Data Safety / App Privacy answers |
| Marketing URL | Optional until the site exists |

## Screenshots and store assets

Capture from a physical device or a high-density emulator with real-looking
demo data (not “Test GSTIN” / “ABC Customer”).

Minimum set, in this order:

1. Home — this month collected, To collect queue
2. Create invoice — GST line items
3. Invoice PDF preview
4. Customers or To collect chase list
5. Reports or GST pack
6. Backup reminder / Data stays on this phone

Phone screenshots for Play: at least 2, up to 8. Include one short caption
per frame: “GST invoice in 30 seconds”, “Works offline”, “Backup on the
phone”.

Localize listing text for Hindi (and Gujarati if Console allows) after the
English listing is accepted. First submission can be English-only.

Feature graphic (Play, 1024×500): wordmark **Creovo**, short line
“GST Invoice Billing”, no competitor names, no “#1”.

App icon: the current Creovo mark. Do not put the word Billing on the icon;
it will be unreadable at small size.

## Privacy and Data Safety (tell the truth)

Creovo is offline-first. Store forms must not claim “we collect invoices”
if records never leave the device.

Typical honest answers (re-audit SDKs before submit; this is a starting
template, not a legal sign-off):

- Invoice, customer, product, payment, and backup data stay on the device.
- Creovo does not operate a cloud ledger or user account.
- Camera, photos, and contacts are used only when the user picks a logo,
  signature, QR, barcode, or a contact to fill a name/mobile.
- Backup files the user shares (WhatsApp, Files, Drive) leave the device
  under the user’s control. That is user-initiated sharing, not Creovo
  collection.
- If a future `store` flavor adds RevenueCat, declare purchase history /
  device IDs per that SDK’s Data Safety sheet.
- If INTERNET remains in the manifest for crash reporting or store billing,
  declare it. Do not leave a hidden tracker undeclared.

Required in-app surfaces before submit: Privacy, Data & Backup, Help,
Support. Users must understand that uninstall without a backup deletes
records.

## Build and upload sequence

Do not run store uploads from a debug-signed binary.

### Version

1. Set `pubspec.yaml` `version:` to `x.y.z+N` where `N` is higher than any
   previously uploaded build.
2. Record the version in [PROJECT_HANDOFF.md](PROJECT_HANDOFF.md).

### Android (Play)

1. Install a dedicated upload keystore. Keep it **out of Git**. Path and
   passwords live in `android/key.properties` (gitignored) or CI secrets.
2. Point `android/app/build.gradle.kts` release signing at that key, not
   `signingConfigs.debug`.
3. Confirm `targetSdk` meets the current Play requirement (handoff /
   purchase-readiness note: API 36 for new apps/updates in this window).
4. Build:

```bash
flutter clean
flutter pub get
flutter test
flutter build appbundle --release
```

5. Artifact: `build/app/outputs/bundle/release/app-release.aab`
6. Play Console: create the app **once** with application id
   `com.creovo.billing`.
7. Upload to **Closed testing** first, not Production.
8. Fill Data Safety, content rating, store listing, and the privacy URL.
9. Promote to Production only after closed testers (real shops) invoice,
   pay, backup, and restore on low-end Android in Hindi or Gujarati.

### iOS (App Store)

1. Apple Developer account, App ID `com.creovo.billing`, distribution
   profile, and certificates on the Mac that will archive.
2. Archive:

```bash
flutter clean
flutter pub get
flutter build ipa --release
```

   Or archive from Xcode after `flutter build ios --release`.
3. Upload with Transporter or Xcode to TestFlight.
4. TestFlight with the same shops as Play closed testing.
5. Submit for review with the locked name, subtitle, keywords, privacy
   policy, and App Privacy answers.

Do not commit `Podfile.lock` churn, `project.pbxproj` signing noise,
`Package.resolved`, keystores, or `key.properties`.

### Direct APK (not the stores)

WhatsApp/website APKs are a different flavor. Follow
[LICENSING_AND_DEMO.md](LICENSING_AND_DEMO.md). Do not upload that flavor
to Play or App Store. Do not put UPI unlock inside the store flavor.

## Play Console / App Store Connect one-time setup

Create these accounts and records before the first binary:

- Google Play Console developer account (one-time fee, identity verification)
- Apple Developer Program
- Developer name shown publicly: **Creovo** (or the legal entity trading as
  Creovo)
- Store support email and phone that a shop can actually reach
- Privacy policy URL and a simple support page
- Physical address if Console/Apple require it for the developer account

## After first submit

- Never change `com.creovo.billing`.
- Never reuse a build number.
- Keep listing title as **Creovo: GST Invoice Billing** unless search data
  later proves a shorter title converts better. Do not drop GST.
- Release notes: one or two sentences of user-visible change, not an
  engineering changelog.
- If review is rejected, record the reason and the fix in the handoff.
  Common GST-app traps: implying government filing, collecting contacts
  without a reason, leftover debug signing, missing privacy URL, IAP that
  bypasses store billing.

## Related documents

| Document | Use for |
|---|---|
| [START_HERE.md](START_HERE.md) | Session boot order |
| [PROJECT_HANDOFF.md](PROJECT_HANDOFF.md) | What the app actually does today |
| [PRODUCTION_ROADMAP.md](PRODUCTION_ROADMAP.md) | Engineering blockers to public launch |
| [PURCHASE_READINESS_ROADMAP.md](PURCHASE_READINESS_ROADMAP.md) | Play API level, permissions, AAB |
| [QA_CHECKLIST.md](QA_CHECKLIST.md) | Physical-device pass before upload |
| [LICENSING_AND_DEMO.md](LICENSING_AND_DEMO.md) | Pro / IAP / demo APK, when we sell |
| [OFFLINE_MARKET_EXPANSION_ROADMAP.md](OFFLINE_MARKET_EXPANSION_ROADMAP.md) | Features still to build |
