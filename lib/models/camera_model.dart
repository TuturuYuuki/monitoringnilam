import '../utils/location_label_utils.dart';

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
    };
  }
}
