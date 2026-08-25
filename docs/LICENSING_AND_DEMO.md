# Creovo Billing — Licensing, paid unlock, and demo APK

Status: **Client demo kill switch is implemented. Paid unlock (Play Billing /
license keys) is still design only.**  
Captured: 2026-08-17  
Demo APK implemented: 2026-08-19  
Live app status: [PROJECT_HANDOFF.md](PROJECT_HANDOFF.md)

This note records the agreed monetization design so later sessions can
implement it without re-litigating backup, Play/App Store rules, or demo APK
sharing. Invoice data stays on-device. No Creovo cloud ledger, login, or sync
is required.

## Why a local “is paid” flag will not work

Creovo is offline. Business data lives in Drift/SQLite. Settings live in
`AppStorage` (SharedPreferences). Backup copies the **whole SQLite file** plus
a **whitelist** of settings into an unencrypted ZIP.

| User action | What happens to app data | If Pro lives in SQLite or `settings.json` |
|---|---|---|
| Clear cache | Temp files go. Database and settings usually stay. | Paid status usually survives. |
| Clear storage / app data | SQLite, settings, PIN, workspace gone. | Paid status gone unless they restore a ZIP or a store purchase. |
| New phone + Creovo backup | Invoices and settings come back from the ZIP. | The new phone is paid for free. |
| Friend restores that ZIP | They get the business records. | They also get Pro. |

**Rule:** business data travels in the backup. Payment entitlement must not.

Do not store `is_licensed` / `is_pro` / demo start time in Drift or in the
backup settings whitelist (`BackupService` `settings.json` today includes
theme, onboarding, workspace, units, invoice defaults, category, backup
reminder — not app-lock PIN). Keep license and demo clocks off that list.

App lock PIN is already excluded from backup. Treat license the same way.

## Product split (still to decide in detail)

**Free (always, fully offline)**  
Invoices, customers, catalog, PDF, backup/restore. Enough to run a shop.

**Pro, one-time purchase (what we sell)**  
Exact feature list is still open. Likely: no PDF watermark, Purchases
workspace, extra templates, unlimited history. Same Pro on Play, App Store,
and direct APK.

Free vs Pro gates are a later product pass. This document is the entitlement
and demo-APK design.

## Paid unlock that works on Play, App Store, and a sent APK

One UPI/Razorpay “enter key” screen **inside** Play and App Store builds is
not allowed. Google and Apple require their billing for digital unlocks.

One **Pro entitlement** in the app is allowed. Two official ways to pay:

| How they installed | How they pay | Out-of-box tool |
|---|---|---|
| Google Play | Play Billing, one-time Pro | RevenueCat on top of Play Billing |
| Apple App Store | App Store IAP, same Pro | RevenueCat (same product) |
| APK sent by us | UPI / bank / Razorpay, then a license key | Keygen (or LicenseSpring) |

The app only asks: **is Pro unlocked?**  
Yes if RevenueCat says so **or** a valid direct-license key says so.

After first successful store check, Play/App Store cache the receipt locally,
so daily invoicing stays offline. Direct keys verify offline with a signed
license (private key never ships in the APK). Bind direct keys to **GSTIN**
(or business name + mobile if unregistered) so a shared ZIP does not unlock
another shop unless they keep that GSTIN.

iOS has no public “send APK” path. Individual iPhone customers pay through the
App Store.

### User-facing restore (two different buttons)

1. **Restore backup** — invoices, customers, products, purchases, logo.
   Never writes paid = true.
2. **Restore purchase** (store builds) — talks to Play/App Store.
   Direct APK users paste the same GSTIN-bound key again.

After backup restore, copy should say: bills are restored; unlock is tied to
the store account or license key, not the backup file.

### Build flavors (same codebase)

| Flavor | Purpose |
|---|---|
| `demo` | Time-limited sales APK. Kill switch. Watermark. Not for sale. |
| `direct` | Full app + Keygen / paid key. WhatsApp / website APK. |
| `store` | Full app + RevenueCat only. No UPI unlock in-app. Play / App Store. |

Store flavor must not offer an alternative to Play/App Store billing for the
same Pro unlock.

### What not to do

- Boolean paid flag in SharedPreferences or SQLite.
- Putting Pro inside the backup ZIP so “restore works.”
- Device-ID-only lock as the only license (phone upgrade looks like theft).
- Trial counters only in local DB (backup from day 1 resets the trial).
- UPI checkout inside a Play/iOS build to unlock Pro.
- One shared license key with no GSTIN bind.
- Designing around a cracked APK. Cracks will exist. Revenue is honest store
  and key buyers.

