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

  // Create from JSON
  factory AddedDevice.fromJson(Map<String, dynamic> json) {
    return AddedDevice(
      id: json['id'] as String,
      type: json['type'] as String,
      name: json['name'] as String,
      ipAddress: json['ipAddress'] as String,
      locationName: json['locationName'] as String,
      latitude: json['latitude'] as double,
      longitude: json['longitude'] as double,
      containerYard: json['containerYard'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      status: json['status'] as String? ?? 'DOWN',
    );
  }
}
