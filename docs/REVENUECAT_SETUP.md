# Store subscriptions — Creovo setup and testing

Updated: 2026-09-08. Bundle/application ID: `com.creovo.billing`.

## What is implemented, and what is not

The Flutter app uses RevenueCat `purchases_flutter`. Subscribe loads the current
offering's annual package and opens native store checkout. Restore purchases,
pending confirmation, success, cancellation, errors and offline notices are
wired. Returning to the pending screen from background rechecks status; Check
status never charges again. Continue verifies access before opening the app.
Manage renewal opens the store management URL when one exists. Until public
SDK keys and the current annual offering are present, the paywall shows
`₹499 / year` and “Price available from the store at checkout”; that copy is
not a live Play/App Store price.

No account, product, key, offering or agreement has been created on your behalf.
No live/sandbox store transaction has been tested yet. A bundle ID alone is not
enough for real App Store sandbox purchases. The app must be fully rebuilt after
adding the native plugins; hot reload is insufficient.

There is no Razorpay, Stripe, payment screenshot form or manual approval step.
Apple/Google take payment and settle proceeds according to your store agreement.
RevenueCat validates purchases, tracks subscription access, renewals and refunds,
and presents this history in its dashboard. Review its current pricing separately.

## Architecture and identity

- Firebase Phone Auth remains the account login; Firebase trial data is retained.
- RevenueCat App User ID is the Firebase Auth UID, not a phone number or invoice
  customer. Use the same OTP account when switching devices. Account changes
  call RevenueCat logIn before querying/purchasing to avoid the previous user.
- Entitlement identifier: `creovo_pro` (can be overridden with RC_ENTITLEMENT).
- Store access is checked before the Firebase trial. Firebase `status=paid` is
  NOT a store purchase and no longer unlocks the production app's paid gate.
- No RevenueCat paid state is written to Firestore or business backup. The SDK
  caches CustomerInfo. Offline access also requires an unexpired entitlement;
  reconnect after expiry. This is not tamper-proof licensing against a rooted
  device or a modified clock/binary.
- Both platform products must grant the SAME RevenueCat entitlement. RevenueCat
  manages acknowledgement/transaction completion; don't also use a second IAP SDK.

## 1. Start now: RevenueCat Test Store (no Play account needed)

### Fees checked September 8, 2026

- RevenueCat standard pricing: free through USD 2,500 monthly tracked revenue;
  above that, 1% of the whole tracked revenue for that month, not just the excess.
  This is measured before platform commission and billed separately.
- Google Play auto-renewing subscriptions: standard service fee 15%.
- Apple standard auto-renewing subscriptions: 30% in a subscriber's first paid
  year, then 15%; approved Small Business Program members receive the 15% rate
  from the start, subject to eligibility. Enrollment is not automatic.
- These are standard store-billing rates, not regional alternative terms.
  Taxes, currency conversion, refunds and developer-account fees are separate.
  A simplified ₹499 example at 15% leaves ₹424.15 before those adjustments;
  if RevenueCat's paid tier applies, an additional illustrative ₹4.99 leaves
  ₹419.16. This is not a guaranteed tax-inclusive payout estimate.
