import 'dart:async';
import 'dart:io';

abstract class NetworkStatus {
  Future<bool> get isOnline;
}

class DnsNetworkStatus implements NetworkStatus {
  const DnsNetworkStatus();

  @override
  Future<bool> get isOnline async {
    try {
      final result = await InternetAddress.lookup(
        'firestore.googleapis.com',
      ).timeout(const Duration(seconds: 2));
      return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } on SocketException {
      return false;
    } on TimeoutException {
      return false;
    } catch (_) {
      return false;
    }
  }
}

class FixedNetworkStatus implements NetworkStatus {
  const FixedNetworkStatus(this.online);

  final bool online;

  @override
  Future<bool> get isOnline async => online;
}
