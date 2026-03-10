import 'package:flutter/material.dart';

/// Status Helper - Utility function untuk deteksi status konsisten di seluruh app
/// Centralized status checking untuk menghindari inconsistency

/// Check if status indicates device is DOWN
/// Returns true for: DOWN, WARNING, OFFLINE, UNREACHABLE
bool isDownStatus(String? status) {
  if (status == null || status.isEmpty) return true;
  final normalized = status.trim().toUpperCase();
  return normalized == 'DOWN' ||
      normalized == 'WARNING' ||
      normalized == 'OFFLINE' ||
      normalized == 'UNREACHABLE';
}

/// Check if status indicates device is UP
/// Returns true for: UP, ONLINE, OK
bool isUpStatus(String? status) {
  if (status == null || status.isEmpty) return false;
  final normalized = status.trim().toUpperCase();
  return normalized == 'UP' || normalized == 'ONLINE' || normalized == 'OK';
}

/// Normalize status ke canonical form
/// Returns: 'UP' atau 'DOWN'
String normalizeStatus(String? status) {
  if (isDownStatus(status)) return 'DOWN';
  if (isUpStatus(status)) return 'UP';
  return 'UNKNOWN';
}

/// Get color untuk status indicator
/// Returns: Colors.green untuk UP, Colors.red untuk DOWN, Colors.grey untuk UNKNOWN
Color getStatusColor(String? status) {
  if (isUpStatus(status)) {
    return Colors.green;
  } else if (isDownStatus(status)) {
    return Colors.red;
  }
  return Colors.grey;
}

/// Get icon untuk status
IconData getStatusIcon(String? status) {
  if (isUpStatus(status)) {
    return Icons.check_circle;
  } else if (isDownStatus(status)) {
    return Icons.error;
  }
  return Icons.help;
}

/// Get display text untuk status
String getStatusText(String? status) {
  if (isUpStatus(status)) return 'UP';
  if (isDownStatus(status)) return 'DOWN';
  return 'UNKNOWN';
}
