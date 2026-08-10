import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:creovo_invoice/app/enums/invoice_status.dart';
import 'package:creovo_invoice/app/themes/app_theme.dart';
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
}
