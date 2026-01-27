class Tower {
  final int id;
  final String towerId;
  final int towerNumber;
  final String location;
  final String ipAddress;
  final int deviceCount;
  final String status;
  final String traffic;
  final String uptime;
  final String containerYard;
  final String createdAt;

  Tower({
    required this.id,
    required this.towerId,
    required this.towerNumber,
    required this.location,
    required this.ipAddress,
    required this.deviceCount,
    required this.status,
    required this.traffic,
    required this.uptime,
    required this.containerYard,
    required this.createdAt,
  });

  factory Tower.fromJson(Map<String, dynamic> json) {
    return Tower(
      id: int.tryParse(json['id'].toString()) ?? 0,
      towerId: json['tower_id']?.toString() ?? '',
      towerNumber: int.tryParse(json['tower_number'].toString()) ?? 0,
      location: json['location']?.toString() ?? '',
      ipAddress: json['ip_address']?.toString() ?? '',
      deviceCount: int.tryParse(json['device_count'].toString()) ?? 0,
      status: json['status']?.toString() ?? 'Unknown',
      traffic: json['traffic']?.toString() ?? '0 Mbps',
      uptime: json['uptime']?.toString() ?? '0%',
      containerYard: json['container_yard']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tower_id': towerId,
      'tower_number': towerNumber,
      'location': location,
      'ip_address': ipAddress,
      'device_count': deviceCount,
      'status': status,
      'traffic': traffic,
      'uptime': uptime,
      'container_yard': containerYard,
      'created_at': createdAt,
    };
  }
}
