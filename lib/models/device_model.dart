import 'package:latlong2/latlong.dart';

class AddedDevice {
  final String id;
  final String type; // Tower, CCTV, MMT
  final String name;
  final String ipAddress;
  final String locationName;
  final double latitude;
  final double longitude;
  final String containerYard;
  final DateTime createdAt;
  String status; // UP or DOWN - mutable for updates

  AddedDevice({
    required this.id,
    required this.type,
    required this.name,
    required this.ipAddress,
    required this.locationName,
    required this.latitude,
    required this.longitude,
    required this.containerYard,
    required this.createdAt,
    this.status = 'DOWN', // default DOWN
  });

  LatLng get coordinate => LatLng(latitude, longitude);

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'name': name,
      'ipAddress': ipAddress,
      'locationName': locationName,
      'latitude': latitude,
      'longitude': longitude,
      'containerYard': containerYard,
      'createdAt': createdAt.toIso8601String(),
      'status': status,
    };
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  // Create from JSON
  factory AddedDevice.fromJson(Map<String, dynamic> json) {
    final createdAtRaw = (json['createdAt'] ?? '').toString();
    final parsedCreatedAt = DateTime.tryParse(createdAtRaw) ?? DateTime.now();

    return AddedDevice(
      id: (json['id'] ?? '').toString(),
      type: (json['type'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      ipAddress: (json['ipAddress'] ?? '').toString(),
      locationName: (json['locationName'] ?? '').toString(),
      latitude: _toDouble(json['latitude']),
      longitude: _toDouble(json['longitude']),
      containerYard: (json['containerYard'] ?? '').toString(),
      createdAt: parsedCreatedAt,
      status: (json['status'] ?? 'DOWN').toString(),
    );
  }
}
