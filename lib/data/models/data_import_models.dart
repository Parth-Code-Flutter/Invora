enum DataImportKind {
  customers,
  suppliers,
  products,
  unpaidInvoices,
  unpaidBills,
  openingBalances,
}

enum DuplicateImportPolicy { skip, update, importAsNew }

enum ImportRowStatus { valid, warning, rejected }

class ImportColumnSpec {
  const ImportColumnSpec({
    required this.key,
    required this.header,
    this.aliases = const [],
    this.required = false,
  });

  final String key;
  final String header;
  final List<String> aliases;
  final bool required;
}

class ImportTemplate {
  const ImportTemplate({
    required this.kind,
    required this.title,
    required this.subtitle,
    required this.fileName,
    required this.columns,
    this.sample = const [],
  });

  final DataImportKind kind;
  final String title;
  final String subtitle;
  final String fileName;
  final List<ImportColumnSpec> columns;
  final List<List<String>> sample;

  List<String> get headers =>
      columns.map((column) => column.header).toList(growable: false);
}

class ImportIssue {
  const ImportIssue({
    required this.rowNumber,
    required this.message,
    this.warning = false,
  });

  final int rowNumber;
  final String message;
  final bool warning;
}

class ImportPreviewRow {
  const ImportPreviewRow({
    required this.rowNumber,
    required this.status,
    required this.values,
    this.issues = const [],
  });

  final int rowNumber;
  final ImportRowStatus status;
  final Map<String, String> values;
  final List<String> issues;
}

class ImportPreview {
  const ImportPreview({
    required this.kind,
    required this.sourceFileName,
    required this.mapping,
    required this.fileHeaders,
    required this.rows,
    required this.issues,
    required this.validCount,
    required this.warningCount,
    required this.rejectedCount,
  });

  final DataImportKind kind;
  final String sourceFileName;
  final Map<String, String> mapping;
  final List<String> fileHeaders;
  final List<ImportPreviewRow> rows;
  final List<ImportIssue> issues;
  final int validCount;
  final int warningCount;
  final int rejectedCount;
}

class ImportBatchResult {
  const ImportBatchResult({
    required this.batchId,
    required this.importedCount,
    required this.skippedCount,
    required this.rejectedCount,
    required this.warningCount,
    required this.errors,
  });

  final int batchId;
  final int importedCount;
  final int skippedCount;
  final int rejectedCount;
  final int warningCount;
  final List<ImportIssue> errors;
}

class ImportBatchSummary {
  const ImportBatchSummary({
    required this.id,
    required this.kind,
    required this.sourceFileName,
    required this.duplicatePolicy,
    required this.importedCount,
    required this.skippedCount,
    required this.rejectedCount,
    required this.warningCount,
    required this.status,
    required this.createdAt,
  });

  final int id;
  final DataImportKind kind;
  final String sourceFileName;
  final DuplicateImportPolicy duplicatePolicy;
  final int importedCount;
  final int skippedCount;
  final int rejectedCount;
  final int warningCount;
  final String status;
  final DateTime createdAt;
}
