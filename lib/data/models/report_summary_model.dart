class ReportSummaryModel {
  const ReportSummaryModel({
    this.totalSalesMinor = 0,
    this.totalReceivedMinor = 0,
    this.outstandingMinor = 0,
    this.invoiceCount = 0,
    this.paidCount = 0,
    this.pendingCount = 0,
    this.monthlySales = const [],
  });

  final int totalSalesMinor;
  final int totalReceivedMinor;
  final int outstandingMinor;
  final int invoiceCount;
  final int paidCount;
  final int pendingCount;
  final List<MonthlySalesPoint> monthlySales;
}

class MonthlySalesPoint {
  const MonthlySalesPoint({required this.month, required this.amountMinor});
  final DateTime month;
  final int amountMinor;
}
