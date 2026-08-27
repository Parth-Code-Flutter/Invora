enum GstExportKind { sales, creditNotes, purchases, hsn, exceptions }

enum GstExportPeriodPreset { thisMonth, lastMonth, thisFy, lastFy, custom }

enum GstSupplyType { b2b, b2c }

enum GstExportSource { invoice, creditNote, purchase }

enum GstExportPreviewTab { sales, creditNotes, purchases, hsn, exceptions }

class GstExportPeriod {
  const GstExportPeriod({
    required this.from,
    required this.to,
    required this.preset,
  });

  final DateTime from;
  final DateTime to;
  final GstExportPeriodPreset preset;

  static DateTime dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  static DateTime financialYearStart(DateTime now) =>
      now.month >= 4 ? DateTime(now.year, 4, 1) : DateTime(now.year - 1, 4, 1);

  static DateTime financialYearEnd(DateTime start) =>
      DateTime(start.year + 1, 3, 31);

  factory GstExportPeriod.fromPreset(
    GstExportPeriodPreset preset, {
    DateTime? now,
    DateTime? customFrom,
    DateTime? customTo,
  }) {
    final today = dateOnly(now ?? DateTime.now());
    switch (preset) {
      case GstExportPeriodPreset.thisMonth:
        return GstExportPeriod(
          from: DateTime(today.year, today.month, 1),
          to: today,
          preset: preset,
        );
      case GstExportPeriodPreset.lastMonth:
        final firstThisMonth = DateTime(today.year, today.month, 1);
        final lastMonthEnd = firstThisMonth.subtract(const Duration(days: 1));
        return GstExportPeriod(
          from: DateTime(lastMonthEnd.year, lastMonthEnd.month, 1),
          to: lastMonthEnd,
          preset: preset,
        );
      case GstExportPeriodPreset.thisFy:
        final start = financialYearStart(today);
        return GstExportPeriod(from: start, to: today, preset: preset);
      case GstExportPeriodPreset.lastFy:
        final thisStart = financialYearStart(today);
        final lastStart = DateTime(thisStart.year - 1, 4, 1);
        return GstExportPeriod(
          from: lastStart,
          to: financialYearEnd(lastStart),
          preset: preset,
        );
      case GstExportPeriodPreset.custom:
        return GstExportPeriod(
          from: dateOnly(customFrom ?? DateTime(today.year, today.month, 1)),
          to: dateOnly(customTo ?? today),
          preset: preset,
        );
    }
  }

  String get fyLabel {
    final start = from.month >= 4 ? from.year : from.year - 1;
    return 'FY $start-${(start + 1) % 100}';
  }

  String get rangeLabel => '${_display(from)} – ${_display(to)}';

  static String _display(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
}

class GstExportSummary {
  const GstExportSummary({
    required this.invoiceCount,
    required this.creditNoteCount,
    required this.purchaseCount,
    required this.exceptionCount,
    required this.b2bCount,
    required this.b2cCount,
    required this.taxableSalesMinor,
    required this.outputTaxMinor,
    required this.creditNoteTotalMinor,
    required this.purchaseTotalMinor,
    required this.itcMinor,
  });

  final int invoiceCount;
  final int creditNoteCount;
  final int purchaseCount;
  final int exceptionCount;
  final int b2bCount;
  final int b2cCount;
  final int taxableSalesMinor;
  final int outputTaxMinor;
  final int creditNoteTotalMinor;
  final int purchaseTotalMinor;
  final int itcMinor;
}

class GstSalesRegisterRow {
  const GstSalesRegisterRow({
    this.invoiceId,
    required this.invoiceDate,
    required this.invoiceNumber,
    required this.customerName,
    this.gstin,
    required this.supplyType,
    required this.taxMode,
    required this.taxableMinor,
    required this.cgstMinor,
    required this.sgstMinor,
    required this.igstMinor,
    required this.taxMinor,
    required this.grandTotalMinor,
  });

  final int? invoiceId;
  final DateTime invoiceDate;
  final String invoiceNumber;
  final String customerName;
  final String? gstin;
  final GstSupplyType supplyType;
  final String taxMode;
  final int taxableMinor;
  final int cgstMinor;
  final int sgstMinor;
  final int igstMinor;
  final int taxMinor;
  final int grandTotalMinor;
}

class GstCreditNoteRegisterRow {
  const GstCreditNoteRegisterRow({
    this.creditNoteId,
    required this.creditNoteDate,
    required this.creditNoteNumber,
    required this.invoiceNumber,
    required this.customerName,
    this.gstin,
    required this.taxMode,
    required this.taxableMinor,
    required this.taxMinor,
    required this.grandTotalMinor,
    required this.reason,
  });

  final int? creditNoteId;
  final DateTime creditNoteDate;
  final String creditNoteNumber;
  final String invoiceNumber;
  final String customerName;
  final String? gstin;
  final String taxMode;
  final int taxableMinor;
  final int taxMinor;
  final int grandTotalMinor;
  final String reason;
}

class GstPurchaseRegisterRow {
  const GstPurchaseRegisterRow({
    this.billId,
    required this.billDate,
    required this.billNumber,
    required this.supplierName,
    this.gstin,
    required this.taxMode,
    required this.reverseCharge,
    required this.itcEligible,
    required this.taxableMinor,
    required this.taxMinor,
    required this.totalMinor,
  });

  final int? billId;
  final DateTime billDate;
  final String billNumber;
  final String supplierName;
  final String? gstin;
  final String taxMode;
  final bool reverseCharge;
  final bool itcEligible;
  final int taxableMinor;
  final int taxMinor;
  final int totalMinor;
}

class GstHsnSummaryRow {
  const GstHsnSummaryRow({
    required this.hsnSac,
    required this.documentCount,
    required this.taxableMinor,
    required this.taxMinor,
    required this.totalMinor,
  });

  final String hsnSac;
  final int documentCount;
  final int taxableMinor;
  final int taxMinor;
  final int totalMinor;
}

class GstExportException {
  const GstExportException({
    required this.documentNumber,
    required this.documentDate,
    required this.kind,
    required this.message,
    required this.source,
    this.documentId,
  });

  final String documentNumber;
  final DateTime documentDate;
  final String kind;
  final String message;
  final GstExportSource source;
  final int? documentId;
}

class GstExportPack {
  const GstExportPack({
    required this.period,
    required this.businessName,
    this.gstin,
    required this.generatedAt,
    required this.summary,
    required this.sales,
    required this.creditNotes,
    required this.purchases,
    required this.hsn,
    required this.exceptions,
  });

  static const filingStatus = 'Prepared';
  static const portalStatus = 'Not submitted';

  final GstExportPeriod period;
  final String businessName;
  final String? gstin;
  final DateTime generatedAt;
  final GstExportSummary summary;
  final List<GstSalesRegisterRow> sales;
  final List<GstCreditNoteRegisterRow> creditNotes;
  final List<GstPurchaseRegisterRow> purchases;
  final List<GstHsnSummaryRow> hsn;
  final List<GstExportException> exceptions;
}
