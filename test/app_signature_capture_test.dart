import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:creovo_invoice/app/themes/app_theme.dart';
import 'package:creovo_invoice/app/widgets/app_button.dart';
import 'package:creovo_invoice/app/widgets/app_signature_capture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('signature source sheet offers draw, gallery, and camera', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showSignatureSourceSheet(context),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Add signature'), findsOneWidget);
    expect(find.text('Draw signature'), findsOneWidget);
    expect(find.text('Pick from gallery'), findsOneWidget);
    expect(find.text('Take a photo'), findsOneWidget);
  });

  testWidgets('signature pad stays disabled until ink is drawn', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showSignaturePadDialog(context),
              child: const Text('Open pad'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open pad'));
    await tester.pumpAndSettle();

    expect(find.text('Sign here'), findsOneWidget);
    expect(
      tester
          .widget<AppButton>(find.widgetWithText(AppButton, 'Use signature'))
          .onPressed,
      isNull,
    );

    final pad = tester.getRect(find.byKey(const Key('signature-pad')));
    await tester.timedDragFrom(
      pad.centerLeft + const Offset(24, 0),
      const Offset(140, 18),
      const Duration(milliseconds: 200),
    );
    await tester.pump();

    expect(find.text('Sign here'), findsNothing);
    expect(
      tester
          .widget<AppButton>(find.widgetWithText(AppButton, 'Use signature'))
          .onPressed,
      isNotNull,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('reopening the pad shows the signature already drawn', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showSignaturePadDialog(
                context,
                existingPng: Uint8List.fromList(_onePixelPng),
              ),
              child: const Text('Open pad'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open pad'));
    await tester.pumpAndSettle();

    expect(find.text('Sign here'), findsNothing);
    expect(find.byType(Image), findsOneWidget);
    expect(
      tester
          .widget<AppButton>(find.widgetWithText(AppButton, 'Use signature'))
          .onPressed,
      isNotNull,
    );
  });

  testWidgets('tablet source sheet opens as a centred dialog', (tester) async {
    tester.view.physicalSize = const Size(834, 1194);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showSignatureSourceSheet(context),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.byType(Dialog), findsOneWidget);
    expect(find.text('Draw signature'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

const _onePixelPng = <int>[
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x48,
  0x44,
  0x52,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x01,
  0x08,
  0x02,
  0x00,
  0x00,
  0x00,
  0x90,
  0x77,
  0x53,
  0xDE,
  0x00,
  0x00,
  0x00,
  0x0C,
  0x49,
  0x44,
  0x41,
  0x54,
  0x08,
  0xD7,
  0x63,
  0xF8,
  0xCF,
  0xC0,
  0x00,
  0x00,
  0x03,
  0x01,
  0x01,
  0x00,
  0x18,
  0xDD,
  0x8D,
  0xB0,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49,
  0x45,
  0x4E,
  0x44,
  0xAE,
  0x42,
  0x60,
  0x82,
];
