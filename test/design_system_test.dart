import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:creovo_invoice/app/enums/invoice_status.dart';
import 'package:creovo_invoice/app/constants/app_colors.dart';
import 'package:creovo_invoice/app/themes/app_theme.dart';
import 'package:creovo_invoice/app/widgets/app_module_banner.dart';
import 'package:creovo_invoice/app/widgets/app_search_field.dart';
import 'package:creovo_invoice/app/widgets/app_status_chip.dart';
import 'package:creovo_invoice/app/widgets/app_text_field.dart';

void main() {
  testWidgets('shared fields and status chip expose clear semantics', (
    tester,
  ) async {
    final textController = TextEditingController();
    addTearDown(textController.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Column(
            children: [
              AppSearchField(hint: 'Search invoices', onChanged: (_) {}),
              AppTextField(
                controller: textController,
                label: 'Business name',
                hint: 'Enter business name',
              ),
              const AppStatusChip(status: InvoiceStatus.partiallyPaid),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Business name'), findsOneWidget);
    expect(find.text('Partially paid'), findsOneWidget);
    expect(
      tester.getSemantics(find.byType(AppStatusChip)),
      matchesSemantics(label: 'Status: Partially paid'),
    );
  });

  testWidgets('module banner stays usable on a narrow phone', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 320,
              child: AppModuleBanner(
                title: 'Your money timeline',
                subtitle: 'Create quickly and see what is paid or still due.',
                icon: Icons.receipt_long_outlined,
                colors: const [AppColors.secondary, AppColors.primary],
                actionLabel: 'New invoice',
                onAction: () {},
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Your money timeline'), findsOneWidget);
    expect(find.byTooltip('New invoice'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
