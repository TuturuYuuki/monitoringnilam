import 'package:monitoring/utils/location_label_utils.dart';

class Camera {
  final int id;
  final String cameraId;
  final String location;
  final String ipAddress;
  final String status;
  final String type;
  final String containerYard;
  final String areaType;
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

  Camera({
    required this.id,
    required this.cameraId,
    required this.location,
    required this.ipAddress,
    required this.status,
    required this.type,
    required this.containerYard,
    required this.areaType,
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

  factory Camera.fromJson(Map<String, dynamic> json) {
    return Camera(
      id: int.tryParse(json['id'].toString()) ?? 0,
      cameraId: json['camera_id']?.toString() ?? '',
      location: normalizeLocationLabel(json['location']?.toString() ?? ''),
      ipAddress: json['ip_address']?.toString() ?? '',
      status: json['status']?.toString() ?? 'Unknown',
      type: json['type']?.toString() ?? 'Fixed',
      containerYard: json['container_yard']?.toString() ?? '',
      areaType: json['area_type']?.toString() ?? '',
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
      'camera_id': cameraId,
      'location': location,
      'ip_address': ipAddress,
      'status': status,
      'type': type,
      'container_yard': containerYard,
      'area_type': areaType,
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
