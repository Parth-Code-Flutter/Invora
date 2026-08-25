import '../../app/constants/app_storage_key_const.dart';
import 'app_storage.dart';
import 'demo_build_config.dart';

/// Calendar kill switch for client demo APKs.
///
/// Default / Play builds construct this with [DemoBuildConfig.fromEnvironment]
/// and no dart-defines, so [isExpired] stays false. Last-seen day is stored
/// on-device only and must never be added to backup `settings.json`.
class DemoAccessService {
  DemoAccessService({
    required this.config,
    required this._storage,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final DemoBuildConfig config;
  final AppStorage _storage;
  final DateTime Function() _clock;

  var _expired = false;

  bool get isDemoBuild => config.isDemoBuild;

  bool get isExpired => _expired;

  String get lockTitle => 'Please contact your sales person';

  String get lockMessage {
    final client = config.clientName.trim();
    final expiry = config.expiresAt;
    if (client.isNotEmpty && expiry != null) {
      return 'This demo for $client ended on ${DemoBuildConfig.formatDay(expiry)}.';
    }
    if (expiry != null) {
      return 'This demo ended on ${DemoBuildConfig.formatDay(expiry)}.';
    }
    return 'This demo build is no longer available.';
  }

  /// Recomputes expiry from the baked-in date, build day, and last-seen day.
  bool evaluate() {
    _expired = _computeExpired();
    if (isDemoBuild && !_expired) {
      _storage.setString(
        AppStorageKeyConst.demoLastSeenDay,
        DemoBuildConfig.formatDay(_day(_clock())),
      );
    }
    return _expired;
  }

  bool _computeExpired() {
    final expiresAt = config.expiresAt;
    if (expiresAt == null) return false;

    final now = _day(_clock());
    if (now.isAfter(_day(expiresAt))) return true;

    final buildTime = config.buildTime;
    if (buildTime != null && now.isBefore(_day(buildTime))) return true;

    final lastSeenRaw = _storage.getString(AppStorageKeyConst.demoLastSeenDay);
    final lastSeen = lastSeenRaw == null
        ? null
        : DemoBuildConfig.parseDay(lastSeenRaw);
    if (lastSeen != null && now.isBefore(_day(lastSeen))) return true;

    return false;
  }

  DateTime _day(DateTime value) => DateTime(value.year, value.month, value.day);
}
