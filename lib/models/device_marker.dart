/// ============================================================================
/// Device Marker Model
/// 
/// Represents a single device/location marker on the Nilam Layout Map
/// Contains both geographic (lat/lng) and visual (pixel) coordinates
/// ============================================================================
library;

import 'package:flutter/material.dart';
import 'package:monitoring/utils/device_icon_resolver.dart';

enum DeviceType {
  tower,
  cctv,
  rtg,
  rs,
  gate,
  parking,
}

class DeviceMarker {
  /// Unique identifier for the device
  final String id;

  /// Display name (e.g., "Tower 1", "CAM 01", "MMT 15")
  final String name;

  /// Device type for icon and styling
  final DeviceType type;

  /// Current status
  final String status;  // 'UP' or 'DOWN'

  /// IP Address (for network devices)
  final String? ipAddress;

  /// Geographic coordinates (from database)
  final double latitude;
  final double longitude;

  /// Pixel coordinates on PNG layout (calculated from lat/lng)
  final double pixelX;
  final double pixelY;

  /// Container yard (CY1, CY2, CY3, or null for special locations)
  final String? containerYard;

  /// Additional metadata
  final DateTime? lastUpdated;
  final String? description;

  DeviceMarker({
    required this.id,
    required this.name,
    required this.type,
    required this.status,
    required this.latitude,
    required this.longitude,
    required this.pixelX,
    required this.pixelY,
    this.ipAddress,
    this.containerYard,
    this.lastUpdated,
    this.description,
  });

  /// ===== Getters for UI Properties =====

  /// Get marker color based on status
  Color get statusColor {
    switch (status.toUpperCase()) {
      case 'UP':
        return Colors.green;
      case 'DOWN':
        return Colors.red;
      case 'WARNING':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  /// Get marker icon based on device type
  IconData get icon {
    switch (type) {
      case DeviceType.tower:
        return DeviceIconResolver.iconForType('TOWER');
      case DeviceType.cctv:
        return DeviceIconResolver.iconForType('CCTV');
      case DeviceType.rtg:
        return DeviceIconResolver.iconForType('RTG');
      case DeviceType.rs:
        return DeviceIconResolver.iconForType('RS');
      case DeviceType.gate:
        return DeviceIconResolver.iconForType('GATE');
      case DeviceType.parking:
        return DeviceIconResolver.iconForType('PARKING');
    }
  }

  /// Get marker size based on device type
  double get markerSize {
    switch (type) {
      case DeviceType.tower:
      case DeviceType.gate:
      case DeviceType.parking:
        return 50.0;
      default:
        return 40.0;
    }
  }

  /// Get display color for device type
  Color get typeColor {
    switch (type) {
      case DeviceType.tower:
        return DeviceIconResolver.colorForType('TOWER');
      case DeviceType.cctv:
        return DeviceIconResolver.colorForType('CCTV');
      case DeviceType.rtg:
        return DeviceIconResolver.colorForType('RTG');
      case DeviceType.rs:
        return DeviceIconResolver.colorForType('RS');
      case DeviceType.gate:
        return DeviceIconResolver.colorForType('GATE');
      case DeviceType.parking:
        return DeviceIconResolver.colorForType('PARKING');
    }
  }

  /// Get friendly type name
  String get typeName {
    switch (type) {
      case DeviceType.tower:
        return 'Tower/AP';
      case DeviceType.cctv:
        return 'CCTV';
      case DeviceType.rtg:
        return 'RTG';
      case DeviceType.rs:
        return 'RS';
      case DeviceType.gate:
        return 'Gate';
      case DeviceType.parking:
        return 'Parking';
    }
  }

  /// Check if device is online
  bool get isOnline => status.toUpperCase() == 'UP';

  /// Get detailed status text
  String get statusText {
    if (isOnline) {
      return '🟢 ONLINE';
    } else {
      return '🔴 OFFLINE';
    }
  }

  /// ===== Utility Methods =====

  /// Create a copy with modified fields
  DeviceMarker copyWith({
    String? id,
    String? name,
    DeviceType? type,
    String? status,
    String? ipAddress,
    double? latitude,
    double? longitude,
    double? pixelX,
    double? pixelY,
    String? containerYard,
    DateTime? lastUpdated,
    String? description,
  }) {
    return DeviceMarker(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      status: status ?? this.status,
      ipAddress: ipAddress ?? this.ipAddress,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      pixelX: pixelX ?? this.pixelX,
      pixelY: pixelY ?? this.pixelY,
      containerYard: containerYard ?? this.containerYard,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      description: description ?? this.description,
    );
  }

  /// Get info string for debugging
  String getInfoString() {
    return '''
DeviceMarker:
  ID: $id
  Name: $name
  Type: $typeName ($type)
  Status: $status
  Coord: ($latitude, $longitude)
  Pixel: ($pixelX, $pixelY)
  IP: ${ipAddress ?? 'N/A'}
  CY: ${containerYard ?? 'Special'}
  Updated: ${lastUpdated?.toIso8601String() ?? 'N/A'}
''';
  }

  /// ===== Equality & Hashing =====

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeviceMarker &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          status == other.status;

  @override
  int get hashCode => id.hashCode ^ status.hashCode;

  @override
  String toString() => '$name [$typeName] - $status';
}
