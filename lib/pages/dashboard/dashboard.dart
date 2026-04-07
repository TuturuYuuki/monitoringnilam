import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:monitoring/main.dart';
import 'package:monitoring/services/api_service.dart';
import 'package:monitoring/models/camera_model.dart';
import 'package:monitoring/models/tower_model.dart';
import 'package:monitoring/models/alert_model.dart';
import 'package:monitoring/models/device_model.dart';
import 'package:monitoring/models/device_marker.dart';
import 'package:monitoring/pages/network/network.dart';
import 'package:monitoring/pages/cctv/cctv.dart';
import 'package:monitoring/pages/alerts/alerts.dart';
import 'package:monitoring/pages/profile/profile.dart';
import 'package:monitoring/pages/devices/add_device.dart';
import 'package:monitoring/services/device_storage_service.dart';
import 'package:monitoring/utils/tower_status_override.dart';
import 'package:monitoring/utils/layout_mapper.dart';
import 'package:monitoring/utils/device_icon_resolver.dart';
import 'package:monitoring/utils/location_label_utils.dart';

import 'package:monitoring/widgets/global_header_bar.dart';
import 'package:monitoring/widgets/global_sidebar_nav.dart';
import 'package:monitoring/pages/report/report_page.dart';
import 'package:monitoring/pages/network/tower_management.dart';
import 'package:monitoring/pages/mmt/mmt_monitoring.dart';

