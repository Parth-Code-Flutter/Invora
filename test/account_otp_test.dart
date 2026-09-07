import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:creovo_invoice/app/widgets/app_button.dart';
import 'package:creovo_invoice/app/widgets/app_otp_field.dart';
import 'package:creovo_invoice/data/services/account_auth_service.dart';
import 'package:creovo_invoice/data/services/account_phone.dart';
import 'package:creovo_invoice/data/services/app_database.dart';
import 'package:creovo_invoice/data/services/app_storage.dart';
import 'package:creovo_invoice/data/services/local_database_service.dart';
import 'package:creovo_invoice/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(Get.reset);

  test(
    'account phone helpers use Indian E.164 without storing invoice numbers',
    () {
      expect(AccountPhone.normalizeTenDigit('98 76-543210'), '9876543210');
      expect(AccountPhone.toE164('9876543210'), '+919876543210');
      expect(AccountPhone.toDocId('+919876543210'), '919876543210');
      expect(
        AccountPhone.validateNational('1234567890'),
        'Indian mobiles are 10 digits and start with 6, 7, 8 or 9.',
      );
      expect(AccountPhone.validateNational('9876543210'), isNull);
      expect(
        AccountPhone.parseImported('+91 98765 43210')?.e164,
        '+919876543210',
      );
    },
  );

  test('maps Firebase SMS region blocks to a clear account error', () {
    expect(
      mapPhoneAuthFailure(
        code: 'operation-not-allowed',
        message:
            'This operation is not allowed. [ SMS unable to be sent until this region enabled by the app developer. ]',
      ).message,
      'SMS to India is not allowed yet. In Firebase, enable Phone sign-in and allow India in SMS region policy.',
    );
  });

  test('maps Firestore API-off to a clear account error', () {
    expect(
      mapEntitlementFailure(
        code: 'unavailable',
        message: 'Failed to get document because the client is offline.',
      ).message,
      'Cloud Firestore is off. In Firebase, create a Firestore database for creovobilling, wait a minute, then tap Verify again.',
    );
    expect(
      mapEntitlementFailure(
        code: 'permission-denied',
        message:
            'Cloud Firestore API has not been used in project creovobilling before or it is disabled.',
      ).message,
      'Cloud Firestore is off. In Firebase, create a Firestore database for creovobilling, wait a minute, then tap Verify again.',
    );
  });

  testWidgets('unverified launch opens account OTP before onboarding', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final storage = await AppStorage.create();
    final databaseService = LocalDatabaseService(
      AppDatabase.forTesting(NativeDatabase.memory()),
    );
    await databaseService.initialize();
    addTearDown(databaseService.database.close);

    await tester.pumpWidget(
      CreovoInvoiceApp(
        appStorage: storage,
        databaseService: databaseService,
        accountAuth: SkipAccountAuthService(isVerified: false),
      ),
    );
    await tester.pump(const Duration(milliseconds: 1700));
    await tester.pumpAndSettle();

    expect(find.text('Welcome to Creovo Billing'), findsNothing);
    expect(find.text('Your first bill is minutes away'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Account mobile *')).dy,
      lessThan(tester.getTopLeft(find.text('Works offline')).dy),
    );
    expect(find.text('+91'), findsWidgets);
    expect(find.text('Use a number from this phone'), findsOneWidget);
    expect(find.text('On this phone'), findsNothing);
    expect(
      find.text('Used Only To Check Your Trial And Subscription.'),
      findsNothing,
    );
    expect(find.text('Your invoice, ready in minutes'), findsNothing);

    await tester.enterText(find.byType(TextFormField), '1234567890');
    await tester.tap(find.widgetWithText(AppButton, 'Send OTP'));
    await tester.pumpAndSettle();

    expect(
      find.text('Indian mobiles are 10 digits and start with 6, 7, 8 or 9.'),
      findsOneWidget,
    );
    expect(find.text('Enter OTP *'), findsNothing);
    expect(find.byType(AppOtpField), findsNothing);

    await tester.enterText(find.byType(TextFormField), '9876543210');
    await tester.tap(find.widgetWithText(AppButton, 'Send OTP'));
    await tester.pumpAndSettle();

    expect(find.text('Enter OTP'), findsOneWidget);
    expect(find.byType(AppOtpField), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('app-otp-input')),
      '123456',
    );
    await tester.pumpAndSettle();

    expect(find.text('Your invoice, ready in minutes'), findsOneWidget);
  });

  testWidgets('reinstall with leftover phone session still opens account OTP', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final storage = await AppStorage.create();
    final databaseService = LocalDatabaseService(
      AppDatabase.forTesting(NativeDatabase.memory()),
    );
    await databaseService.initialize();
    addTearDown(databaseService.database.close);
    final leftover = _LeftoverPhoneAuth();

    await tester.pumpWidget(
      CreovoInvoiceApp(
        appStorage: storage,
        databaseService: databaseService,
        accountAuth: leftover,
      ),
    );
    await tester.pump(const Duration(milliseconds: 1700));
    await tester.pumpAndSettle();

    expect(leftover.isVerified, isFalse);
    expect(find.text('Your first bill is minutes away'), findsOneWidget);
    expect(find.text('Account mobile *'), findsOneWidget);
    expect(find.text('Business Name'), findsNothing);
    expect(find.text('Business Name *'), findsNothing);
  });
}

class _LeftoverPhoneAuth implements AccountAuthService {
  @override
  bool isVerified = true;

  @override
  String? e164Mobile = '+919876543210';

  @override
  Future<void> sendOtp(String phone) async {}

  @override
  Future<void> verifyOtp(String smsCode) async {}

  @override
  Future<void> signOut() async {
    isVerified = false;
    e164Mobile = null;
  }
}
