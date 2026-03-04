import 'dart:async';
import 'dart:io';

class PingService {
  static final PingService _instance = PingService._internal();

  factory PingService() {
    return _instance;
  }

  PingService._internal();

  /// Ping IP address dan cek apakah UP atau DOWN
  /// Returns: true jika UP, false jika DOWN
  Future<bool> pingIP(String ipAddress) async {
    try {
      // Use ICMPv4 echo request via ProcessResult
      final result = await Process.run(
        'ping',
        [
          '-n', // jumlah ping packets
          '1', // 1 packet saja untuk cepat
          '-w',
          '2000', // timeout 2 detik
          ipAddress
        ],
      ).timeout(const Duration(seconds: 3));

      // On Windows, ping return code 0 = SUCCESS, non-zero = FAILED
      return result.exitCode == 0;
    } catch (e) {
      // Ping error - device is down
      return false;
    }
  }

  /// Ping multiple IPs dan return map dengan status
  Future<Map<String, bool>> pingMultiple(List<String> ipAddresses) async {
    final results = <String, bool>{};
    final futures = <Future<void>>[];

    for (final ip in ipAddresses) {
      futures.add(
        pingIP(ip).then((isUp) {
          results[ip] = isUp;
        }),
      );
    }

    await Future.wait(futures);
    return results;
  }

  /// Real-time monitoring dengan interval
  /// Returns Stream<Map<String, bool>> dengan status terbaru
  Stream<Map<String, bool>> monitorIPs(
    List<String> ipAddresses, {
    Duration interval = const Duration(seconds: 5),
  }) async* {
    while (true) {
      final results = await pingMultiple(ipAddresses);
      yield results;
      await Future.delayed(interval);
    }
  }
}
