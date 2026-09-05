# Creovo Billing — Licensing, paid unlock, and demo APK

Status: **Phone OTP entitlement is in the app. Store billing is still design only. Direct-APK payment is manual console `status=paid` until an admin proof queue ships.**  
Captured: 2026-08-17; OTP path added 2026-09-03; admin proof queue agreed 2026-09-05  
Live app status: [PROJECT_HANDOFF.md](PROJECT_HANDOFF.md)

This note records the agreed monetization design so later sessions can
implement it without re-litigating backup, Play/App Store rules, or demo APK
sharing. **Agents: any subscription, trial, paid unlock, UPI screenshot, or
admin-panel task starts here** (then check `PROJECT_HANDOFF.md` for what the
app already does). Invoice data stays on-device. No Creovo cloud ledger,
login, or sync is required.

## Why a local “is paid” flag will not work

Creovo is offline. Business data lives in Drift/SQLite. Settings live in
`AppStorage` (SharedPreferences). Backup copies the **whole SQLite file** plus
a **whitelist** of settings into a password-protected ZIP.

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
| APK sent by us | UPI to a **business** UPI/QR (not the operator’s personal mobile), screenshot in-app, admin approve | Admin website + Firebase Admin (interim: Firestore console `status=paid`) |

The app only asks: **is Pro unlocked?**  
Yes if RevenueCat says so **or** Firestore `entitlements/{91…}.status` is paid (set only by admin / Admin SDK, never by the phone). A later Keygen path can sit beside that for signed APK keys.

After first successful store check, Play/App Store cache the receipt locally,
so daily invoicing stays offline. Direct APK unlock is the OTP mobile plus a
server-written paid window (`trialEndsAt`). Bind later signed keys to **GSTIN**
(or business name + mobile if unregistered) so a shared ZIP does not unlock
another shop unless they keep that GSTIN.

iOS has no public “send APK” path. Individual iPhone customers pay through the
App Store.

### User-facing restore (two different buttons)

1. **Restore backup** — invoices, customers, products, purchases, logo.
   Never writes paid = true.
2. **Restore purchase** (store builds) — talks to Play/App Store.
   Direct APK: **Refresh plan** after admin Approve (same OTP number).
   A later signed key is optional.

After backup restore, copy should say: bills are restored; unlock is tied to
the store account or license key, not the backup file.

### Build flavors (same codebase)

| Flavor | Purpose |
|---|---|
| `demo` | Time-limited sales APK. Kill switch. Watermark. Not for sale. |
| `direct` | Full app + UPI proof + admin approve (console until the panel ships). WhatsApp / website APK. No personal operator number in the product. |
| `store` | Full app + RevenueCat only. No UPI unlock in-app. Play / App Store. |

Store flavor must not offer an alternative to Play/App Store billing for the
same Pro unlock.

### What not to do

- Boolean paid flag in SharedPreferences or SQLite.
- Putting Pro inside the backup ZIP so “restore works.”
- Device-ID-only lock as the only license (phone upgrade looks like theft).
- Trial counters only in local DB (backup from day 1 resets the trial).
- UPI checkout **or** “I’ve paid, unlock me” inside a Play/iOS **store** build.
- Unlocking from screenshot upload alone (phone must not write `status=paid`).
- Putting payment proofs or invoices in a collection the phone can update to paid.
- One shared license key with no GSTIN bind.
- Designing around a cracked APK. Cracks will exist. Revenue is honest store
  and key buyers.

### Suggested implementation order (when we pick this up)

1. Decide Free vs Pro features (today the whole shop is trial-then-yearly).
2. Direct APK: business UPI/QR on the paywall, in-app screenshot, admin
   queue (this doc). Console `status=paid` until that panel exists.
3. When publishing: `store` flavor + RevenueCat / Play + App Store IAP.
   No UPI screenshot unlock in that binary.
4. Optional later: Keygen for signed APK keys beside the admin queue.
5. Never put Pro in the ZIP.

A 100% offline APK cannot be piracy-proof. Do not warp backup or GST workflows
around that.

## Direct APK: UPI proof + admin panel (agreed, not built)

Volume is small (~10 shops / month). The pain is **not** Firestore Console
clicks; it is sharing the operator’s **personal number** and chasing
WhatsApp screenshots. Collect money **outside** the app. Firebase is only
the queue and the paid switch.

Razorpay / Play Billing / App Store IAP are **not** required for this path.
Store listing later needs a separate `store` flavor (see above). This
section is **direct APK / WhatsApp / website** only.

### Who the shop is

The person is the **OTP account mobile** (`entitlements/{91…}`). Invoice
data never goes to Firebase.

### Price the paywall shows

`plans/default.priceInr` (number). If it is `0`, the UI still shows the
hardcoded ₹499 offer. Set a real number (e.g. `499`) for that amount to
appear. `title` `Default` displays as **Creovo Yearly**. Shops pick up a
new price when **online** + Refresh plan / relaunch. Clients cannot edit
`plans`; only console or Admin SDK.

### Shop flow

1. Trial ends → `/subscription` paywall. Show a **business UPI ID or QR**
   (not a personal mobile).
2. They pay in GPay / PhonePe.
3. In-app **I’ve paid** → attach screenshot → Submit. Needs internet
   **that session**. Creates a **pending** request (mobile, time, amount,
   photo in Storage). Shop stays **locked**.
4. App shows **Waiting for confirmation**.
5. After admin Approve, they need internet **once** more → Refresh plan
   (or reopen). Then GST billing is offline again until the paid window
   ends.

Subscribe today only re-reads Firestore. It does not charge and does not
upload a proof.

