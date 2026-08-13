import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:creovo_invoice/app/widgets/app_dialog.dart';

void main() {
  testWidgets('confirm dialogs use a centered glow icon and paired actions', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showAppConfirmDialog(
                context: context,
                destructive: true,
                title: 'Delete customer?',
                message: 'Historical invoices will remain unchanged.',
                confirmLabel: 'Delete',
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Delete customer?'), findsOneWidget);
    expect(
      find.text('Historical invoices will remain unchanged.'),
      findsOneWidget,
    );
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);
    expect(find.byIcon(Icons.priority_high_rounded), findsOneWidget);
    expect(find.byType(AppDialogButton), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('notice dialogs use the success bounce surface', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showAppNoticeDialog(
                context: context,
                title: 'Restore complete',
                message: 'Close and reopen the app.',
                actionLabel: 'I’ll restart now',
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Restore complete'), findsOneWidget);
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    await tester.tap(find.text('I’ll restart now'));
    await tester.pumpAndSettle();
    expect(find.text('Restore complete'), findsNothing);
  });

  testWidgets('question dialogs animate without overflowing', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppDialog(
            tone: AppDialogTone.question,
            title: Text('Enable notifications?'),
            content: Text('Stay up to date with personalized alerts.'),
            actions: [
              AppDialogButton(
                label: 'No Thanks',
                variant: AppDialogButtonVariant.outlined,
                onPressed: null,
              ),
              AppDialogButton(
                label: 'Enable',
                icon: Icons.notifications_outlined,
                onPressed: null,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Enable notifications?'), findsOneWidget);
    expect(find.byIcon(Icons.help_rounded), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
