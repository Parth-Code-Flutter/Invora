import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:creovo_invoice/app/themes/app_theme.dart';
import 'package:creovo_invoice/app/widgets/app_empty_state.dart';

void main() {
  for (final height in [360.0, 220.0]) {
    testWidgets('purchase empty action is reachable at height $height', (
      tester,
    ) async {
      var pressed = false;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 320,
                height: height,
                child: MediaQuery(
                  data: MediaQueryData(
                    textScaler: TextScaler.linear(height == 220 ? 1.5 : 1),
                  ),
                  child: AppEmptyState(
                    illustration: AppEmptyIllustration.purchaseBills,
                    title: 'No purchase bills yet',
                    message:
                        'Record supplier bills and track payments in one place.',
                    actionLabel: 'Create purchase bill',
                    onAction: () => pressed = true,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final action = find.text('Create purchase bill');
      await tester.ensureVisible(action);
      await tester.pumpAndSettle();
      await tester.tap(action);
      expect(pressed, isTrue);
      expect(tester.takeException(), isNull);
    });
  }
}
