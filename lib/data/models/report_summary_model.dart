class ReportSummaryModel {
  const ReportSummaryModel({
    this.totalSalesMinor = 0,
    this.totalReceivedMinor = 0,
    this.outstandingMinor = 0,
    this.invoiceCount = 0,
    this.paidCount = 0,
    this.pendingCount = 0,
    this.creditNoteCount = 0,
    this.creditNoteMinor = 0,
    this.previousTotalSalesMinor = 0,
    this.previousReceivedMinor = 0,
    this.monthlySales = const [],
  });

  final int totalSalesMinor;
  final int totalReceivedMinor;
  final int outstandingMinor;
  final int invoiceCount;
  final int paidCount;
  final int pendingCount;
  final int creditNoteCount;
  final int creditNoteMinor;
  final int previousTotalSalesMinor;
  final int previousReceivedMinor;
  final List<MonthlySalesPoint> monthlySales;

  double get collectionRate {
    if (totalSalesMinor <= 0) return 0;
    return (totalReceivedMinor / totalSalesMinor).clamp(0, 1);
  }

  double get salesChangePercent {
    if (previousTotalSalesMinor == 0) {
      return totalSalesMinor == 0 ? 0 : 100;
    }
    return (totalSalesMinor - previousTotalSalesMinor) /
        previousTotalSalesMinor *
        100;
  }

  bool get hasPreviousSales => previousTotalSalesMinor > 0;
}

class MonthlySalesPoint {
  const MonthlySalesPoint({
    required this.month,
    required this.amountMinor,
    this.receivedMinor = 0,
  });
  final DateTime month;
  final int amountMinor;
  final int receivedMinor;
}
