class Alert {
  final int id; // Ubah dynamic menjadi int agar pasti angka
  final String title;
  final String description;
  final String severity; 
  final String timestamp;
  final String route;
  final bool isRead;
  final String createdAt;
  final String category;

  final String? tanggal;
  final String? waktu;
  final String? lokasi;

  Alert({
    required this.id,
    required this.title,
    required this.description,
    this.severity = 'critical',
    required this.timestamp,
    required this.route,
    this.isRead = false,
    this.createdAt = '',
    this.category = 'Other',
    this.tanggal,
    this.waktu,
    this.lokasi,
  });

  factory Alert.fromJson(Map<String, dynamic> json) {
  return Alert(
    id: int.tryParse(json['id'].toString()) ?? 0,
    title: json['title'] ?? '',
    description: json['description'] ?? '',
    lokasi: json['lokasi'], // Pastikan nama kolom di DB 'lokasi'
    tanggal: json['tanggal'], // Pastikan nama kolom di DB 'tanggal'
    waktu: json['waktu'], // Pastikan nama kolom di DB 'waktu'
    severity: json['severity'] ?? 'critical',
    timestamp: json['timestamp'] ?? '',
    route: json['route'] ?? '/alerts',
  );
}

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'severity': severity,
      'timestamp': timestamp,
      'route': route,
      'is_read': isRead ? 1 : 0,
      'created_at': createdAt,
      'category': category,
      'tanggal': tanggal,
      'waktu': waktu,
      'lokasi': lokasi,
    };
  }
}