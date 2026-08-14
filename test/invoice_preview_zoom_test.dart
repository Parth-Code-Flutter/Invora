import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:printing/printing.dart';

import 'package:creovo_invoice/modules/invoices/screens/invoice_preview_screen.dart';

void main() {
  testWidgets('invoice preview supports direct zoom and double-tap reset', (
    tester,
  ) async {
    final image = MemoryImage(
      Uint8List.fromList(
        base64Decode(
          'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
        ),
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ZoomablePdfPages(
            pages: [PdfPreviewPageData(image: image, width: 1, height: 1)],
          ),
        ),
      ),
    );

    final viewer = tester.widget<InteractiveViewer>(
      find.byType(InteractiveViewer),
    );
    expect(viewer.scaleEnabled, isTrue);
    expect(viewer.panEnabled, isTrue);
    expect(viewer.maxScale, 5);

    final target = find.byType(InteractiveViewer);
    await tester.tap(target);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(target);
    await tester.pumpAndSettle();
    expect(viewer.transformationController!.value.getMaxScaleOnAxis(), 2.25);

    await tester.tap(target);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(target);
    await tester.pumpAndSettle();
    expect(viewer.transformationController!.value.getMaxScaleOnAxis(), 1);
    expect(tester.takeException(), isNull);
  });
}
