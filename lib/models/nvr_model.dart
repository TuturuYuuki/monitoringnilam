class NVR {
  final int id;
  final String nvrId;
  final String location;
  final String ipAddress;
  final String status;
  final String type;
  final String containerYard;
  final double? latitude;
  final double? longitude;
  final String createdAt;
  final String updatedAt;

  NVR({
    required this.id,
    required this.nvrId,
    required this.location,
    required this.ipAddress,
    required this.status,
    required this.type,
    required this.containerYard,
    this.latitude,
    this.longitude,
    required this.createdAt,
    required this.updatedAt,
  });

  factory NVR.fromJson(Map<String, dynamic> json) {
    return NVR(
      id: int.parse(json['id'].toString()),
      nvrId: json['nvr_id'] ?? '',
      location: json['location'] ?? '',
      ipAddress: json['ip_address'] ?? '',
      status: json['status'] ?? 'UP',
      type: json['type'] ?? 'Standard',
      containerYard: json['container_yard'] ?? '',
      latitude: json['latitude'] != null ? double.tryParse(json['latitude'].toString()) : null,
      longitude: json['longitude'] != null ? double.tryParse(json['longitude'].toString()) : null,
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'] ?? '',
    );
  }
}