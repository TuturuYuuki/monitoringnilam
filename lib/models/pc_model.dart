class PCModel {
  final int? id;
  final String pcId;
  final String location;
  final String ipAddress;
  final String status;
  final String type;
  final String containerYard;
  final double latitude;
  final double longitude;
  final int latencyMs;
  final String? updatedAt;

  PCModel({
    this.id,
    required this.pcId,
    required this.location,
    required this.ipAddress,
    this.status = 'DOWN',
    required this.type,
    required this.containerYard,
    required this.latitude,
    required this.longitude,
    this.latencyMs = 0,
    this.updatedAt,
  });

  factory PCModel.fromJson(Map<String, dynamic> json) {
    return PCModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? ''),
      pcId: json['pc_id'] ?? '',
      location: json['location'] ?? '',
      ipAddress: json['ip_address'] ?? '',
      status: json['status'] ?? 'DOWN',
      type: json['type'] ?? 'PC',
      containerYard: json['container_yard'] ?? '',
      latitude: double.tryParse(json['latitude']?.toString() ?? '0.0') ?? 0.0,
      longitude: double.tryParse(json['longitude']?.toString() ?? '0.0') ?? 0.0,
      latencyMs: json['latency_ms'] is int ? json['latency_ms'] : int.tryParse(json['latency_ms']?.toString() ?? '0') ?? 0,
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pc_id': pcId,
      'location': location,
      'ip_address': ipAddress,
      'status': status,
      'type': type,
      'container_yard': containerYard,
      'latitude': latitude,
      'longitude': longitude,
      'latency_ms': latencyMs,
      'updated_at': updatedAt,
    };
  }
}
