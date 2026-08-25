/// Compile-time demo APK settings. Empty values mean this is not a demo build.
///
/// Pass `--dart-define=DEMO_EXPIRES_AT=YYYY-MM-DD` (and optional client name /
/// build day) only when packaging a client demo APK. Store and daily debug
/// builds omit the defines so the kill switch never arms.
class DemoBuildConfig {
  const DemoBuildConfig({this.expiresAt, this.buildTime, this.clientName = ''});

  factory DemoBuildConfig.fromEnvironment() => DemoBuildConfig(
    expiresAt: parseDay(const String.fromEnvironment('DEMO_EXPIRES_AT')),
    buildTime: parseDay(const String.fromEnvironment('DEMO_BUILD_TIME')),
    clientName: const String.fromEnvironment('DEMO_CLIENT_NAME'),
  );

  /// Last inclusive calendar day this APK may be used.
  final DateTime? expiresAt;

  /// Calendar day the APK was packaged. Device dates before this look like
  /// clock rollback.
  final DateTime? buildTime;

  final String clientName;

  bool get isDemoBuild => expiresAt != null;

  static DateTime? parseDay(String raw) {
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(raw.trim());
    if (match == null) return null;
    final year = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    final day = int.parse(match.group(3)!);
    final value = DateTime(year, month, day);
    if (value.year != year || value.month != month || value.day != day) {
      return null;
    }
    return value;
  }

  static String formatDay(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }
}
