import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:creovo_invoice/app/widgets/app_button.dart';
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

    expect(find.text('Your first offline billing app'), findsOneWidget);
    expect(find.text('+91'), findsWidgets);
    expect(find.text('Use a number from this phone'), findsOneWidget);
    expect(find.text('On this phone'), findsNothing);
    expect(
      find.text('Used only to check your trial and subscription.'),
      findsOneWidget,
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

    await tester.enterText(find.byType(TextFormField), '9876543210');
    await tester.tap(find.widgetWithText(AppButton, 'Send OTP'));
    await tester.pumpAndSettle();

    expect(find.text('Enter OTP *'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).last, '123456');
    await tester.tap(find.widgetWithText(AppButton, 'Verify & continue'));
    await tester.pumpAndSettle();

    expect(find.text('Your invoice, ready in minutes'), findsOneWidget);
  });
}
