class User {
  final int id;
  final String username;
  final String email;
  final String fullname;
  final String role;
  final String division;
  final String phone;
  final String location;
  final String createdAt;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.fullname,
    required this.role,
    required this.division,
    required this.phone,
    required this.location,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      fullname: json['fullname'] ?? '',
      role: json['role'] ?? (json['division'] ?? json['divisi'] ?? 'user'),
      division: json['division'] ?? json['divisi'] ?? '',
      phone: json['phone'] ??
          json['phone_number'] ??
          json['no_telp'] ??
          json['telp'] ??
          '',
      location: json['location'] ?? json['lokasi'] ?? json['address'] ?? '',
      createdAt: json['created_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'fullname': fullname,
      'role': role,
      'division': division,
      'phone': phone,
      'location': location,
      'created_at': createdAt,
    };
  }
}
