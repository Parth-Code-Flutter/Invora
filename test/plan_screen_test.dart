import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:creovo_invoice/app/themes/app_theme.dart';
import 'package:creovo_invoice/data/services/account_auth_service.dart';
import 'package:creovo_invoice/data/services/account_entitlement_service.dart';
import 'package:creovo_invoice/data/services/entitlement_policy.dart';
import 'package:creovo_invoice/data/services/network_status.dart';
import 'package:creovo_invoice/modules/account/controllers/plan_controller.dart';
import 'package:creovo_invoice/modules/account/screens/plan_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(Get.reset);

  Future<void> pumpPlan(
    WidgetTester tester, {
    required EntitlementSnapshot snapshot,
  }) async {
    final entitlements = AccountEntitlementService(
      network: const FixedNetworkStatus(false),
      clock: () => DateTime.utc(2026, 9, 1, 8),
    );
    entitlements.lastAccess = EntitlementAccess.active;
    entitlements.lastSnapshot = snapshot;
    Get.put<AccountAuthService>(SkipAccountAuthService());
    Get.put<AccountEntitlementService>(entitlements);
    Get.put(
      PlanController(
        Get.find<AccountAuthService>(),
        Get.find<AccountEntitlementService>(),
      ),
    );

    tester.view.physicalSize = const Size(400, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      GetMaterialApp(theme: AppTheme.light, home: const PlanScreen()),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('in-app plan page matches the Figma management layout', (
    tester,
  ) async {
    await pumpPlan(
      tester,
      snapshot: EntitlementSnapshot(
        mobile: '+917048321663',
        status: 'trial',
        planId: 'default',
        trialEndsAt: DateTime.now().toUtc().add(const Duration(days: 10)),
        planTitle: 'Default',
        priceInr: 0,
        period: 'yearly',
      ),
    );

    expect(find.text('Your plan'), findsWidgets);
    expect(find.text('Subscription & Billing'), findsOneWidget);
    expect(find.text('Help'), findsOneWidget);
    expect(find.text('Creovo Yearly'), findsWidgets);
    expect(find.text('All-in-one Business Suite'), findsOneWidget);
    expect(find.text('ACTIVE'), findsOneWidget);
    expect(find.text('VALIDITY & STATUS'), findsOneWidget);
    expect(find.text('Trial License'), findsOneWidget);
    expect(find.text('Auto-Renewal is Off'), findsOneWidget);
    expect(find.text('PLAN PRIVILEGES'), findsOneWidget);
    expect(find.text('Unlimited GST Bills'), findsOneWidget);
    expect(find.text('Ledger & Khata'), findsOneWidget);
    expect(find.text('100% Offline & Safe'), findsOneWidget);
    expect(find.text('Priority Support'), findsOneWidget);
    expect(find.text('Registered Mobile'), findsOneWidget);
    expect(find.text('+91 70483 21663'), findsOneWidget);
    await tester.ensureVisible(find.text('Refresh Plan'));
    expect(find.text('Refresh Plan'), findsOneWidget);
    expect(find.text('Chat on WhatsApp'), findsOneWidget);
    expect(find.text('Manage Renewal'), findsOneWidget);
    expect(find.text('Subscribe to Creovo Yearly'), findsNothing);
    expect(find.text('Your shop is on a trial'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('paid yearly plan shows an active license badge', (tester) async {
    await pumpPlan(
      tester,
      snapshot: const EntitlementSnapshot(
        mobile: '+917048321663',
        status: 'paid',
        planId: 'default',
        trialEndsAt: null,
        planTitle: 'Default',
        priceInr: 499,
        period: 'yearly',
      ),
    );

    expect(find.text('Active License'), findsOneWidget);
    expect(find.text('₹499/yr'), findsOneWidget);
    expect(find.text('All Unlocked'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
