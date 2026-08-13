import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:creovo_invoice/app/widgets/unsaved_changes_scope.dart';

void main() {
  testWidgets('clean forms leave immediately without a warning', (
    tester,
  ) async {
    await _openProtectedPage(tester, hasChanges: () => false);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('Protected form'), findsNothing);
    expect(find.text('Unsaved Changes'), findsNothing);
  });

  testWidgets('dirty forms can continue editing or discard', (tester) async {
    await _openProtectedPage(tester, hasChanges: () => true);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Unsaved Changes'), findsOneWidget);

    await tester.tap(find.text('Continue editing'));
    await tester.pumpAndSettle();
    expect(find.text('Protected form'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();
    expect(find.text('Protected form'), findsNothing);
  });

  testWidgets('invoice-style forms can save a draft before leaving', (
    tester,
  ) async {
    var savedDraft = false;
    await _openProtectedPage(
      tester,
      hasChanges: () => true,
      onSaveDraft: () async {
        savedDraft = true;
        return true;
      },
    );

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Save draft'), findsOneWidget);
    await tester.tap(find.text('Save draft'));
    await tester.pumpAndSettle();

    expect(savedDraft, isTrue);
    expect(find.text('Protected form'), findsNothing);
  });
}

Future<void> _openProtectedPage(
  WidgetTester tester, {
  required bool Function() hasChanges,
  Future<bool> Function()? onSaveDraft,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: FilledButton(
              onPressed: () => Navigator.push<void>(
                context,
                MaterialPageRoute(
                  builder: (_) => UnsavedChangesScope(
                    hasChanges: hasChanges,
                    onSaveDraft: onSaveDraft,
                    child: const Scaffold(body: Text('Protected form')),
                  ),
                ),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}