### Suggested implementation order (when we pick this up)

1. Decide Free vs Pro features.
2. Add an entitlement check so gated features refuse to run unless unlocked.
3. Ship `direct` + Keygen and sell APK keys (income before stores).
4. When publishing: `store` flavor + RevenueCat, same lifetime Pro product.
5. Never put Pro in the ZIP.

A 100% offline APK cannot be piracy-proof. Do not warp backup or GST workflows
around that.

## Demo APK for sending to a client (15 days)

This is **not** the paid license. It is a time-bomb binary so a sales demo
cannot be forwarded as a free forever app.

**Implemented.** Default debug/release/Play builds do **not** pass
`DEMO_EXPIRES_AT`, so the lock never arms. Only APKs built with
`tool/build_demo_apk.sh` (or the same `--dart-define`s) expire.

**Do not** implement “15 days from first open” in prefs or SQLite. Every new
phone, clear-data, or reinstall would start a fresh 15 days.

**Do** bake a **calendar expiry** into that APK (`DEMO_EXPIRES_AT` = send date
+ 15 days, last inclusive calendar day). Sharing the file does not mint extra
time. Every copy of that build dies on the same day.

| Approach | Forwarded APK | Clear data / reinstall | New phone |
|---|---|---|---|
| 15 days from first launch, saved locally | New 15 days each install | New 15 days | New 15 days |
| Expiry date compiled into the APK | Same deadline for everyone | Still dead after that date | Still dead after that date |

### How to build a client demo APK

Either command writes `build/app/outputs/flutter-apk/app-release.apk`. That
file is the demo; copy it only if you need a second named copy.

**Direct Flutter command** (set expiry yourself). Example for a 19 Aug 2026
send date, last inclusive day 3 Sep 2026:

```bash
flutter build apk --release \
  --dart-define=DEMO_EXPIRES_AT=2026-09-03 \
  --dart-define=DEMO_BUILD_TIME=2026-08-19 \
  --dart-define=DEMO_CLIENT_NAME="Client demo"
```

- `DEMO_EXPIRES_AT` = last inclusive calendar day (send date + 15 days)
- `DEMO_BUILD_TIME` = the day you package the APK
- `DEMO_CLIENT_NAME` = label shown on the expired screen

**Helper script** (computes today + 15 days):

```bash
./tool/build_demo_apk.sh "Sharma Traders"
```

Daily work stays `flutter run` / `flutter build apk` **without** those defines.

### Client-specific demo, not the production APK

- Never send a Play/production APK for a trial. Only the dart-define demo APK.
- Per client when building: expiry day + `DEMO_CLIENT_NAME`.
- Lock copy includes the client name so a leak is identifiable.
- PDF watermarking is still optional/future; the kill switch is the lock.

### After expiry

Block **all** features: splash, home, invoices, purchases, backup, restore.
Show a dialog (and keep them on a dead screen if they dismiss):

**Please contact your sales person**

Optional subtitle: demo ended on &lt;date&gt; / demo for &lt;client&gt;.
Restoring a ZIP must not skip the kill switch. The deadline lives in the APK,
not in restored settings.

### Clock rollback

The app is offline, so there is no trusted network clock. Casual protection:

- Bake in `buildTime` and `expiresAt`.
- If device time is before build time, or before last-seen time, treat as
  expired.
- Store last-seen time on device only, never in the backup ZIP.

A patched APK can still skip this. That is acceptable for a sales demo.

### When they buy

Send a `direct` or store build with **no** 15-day bomb. Demo expiry is not
converted into a Pro license.

## Current codebase facts this design depends on

- No Play Billing, RevenueCat, or Keygen in the project today.
- Backup: full SQLite + settings whitelist + media; restore remaps media
  paths and rebuilds database-bound GetX runtime.
- `AppStorageKeyConst` holds UI/business defaults, app-lock hashes, and
  (on demo APKs only) a last-seen calendar day that is **not** copied into
  backup `settings.json`.
- Product plan (`CODEX_IMPLEMENTATION_PLAN.md`) still says no cloud of
  invoice data. Licensing as designed does not add invoice sync.

## Open decisions (do not block other app work)

- Exact Free vs Pro feature list and price.
- Lifetime only vs lifetime + yearly SKU.
- Keygen vs LicenseSpring for the direct APK.
- Whether Purchases stays free or is a Pro gate.
- Per-client demo naming convention and who builds those APKs.
