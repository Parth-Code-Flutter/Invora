import 'package:creovo_invoice/app/widgets/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('optional field preserves a null validator result', (
    tester,
  ) async {
    final formKey = GlobalKey<FormState>();
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Form(
            key: formKey,
            child: AppTextField(
              controller: controller,
              label: 'Email address (optional)',
              validator: (value) => (value?.trim().isEmpty ?? true)
                  ? null
                  : 'Enter a valid email address.',
            ),
          ),
        ),
      ),
    );

    expect(formKey.currentState!.validate(), isTrue);
    await tester.pump();
    expect(find.text('Enter a valid email address.'), findsNothing);

    controller.text = 'invalid';
    expect(formKey.currentState!.validate(), isFalse);
    await tester.pump();
    expect(find.text('Enter a valid email address.'), findsOneWidget);
  });
}
