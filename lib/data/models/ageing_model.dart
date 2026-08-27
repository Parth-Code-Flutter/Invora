enum AgeingSide { receivables, payables }

enum AgeingBucket { notDue, d1to30, d31to60, d61to90, d90plus }

enum AgeingReminderStatus { none, prepared, shared, skipped }

class AgeingMath {
  static DateTime dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  static int daysPastDue(DateTime due, DateTime asOf) =>
      dateOnly(asOf).difference(dateOnly(due)).inDays;

  static AgeingBucket bucketFor(int daysPastDue) {
    if (daysPastDue <= 0) return AgeingBucket.notDue;
    if (daysPastDue <= 30) return AgeingBucket.d1to30;
    if (daysPastDue <= 60) return AgeingBucket.d31to60;
    if (daysPastDue <= 90) return AgeingBucket.d61to90;
    return AgeingBucket.d90plus;
  }

  static String dateLabel(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
}

extension AgeingBucketX on AgeingBucket {
  String get label => switch (this) {
    AgeingBucket.notDue => 'Not due',
    AgeingBucket.d1to30 => '1–30',
    AgeingBucket.d31to60 => '31–60',
    AgeingBucket.d61to90 => '61–90',
    AgeingBucket.d90plus => '90+',
  };

  String get fullLabel => switch (this) {
    AgeingBucket.notDue => 'Not due',
    AgeingBucket.d1to30 => '1–30 days',
    AgeingBucket.d31to60 => '31–60 days',
    AgeingBucket.d61to90 => '61–90 days',
    AgeingBucket.d90plus => '90+ days',
  };
}

extension AgeingReminderStatusX on AgeingReminderStatus {
  String get label => switch (this) {
    AgeingReminderStatus.none => '',
    AgeingReminderStatus.prepared => 'Prepared',
    AgeingReminderStatus.shared => 'Shared',
    AgeingReminderStatus.skipped => 'Skipped',
  };
}

class AgeingRow {
  const AgeingRow({
    required this.side,
    required this.documentId,
    required this.documentNumber,
    required this.partyName,
    required this.dueDate,
    required this.daysPastDue,
    required this.bucket,
    required this.balanceMinor,
    this.partyId,
    this.partyMobile,
    this.reminderStatus = AgeingReminderStatus.none,
  });

  final AgeingSide side;
  final int documentId;
  final int? partyId;
  final String documentNumber;
  final String partyName;
  final String? partyMobile;
  final DateTime dueDate;
  final int daysPastDue;
  final AgeingBucket bucket;
  final int balanceMinor;
  final AgeingReminderStatus reminderStatus;

  String get storageKey => '${side.name}:$documentId';

  AgeingRow withStatus(AgeingReminderStatus status) => AgeingRow(
    side: side,
    documentId: documentId,
    documentNumber: documentNumber,
    partyName: partyName,
    dueDate: dueDate,
    daysPastDue: daysPastDue,
    bucket: bucket,
    balanceMinor: balanceMinor,
    partyId: partyId,
    partyMobile: partyMobile,
    reminderStatus: status,
  );
}

class AgeingBucketSummary {
  const AgeingBucketSummary({
    required this.bucket,
    required this.count,
    required this.amountMinor,
  });

  final AgeingBucket bucket;
  final int count;
  final int amountMinor;
}

class AgeingPack {
  const AgeingPack({
    required this.asOf,
    required this.businessName,
    required this.currencySymbol,
    this.upiId,
    required this.receivables,
    required this.payables,
  });

  static const deliveryClaim = 'Delivered';

  final DateTime asOf;
  final String businessName;
  final String currencySymbol;
  final String? upiId;
  final List<AgeingRow> receivables;
  final List<AgeingRow> payables;

  List<AgeingRow> rowsFor(AgeingSide side) =>
      side == AgeingSide.receivables ? receivables : payables;

  int totalMinor(AgeingSide side) =>
      rowsFor(side).fold(0, (sum, row) => sum + row.balanceMinor);

  List<AgeingBucketSummary> buckets(AgeingSide side) => [
    for (final bucket in AgeingBucket.values)
      AgeingBucketSummary(
        bucket: bucket,
        count: rowsFor(side).where((row) => row.bucket == bucket).length,
        amountMinor: rowsFor(side)
            .where((row) => row.bucket == bucket)
            .fold(0, (sum, row) => sum + row.balanceMinor),
      ),
  ];

  List<AgeingRow> inBucket(AgeingSide side, AgeingBucket bucket) {
    final rows = rowsFor(side).where((row) => row.bucket == bucket).toList()
      ..sort((left, right) {
        final byDays = right.daysPastDue.compareTo(left.daysPastDue);
        if (byDays != 0) return byDays;
        return left.documentNumber.compareTo(right.documentNumber);
      });
    return rows;
  }

  AgeingPack replacing(AgeingRow next) {
    List<AgeingRow> apply(List<AgeingRow> rows) => [
      for (final row in rows)
        if (row.storageKey == next.storageKey) next else row,
    ];
    return AgeingPack(
      asOf: asOf,
      businessName: businessName,
      currencySymbol: currencySymbol,
      upiId: upiId,
      receivables: apply(receivables),
      payables: apply(payables),
    );
  }
}
