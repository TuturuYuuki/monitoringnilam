class DeviceDiagnosticsViewModel {
  final String deviceId;
  final String deviceName;
  final String deviceType;
  final String status;
  final String ipAddress;
  final String location;
  final String yard;
  final DateTime lastUpdated;

  DeviceDiagnosticsViewModel({
    required this.deviceId,
    required this.deviceName,
    required this.deviceType,
    required this.status,
    required this.ipAddress,
    required this.location,
    required this.yard,
    required this.lastUpdated,
  });

  factory DeviceDiagnosticsViewModel.fromRouteArgs(Map<String, dynamic>? args) {
    final routeArgs = args ?? <String, dynamic>{};

    final dateArg = routeArgs['lastUpdated'];
    DateTime parsedDate;

    if (dateArg is DateTime) {
      parsedDate = dateArg;
    } else if (dateArg is String) {
      parsedDate = DateTime.tryParse(dateArg) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    final deviceName = routeArgs['deviceName']?.toString() ?? 'Unknown Device';
    final deviceId = routeArgs['deviceId']?.toString() ?? deviceName;

    return DeviceDiagnosticsViewModel(
      deviceId: deviceId,
      deviceName: deviceName,
      deviceType: (routeArgs['deviceType']?.toString() ?? 'AP').toUpperCase(),
      status: (routeArgs['status']?.toString() ?? 'UP').toUpperCase(),
      ipAddress: routeArgs['ip']?.toString() ?? '0.0.0.0',
      location: routeArgs['location']?.toString() ?? '-',
      yard: routeArgs['containerYard']?.toString() ?? '-',
      lastUpdated: parsedDate,
    );
  }

  bool get isUp => status == 'UP';

  bool get isAccessPoint =>
      deviceType.contains('AP') ||
      deviceType == 'TOWER' ||
      deviceType == 'ACCESS_POINT';
  bool get isMmt => deviceType == 'MMT' || deviceType == 'MMTS';

  String get diagnosticsLabel {
    if (isAccessPoint) {
      return 'Access Point Diagnostics';
    }
    if (isMmt) {
      return 'MMT Diagnostics';
    }
    return 'CCTV Diagnostics';
  }

  String get deviceCategoryLabel {
    if (isAccessPoint) {
      return 'Access Point';
    }
    if (isMmt) {
      return 'MMT';
    }
    return 'CCTV';
  }

  String get lastUpdatedLabel =>
      '${lastUpdated.hour.toString().padLeft(2, '0')}:${lastUpdated.minute.toString().padLeft(2, '0')}:${lastUpdated.second.toString().padLeft(2, '0')}';
}