- Sources: [RevenueCat pricing](https://www.revenuecat.com/pricing),
  [Google fees](https://support.google.com/googleplay/android-developer/answer/112622),
  [Apple subscriptions](https://developer.apple.com/app-store/subscriptions/),
  [Apple Small Business](https://developer.apple.com/app-store/small-business-program/).

1. Create a RevenueCat account and a project named Creovo.
2. Open Product catalog. Create entitlement `creovo_pro`.
3. In Test Store, create an annual subscription product with your intended price.
4. Attach that product to `creovo_pro`.
5. Create an offering (for example `default`), make it current, and add its
   **Annual** package (`$rc_annual`) using that Test Store product.
6. Copy the Test Store **public SDK key** from Project settings → API keys.
7. Run a development build:

   ```sh
   flutter run --dart-define=RC_TEST_API_KEY=test_YOUR_PUBLIC_KEY
   ```

8. Sign in using OTP, open the subscription page, and try Subscribe/Restore.
   Look up that Firebase UID in RevenueCat Customers to inspect entitlement.

Test Store simulates transactions; it does not validate real Apple/Google store
configuration or charge money. Test keys are ignored/rejected in release builds.
Never ship a Test Store key as an Apple/Google key. No secret API key belongs in
Dart, git, the APK, or this document.

## 2. Apple setup — you currently have only the bundle ID

1. Ensure Apple Developer membership is active. In App Store Connect, create a
   new app using your existing `com.creovo.billing` bundle ID and a unique SKU.
2. Complete Business agreements (Paid Apps), tax and bank details as requested.
3. Under the app's subscriptions, create a subscription group (Creovo Pro).
4. Add a **one-year auto-renewable subscription**, e.g. product ID
   `creovo_yearly`. These are suggested IDs, not already-created products.
5. Configure availability, actual price, display name, description, and required
   review information/screenshot. Do not advertise a fabricated 50% discount.
6. In RevenueCat add an App Store app with the matching bundle ID. Follow its
   Apple credentials wizard (In-App Purchase key, key ID, issuer ID and any
   requested App Store Connect API credentials). Upload private `.p8` keys only
   in the appropriate secure dashboard—never send them in chat or commit them.
7. Import the product, attach `creovo_pro`, and map it to the current offering's
   Annual package for the Apple app.
8. Enable In-App Purchase capability for Runner in Xcode if not already enabled.
   Let Flutter resolve native dependencies using the project's current iOS setup.
9. Create a sandbox tester in App Store Connect and use Apple's documented
   sandbox sign-in process on your test device. Run with the Apple public key:

   ```sh
   flutter run --dart-define=RC_APPLE_API_KEY=appl_YOUR_PUBLIC_KEY
   ```

10. Verify real sandbox purchases and restore on a device; then upload a build
    to TestFlight for pre-release testing. Public release is not required.
    Local Xcode StoreKit testing is another simulation option, not a substitute
    for RevenueCat plus real App Store sandbox verification.

## 3. Google Play — when your account is approved

1. Create the Play Console app for `com.creovo.billing`; complete the required
   payments/merchant setup, bank and tax information.
2. Upload a signed AAB to an internal test track. Keep signing secrets out of git.
3. Create a subscription (e.g. `creovo_yearly`) with an active annual,
   auto-renewing base plan (e.g. `yearly`). Configure countries and price.
4. Add the Google Play app in RevenueCat. Follow its Google service-account
   credential instructions, grant the required Play Console permissions, and
   configure real-time developer notifications as instructed by the dashboard.
5. Import the exact product/base plan, attach `creovo_pro`, and map it to the
   same current offering's Annual package for Android.
6. Add test accounts as **license testers** and internal-track testers. Accept
   the opt-in link and install using the tester's Play account.
7. Build using the Google public SDK key:

   ```sh
   flutter build appbundle --dart-define=RC_GOOGLE_API_KEY=goog_YOUR_PUBLIC_KEY
   ```

8. Confirm the purchase sheet shows a test payment method. Use license-test
   methods, not real cards. Internal-track membership alone is not the same
   thing as license testing. Test delayed/pending payments too.

## 4. Required verification before release

- Success unlocks only `creovo_pro`; cancellation/failure/pending do not unlock.
- Purchase completion after background/relaunch, Restore after reinstall, and
  same-OTP cross-device access work. Test different OTP/store accounts; select
  and verify RevenueCat restore/transfer behaviour deliberately to prevent
  accidental entitlement transfer between customers.
- Test renewal, expiry, refund/revocation, offline before and after expiry, and
  unavailable products. Confirm Firebase trial and purchase access agree.
- Terms of Service, Privacy Policy and Support labels on the paywall still need
  real published destinations and functional links before store submission.
  Update privacy declarations to include Firebase UID and purchase processing
  by RevenueCat; invoice data remains local.
- Review older Your plan copy/auto-renew presentation against real cancellation
  state before release; no fabricated next-charge amounts should be shown.
- Configure real products and production public keys for each platform. No test
  keys, secret keys or manual Firestore paid flags as release shortcuts.
- Test native builds on both platforms; widget tests do not validate native
  SDK installation, signing, console configuration or money movement.

## Official references

- [RevenueCat Flutter installation](https://www.revenuecat.com/docs/getting-started/installation/flutter)
- [Test Store](https://www.revenuecat.com/docs/test-and-launch/sandbox/test-store)
- [SDK configuration](https://www.revenuecat.com/docs/getting-started/configuring-sdk)
- [Making purchases](https://www.revenuecat.com/docs/getting-started/making-purchases)
- [Google billing tests](https://developer.android.com/google/play/billing/test)
- [Apple testing](https://developer.apple.com/documentation/storekit/testing-at-all-stages-of-development-with-xcode-and-the-sandbox)
# Firebase purchase mirroring (not deployed)

The existing phone-keyed `entitlements` document is trial history, not a live
RevenueCat subscription mirror. Keep its trial dates intact. Use the official
RevenueCat Firebase extension to write verified customer records and lifecycle
events into separate collections (for example `billingCustomers` keyed by
Firebase UID and `billingEvents`). The app already identifies RevenueCat users
with Firebase UID. Never enable client writes to paid status.

Installation requires Firebase Blaze billing; obtain owner approval first.
Follow https://www.revenuecat.com/docs/integrations/third-party-integrations/firebase-integration
for extension installation, webhook configuration, and sandbox event testing.
Verify a fresh purchase, renewal, expiration and cancellation after setup;
previous purchases are not assumed to have been backfilled. This sync is not
deployed or verified yet. RevenueCat remains the app's paid-access authority.
