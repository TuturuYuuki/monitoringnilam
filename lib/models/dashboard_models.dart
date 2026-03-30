import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

// Container Yards - sesuai layout gambar ilustrasi
class ContainerYard {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final Color color;

  ContainerYard({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.color,
  });

  LatLng get coordinate => LatLng(latitude, longitude);
}

// Tower/Access Point - sesuai layout gambar ilustrasi
class TowerPoint {
  final int number;
  final String name;
  final String label;
  final double latitude;
  final double longitude;
  final String containerYard;
  final String? towerIdHint;

  TowerPoint({
    required this.number,
    required this.name,
    String? label,
    required this.latitude,
    required this.longitude,
    required this.containerYard,
    this.towerIdHint,
  }) : label = label ?? name;

  LatLng get coordinate => LatLng(latitude, longitude);
}

// Special Locations
class SpecialLocation {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final Color color;
  final IconData icon;
  final String? iconAsset;

  SpecialLocation({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.color,
    required this.icon,
    this.iconAsset,
  });

  LatLng get coordinate => LatLng(latitude, longitude);
}

class DeviceLocationPoint {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final String containerYard;
  final Color color;
  final String iconAsset;
  String status; // UP or DOWN - mutable for updates

  DeviceLocationPoint({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.containerYard,
    required this.color,
    required this.iconAsset,
    this.status = 'UP', // default UP
  });

  LatLng get coordinate => LatLng(latitude, longitude);
}
