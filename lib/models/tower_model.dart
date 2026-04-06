import 'package:monitoring/utils/location_label_utils.dart';

class Tower {
  final int id;
  final String towerId;
  final int towerNumber;
  final String location;
  final String ipAddress;
  final String status;
  final String containerYard;
  final String createdAt;
  final String updatedAt;
  final double? latitude;
  final double? longitude;

  final int cpuLoad;
  final int ramUsage;
  final int latencyMs;
  final double packetLoss;
  final int bwRx;
  final int bwTx;
  final int uptimeSeconds;
  final String? macAddress;
  final String firmwareVersion;

  Tower({
    required this.id,
    required this.towerId,
    required this.towerNumber,
    required this.location,
    required this.ipAddress,
    required this.status,
    required this.containerYard,
    required this.createdAt,
    required this.updatedAt,
    this.latitude,
    this.longitude,
    this.cpuLoad = 0,
    this.ramUsage = 0,
    this.latencyMs = 0,
    this.packetLoss = 0.0,
    this.bwRx = 0,
    this.bwTx = 0,
    this.uptimeSeconds = 0,
    this.macAddress,
    this.firmwareVersion = '1.0.0',
  });

  factory Tower.fromJson(Map<String, dynamic> json) {
    return Tower(
      id: int.tryParse(json['id'].toString()) ?? 0,
      towerId: json['tower_id']?.toString() ?? '',
      towerNumber: int.tryParse(json['tower_number'].toString()) ?? 0,
      location: normalizeLocationLabel(json['location']?.toString() ?? ''),
      ipAddress: json['ip_address']?.toString() ?? '',
      status: json['status']?.toString() ?? 'Unknown',
      containerYard: json['container_yard']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
      updatedAt: json['updated_at']?.toString() ?? '',
      latitude: json['latitude'] != null ? double.tryParse(json['latitude'].toString()) : null,
      longitude: json['longitude'] != null ? double.tryParse(json['longitude'].toString()) : null,
      cpuLoad: int.tryParse(json['cpu_load'].toString()) ?? 0,
      ramUsage: int.tryParse(json['ram_usage'].toString()) ?? 0,
      latencyMs: int.tryParse(json['latency_ms'].toString()) ?? 0,
      packetLoss: double.tryParse(json['packet_loss'].toString()) ?? 0.0,
      bwRx: int.tryParse(json['bw_rx'].toString()) ?? 0,
      bwTx: int.tryParse(json['bw_tx'].toString()) ?? 0,
      uptimeSeconds: int.tryParse(json['uptime_seconds'].toString()) ?? 0,
      macAddress: json['mac_address']?.toString(),
      firmwareVersion: json['firmware_version']?.toString() ?? '1.0.0',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tower_id': towerId,
      'tower_number': towerNumber,
      'location': location,
      'ip_address': ipAddress,
      'status': status,
      'container_yard': containerYard,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'latitude': latitude,
      'longitude': longitude,
      'cpu_load': cpuLoad,
      'ram_usage': ramUsage,
      'latency_ms': latencyMs,
      'packet_loss': packetLoss,
      'bw_rx': bwRx,
      'bw_tx': bwTx,
      'uptime_seconds': uptimeSeconds,
      'mac_address': macAddress,
      'firmware_version': firmwareVersion,
    };
  }
}
