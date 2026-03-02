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
  });

  factory Tower.fromJson(Map<String, dynamic> json) {
    return Tower(
      id: int.tryParse(json['id'].toString()) ?? 0,
      towerId: json['tower_id']?.toString() ?? '',
      towerNumber: int.tryParse(json['tower_number'].toString()) ?? 0,
      location: json['location']?.toString() ?? '',
      ipAddress: json['ip_address']?.toString() ?? '',
      status: json['status']?.toString() ?? 'Unknown',
      containerYard: json['container_yard']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
      updatedAt: json['updated_at']?.toString() ?? '',
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
    };
  }
}
