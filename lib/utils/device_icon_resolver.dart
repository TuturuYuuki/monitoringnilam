import 'package:flutter/material.dart';

class DeviceIconResolver {
  static String normalizeType(String rawType) {
    final value = rawType.trim().toUpperCase();

    if (value == 'ACCESS POINT' || value == 'ACCESS_POINT' || value == 'AP') {
      return 'ACCESS_POINT';
    }
    if (value == 'CAMERA' || value == 'CAM' || value == 'CCTV') {
      return 'CCTV';
    }
    if (value == 'TOWER') {
      return 'TOWER';
    }
    if (value == 'MMT') {
      return 'MMT';
    }
    if (value == 'RTG') {
      return 'RTG';
    }
    if (value == 'RS') {
      return 'RS';
    }
    if (value == 'CC') {
      return 'CC';
    }
    if (value == 'GATE') {
      return 'GATE';
    }
    if (value == 'PARKING') {
      return 'PARKING';
    }

    return value;
  }

  static IconData iconForType(String rawType) {
    switch (normalizeType(rawType)) {
      case 'TOWER':
      case 'ACCESS_POINT':
        return Icons.router;
      case 'CCTV':
        return Icons.videocam;
      case 'MMT':
        return Icons.tablet_mac;
      case 'RTG':
        return Icons.local_shipping;
      case 'RS':
        return Icons.engineering;
      case 'CC':
        return Icons.construction;
      case 'GATE':
        return Icons.directions_walk;
      case 'PARKING':
        return Icons.local_parking;
      default:
        return Icons.device_unknown;
    }
  }

  static Color colorForType(String rawType) {
    switch (normalizeType(rawType)) {
      case 'TOWER':
      case 'ACCESS_POINT':
        return const Color(0xFF1976D2);
      case 'CCTV':
        return const Color(0xFF00BCD4);
      case 'MMT':
        return const Color(0xFFEF6C00);
      case 'RTG':
        return Colors.orange;
      case 'RS':
        return const Color(0xFF00897B);
      case 'CC':
        return Colors.blueGrey;
      case 'GATE':
        return Colors.brown;
      case 'PARKING':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }

  static String? assetForType(String rawType) {
    switch (normalizeType(rawType)) {
      case 'TOWER':
      case 'ACCESS_POINT':
        return 'assets/images/Tower.png';
      case 'RTG':
        return 'assets/images/RTG.png';
      case 'RS':
        return 'assets/images/RS.png';
      case 'CC':
        return 'assets/images/CC.png';
      case 'GATE':
        return 'assets/images/Gate.png';
      case 'PARKING':
        return 'assets/images/Parking.png';
      default:
        return null;
    }
  }

  static IconData iconForLocationName(String locationName) {
    final normalized = locationName.trim().toUpperCase();

    if (normalized.startsWith('TOWER') || RegExp(r'^T\d').hasMatch(normalized)) {
      return iconForType('TOWER');
    }
    if (normalized.startsWith('RTG')) {
      return iconForType('RTG');
    }
    if (normalized.startsWith('RS')) {
      return iconForType('RS');
    }
    if (normalized.startsWith('CC')) {
      return iconForType('CC');
    }
    if (normalized.startsWith('MMT')) {
      return iconForType('MMT');
    }
    if (normalized.contains('GATE')) {
      return iconForType('GATE');
    }
    if (normalized.contains('PARKING')) {
      return iconForType('PARKING');
    }

    return Icons.location_on;
  }
}
