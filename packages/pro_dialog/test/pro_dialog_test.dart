import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pro_dialog/pro_dialog.dart';

void main() {
  testWidgets('confirm dialogs use a centered tone icon and paired actions', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => ProDialog.confirm(
                context,
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
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);
    expect(find.byIcon(Icons.priority_high_rounded), findsOneWidget);
    expect(find.byType(ProDialogButton), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('notice dialogs use the success surface', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => ProDialog.notice(
                context,
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
          body: ProDialog(
            tone: ProDialogTone.question,
            title: Text('Enable notifications?'),
            content: Text('Stay up to date with personalized alerts.'),
            actions: [
              ProDialogButton(
                label: 'No Thanks',
                variant: ProDialogButtonVariant.outlined,
                onPressed: null,
              ),
              ProDialogButton(
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

    final filledInk = tester.widget<Ink>(
      find.descendant(
        of: find.widgetWithText(ProDialogButton, 'Enable'),
        matching: find.byType(Ink),
      ),
    );
    final filled = filledInk.decoration! as BoxDecoration;
    expect(filled.gradient, isA<LinearGradient>());
    expect((filled.gradient! as LinearGradient).colors, const [
      Color(0xFFF36F62),
      Color(0xFF6A315F),
    ]);

    final outlinedInk = tester.widget<Ink>(
      find.descendant(
        of: find.widgetWithText(ProDialogButton, 'No Thanks'),
        matching: find.byType(Ink),
      ),
    );
    final outlined = outlinedInk.decoration! as BoxDecoration;
    expect(outlined.color, const Color(0xFFFFFCF8));
    expect(outlined.border!.top.color, const Color(0xFF6A315F));
  });

  testWidgets('warning filled confirms stay type-tinted, outlined stay plum', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ProDialog(
            tone: ProDialogTone.warning,
            stackedActions: true,
            title: Text('Unsaved Changes'),
            content: Text('Save, continue, or discard.'),
            actions: [
              ProDialogButton(
                label: 'Continue editing',
                variant: ProDialogButtonVariant.outlined,
                onPressed: null,
              ),
              ProDialogButton(
                label: 'Discard',
                variant: ProDialogButtonVariant.outlined,
                tone: ProDialogTone.error,
                onPressed: null,
              ),
              ProDialogButton(label: 'Save draft', onPressed: null),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final saveInk = tester.widget<Ink>(
      find.descendant(
        of: find.widgetWithText(ProDialogButton, 'Save draft'),
        matching: find.byType(Ink),
      ),
    );
    expect(
      ((saveInk.decoration! as BoxDecoration).gradient! as LinearGradient)
          .colors,
      const [Color(0xFFF36F62), Color(0xFFE58A3A)],
    );

    final continueInk = tester.widget<Ink>(
      find.descendant(
        of: find.widgetWithText(ProDialogButton, 'Continue editing'),
        matching: find.byType(Ink),
      ),
    );
    expect(
      (continueInk.decoration! as BoxDecoration).border!.top.color,
      const Color(0xFF6A315F),
    );

    final discardInk = tester.widget<Ink>(
      find.descendant(
        of: find.widgetWithText(ProDialogButton, 'Discard'),
        matching: find.byType(Ink),
      ),
    );
    expect(
      (discardInk.decoration! as BoxDecoration).border!.top.color,
      const Color(0xFFDC2626),
    );
  });

  testWidgets('long confirm labels stay fully visible on a phone width', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => ProDialog.confirm(
                context,
                destructive: true,
                title: 'Remove item?',
                message: 'This item will be removed from this invoice.',
                confirmLabel: 'Remove item',
                cancelLabel: 'Keep item',
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Keep item'), findsOneWidget);
    expect(find.text('Remove item'), findsOneWidget);
    final keep = tester.getRect(
      find.widgetWithText(ProDialogButton, 'Keep item'),
    );
    final remove = tester.getRect(
      find.widgetWithText(ProDialogButton, 'Remove item'),
    );
    expect(keep.width, closeTo(remove.width, 1));
    expect(keep.width, greaterThan(200));
    expect(remove.top, greaterThan(keep.bottom));
    expect(tester.takeException(), isNull);
  });
}
