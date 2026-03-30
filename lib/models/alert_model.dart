import 'package:monitoring/utils/location_label_utils.dart';

class Alert {
  final int id; // Ubah dynamic menjadi int agar pasti angka
  final String alertKey;
  final String title;
  final String description;
  final String severity; 
  final String timestamp;
  final String route;
  final bool isRead;
  final String createdAt;
  final String category;
  final String source;

  final String? tanggal;
  final String? waktu;
  final String? lokasi;

  // Lifecycle fields
  final String alertStatus;     // open | acknowledged | resolved
  final String? resolvedAt;
  final String? acknowledgedAt;
  final String? deviceId;
  final String? deviceType;

  Alert({
    required this.id,
    required this.alertKey,
    required this.title,
    required this.description,
    this.severity = 'critical',
    required this.timestamp,
    required this.route,
    this.isRead = false,
    this.createdAt = '',
    this.category = 'Other',
    this.source = 'history',
    this.tanggal,
    this.waktu,
    this.lokasi,
    this.alertStatus = 'open',
    this.resolvedAt,
    this.acknowledgedAt,
    this.deviceId,
    this.deviceType,
  });

  factory Alert.fromJson(Map<String, dynamic> json) {
  final parsedId = int.tryParse((json['id'] ?? '').toString()) ?? 0;
  final source = (json['source'] ?? 'history').toString();
  final fallbackKey = source == 'current'
      ? 'current:${json['id'] ?? ''}:${json['title'] ?? ''}'
      : 'history:$parsedId';

  return Alert(
    id: parsedId,
    alertKey: (json['alert_key'] ?? fallbackKey).toString(),
    title: json['title'] ?? '',
    description: json['description'] ?? '',
    lokasi: normalizeLocationLabel((json['lokasi'] ?? '').toString()),
    tanggal: json['tanggal'],
    waktu: json['waktu'],
    severity: json['severity'] ?? 'critical',
    timestamp: json['timestamp'] ?? '',
    route: json['route'] ?? '/alerts',
    isRead: ((json['is_read'] ?? 0).toString() == '1'),
    createdAt: (json['created_at'] ?? '').toString(),
    category: (json['category'] ?? 'Other').toString(),
    source: source,
    alertStatus: (json['status'] ?? 'open').toString(),
    resolvedAt: json['resolved_at']?.toString(),
    acknowledgedAt: json['acknowledged_at']?.toString(),
    deviceId: json['device_id']?.toString(),
    deviceType: json['device_type']?.toString(),
  );
}

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'alert_key': alertKey,
      'title': title,
      'description': description,
      'severity': severity,
      'timestamp': timestamp,
      'route': route,
      'is_read': isRead ? 1 : 0,
      'created_at': createdAt,
      'category': category,
      'source': source,
      'tanggal': tanggal,
      'waktu': waktu,
      'lokasi': lokasi,
      'status': alertStatus,
      'resolved_at': resolvedAt,
      'acknowledged_at': acknowledgedAt,
      'device_id': deviceId,
      'device_type': deviceType,
    };
  }
}