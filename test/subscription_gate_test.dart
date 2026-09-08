import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:creovo_invoice/app/themes/app_theme.dart';
import 'package:creovo_invoice/app/widgets/app_button.dart';
import 'package:creovo_invoice/data/services/account_auth_service.dart';
import 'package:creovo_invoice/data/services/account_entitlement_service.dart';
import 'package:creovo_invoice/data/services/entitlement_policy.dart';
import 'package:creovo_invoice/data/services/network_status.dart';
import 'package:creovo_invoice/data/services/store_billing_service.dart';
import 'package:creovo_invoice/modules/account/controllers/subscription_gate_controller.dart';
import 'package:creovo_invoice/modules/account/screens/subscription_gate_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(Get.reset);

  Future<void> pumpGate(
    WidgetTester tester, {
    required EntitlementAccess access,
    StoreBilling? billing,
    bool online = false,
  }) async {
    final entitlements = AccountEntitlementService(
      network: FixedNetworkStatus(online),
      billing: billing,
    );
    entitlements.lastAccess = access;
    entitlements.lastSnapshot = EntitlementSnapshot(
      mobile: '+917048321663',
      status: 'trial',
      planId: 'default',
      trialEndsAt: DateTime.utc(2026, 9, 4, 17),
      planTitle: 'Default',
      priceInr: 0,
      period: 'yearly',
    );
    Get.put<AccountAuthService>(SkipAccountAuthService());
    Get.put<AccountEntitlementService>(entitlements);
    Get.put(SubscriptionGateController());
    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.light,
        home: const SubscriptionGateScreen(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('expired trial shows the subscription page', (tester) async {
    tester.view.physicalSize = const Size(400, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpGate(tester, access: EntitlementAccess.expired);

    expect(find.text('Keep creating GST invoices'), findsOneWidget);
    expect(find.text('Creovo Yearly'), findsOneWidget);
    expect(find.text('SAVE 50% TODAY'), findsNothing);
    expect(find.text('₹499 / year'), findsOneWidget);
    expect(
      find.text(
        'Price available from the store at checkout. Auto-renews yearly.',
      ),
      findsOneWidget,
    );
    expect(find.text('Subscribe'), findsOneWidget);
    expect(find.text('Payment reminders & WhatsApp share'), findsNothing);
    expect(find.text('Products, stock & customers'), findsOneWidget);
    expect(find.text('Unlimited GST invoices & PDFs'), findsOneWidget);
    expect(find.text('Check subscription'), findsNothing);
    expect(find.text('Use a different phone number'), findsOneWidget);
    expect(find.text('RESTORE'), findsNothing);
    expect(find.byIcon(Icons.close_rounded), findsNothing);
    expect(find.widgetWithText(AppButton, 'Subscribe'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final result in [
    BillingResult.active,
    BillingResult.pending,
    BillingResult.cancelled,
  ]) {
    testWidgets('store purchase maps $result without granting pending access', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(400, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final billing = _FakeBilling(result);
      await pumpGate(
        tester,
        access: EntitlementAccess.expired,
        billing: billing,
        online: true,
      );
      await Get.find<SubscriptionGateController>().loadOffer();
      await tester.pumpAndSettle();
      expect(find.text('₹599 / year'), findsOneWidget);
      await tester.tap(find.widgetWithText(AppButton, 'Subscribe'));
      await tester.pumpAndSettle();
      expect(billing.purchases, 1);
      expect(
        Get.find<SubscriptionGateController>().stage.value,
        result == BillingResult.active
            ? SubscriptionStage.success
            : result == BillingResult.pending
            ? SubscriptionStage.pending
            : SubscriptionStage.offer,
      );
      if (result == BillingResult.pending) {
        expect(find.text('Waiting for payment confirmation'), findsOneWidget);
        billing.active = true;
        await tester.tap(find.text('Check status'));
        await tester.pumpAndSettle();
        expect(find.text('You’re subscribed!'), findsOneWidget);
        expect(billing.purchases, 1);
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('restore does not start a new purchase', (tester) async {
    final billing = _FakeBilling(BillingResult.active);
    await pumpGate(
      tester,
      access: EntitlementAccess.expired,
      billing: billing,
      online: true,
    );
    await Get.find<SubscriptionGateController>().restore(
      tester.element(find.byType(SubscriptionGateScreen)),
    );
    await tester.pumpAndSettle();
    expect(billing.purchases, 0);
    expect(find.text('You’re subscribed!'), findsOneWidget);
  });

  testWidgets('last-day offline prompt asks to turn internet on', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpGate(tester, access: EntitlementAccess.needsNetwork);

    expect(find.text('Turn on internet'), findsOneWidget);
    expect(
      find.text(
        'Today is the last day of your trial. Connect once to confirm your Creovo Yearly plan.',
      ),
      findsOneWidget,
    );
    expect(find.text('Turn on internet & continue'), findsOneWidget);
    expect(find.text('Subscribe'), findsNothing);
    expect(find.text('Keep creating GST invoices'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('offline subscribe shows notice and stays on gate', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pumpGate(tester, access: EntitlementAccess.expired);
    final subscribe = find.widgetWithText(AppButton, 'Subscribe');
    await tester.ensureVisible(subscribe);
    await tester.tap(subscribe);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Connect to the internet'), findsOneWidget);
    expect(Get.find<SubscriptionGateController>().working.value, isTrue);
    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();
    expect(find.text('Connect to the internet'), findsNothing);
    expect(find.byType(SubscriptionGateScreen), findsOneWidget);
    expect(Get.find<SubscriptionGateController>().working.value, isFalse);
    await tester.tap(subscribe);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Connect to the internet'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _FakeBilling implements StoreBilling {
  @override
  Future<void> manage() async {}
  _FakeBilling(this.result);
  final BillingResult result;
  int purchases = 0;
  bool active = false;
  @override
  bool get configured => true;
  @override
  String get priceLabel => '₹599';
  @override
  Future<void> loadOffer() async {}
  @override
  Future<BillingAccess> access({bool refresh = false}) async =>
      BillingAccess(active: active);
  @override
  Future<BillingResult> purchase() async {
    purchases++;
    return result;
  }

  @override
  Future<BillingResult> restore() async => result;

  @override
  Future<void> resetIdentity() async {}
}
