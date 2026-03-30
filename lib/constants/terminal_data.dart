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

// Tower Points - 26 towers sesuai list koordinat
final List<TowerPoint> towerPoints = [
  // CY2 Towers (1-6)
  TowerPoint(
      number: 1,
      name: 'Tower 1',
      label: '1',
      latitude: -7.209459,
      longitude: 112.724717,
      containerYard: 'CY2'),
  TowerPoint(
      number: 2,
      name: 'Tower 2',
      label: '2',
      latitude: -7.209191,
      longitude: 112.725250,
      containerYard: 'CY2'),
  TowerPoint(
      number: 3,
      name: 'Tower 3',
      label: '3',
      latitude: -7.208561,
      longitude: 112.724946,
      containerYard: 'CY2'),
  TowerPoint(
      number: 4,
      name: 'Tower 4',
      label: '4',
      latitude: -7.208150,
      longitude: 112.724395,
      containerYard: 'CY2'),
  TowerPoint(
      number: 5,
      name: 'Tower 5',
      label: '5',
      latitude: -7.208262,
      longitude: 112.724161,
      containerYard: 'CY2'),
  TowerPoint(
      number: 6,
      name: 'Tower 6',
      label: '6',
      latitude: -7.208956,
      longitude: 112.724173,
      containerYard: 'CY2'),

  // CY1 Towers (7-17)
  TowerPoint(
      number: 7,
      name: 'Tower 7',
      label: '7',
      latitude: -7.207690,
      longitude: 112.723693,
      containerYard: 'CY1'),
  TowerPoint(
      number: 8,
      name: 'Tower 8',
      label: '8',
      latitude: -7.207567,
      longitude: 112.723945,
      containerYard: 'CY1'),
  TowerPoint(
      number: 9,
      name: 'Tower 9',
      label: '9',
      latitude: -7.207156,
      longitude: 112.724302,
      containerYard: 'CY1'),
  TowerPoint(
      number: 10,
      name: 'Tower 10',
      label: '10',
      latitude: -7.204341,
      longitude: 112.722956,
      containerYard: 'CY1'),
  TowerPoint(
      number: 11,
      name: 'Tower 11',
      label: '11',
      latitude: -7.204080,
      longitude: 112.722354,
      containerYard: 'CY1'),
  TowerPoint(
      number: 27,
      name: 'Tower 12A',
      label: '12A',
      towerIdHint: '12A',
      latitude: -7.204228,
      longitude: 112.722045,
      containerYard: 'CY1'),
  TowerPoint(
      number: 12,
      name: 'Tower 12',
      label: '12',
      latitude: -7.204460,
      longitude: 112.721970,
      containerYard: 'CY1'),
  TowerPoint(
      number: 13,
      name: 'Tower 13',
      label: '13',
      latitude: -7.205410,
      longitude: 112.722386,
      containerYard: 'CY1'),
  TowerPoint(
      number: 14,
      name: 'Tower 14',
      label: '14',
      latitude: -7.206786,
      longitude: 112.723023,
      containerYard: 'CY1'),
  TowerPoint(
      number: 15,
      name: 'Tower 15',
      label: '15',
      latitude: -7.207566,
      longitude: 112.723469,
      containerYard: 'CY1'),
  TowerPoint(
      number: 16,
      name: 'Tower 16',
      label: '16',
      latitude: -7.207342,
      longitude: 112.723059,
      containerYard: 'CY1'),
  TowerPoint(
      number: 17,
      name: 'Tower 17',
      label: '17',
      latitude: -7.209240,
      longitude: 112.723915,
      containerYard: 'CY1'),

  // CY3 Towers (18-26)
  TowerPoint(
      number: 18,
      name: 'Tower 18',
      label: '18',
      latitude: -7.210090,
      longitude: 112.724321,
      containerYard: 'CY3'),
  TowerPoint(
      number: 19,
      name: 'Tower 19',
      label: '19',
      latitude: -7.210336,
      longitude: 112.723639,
      containerYard: 'CY3'),
  TowerPoint(
      number: 20,
      name: 'Tower 20',
      label: '20',
      latitude: -7.210082,
      longitude: 112.723303,
      containerYard: 'CY3'),
  TowerPoint(
      number: 21,
      name: 'Tower 21',
      label: '21',
      latitude: -7.209070,
      longitude: 112.722914,
      containerYard: 'CY3'),
  TowerPoint(
      number: 22,
      name: 'Tower 22',
      label: '22',
      latitude: -7.208501,
      longitude: 112.722942,
      containerYard: 'CY3'),
  TowerPoint(
      number: 23,
      name: 'Tower 23',
      label: '23',
      latitude: -7.208017,
      longitude: 112.722195,
      containerYard: 'CY3'),
  TowerPoint(
      number: 24,
      name: 'Tower 24',
      label: '24',
      latitude: -7.207314,
      longitude: 112.722005,
      containerYard: 'CY3'),
  TowerPoint(
      number: 25,
      name: 'Tower 25',
      label: '25',
      latitude: -7.207213,
      longitude: 112.722232,
      containerYard: 'CY3'),
  TowerPoint(
      number: 26,
      name: 'Tower 26',
      label: '26',
      latitude: -7.207029,
      longitude: 112.722613,
      containerYard: 'CY3'),

  // PARKING Towers (P1-P3)
  TowerPoint(
      number: 28,
      name: 'Tower P1',
      label: 'P1',
      towerIdHint: 'P1',
      latitude: -7.209600,
      longitude: 112.725100,
      containerYard: 'PARKING'),
  TowerPoint(
      number: 29,
      name: 'Tower P2',
      label: 'P2',
      towerIdHint: 'P2',
      latitude: -7.209850,
      longitude: 112.724900,
      containerYard: 'PARKING'),
  TowerPoint(
      number: 30,
      name: 'Tower P3',
      label: 'P3',
      towerIdHint: 'P3',
      latitude: -7.209950,
      longitude: 112.725200,
      containerYard: 'PARKING'),

  // GATE Towers (G1-G2)
  TowerPoint(
      number: 31,
      name: 'Tower G1',
      label: 'G1',
      towerIdHint: 'G1',
      latitude: -7.209800,
      longitude: 112.724400,
      containerYard: 'GATE'),
  TowerPoint(
      number: 32,
      name: 'Tower G2',
      label: 'G2',
      towerIdHint: 'G2',
      latitude: -7.210050,
      longitude: 112.724550,
      containerYard: 'GATE'),
];
