import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:creovo_invoice/data/models/customer_model.dart';
import 'package:creovo_invoice/data/services/data_export_service.dart';

void main() {
  test('CSV encoding escapes commas, quotes and line breaks', () {
    final csv = DataExportService.encodeCsv([
      ['Plain', 'Comma, value', 'Quote "value"', 'Two\nlines'],
    ]);

    expect(csv, 'Plain,"Comma, value","Quote ""value""","Two\nlines"');
  });

  test('customer export preserves Unicode and uses documented columns', () {
    final rows = DataExportService.customerRows([
      CustomerModel(
        name: 'શ્રી Ram, Traders',
        mobile: '9876543210',
        email: 'ram@example.com',
        notes: 'Prefers "email"',
        createdAt: DateTime.utc(2026, 8, 12),
        updatedAt: DateTime.utc(2026, 8, 12),
      ),
    ]);
    final bytes = utf8.encode('\ufeff${DataExportService.encodeCsv(rows)}');
    final csv = utf8.decode(bytes);

    // Dart's UTF-8 decoder consumes the BOM; spreadsheet applications use the
    // original encoded BOM to detect Unicode correctly.
    expect(bytes.take(3), [0xEF, 0xBB, 0xBF]);
    expect(csv.startsWith('Name,Company,Mobile'), isTrue);
    expect(csv, contains('"શ્રી Ram, Traders"'));
    expect(csv, contains('"Prefers ""email"""'));
    expect(csv, contains('9876543210'));
  });

  test('empty customer export still contains a useful header', () {
    final csv = DataExportService.encodeCsv(
      DataExportService.customerRows(const []),
    );

    expect(csv.split('\r\n'), hasLength(1));
    expect(csv, contains('GSTIN'));
    expect(csv, contains('Created at'));
  });
}
