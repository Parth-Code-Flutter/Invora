enum EntitlementAccess { active, needsNetwork, expired }

class EntitlementSnapshot {
  const EntitlementSnapshot({
    required this.mobile,
    required this.status,
    required this.planId,
    this.trialEndsAt,
    this.planTitle = 'Creovo Billing',
    this.priceInr = 0,
    this.period = 'yearly',
  });

  final String mobile;
  final String status;
  final String planId;
  final DateTime? trialEndsAt;
  final String planTitle;
  final int priceInr;
  final String period;

  String get displayTitle {
    final title = planTitle.trim();
    if (title.isEmpty || title.toLowerCase() == 'default') {
      return 'Creovo Yearly';
    }
    return title;
  }

  String get billedPeriodLabel {
    switch (period.toLowerCase()) {
      case 'month':
      case 'monthly':
        return 'month';
      default:
        return 'year';
    }
  }

  String get priceLine {
    if (priceInr <= 0) return 'One plan · billed each $billedPeriodLabel';
    return '₹$priceInr / $billedPeriodLabel';
  }

  /// Stitch offer when Firestore `priceInr` is still 0.
  int get offerPriceInr => priceInr > 0 ? priceInr : 499;

  int get offerListPriceInr =>
      priceInr <= 0 || priceInr == 499 ? 999 : priceInr * 2;

  int get offerMonthlyInr => offerPriceInr ~/ 12;

  int remainingDays([DateTime? now]) {
    final ends = trialEndsAt;
    if (ends == null) return 0;
    final ms = ends
        .toUtc()
        .difference((now ?? DateTime.now()).toUtc())
        .inMilliseconds;
    if (ms <= 0) return 0;
    return (ms / Duration.millisecondsPerDay).ceil();
  }

  int get licenseTotalDays => isPaid ? 365 : 90;

  String get yearlyPriceLabel => '₹$offerPriceInr/yr';

  double licenseProgress([DateTime? now]) {
    final remaining = remainingDays(now);
    if (remaining <= 0) return isPaid ? 1 : 0;
    return (remaining / licenseTotalDays).clamp(0.0, 1.0);
  }

  String get statusLabel {
    if (isPaid) return 'Subscribed';
    if (isCancelled) return 'Ended';
    return 'Trial';
  }

  String moreSubtitle([DateTime? now]) {
    if (isPaid) return 'Subscribed · $priceLine';
    if (isCancelled) return 'Plan ended';
    final days = remainingDays(now);
    if (days <= 0) return 'Trial ended';
    if (days == 1) return 'Trial · 1 day left';
    return 'Trial · $days days left';
  }

  bool get isPaid {
    switch (status.toLowerCase()) {
      case 'paid':
      case 'active':
      case 'subscribed':
      case 'pro':
        return true;
      default:
        return false;
    }
  }

  bool get isCancelled {
    switch (status.toLowerCase()) {
      case 'expired':
      case 'cancelled':
      case 'lapsed':
        return true;
      default:
        return false;
    }
  }
}

abstract final class EntitlementPolicy {
  static bool isSameLocalDay(DateTime left, DateTime right) {
    final a = left.toLocal();
    final b = right.toLocal();
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// [now] and [trialEndsAt] should be UTC instants. Calendar-day checks use
  /// the device local timezone so the last-day internet prompt matches the
  /// date the shopkeeper sees.
  static EntitlementAccess decide({
    required bool online,
    required DateTime now,
    required EntitlementSnapshot? snapshot,
    DateTime? lastSeenAt,
  }) {
    if (snapshot == null) return EntitlementAccess.needsNetwork;
    if (snapshot.isCancelled) return EntitlementAccess.expired;
    if (snapshot.isPaid) return EntitlementAccess.active;

    if (lastSeenAt != null &&
        now.isBefore(lastSeenAt.subtract(const Duration(hours: 1)))) {
      return online ? EntitlementAccess.active : EntitlementAccess.needsNetwork;
    }

    final ends = snapshot.trialEndsAt;
    if (ends == null) return EntitlementAccess.expired;
    if (!now.toUtc().isBefore(ends.toUtc())) {
      return EntitlementAccess.expired;
    }
    if (!online && isSameLocalDay(now, ends)) {
      return EntitlementAccess.needsNetwork;
    }
    return EntitlementAccess.active;
  }
}