// Konstanta lokasi TPK Nilam - sesuai layout gambar
import 'package:monitoring/models/dashboard_models.dart';
import 'package:monitoring/constants/terminal_data.dart';
import 'package:monitoring/widgets/dashboard/status_cards.dart';
import 'package:monitoring/widgets/global_footer.dart';
import 'package:monitoring/widgets/dashboard/live_terminal_map.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> with RouteAware {
  late MapController mapController;

  late ApiService apiService;
  List<Camera> cameras = [];
  List<Tower> towers = [];
  List<Alert> alerts = [];
  List<AddedDevice> addedDevices = [];
  List<Map<String, dynamic>> masterLocations = [];
  List<Map<String, dynamic>> _latestMmtRows = [];
  Map<String, String> deviceStatuses = {};
  Map<String, String> _mmtStatusByIp = {};
  bool _isPickTowerMode = false;
  String? _pickTowerYard;
  int totalUpMMT = 0;
  int totalDownMMT = 0;
  Timer? _refreshTimer;
  Timer? _blinkTimer;
  bool _isLoadingDashboard = false;
  bool _isPingInProgress = false;
  DateTime? _lastPingCheckAt;
  static const Duration _pingCheckInterval = Duration(seconds: 30);
  bool _isRouteSubscribed = false;
  int totalUpCameras = 0;
  int totalDownCameras = 0;
  int totalOnlineTowers = 0;
  int totalTowers = 0;
  int totalWarnings = 0;
  int totalDownTowers = 0;

  // Tracking blinking locations with multiple devices where at least one is DOWN
  final Set<String> _locationKeysWithDownDevices = {};
  bool _isBlinkVisible = true;
  double get towerUptimePercent =>
      totalTowers == 0 ? 0 : (totalOnlineTowers / totalTowers) * 100;
  List<Alert> get activeAlerts => alerts
      .where((a) => a.severity == 'critical' || a.severity == 'warning')
      .toList();
  int get totalActiveAlerts => activeAlerts.length;
  int get criticalAlertsCount =>
      activeAlerts.where((a) => a.severity == 'critical').length;
  int get warningAlertsCount =>
      activeAlerts.where((a) => a.severity == 'warning').length;

  @override
  void initState() {
    super.initState();
    mapController = MapController();
    apiService = ApiService();
    _loadDashboardData();
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        _loadDashboardData();
      }
    });

    // Start blinking animation timer (toggle every 500ms = 1 second cycle)
    _blinkTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (mounted && _locationKeysWithDownDevices.isNotEmpty) {
        setState(() {
          _isBlinkVisible = !_isBlinkVisible;
        });
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute && !_isRouteSubscribed) {
      routeObserver.subscribe(this, route);
      _isRouteSubscribed = true;
    }
    final args = route?.settings.arguments;
    if (args is Map) {
      if (args['refresh'] == true) {
        _refreshAfterNavigation();
      }

      final pickMode = args['pickTowerPosition'] == true;
      final targetYard = args['yard']?.toString();
      if (pickMode != _isPickTowerMode || targetYard != _pickTowerYard) {
        setState(() {
          _isPickTowerMode = pickMode;
          _pickTowerYard = targetYard;
        });
      }
    } else if (_isPickTowerMode || _pickTowerYard != null) {
      setState(() {
        _isPickTowerMode = false;
        _pickTowerYard = null;
      });
    }
    // Reload data when returning from add device or other pages
    // This ensures added device icons appear immediately on map
    if (mounted) {
      _loadDashboardData();
    }
  }

  @override
  void didPopNext() {
    _refreshAfterNavigation();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _blinkTimer?.cancel();
    if (_isRouteSubscribed) {
      routeObserver.unsubscribe(this);
    }
    super.dispose();
  }

  void _refreshAfterNavigation() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadDashboardData();
      }
    });
  }

  Future<void> _loadDashboardData() async {
    if (_isLoadingDashboard) {
      return;
    }

    _isLoadingDashboard = true;
    try {
      _triggerPingCheck().catchError((e) => debugPrint('Ping error: $e'));
      await apiService.getDashboardStats();
      // Separate void future from non-void futures
      final results = await Future.wait([
        apiService.getAllCameras(),
        apiService.getAllTowers(),
        apiService.getAllAlerts(),
        apiService.getAllMasterLocations(),
      ]);
      final fetchedCameras = results[0] as List<Camera>;
      final fetchedTowers = results[1] as List<Tower>;

      // Handle new paginated response format (getAllAlerts always returns Map<String, dynamic>)
      List<Alert> fetchedAlerts = [];
      final alertsResponse = results[2] as Map<String, dynamic>;

      // Extract alerts list from response map using explicit loop
      final alertListRaw = alertsResponse['alerts'] as List? ?? [];
      for (var data in alertListRaw) {
        if (data is Alert) {
          fetchedAlerts.add(data);
        } else {
          fetchedAlerts.add(Alert.fromJson(data as Map<String, dynamic>));
        }
      }

      // Extract master locations
      final fetchedMasterLocations = results[3] as List<Map<String, dynamic>>;

      // Run void future separately after other data loads
      await _updateDeviceLocationStatuses();

      final updatedTowers = applyForcedTowerStatus(fetchedTowers);
      final updatedCameras = applyForcedCameraStatus(fetchedCameras);
      final ipStatus = _buildIpStatusMap(updatedTowers, updatedCameras);
      final effectiveTowers = _applyIpStatusToTowers(updatedTowers, ipStatus);
      final effectiveCameras =
          _applyIpStatusToCameras(updatedCameras, ipStatus);
      final List<Alert> generatedAlerts = [];

      for (final tower in effectiveTowers) {
        if (isDownStatus(tower.status)) {
          String route = '/ ';
          if (tower.containerYard == 'CY2') {
            route = '/network-cy2';
          } else if (tower.containerYard == 'CY3') {
            route = '/network-cy3';
          }

          final timestamp = tower.updatedAt.isNotEmpty
              ? tower.updatedAt
              : (tower.createdAt.isNotEmpty
                  ? tower.createdAt
                  : DateTime.now().toString());

          generatedAlerts.add(Alert(
            id: int.tryParse(tower.id.toString()) ??
                0, // Ubah ke int agar tidak error
            alertKey: 'generated:${tower.id}:${tower.towerId}:AP_DOWN',
            title: 'Access Point DOWN - ${tower.towerId}',
            description:
                '${tower.location} access point offline (${tower.towerId})',
            severity: 'critical',
            timestamp: timestamp,
            route: route,
            category: 'Access Point',
          ));
        }
      }

      for (final camera in effectiveCameras) {
        if (isDownStatus(camera.status)) {
          String route = '/cctv';
          if (camera.containerYard == 'CY2') {
            route = '/cctv-cy2';
          } else if (camera.containerYard == 'CY3') {
            route = '/cctv-cy3';
          }

          final timestamp = camera.updatedAt.isNotEmpty
              ? camera.updatedAt
              : (camera.createdAt.isNotEmpty
                  ? camera.createdAt
                  : DateTime.now().toString());

          generatedAlerts.add(Alert(
            id: (int.tryParse(camera.id.toString()) ?? 0) + 1000, // ID unik
            alertKey:
                'generated:${camera.id + 1000}:${camera.cameraId}:CCTV_DOWN',
            title: 'CCTV DOWN - ${camera.cameraId}',
            description:
                '${camera.location} camera offline (${camera.cameraId})',
            severity: 'critical',
            timestamp: timestamp,
            route: route,
            category: 'CCTV',
          ));
        }
      }

      final mmts = await apiService.getAllMMTs();
      for (final mmt in mmts) {
        // Find realtime status (downCount from realtime ping overrides static DB row if available)
        final status = deviceStatuses[mmt.mmtId] ?? mmt.status;
        if (isDownStatus(status)) {
          const route =
              '/mmt'; // Placeholder route if no MMT page explicitly mapped
          final timestamp = mmt.updatedAt.isNotEmpty
              ? mmt.updatedAt
              : (mmt.createdAt.isNotEmpty
                  ? mmt.createdAt
                  : DateTime.now().toString());

          generatedAlerts.add(Alert(
            id: (int.tryParse(mmt.id.toString()) ?? 0) + 2000, // ID unik
            alertKey: 'generated:${mmt.id + 2000}:${mmt.mmtId}:MMT_DOWN',
            title: 'MMT DOWN - ${mmt.mmtId}',
            description: '${mmt.location} MMT offline (${mmt.mmtId})',
            severity: 'critical',
            timestamp: timestamp,
            route: route,
            category: 'MMT',
          ));
        }
      }

      // Always fetch device list from backend (towers, cameras, mmts)
      List<AddedDevice> devices = [];
      for (final tower in effectiveTowers) {
        devices.add(AddedDevice(
          id: tower.id.toString(),
          name: tower.towerId,
          type: 'Tower',
          ipAddress: tower.ipAddress,
          locationName: tower.location,
          latitude: tower.latitude ?? 0.0,
          longitude: tower.longitude ?? 0.0,
          containerYard: tower.containerYard,
          createdAt: DateTime.tryParse(tower.createdAt) ?? DateTime.now(),
          status: tower.status,
        ));
      }
      for (final camera in effectiveCameras) {
        devices.add(AddedDevice(
          id: camera.id.toString(),
          name: camera.cameraId,
          type: 'CCTV',
          ipAddress: camera.ipAddress,
          locationName: camera.location,
          latitude: camera.latitude ?? 0.0,
          longitude: camera.longitude ?? 0.0,
          containerYard: camera.containerYard,
          createdAt: DateTime.tryParse(camera.createdAt) ?? DateTime.now(),
          status: camera.status,
        ));
      }
      for (final mmt in mmts) {
        devices.add(AddedDevice(
          id: mmt.id.toString(),
          name: mmt.mmtId,
          type: 'MMT',
          ipAddress: mmt.ipAddress,
          locationName: mmt.location,
          latitude: 0.0,
          longitude: 0.0,
          containerYard: mmt.containerYard,
          createdAt: DateTime.tryParse(mmt.createdAt) ?? DateTime.now(),
          status: deviceStatuses[mmt.mmtId] ??
              mmt.status, // use realtime logic if cached early
        ));
      }
      devices.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      for (var device in devices) {
        if (device.type == 'MMT') {
          device.status = deviceStatuses[device.name] ??
              deviceStatuses[device.id] ??
              'DOWN';
        } else if (device.type == 'Access Point' || device.type == 'Tower') {
          if (effectiveTowers.isNotEmpty) {
            final tower = effectiveTowers.firstWhere(
              (t) =>
                  t.towerId == device.name || t.ipAddress == device.ipAddress,
              orElse: () => effectiveTowers.first,
            );
            if (tower.towerId == device.name ||
                tower.ipAddress == device.ipAddress) {
              device.status = tower.status;
            }
          }
        } else if (device.type == 'CCTV') {
          if (effectiveCameras.isNotEmpty) {
            final camera = effectiveCameras.firstWhere(
              (c) =>
                  c.cameraId == device.name || c.ipAddress == device.ipAddress,
              orElse: () => effectiveCameras.first,
            );
            if (camera.cameraId == device.name ||
                camera.ipAddress == device.ipAddress) {
              device.status = camera.status;
            }
          }
        }

        final ipKey = device.ipAddress.trim();
        final ipStatusValue = ipStatus[ipKey];
        if (ipStatusValue != null) {
          device.status = ipStatusValue;
        }
      }

      devices.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // 3. FILTER ALERTS - Hanya tampilkan yang masih aktif (device masih DOWN)
      // Do this before setState since it's async
      final activeAlerts = await apiService.filterActiveAlerts(
        fetchedAlerts,
        towers,
        effectiveCameras,
        devices,
      );

      if (mounted) {
        setState(() {
          // 1. Simpan Data Master
          cameras = effectiveCameras;
          towers = effectiveTowers;
          masterLocations = fetchedMasterLocations;

          // 2. Gabungkan SEMUA perangkat ke dalam addedDevices agar muncul di METER/MAP
          // Kita bersihkan dulu agar tidak duplikat saat refresh
          addedDevices = [];
          addedDevices.addAll(
              devices); // 'devices' adalah list yang sudah Anda buat di baris 440-490

          // 3. Hitung Statistik (Tetap seperti kode Anda)
          totalTowers = towers.length;
          totalOnlineTowers =
              towers.where((t) => !isDownStatus(t.status)).length;
          totalDownTowers = (totalTowers - totalOnlineTowers).clamp(0, 999);

          int allCamerasCount = cameras.length;
          totalUpCameras = cameras.where((c) => !isDownStatus(c.status)).length;
          totalDownCameras = (allCamerasCount - totalUpCameras).clamp(0, 999);

          // 4. Update Alerts (Tetap seperti kode Anda)
          final combined = [...activeAlerts, ...generatedAlerts];
          final uniqueAlerts = <String, Alert>{};
          for (final a in combined) {
            String devName = a.title;

            if (devName.contains(' - ')) {
              devName = devName.split(' - ').last.trim();
            } else if (devName.toLowerCase().contains(' is ')) {
              devName = devName
                  .split(RegExp(r'\s+is\s+', caseSensitive: false))
                  .first
                  .trim();
            }
            devName = devName.replaceAll(
                RegExp(r'(Access\sPoint|CCTV|MMT)\s+DOWN\s+-\s+',
                    caseSensitive: false),
                '');
            devName = devName.trim();

            if (!uniqueAlerts.containsKey(devName)) {
              uniqueAlerts[devName] = a;
            } else if (a.severity == 'critical' &&
                uniqueAlerts[devName]!.severity != 'critical') {
              uniqueAlerts[devName] = a;
            }
          }
          alerts = uniqueAlerts.values.toList()
            ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

          totalWarnings = alerts.length;

          // 5. Trigger Blinking
          _updateBlinkingLocations();
        });
      }
    } catch (e) {
      print('Error loading dashboard data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error refreshing data: ${e.toString()}'),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } finally {
      _isLoadingDashboard = false;
    }
  }

  Future<void> _loadAddedDevices(Map<String, String> ipStatus) async {
    try {
      List<AddedDevice> devices = await DeviceStorageService.getDevices();
      for (var device in devices) {
        final ipKey = device.ipAddress.trim();
        if (ipStatus.containsKey(ipKey)) {
          device.status = ipStatus[ipKey]!;
        }
      }
      if (mounted) {
        setState(() {
          addedDevices = devices;
          addedDevices.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        });
      }
    } catch (e) {
      debugPrint("Error loading added devices: $e");
    }
  }

  Future<void> _updateDeviceLocationStatuses() async {
    try {
      // Get all MMT devices from database
      // The realtime ping check has already updated all statuses in the database
      // So we just read the current status from database without individual pings
      final response = await http.get(
        Uri.parse(
            'http://localhost/monitoring_api/index.php?endpoint=mmt&action=all'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final List<dynamic> mmtList = data['data'];

          // Clear and prepare device statuses map
          deviceStatuses.clear();
          final mmtStatusByIp = <String, String>{};
          var upCount = 0;
          var downCount = 0;

          // Update device statuses from database
          _latestMmtRows = mmtList.whereType<Map>().map((row) {
            final mapped = row.map(
              (key, value) => MapEntry(key.toString(), value),
            );
            return {
              ...mapped,
              'location': normalizeLocationLabel(
                (mapped['location'] ?? '').toString(),
              ),
            };
          }).toList(growable: false);

          for (var mmt in mmtList) {
            final mmtId = mmt['mmt_id']?.toString() ?? '';
            final deviceId = mmtId.isNotEmpty
                ? mmtId
                : (mmt['id']?.toString() ?? mmt['device_id']?.toString() ?? '');
            final ipAddress = mmt['ip_address']?.toString() ?? '';

            // Read status directly from database (already updated by realtime ping)
            final status = mmt['status']?.toString().toUpperCase() ?? 'DOWN';

            if (status == 'UP') {
              upCount++;
            } else {
              downCount++;
            }

            if (deviceId.isNotEmpty) {
              deviceStatuses[deviceId] = status;
            }
            if (ipAddress.isNotEmpty) {
              _mergeIpStatus(mmtStatusByIp, ipAddress, status);
            }
          }

          _mmtStatusByIp = mmtStatusByIp;
          totalUpMMT = upCount;
          totalDownMMT = downCount;

          // Update status in deviceLocationPoints
          for (var device in deviceLocationPoints) {
            device.status = deviceStatuses[device.id] ?? 'DOWN';
          }

          print(
              'Updated ${deviceStatuses.length} Device Statuses From Database');
        }
      }
    } catch (e) {
      print('Error Updating Device Location Statuses: $e');
    }
  }

  Future<void> _triggerPingCheck({bool force = false}) async {
    final now = DateTime.now();

    if (_isPingInProgress) {
      return;
    }

    if (!force &&
        _lastPingCheckAt != null &&
        now.difference(_lastPingCheckAt!) < _pingCheckInterval) {
      return;
    }

    _isPingInProgress = true;
    _lastPingCheckAt = now;

    try {
      const baseUrl = 'http://localhost/monitoring_api/index.php';

      // Call realtime ping endpoint yang update semua towers dan cameras sekaligus
      final response = await http
          .get(
        Uri.parse('$baseUrl?endpoint=realtime&action=all'),
      )
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('Realtime Ping Timed Out - Skipping');
          return http.Response('{"success":false,"message":"Timeout"}', 408);
        },
      );

      if (response.statusCode == 200) {
        // Wait a moment for database to update
        await Future.delayed(const Duration(milliseconds: 500));
        print('Realtime Ping Check Completed: ${response.statusCode}');
      } else {
        print('Realtime Ping Failed: ${response.statusCode}');
      }
    } catch (e) {
      // Silent fail - just log, don't throw
      // This prevents error snackbar spam during auto-refresh
      print('Error Triggering Ping Check (Ignored): $e');
    } finally {
      _isPingInProgress = false;
    }
  }

  void _mergeIpStatus(Map<String, String> map, String ip, String status) {
    final normalized = status.toUpperCase();
    if (ip.isEmpty) {
      return;
    }
    final current = map[ip];
    if (normalized == 'UP') {
      map[ip] = 'UP';
      return;
    }
    if (current == null) {
      map[ip] = normalized;
      return;
    }
    if (current != 'UP' && normalized == 'DOWN') {
      map[ip] = 'DOWN';
    }
  }

  Map<String, String> _buildIpStatusMap(
      List<Tower> towers, List<Camera> cameras) {
    final map = <String, String>{};
    for (final tower in towers) {
      _mergeIpStatus(map, tower.ipAddress.trim(), tower.status);
    }
    for (final camera in cameras) {
      _mergeIpStatus(map, camera.ipAddress.trim(), camera.status);
    }
    for (final entry in _mmtStatusByIp.entries) {
      _mergeIpStatus(map, entry.key, entry.value);
    }
    return map;
  }

  List<Tower> _applyIpStatusToTowers(
      List<Tower> towers, Map<String, String> ipStatus) {
    return towers.map((tower) {
      final ip = tower.ipAddress.trim();
      final forced = ipStatus[ip];
      if (forced == null || tower.status.toUpperCase() == forced) {
        return tower;
      }
      return Tower(
        id: tower.id,
        towerId: tower.towerId,
        towerNumber: tower.towerNumber,
        location: tower.location,
        ipAddress: tower.ipAddress,
        status: forced,
        containerYard: tower.containerYard,
        createdAt: tower.createdAt,
        updatedAt: tower.updatedAt,
      );
    }).toList(growable: false);
  }

  List<Camera> _applyIpStatusToCameras(
      List<Camera> cameras, Map<String, String> ipStatus) {
    return cameras.map((camera) {
      final ip = camera.ipAddress.trim();
      final forced = ipStatus[ip];
      if (forced == null || camera.status.toUpperCase() == forced) {
        return camera;
      }
      return Camera(
        id: camera.id,
        cameraId: camera.cameraId,
        location: camera.location,
        ipAddress: camera.ipAddress,
        status: forced,
        type: camera.type,
        containerYard: camera.containerYard,
        areaType: camera.areaType,
        createdAt: camera.createdAt,
        updatedAt: camera.updatedAt,
      );
    }).toList(growable: false);
  }

  LatLng _offsetPoint(double lat, double lng, int index, int total) {
    if (total <= 1) {
      return LatLng(lat, lng);
    }

    final radius = 0.000025 * (1 + (total ~/ 4) * 0.5);

    final angle = (2 * math.pi * index / total) - (math.pi / 2);

    return LatLng(
        lat + (radius * math.cos(angle)), lng + (radius * math.sin(angle)));
  }

  List<Marker> _buildAddedDeviceMarkers() {
    final totals = <String, int>{};
    for (final device in addedDevices) {
      final key = '${device.latitude}_${device.longitude}';
      totals[key] = (totals[key] ?? 0) + 1;
    }
    final seen = <String, int>{};

    return addedDevices.map((device) {
      final key = '${device.latitude}_${device.longitude}';
      final index = seen[key] ?? 0;
      seen[key] = index + 1;
      final total = totals[key] ?? 1;
      final offset =
          _offsetPoint(device.latitude, device.longitude, index, total);

      // Logika Warna Status
      final bool isDown = isDownStatus(device.status);
      final Color badgeColor = isDown ? Colors.red : Colors.green;

      // Warna Icon Statis berdasarkan Tipe
      final Color iconBaseColor = DeviceIconResolver.colorForType(device.type);

      return Marker(
        point: offset,
        width: 60,
        height: 85, // Tinggi ditambah agar tidak terpotong
        child: GestureDetector(
          onTap: () => _showDevicesAtLocation(
              context, device.latitude, device.longitude),
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // --- BAGIAN STACK UNTUK ICON + DOT ---
                SizedBox(
                  width: 45,
                  height: 45,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Icon Utama
                      Icon(
                        _getDeviceIcon(device.type),
                        color: iconBaseColor,
                        size: 40,
                      ),
                      // Dot Status Melayang di Pojok (TOP RIGHT)
                      Positioned(
                        top: -2,
                        right: -2,
                        child: Container(
                          width: 16, // Ukuran dot diperbesar
                          height: 16,
                          decoration: BoxDecoration(
                            color: badgeColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2.5),
                            boxShadow: [
                              BoxShadow(
                                color: badgeColor.withOpacity(0.5),
                                blurRadius: 6,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                // Label Perangkat
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    device.name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }).toList(growable: false);
  }

  // Build markers for master locations (RTG, RS, CC, etc) with color-coding
  List<Marker> _buildMasterLocationMarkers() {
    if (masterLocations.isEmpty) {
      return [];
    }

    return masterLocations.map((location) {
      final locType =
          (location['location_type'] ?? '').toString().toUpperCase();
      final locCode = (location['location_code'] ?? '').toString();
      final locName = (location['location_name'] ?? '').toString();
      final lat =
          double.tryParse((location['latitude'] ?? '0').toString()) ?? 0.0;
      final lng =
          double.tryParse((location['longitude'] ?? '0').toString()) ?? 0.0;

      // Static icon color based on location type
      final markerColor = DeviceIconResolver.colorForType(locType);
      final markerIcon = DeviceIconResolver.iconForType(locType);

      // For master locations, assume always UP (green badge)
      const badgeColor = Colors.green;

      return Marker(
        point: LatLng(lat, lng),
        width: 60,
        height: 80,
        child: GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Master Location: $locName ($locType)'),
                duration: const Duration(seconds: 2),
                backgroundColor: markerColor,
              ),
            );
          },
          behavior: HitTestBehavior.opaque,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                // Icon with Status Badge
                SizedBox(
                  width: 40,
                  height: 40,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Main Icon (static color based on type)
                      Icon(
                        markerIcon,
                        color: markerColor,
                        size: 38,
                      ),
                      // Status Badge (top-right corner)
                      Positioned(
                        top: -2,
                        right: -2,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: badgeColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 2.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: badgeColor.withOpacity(0.6),
                                blurRadius: 4,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                // Label with rounded background
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white24, width: 0.5),
                  ),
                  child: Text(
                    locCode,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }

  Tower? _findTowerForPoint(TowerPoint point) {
    try {
      return towers.firstWhere((t) => t.towerNumber == point.number);
    } catch (_) {
      final hint = point.towerIdHint ?? point.label;
      if (hint.isEmpty) return null;
      final hintLower = hint.toLowerCase();
      try {
        return towers.firstWhere((t) => t.towerId.toLowerCase() == hintLower);
      } catch (_) {
        return null;
      }
    }
  }

  String _getTowerStatusForPoint(TowerPoint point) {
    final tower = _findTowerForPoint(point);
    return tower?.status.toUpperCase() ?? 'UP';
  }

  // Get tower color based on status
  Color _getTowerColor(TowerPoint point) {
    final status = _getTowerStatusForPoint(point);
    return isDownStatus(status) ? Colors.red : const Color(0xFF2196F3);
  }

  // Detect locations with multiple devices where at least one is DOWN for blinking effect
  void _updateBlinkingLocations() {
    _locationKeysWithDownDevices.clear();

    // Group devices by location
    final Map<String, List<AddedDevice>> devicesByLocation = {};
    for (final device in addedDevices) {
      final key = '${device.latitude}_${device.longitude}';
      if (!devicesByLocation.containsKey(key)) {
        devicesByLocation[key] = [];
      }
      devicesByLocation[key]!.add(device);
    }

    // Check locations with 2+ devices and at least one DOWN
    for (final entry in devicesByLocation.entries) {
      if (entry.value.length >= 2) {
        final hasDownDevice = entry.value.any((d) => d.status == 'DOWN');
        if (hasDownDevice) {
          _locationKeysWithDownDevices.add(entry.key);
        }
      }
    }
  }

  // Get icon untuk added device
  IconData _getDeviceIcon(String deviceType) {
    return DeviceIconResolver.iconForType(deviceType);
  }

  // Get color untuk device berdasarkan tipe
  Color _getDeviceColor(String deviceType) {
    return DeviceIconResolver.colorForType(deviceType);
  }

  int get totalCameras => totalUpCameras + totalDownCameras;

  Future<List<AddedDevice>> _pruneStaleLocalDevices(
    List<AddedDevice> localDevices, {
    required List<Tower> towersFromDb,
    required List<Camera> camerasFromDb,
    required List<Map<String, dynamic>> latestMmtRows,
  }) async {
    final towerNames = towersFromDb
        .map((t) => t.towerId.trim().toLowerCase())
        .where((v) => v.isNotEmpty)
        .toSet();
    final towerIps = towersFromDb
        .map((t) => t.ipAddress.trim())
        .where((v) => v.isNotEmpty)
        .toSet();

    final cameraNames = camerasFromDb
        .map((c) => c.cameraId.trim().toLowerCase())
        .where((v) => v.isNotEmpty)
        .toSet();
    final cameraIps = camerasFromDb
        .map((c) => c.ipAddress.trim())
        .where((v) => v.isNotEmpty)
        .toSet();

    final mmtNames = latestMmtRows
        .map((m) => (m['mmt_id'] ?? '').toString().trim().toLowerCase())
        .where((v) => v.isNotEmpty)
        .toSet();
    final mmtIps = latestMmtRows
        .map((m) => (m['ip_address'] ?? '').toString().trim())
        .where((v) => v.isNotEmpty)
        .toSet();

    final filtered = localDevices.where((d) {
      final type = d.type.trim().toUpperCase();
      final name = d.name.trim().toLowerCase();
      final ip = d.ipAddress.trim();

      if (type == 'ACCESS POINT' || type == 'TOWER') {
        return towerNames.contains(name) || towerIps.contains(ip);
      }
      if (type == 'CCTV') {
        return cameraNames.contains(name) || cameraIps.contains(ip);
      }
      if (type == 'MMT') {
        return mmtNames.contains(name) || mmtIps.contains(ip);
      }

      return true;
    }).toList(growable: false);

    if (filtered.length != localDevices.length) {
      await DeviceStorageService.overwriteDevices(filtered);
    }

    return filtered;
  }

  List<AddedDevice> _buildLayoutDevices() {
    final merged = <AddedDevice>[...addedDevices];
    final existingKeys = <String>{};

    for (final device in merged) {
      final key =
          '${device.type.toUpperCase()}|${device.ipAddress.trim().toUpperCase()}|${device.locationName.toUpperCase()}';
      existingKeys.add(key);
    }

    for (final camera in cameras) {
      final locationName = camera.location.trim();
      if (locationName.isEmpty) {
        continue;
      }

      final cameraAsDevice = AddedDevice(
        id: 'camera_${camera.id}',
        type: 'CCTV',
        name: camera.cameraId,
        ipAddress: camera.ipAddress,
        locationName: locationName,
        latitude: camera.latitude ?? 0,
        longitude: camera.longitude ?? 0,
        containerYard: camera.containerYard,
        createdAt: DateTime.tryParse(camera.createdAt) ?? DateTime.now(),
        status: camera.status,
      );

      final key =
          '${cameraAsDevice.type.toUpperCase()}|${cameraAsDevice.ipAddress.trim().toUpperCase()}|${cameraAsDevice.locationName.toUpperCase()}';
      if (existingKeys.add(key)) {
        merged.add(cameraAsDevice);
      }
    }

    for (final mmt in _latestMmtRows) {
      final mmtId = (mmt['mmt_id'] ?? '').toString().trim();
      final ipAddress = (mmt['ip_address'] ?? '').toString().trim();
      final locationName = (mmt['location'] ?? '').toString().trim();
      if (mmtId.isEmpty || locationName.isEmpty) {
        continue;
      }

      final mmtAsDevice = AddedDevice(
        id: 'mmt_${(mmt['id'] ?? mmtId).toString()}',
        type: 'MMT',
        name: mmtId,
        ipAddress: ipAddress,
        locationName: locationName,
        latitude: 0,
        longitude: 0,
        containerYard: (mmt['container_yard'] ?? '').toString(),
        createdAt: DateTime.now(),
        status: (mmt['status'] ?? 'DOWN').toString().toUpperCase(),
      );

      final key =
          '${mmtAsDevice.type.toUpperCase()}|${mmtAsDevice.ipAddress.trim().toUpperCase()}|${mmtAsDevice.locationName.toUpperCase()}';
      if (existingKeys.add(key)) {
        merged.add(mmtAsDevice);
      }
    }

    return merged;
  }

  // ═══════════════════════════════════════════════════════════════
  // TOWER POSITION UPDATE - FREEROAM CALLBACK
  // ═══════════════════════════════════════════════════════════════
  Future<void> _handleTowerPositionUpdate(
    String towerId,
    double newLatitude,
    double newLongitude,
  ) async {
    try {
      // Find tower
      final towerIndex = towers.indexWhere((t) => t.towerId == towerId);
      if (towerIndex == -1) return;

      final tower = towers[towerIndex];

      // ────────────────────────────────────────────────────────────
      // VALIDATE POSITION
      // ────────────────────────────────────────────────────────────
      final validationResult = await apiService.validateTowerPosition(
        tower.containerYard,
        newLatitude,
        newLongitude,
      );

      if (validationResult['success'] == true &&
          validationResult['valid'] == false) {
        print('⚠️ Position validation failed - outside bounds');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ Position outside allowed bounds for this yard'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // ────────────────────────────────────────────────────────────
      // UPDATE UI IMMEDIATELY
      // ────────────────────────────────────────────────────────────
      setState(() {
        towers[towerIndex] = Tower(
          id: tower.id,
          towerId: tower.towerId,
          towerNumber: tower.towerNumber,
          location: tower.location,
          ipAddress: tower.ipAddress,
          status: tower.status,
          containerYard: tower.containerYard,
          createdAt: tower.createdAt,
          updatedAt: tower.updatedAt,
          latitude: newLatitude,
          longitude: newLongitude,
        );

        // Keep master location point in sync immediately so grouped devices follow tower drag in UI.
        final towerCode = tower.towerId.toUpperCase();
        final masterIdx = masterLocations.indexWhere((m) {
          final type = (m['location_type'] ?? '').toString().toUpperCase();
          final code = (m['location_code'] ?? '').toString().toUpperCase();
          final name = (m['location_name'] ?? '').toString().toUpperCase();
          return type == 'TOWER' && (code == towerCode || name == towerCode);
        });

        if (masterIdx >= 0) {
          masterLocations[masterIdx] = {
            ...masterLocations[masterIdx],
            'latitude': newLatitude,
            'longitude': newLongitude,
          };
        }
      });

      // ────────────────────────────────────────────────────────────
      // SAVE TO DATABASE WITH HISTORY
      // ────────────────────────────────────────────────────────────
      final result = await apiService.updateTowerPositionWithHistory(
        tower.id,
        newLatitude,
        newLongitude,
        changedBy: 'freeroam_drag',
        changeReason: 'Position updated via map drag (freeroam mode)',
      );

      if (!result['success']) {
        print(
            '⚠️ Warning: Failed to save position to database: ${result['message']}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Position updated locally but DB save failed: ${result['message']}')),
        );
      } else {
        print('✓ Tower position updated and saved to database');
      }
    } catch (e) {
      print('Error handling tower position update: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating tower position: $e')),
      );
    }
  }

  String _normalizeMasterKey(String value) {
    return value.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
  }

  Future<void> _handleMasterPositionUpdate(
    Map<String, dynamic> master,
    double newLatitude,
    double newLongitude,
  ) async {
    final itemId = int.tryParse((master['item_id'] ?? '').toString());
    if (itemId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Master location tidak memiliki item_id. Tidak bisa disimpan.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final locType = (master['location_type'] ?? '').toString().toUpperCase();
    final codeKey =
        _normalizeMasterKey((master['location_code'] ?? '').toString());
    final nameKey =
        _normalizeMasterKey((master['location_name'] ?? '').toString());

    setState(() {
      final idx = masterLocations.indexWhere(
        (m) => (m['item_id'] ?? '').toString() == itemId.toString(),
      );

      if (idx >= 0) {
        masterLocations[idx] = {
          ...masterLocations[idx],
          'latitude': newLatitude,
          'longitude': newLongitude,
        };
      }

      if (locType == 'TOWER') {
        for (var i = 0; i < towers.length; i++) {
          final tower = towers[i];
          final towerIdKey = _normalizeMasterKey(tower.towerId);
          final towerLocKey = _normalizeMasterKey(tower.location);
          final isMatch = (codeKey.isNotEmpty &&
                  (towerIdKey.contains(codeKey) ||
                      towerLocKey.contains(codeKey))) ||
              (nameKey.isNotEmpty &&
                  (towerIdKey.contains(nameKey) ||
                      towerLocKey.contains(nameKey)));

          if (!isMatch) continue;

          towers[i] = Tower(
            id: tower.id,
            towerId: tower.towerId,
            towerNumber: tower.towerNumber,
            location: tower.location,
            ipAddress: tower.ipAddress,
            status: tower.status,
            containerYard: tower.containerYard,
            createdAt: tower.createdAt,
            updatedAt: tower.updatedAt,
            latitude: newLatitude,
            longitude: newLongitude,
          );
          break;
        }
      }
    });

    final saveMasterResult = await apiService.updateMasterLocation(itemId, {
      'latitude': newLatitude,
      'longitude': newLongitude,
    });

    if (!saveMasterResult['success']) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Gagal simpan posisi master: ${saveMasterResult['message']}'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    if (locType == 'TOWER') {
      Tower? matchedTower;
      try {
        matchedTower = towers.firstWhere((tower) {
          final towerIdKey = _normalizeMasterKey(tower.towerId);
          final towerLocKey = _normalizeMasterKey(tower.location);
          return (codeKey.isNotEmpty &&
                  (towerIdKey.contains(codeKey) ||
                      towerLocKey.contains(codeKey))) ||
              (nameKey.isNotEmpty &&
                  (towerIdKey.contains(nameKey) ||
                      towerLocKey.contains(nameKey)));
        });
      } catch (_) {
        matchedTower = null;
      }

      if (matchedTower != null) {
        await apiService.updateTowerPositionWithHistory(
          matchedTower.id,
          newLatitude,
          newLongitude,
          changedBy: 'freeroam_drag_master',
          changeReason: 'Master Tower Position Updated Via Freeroam',
        );
      }
    }
  }

  void _centerMapToTPK() {
    final points = [
      TPKNilamLocation.coordinate,
      ...containerYards.map((c) => c.coordinate),
      ...deviceLocationPoints.map((d) => d.coordinate),
      ...towerPoints.map((t) => t.coordinate),
      ...specialLocations.map((s) => s.coordinate),
    ];

    if (points.isEmpty) {
      mapController.move(
          TPKNilamLocation.coordinate, TPKNilamLocation.defaultZoom);
      return;
    }

    final bounds = LatLngBounds.fromPoints(points);
    mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(80),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2C3E50),
      body: Column(
        children: [
          const GlobalHeaderBar(
            currentRoute: '/dashboard',
          ),
          Expanded(
            child: _buildContent(context),
          ),
          const GlobalFooter(),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final isMobile = isMobileScreen(context);

    if (isMobile) {
      return SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              SizedBox(
                height: 500,
                child: LiveTerminalMap(
                  devices: _buildLayoutDevices(),
                  towers: towers,
                  masterLocations: masterLocations,
                  isPickMode: _isPickTowerMode,
                  pickYardFilter: _pickTowerYard,
                  onAreaPicked: _handleAreaPickedForTower,
                  onTowerMoved: _handleTowerPositionUpdate,
                  onMasterMoved: _handleMasterPositionUpdate,
                  onTriggerPingCheck: _triggerPingCheck,
                  onLoadDashboardData: _loadDashboardData,
                ),
              ),
              const SizedBox(height: 16),
              _buildDashboardStatsBottom(context, isMobile: true),
            ],
          ),
        ),
      );
    }

    return GlobalSidebarNav(
      currentRoute: '/dashboard',
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final mapHeight = constraints.maxWidth > 1400 ? 580.0 : 490.0;

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: mapHeight,
                    child: LiveTerminalMap(
                      devices: _buildLayoutDevices(),
                      towers: towers,
                      masterLocations: masterLocations,
                      isPickMode: _isPickTowerMode,
                      pickYardFilter: _pickTowerYard,
                      onAreaPicked: _handleAreaPickedForTower,
                      onTowerMoved: _handleTowerPositionUpdate,
                      onMasterMoved: _handleMasterPositionUpdate,
                      onTriggerPingCheck: _triggerPingCheck,
                      onLoadDashboardData: _loadDashboardData,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildDashboardStatsBottom(
                    context,
                    isMobile: false,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDashboardStatsBottom(BuildContext context,
      {required bool isMobile}) {
    if (isMobile) {
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          SizedBox(
              width: double.infinity,
              child: NetworkStatusCard(
                  totalOnline: totalOnlineTowers, totalDown: totalDownTowers)),
          SizedBox(
              width: double.infinity,
              child: CCTVMonitoringCard(
                  totalUp: totalUpCameras, totalDown: totalDownCameras)),
          SizedBox(
              width: double.infinity,
              child: MMTMonitoringCard(
                  totalUp: totalUpMMT, totalDown: totalDownMMT)),
          SizedBox(
              width: double.infinity,
              child: ActiveAlertsCard(totalWarnings: totalWarnings)),
        ],
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompactDesktop = constraints.maxWidth < 1300;

        if (!isCompactDesktop) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                  child: NetworkStatusCard(
                      totalOnline: totalOnlineTowers,
                      totalDown: totalDownTowers)),
              const SizedBox(width: 12),
              Expanded(
                  child: CCTVMonitoringCard(
                      totalUp: totalUpCameras, totalDown: totalDownCameras)),
              const SizedBox(width: 12),
              Expanded(
                  child: MMTMonitoringCard(
                      totalUp: totalUpMMT, totalDown: totalDownMMT)),
              const SizedBox(width: 12),
              Expanded(child: ActiveAlertsCard(totalWarnings: totalWarnings)),
            ],
          );
        }

        final cardWidth = (constraints.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
                width: cardWidth,
                child: NetworkStatusCard(
                    totalOnline: totalOnlineTowers,
                    totalDown: totalDownTowers)),
            SizedBox(
                width: cardWidth,
                child: CCTVMonitoringCard(
                    totalUp: totalUpCameras, totalDown: totalDownCameras)),
            SizedBox(
                width: cardWidth,
                child: MMTMonitoringCard(
                    totalUp: totalUpMMT, totalDown: totalDownMMT)),
            SizedBox(
                width: cardWidth,
                child: ActiveAlertsCard(totalWarnings: totalWarnings)),
          ],
        );
      },
    );
  }

  // Navigate to CCTV page based on Container Yard ID
  void _navigateToCCTV(BuildContext context, String cyId) {
    String route = '/cctv';
    if (cyId == 'CY2') {
      route = '/cctv-cy2';
    } else if (cyId == 'CY3') {
      route = '/cctv-cy3';
    }
    navigateWithLoading(context, route);
  }

  // Navigate to Gate or Parking CCTV
  void _navigateToSpecialLocation(BuildContext context, String locationId) {
    String route = '/cctv-gate';
    if (locationId == 'PARKING') {
      route = '/cctv-parking';
    }
    navigateWithLoading(context, route);
  }

  void _showDevicesAtLocation(
      BuildContext context, double latitude, double longitude) {
    // Find all devices at this location
    final devicesAtLocation = addedDevices
        .where((d) => d.latitude == latitude && d.longitude == longitude)
        .toList();

    if (devicesAtLocation.isEmpty) {
      return;
    }

    if (devicesAtLocation.length == 1) {
      // If only one device, navigate directly
      _navigateAddedDevice(context, devicesAtLocation.first);
      return;
    }

    // Show dialog with list of devices at this location
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, animation, secondaryAnimation) {
        return ScaleTransition(
          scale: animation,
          child: Center(
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: 400,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 10,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Devices at this Location',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Latitude: ${latitude.toStringAsFixed(6)}\n'
                      'Longitude: ${longitude.toStringAsFixed(6)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 300),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: devicesAtLocation.length,
                        itemBuilder: (context, index) {
                          final device = devicesAtLocation[index];
                          return GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                              _navigateAddedDevice(context, device);
                            },
                            child: MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: device.status == 'UP'
                                        ? Colors.green
                                        : Colors.red,
                                    width: 2,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      _getDeviceIcon(device.type),
                                      color: device.status == 'UP'
                                          ? Colors.green
                                          : Colors.red,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            device.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${device.type} • ${device.status}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.black54,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(
                                      Icons.arrow_forward_ios,
                                      size: 16,
                                      color: Colors.black54,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[300],
                            foregroundColor: Colors.black,
                          ),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _navigateAddedDevice(BuildContext context, AddedDevice device) {
    final type = device.type;
    if (type == 'Access Point' || type == 'Tower') {
      String route = '/network';
      if (device.containerYard == 'CY2') {
        route = '/network-cy2';
      } else if (device.containerYard == 'CY3') {
        route = '/network-cy3';
      }
      navigateWithLoading(context, route);
      return;
    }

    if (type == 'CCTV') {
      final location = device.locationName.toLowerCase();
      String route = '/cctv';
      if (location.contains('gate')) {
        route = '/cctv-gate';
      } else if (location.contains('parking')) {
        route = '/cctv-parking';
      } else if (device.containerYard == 'CY2') {
        route = '/cctv-cy2';
      } else if (device.containerYard == 'CY3') {
        route = '/cctv-cy3';
      }
      navigateWithLoading(context, route);
      return;
    }

    // MMT: no dedicated page yet, show detail info
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${device.name} (MMT) - ${device.status}'),
        duration: const Duration(seconds: 2),
        backgroundColor: device.status == 'UP' ? Colors.green : Colors.red,
      ),
    );
  }

  Widget _buildMinimalHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1A237E).withOpacity(0.9),
            const Color(0xFF0D47A1).withOpacity(0.9),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            Icons.monitor_heart,
            color: Colors.white,
            size: 32,
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TPK Nilam Monitoring',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Real-time Dashboard',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const Spacer(),
          // Status indicators
          _buildHeaderStatusBadge(
            'Towers',
            '$totalOnlineTowers/$totalTowers',
            totalDownTowers > 0 ? Colors.red : Colors.green,
          ),
          const SizedBox(width: 12),
          _buildHeaderStatusBadge(
            'Cameras',
            '$totalUpCameras/$totalCameras',
            totalDownCameras > 0 ? Colors.orange : Colors.green,
          ),
          const SizedBox(width: 12),
          _buildHeaderStatusBadge(
            'Alerts',
            '$totalActiveAlerts',
            totalActiveAlerts > 0 ? Colors.red : Colors.green,
          ),
          const SizedBox(width: 16),
          // Profile button
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfilePage()),
              );
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(
                Icons.person,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderStatusBadge(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // Keep old header for reference/backup
  Widget _buildHeader(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return Container(
      width: screenWidth,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      color: const Color(0xFF1976D2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Terminal Nilam - FIXED
          const Text(
            'Terminal Nilam',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 30),
          // Buttons + Profile - SCROLL HORIZONTAL
          Expanded(
            child: ScrollConfiguration(
              behavior:
                  ScrollConfiguration.of(context).copyWith(scrollbars: false),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildHeaderOpenButton(
                        'Add New Device', const AddDevicePage()),
                    const SizedBox(width: 12),
                    _buildHeaderOpenButton(
                        'Master Data', const TowerManagementPage()),
                    const SizedBox(width: 12),
                    _buildHeaderOpenButton('Dashboard', const DashboardPage(),
                        isActive: true),
                    const SizedBox(width: 12),
                    _buildHeaderOpenButton('Access Point', const NetworkPage()),
                    const SizedBox(width: 12),
                    _buildHeaderOpenButton('CCTV', const CCTVPage()),
                    const SizedBox(width: 12),
                    _buildHeaderOpenButton('MMT', const MMTMonitoringPage()),
                    const SizedBox(width: 12),
                    _buildHeaderOpenButton('Alert', const AlertsPage()),
                    const SizedBox(width: 12),
                    _buildHeaderOpenButton('Alert Report', const ReportPage()),
                    const SizedBox(width: 12),
                    _buildHeaderButton(
                        'Logout', () => _showLogoutDialog(context)),
                    const SizedBox(width: 12),
                    // Profile Icon
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const ProfilePage()),
                        );
                      },
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(50),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.person,
                            color: Color(0xFF1976D2),
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderButton(String text, VoidCallback onPressed,
      {bool isActive = false}) {
    return GestureDetector(
      onTap: onPressed,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(25),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              decoration: BoxDecoration(
                color: isActive
                    ? Colors.white.withOpacity(0.8)
                    : Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                  color:
                      isActive ? Colors.black : Colors.white.withOpacity(0.9),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderOpenButton(String text, Widget openPage,
      {bool isActive = false}) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => openPage),
        );
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(25),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              decoration: BoxDecoration(
                color: isActive
                    ? Colors.white.withOpacity(0.8)
                    : Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                  color:
                      isActive ? Colors.black : Colors.white.withOpacity(0.9),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleAreaPickedForTower(String areaId, double relX, double relY) {
    if (!_isPickTowerMode) return;

    if (_pickTowerYard != null && _pickTowerYard != areaId) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Silakan pilih area $_pickTowerYard.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    Navigator.pop(context, {
      'containerYard': areaId,
      'lat': relX,
      'lng': relY,
    });
  }

  List<DeviceMarker> _buildDeviceMarkersForLayoutMap() {
    List<DeviceMarker> markers = [];

    // Add Towers from database
    for (var tower in towers) {
      if (tower.latitude != null && tower.longitude != null) {
        var pixel =
            LayoutMapper.latLngToPixel(tower.latitude!, tower.longitude!);
        markers.add(DeviceMarker(
          id: tower.towerId,
          name: tower.towerId,
          type: DeviceType.tower,
          status: tower.status,
          ipAddress: tower.ipAddress,
          latitude: tower.latitude!,
          longitude: tower.longitude!,
          pixelX: pixel.x,
          pixelY: pixel.y,
          containerYard: tower.containerYard,
          lastUpdated: DateTime.now(),
        ));
      }
    }

    // Add Cameras (CCTV) from database
    for (var camera in cameras) {
      if (camera.latitude != null && camera.longitude != null) {
        var pixel =
            LayoutMapper.latLngToPixel(camera.latitude!, camera.longitude!);
        markers.add(DeviceMarker(
          id: camera.cameraId,
          name: camera.cameraId,
          type: DeviceType.cctv,
          status: camera.status,
          ipAddress: camera.ipAddress,
          latitude: camera.latitude!,
          longitude: camera.longitude!,
          pixelX: pixel.x,
          pixelY: pixel.y,
          containerYard: camera.containerYard,
          lastUpdated: DateTime.now(),
        ));
      }
    }

    return markers;
  }

  Widget _buildActivityTimeline() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1976D2).withOpacity(0.8),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.timeline,
                        color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Activity Timeline',
                    style: TextStyle(
                      color: Colors.white, // Changed to white
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 100,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(50, (index) {
                    double height = 20 + (index % 5) * 15.0;
                    return Container(
                      width: 4,
                      height: height,
                      decoration: BoxDecoration(
                        color:
                            Colors.white.withOpacity(0.3), // Changed to white
                        borderRadius: BorderRadius.circular(2),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '00:00',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.6), fontSize: 12),
                  ),
                  Text(
                    '12:00',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.6), fontSize: 12),
                  ),
                  Text(
                    '23:59',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.6), fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout', style: TextStyle(color: Colors.black87)),
        content: const Text('Are You Sure To Logout?',
            style: TextStyle(color: Colors.black87)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text('Cancel', style: TextStyle(color: Colors.black87)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
