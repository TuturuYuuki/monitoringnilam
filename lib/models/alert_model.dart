class Alert {
  final dynamic id;
  final String title;
  final String description;
  final String severity;
  final String timestamp;
  final String route;
  final bool isRead;
  final String createdAt;
  final String category;

  Alert({
    required this.id,
    required this.title,
    required this.description,
    required this.severity,
    required this.timestamp,
    required this.route,
    this.isRead = false,
    this.createdAt = '',
    this.category = 'Other',
  });

  factory Alert.fromJson(Map<String, dynamic> json) {
    return Alert(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      severity: json['severity'] ?? 'info',
      timestamp: json['timestamp'] ?? '',
      route: json['route'] ?? '',
      isRead: json['is_read'] == 1 || json['is_read'] == true,
      createdAt: json['created_at'] ?? '',
      category: json['category'] ?? 'Other',
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
    };
  }
}