### Admin panel (to build)

One login only the operator has (not the shop OTP). Inbox of requests:

| Row | Meaning |
|---|---|
| Account mobile | Who they are (`+91 …` / doc id `91…`) |
| Submitted at | When the proof arrived |
| Amount claimed | Should match current `priceInr` |
| Screenshot | Storage URL; operator looks at it |
| Status | `pending` / `approved` / `rejected` |

Actions:

- **Approve 1 year** — server writes `entitlements/{91…}`:
  `status=paid`, `trialEndsAt` = now + 365 days. Phone cannot do this.
- **Reject** — short reason; shop sees it after Refresh.

Until this panel exists, the same writes are done in **Firestore Console**
on the existing entitlement document (do not create entitlements by hand;
the app creates them after OTP).

### How to treat a screenshot as fake

Approve only if **all** look right:

- Payee UPI / QR in the shot is **ours**
- Amount matches current `plans/default.priceInr`
- Time is recent (not an old receipt)
- Payer identity is plausible
- No duplicate pending/approved proof for this mobile for this period

Otherwise **Reject**. Upload must never auto-unlock.

### Offline vs online

| Moment | Need internet? |
|---|---|
| Daily GST billing | No |
| UPI pay + submit screenshot | Yes, that session |
| Operator Approve / Reject | Operator on admin |
| Unlock on their phone | Yes, once after Approve |

If they never come online after Approve, they stay on the paywall.

### Data shape (when we implement)

- Firestore e.g. `paymentProofs/{id}`: mobile, amountInr, createdAt,
  storagePath, status, reviewer note. Phone may **create pending** for
  its own mobile only.
- Storage: screenshot under that mobile; admin backend can read all.
- Rules stay: phone **read** own entitlement; phone **cannot** set
  `status=paid` or edit `plans`.
- Invoice PDFs and SQLite stay on device. Proofs are not in the backup ZIP.

### What not to build in this path

- In-app Razorpay/UPI checkout as the store unlock
- Chat to the operator’s personal number
- Auto-renew, payment receipts as GST tax invoices
- Unlock without a human Approve

## Demo APK for sending to a client (15 days)

This is **not** the paid license. It is a time-bomb binary so a sales demo
cannot be forwarded as a free forever app.

**Do not** implement “15 days from first open” in prefs or SQLite. Every new
phone, clear-data, or reinstall would start a fresh 15 days.

**Do** bake a **calendar expiry** into that APK (`expiresAt` = send date + 15
days, not merely compile date + 15). Sharing the file does not mint extra
time. Every copy of that build dies on the same day.

| Approach | Forwarded APK | Clear data / reinstall | New phone |
|---|---|---|---|
| 15 days from first launch, saved locally | New 15 days each install | New 15 days | New 15 days |
| Expiry date compiled into the APK | Same deadline for everyone | Still dead after that date | Still dead after that date |

### Client-specific demo, not the production APK

- Flutter `demo` flavor only. Never send Play/production/`direct` APK for a
  trial.
- Per client when building: `expiresAt` + `clientName`.
- Banner and lock dialog use the client name so a leak is identifiable
  (“Demo for Sharma Traders”).
- Watermark PDFs as demo even during the 15 days.

### After expiry

Block **all** features: splash, home, invoices, purchases, backup, restore.
Show a dialog (and keep them on a dead screen if they dismiss):

**Please contact sales person**

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

- Phone OTP account identity is implemented. Firestore holds `entitlements`
  (account mobile + trial/plan) and `plans` (price, trialDays). Invoice data
  is not stored there. Invoice mobile on the business profile is a separate
  local field. Splash blocks onboarding and shop setup until Phone Auth and
  entitlement sync both succeed. After first sync, later launches re-read
  `status` and `trialEndsAt` when online. The last-day-offline prompt and
  expired-trial page live on `/subscription`. Plan cache uses `entitlement_*`
  prefs that are not in the backup ZIP. App Store / Play Billing purchase
  is still not wired; a console `status=paid` (admin) can unlock after
  trial until IAP or the admin proof queue ships. Operator steps and the
  OTP screen live in [PROJECT_HANDOFF.md](PROJECT_HANDOFF.md) under Account
  identity. The agreed direct-APK UPI + screenshot + admin inbox is in
  **Direct APK: UPI proof + admin panel** above (not implemented).
- If shops later ask for cloud bills: keep SQLite on device; do not put
  invoices in Firestore. Optional sync would be Postgres (Supabase), still
  keyed by account mobile. Firebase stays OTP + plan only.
- No Play Billing, RevenueCat, Keygen, admin website, or payment-proof
  upload in the project today.
- Backup: full SQLite + settings whitelist + media; restore remaps media
  paths and rebuilds database-bound GetX runtime. Firebase Auth session is
  not in the ZIP.
- `AppStorageKeyConst` holds UI/business defaults and app-lock hashes, not
  entitlements.
- Product plan (`CODEX_IMPLEMENTATION_PLAN.md`) still says no cloud of
  invoice data. Licensing as designed does not add invoice sync.

## Open decisions (do not block other app work)

- Exact Free vs Pro feature list and price (`priceInr` vs ₹499 fallback).
- Lifetime only vs lifetime + yearly SKU.
- Business UPI ID / QR to show on the paywall (must not be a personal mobile).
- Admin panel host (Firebase Hosting + Cloud Function vs a tiny private site).
- Keygen vs LicenseSpring later, or admin-approve only for direct APK.
- Whether Purchases stays free or is a Pro gate.
- Per-client demo naming convention and who builds those APKs.
