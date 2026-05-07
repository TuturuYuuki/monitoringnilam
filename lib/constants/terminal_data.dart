import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:monitoring/models/dashboard_models.dart';

// Konstanta lokasi TPK Nilam - sesuai layout gambar
class TPKNilamLocation {
  static const String name = 'Terminal Nilam';
  static const double latitude = -7.207277;
  static const double longitude = 112.723613;
  static const LatLng coordinate = LatLng(latitude, longitude);
  static const double defaultZoom = 16.5;
}

// Data Container Yards - koordinat presisi
final List<ContainerYard> containerYards = [
  ContainerYard(
    id: 'CY1',
    name: 'Container Yard 1',
    latitude: -7.205843,
    longitude: 112.723164,
    color: const Color(0xFFFFB74D), // Orange
  ),
  ContainerYard(
    id: 'CY2',
    name: 'Container Yard 2',
    latitude: -7.209152,
    longitude: 112.724487,
    color: const Color(0xFF66BB6A), // Hijau
  ),
  ContainerYard(
    id: 'CY3',
    name: 'Container Yard 3',
    latitude: -7.208712,
    longitude: 112.723270,
    color: const Color(0xFFEF9A9A), // Pink
  ),
];

// Special Locations
final List<SpecialLocation> specialLocations = [
  SpecialLocation(
    id: 'GATE',
    name: 'Gate In/Out',
    latitude: -7.2099123,
    longitude: 112.7244489,
    color: const Color.fromARGB(255, 0, 0, 0),
    icon: Icons.directions_walk,
    iconAsset: 'assets/images/Gate.png',
  ),
  SpecialLocation(
    id: 'PARKING',
    name: 'Parking',
    latitude: -7.209907,
    longitude: 112.724877,
    color: const Color.fromARGB(255, 0, 0, 0),
    icon: Icons.local_parking,
    iconAsset: 'assets/images/Parking.png',
  ),
];

// Device Location Points - Master data untuk Map/Monitoring
final List<DeviceLocationPoint> deviceLocationPoints = [
  // CC (CY1)
  DeviceLocationPoint(
    id: 'CC01',
    name: 'CC01 - CY1',
    latitude: -7.204768,
    longitude: 112.723299,
    containerYard: 'CY1',
    color: const Color(0xFF455A64),
    iconAsset: 'assets/images/CC.png',
  ),
  DeviceLocationPoint(
    id: 'CC02',
    name: 'CC02 - CY1',
    latitude: -7.205358,
    longitude: 112.723571,
    containerYard: 'CY1',
    color: const Color(0xFF455A64),
    iconAsset: 'assets/images/CC.png',
  ),
  DeviceLocationPoint(
    id: 'CC03',
    name: 'CC03 - CY1',
    latitude: -7.205947,
    longitude: 112.723840,
    containerYard: 'CY1',
    color: const Color(0xFF455A64),
    iconAsset: 'assets/images/CC.png',
  ),
  DeviceLocationPoint(
    id: 'CC04',
    name: 'CC04 - CY1',
    latitude: -7.206656,
    longitude: 112.724164,
    containerYard: 'CY1',
    color: const Color(0xFF455A64),
    iconAsset: 'assets/images/CC.png',
  ),
  // RTG
  DeviceLocationPoint(
    id: 'RTG01',
    name: 'RTG01 - CY1',
    latitude: -7.204805,
    longitude: 112.722550,
    containerYard: 'CY1',
    color: const Color(0xFFFF9800),
    iconAsset: 'assets/images/RTG.png',
  ),
  DeviceLocationPoint(
    id: 'RTG02',
    name: 'RTG02 - CY1',
    latitude: -7.205129,
    longitude: 112.723000,
    containerYard: 'CY1',
    color: const Color(0xFFFF9800),
    iconAsset: 'assets/images/RTG.png',
  ),
  DeviceLocationPoint(
    id: 'RTG03',
    name: 'RTG03 - CY1',
    latitude: -7.205998,
    longitude: 112.722836,
    containerYard: 'CY1',
    color: const Color(0xFFFF9800),
    iconAsset: 'assets/images/RTG.png',
  ),
  DeviceLocationPoint(
    id: 'RTG04',
    name: 'RTG04 - CY1',
    latitude: -7.206359,
    longitude: 112.723258,
    containerYard: 'CY1',
    color: const Color(0xFFFF9800),
    iconAsset: 'assets/images/RTG.png',
  ),
  DeviceLocationPoint(
    id: 'RTG05',
    name: 'RTG05 - CY1',
    latitude: -7.206749,
    longitude: 112.723464,
    containerYard: 'CY1',
    color: const Color(0xFFFF9800),
    iconAsset: 'assets/images/RTG.png',
  ),
  DeviceLocationPoint(
    id: 'RTG06',
    name: 'RTG06 - CY1',
    latitude: -7.207079,
    longitude: 112.723899,
    containerYard: 'CY1',
    color: const Color(0xFFFF9800),
    iconAsset: 'assets/images/RTG.png',
  ),
  DeviceLocationPoint(
    id: 'RTG07',
    name: 'RTG07 - CY2',
    latitude: -7.208641,
    longitude: 112.724410,
    containerYard: 'CY2',
    color: const Color(0xFFFF9800),
    iconAsset: 'assets/images/RTG.png',
  ),
  DeviceLocationPoint(
    id: 'RTG08',
    name: 'RTG08 - CY2',
    latitude: -7.208957,
    longitude: 112.724877,
    containerYard: 'CY2',
    color: const Color(0xFFFF9800),
    iconAsset: 'assets/images/RTG.png',
  ),
  // RS
  DeviceLocationPoint(
    id: 'RS',
    name: 'RS - CY3',
    latitude: -7.207700,
    longitude: 112.723028,
    containerYard: 'CY3',
    color: const Color(0xFF7B1FA2),
    iconAsset: 'assets/images/RS.png',
  ),
];

// Tower points removed - moved to database MasterLocation system

