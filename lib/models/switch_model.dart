class SwitchModel {
  final int id;
  final String switchId;
  final String location;
  final String ipAddress;
  final String status;
  final String type;
  final String containerYard;
  final double? latitude;
  final double? longitude;
  final String createdAt;
  final String updatedAt;

  SwitchModel({
    required this.id,
    required this.switchId,
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

  factory SwitchModel.fromJson(Map<String, dynamic> json) {
    return SwitchModel(
      id: int.parse(json['id'].toString()),
      switchId: json['switch_id'] ?? '',
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
