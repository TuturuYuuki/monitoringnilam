class Camera {
  final int id;
  final String cameraId;
  final String location;
  final String status;
  final String type;
  final String containerYard;
  final String areaType;
  final String createdAt;
  final String updatedAt;

  Camera({
    required this.id,
    required this.cameraId,
    required this.location,
    required this.status,
    required this.type,
    required this.containerYard,
    required this.areaType,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Camera.fromJson(Map<String, dynamic> json) {
    return Camera(
      id: int.tryParse(json['id'].toString()) ?? 0,
      cameraId: json['camera_id']?.toString() ?? '',
      location: json['location']?.toString() ?? '',
      status: json['status']?.toString() ?? 'Unknown',
      type: json['type']?.toString() ?? 'Fixed',
      containerYard: json['container_yard']?.toString() ?? '',
      areaType: json['area_type']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
      updatedAt: json['updated_at']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'camera_id': cameraId,
      'location': location,
      'status': status,
      'type': type,
      'container_yard': containerYard,
      'area_type': areaType,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
