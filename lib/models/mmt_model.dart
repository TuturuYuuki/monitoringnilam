import '../utils/location_label_utils.dart';

class MMT {
  final int id;
  final String mmtId;
  final String location;
  final String ipAddress;
  final String status;
  final String type;
  final String containerYard;
  final String createdAt;
  final String updatedAt;

  MMT({
    required this.id,
    required this.mmtId,
    required this.location,
    required this.ipAddress,
    required this.status,
    required this.type,
    required this.containerYard,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MMT.fromJson(Map<String, dynamic> json) {
    return MMT(
      id: int.tryParse(json['id'].toString()) ?? 0,
      mmtId: json['mmt_id']?.toString() ?? '',
      location: normalizeLocationLabel(json['location']?.toString() ?? ''),
      ipAddress: json['ip_address']?.toString() ?? '',
      status: json['status']?.toString() ?? 'Unknown',
      type: json['type']?.toString() ?? 'Standard',
      containerYard: json['container_yard']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
      updatedAt: json['updated_at']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mmt_id': mmtId,
      'location': location,
      'ip_address': ipAddress,
      'status': status,
      'type': type,
      'container_yard': containerYard,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
