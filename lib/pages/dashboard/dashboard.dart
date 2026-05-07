import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:monitoring/main.dart';
import 'package:monitoring/services/api_service.dart';
import 'package:monitoring/models/camera_model.dart';
import 'package:monitoring/models/tower_model.dart';
import 'package:monitoring/models/mmt_model.dart';
import 'package:monitoring/models/alert_model.dart';
import 'package:monitoring/models/device_model.dart';
import 'package:monitoring/models/master_location_model.dart';
import 'package:monitoring/utils/tower_status_override.dart';
import 'package:monitoring/utils/location_label_utils.dart';
import 'package:monitoring/models/nvr_model.dart';
import 'package:monitoring/models/switch_model.dart';

import 'package:monitoring/widgets/global_header_bar.dart';
import 'package:monitoring/widgets/global_sidebar_nav.dart';
import 'package:monitoring/widgets/global_footer.dart';
import 'package:monitoring/widgets/dashboard/live_terminal_map.dart';
import 'package:monitoring/theme/app_dropdown_style.dart';
import 'package:monitoring/pages/dashboard/widgets/dashboard_stats_grid.dart';

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
  Map<String, String> deviceStatuses = {};
  Map<String, String> _mmtStatusByIp = {};
  
  bool _isPickTowerMode = false;
  String? _pickTowerYard;
  int totalUpMMT = 0;
  int totalDownMMT = 0;
  Timer? _refreshTimer;
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
  int totalUpNVR = 0;
  int totalDownNVR = 0;
  int totalUpSwitch = 0;
  int totalDownSwitch = 0;

  double get towerUptimePercent =>
      totalTowers == 0 ? 0 : (totalOnlineTowers / totalTowers) * 100;

  List<Alert> get activeAlerts => alerts
      .where((a) => a.severity == 'critical' || a.severity == 'warning')
      .toList();
  
  int get totalActiveAlerts => activeAlerts.length;

  @override
  void initState() {
    super.initState();
    mapController = MapController();
    apiService = ApiService();
    _startAutoRefresh();
    _loadDashboardData();
  }

  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        _loadDashboardData();
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
        _loadDashboardData();
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
    if (mounted) {
      _loadDashboardData();
    }
  }

  @override
  void didPopNext() {
    _loadDashboardData();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    if (_isRouteSubscribed) {
      routeObserver.unsubscribe(this);
    }
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════
  // DATA LOADING
  // ═══════════════════════════════════════════════════════════════

  Future<void> _loadDashboardData() async {
    if (_isLoadingDashboard) return;
    _isLoadingDashboard = true;

    try {
      final results = await Future.wait([
        apiService.getAllCameras().catchError((e) {
          debugPrint('Error fetching cameras: $e');
          return <Camera>[];
        }),
        apiService.getAllTowers().catchError((e) {
          debugPrint('Error fetching towers: $e');
          return <Tower>[];
        }),
        apiService.getAllAlerts().catchError((e) {
          debugPrint('Error fetching alerts: $e');
          return <String, dynamic>{'alerts': <Alert>[]};
        }),
        apiService.getAllMasterLocations().catchError((e) {
          debugPrint('Error fetching master locations: $e');
          return <Map<String, dynamic>>[];
        }),
        apiService.getDashboardStats().catchError((e) {
          debugPrint('Error fetching dashboard stats: $e');
          return <String, dynamic>{};
        }),
        apiService.getAllNVRs().catchError((e) {
          debugPrint('Error fetching NVRs: $e');
          return <NVR>[];
        }),
        apiService.getAllSwitches().catchError((e) {
          debugPrint('Error fetching Switches: $e');
          return <SwitchModel>[];
        }),
      ]);

      // Move ping check to AFTER data fetch so it doesn't block main requests
      _triggerPingCheck().catchError((e) => debugPrint('Ping error: $e'));

      final fetchedCameras = results[0] as List<Camera>;
      final fetchedTowers = results[1] as List<Tower>;
      final alertsResponse = results[2] as Map<String, dynamic>;
      final fetchedMasterLocations = results[3] as List<Map<String, dynamic>>;

      final fetchedMmts = await apiService.getAllMMTs().catchError((e) {
        debugPrint('Error fetching MMTs: $e');
        return <MMT>[];
      });

      final fetchedNvrs = results[5] as List<NVR>;
      final fetchedSwitches = results[6] as List<SwitchModel>;

      await _updateDeviceLocationStatuses();

      final updatedTowers = applyForcedTowerStatus(fetchedTowers);
      final updatedCameras = applyForcedCameraStatus(fetchedCameras);
      final ipStatus = _buildIpStatusMap(updatedTowers, updatedCameras, fetchedNvrs, fetchedSwitches);
      final effectiveTowers = _applyIpStatusToTowers(updatedTowers, ipStatus);
      final effectiveCameras = _applyIpStatusToCameras(updatedCameras, ipStatus);
      
      final List<Alert> generatedAlerts = [];

      // Generate local alerts for down devices
      for (final tower in effectiveTowers) {
        if (isDownStatus(tower.status)) {
          String route = '/network';
          if (tower.containerYard == 'CY2') route = '/network-cy2';
          if (tower.containerYard == 'CY3') route = '/network-cy3';

          generatedAlerts.add(Alert(
            id: int.tryParse(tower.id.toString()) ?? 0,
            alertKey: 'generated:${tower.id}:${tower.towerId}:AP_DOWN',
            title: 'Access Point DOWN - ${tower.towerId}',
            description: '${tower.location} access point offline (${tower.towerId})',
            severity: 'critical',
            timestamp: tower.updatedAt.isNotEmpty ? tower.updatedAt : DateTime.now().toString(),
            route: route,
            category: 'Access Point',
          ));
        }
      }

      for (final camera in effectiveCameras) {
        if (isDownStatus(camera.status)) {
          String route = '/cctv';
          if (camera.containerYard == 'CY2') route = '/cctv-cy2';
          if (camera.containerYard == 'CY3') route = '/cctv-cy3';

          generatedAlerts.add(Alert(
            id: (int.tryParse(camera.id.toString()) ?? 0) + 1000,
            alertKey: 'generated:${camera.id + 1000}:${camera.cameraId}:CCTV_DOWN',
            title: 'CCTV DOWN - ${camera.cameraId}',
            description: '${camera.location} camera offline (${camera.cameraId})',
            severity: 'critical',
            timestamp: camera.updatedAt.isNotEmpty ? camera.updatedAt : DateTime.now().toString(),
            route: route,
            category: 'CCTV',
          ));
        }
      }

      for (final nvr in fetchedNvrs) {
        if (isDownStatus(nvr.status)) {
          generatedAlerts.add(Alert(
            id: (int.tryParse(nvr.id.toString()) ?? 0) + 2000,
            alertKey: 'generated:${nvr.id + 2000}:${nvr.nvrId}:NVR_DOWN',
            title: 'NVR DOWN - ${nvr.nvrId}',
            description: '${nvr.location} NVR offline (${nvr.nvrId})',
            severity: 'critical',
            timestamp: DateTime.now().toString(),
            route: '/nvr-monitoring-${nvr.containerYard.toLowerCase().replaceAll(' ', '')}',
            category: 'NVR',
          ));
        }
      }

      for (final sw in fetchedSwitches) {
        if (isDownStatus(sw.status)) {
          generatedAlerts.add(Alert(
            id: (int.tryParse(sw.id.toString()) ?? 0) + 3000,
            alertKey: 'generated:${sw.id + 3000}:${sw.switchId}:SWITCH_DOWN',
            title: 'SWITCH DOWN - ${sw.switchId}',
            description: '${sw.location} Switch offline (${sw.switchId})',
            severity: 'critical',
            timestamp: DateTime.now().toString(),
            route: '/switch-monitoring-${sw.containerYard.toLowerCase().replaceAll(' ', '')}',
            category: 'Switch',
          ));
        }
      }

      final List<AddedDevice> devices = [];
      final Set<String> seenDeviceKeys = <String>{};
      
      // Prepare master location options for matching
      final masterOptions = buildMasterLocationOptions(fetchedMasterLocations);

      void addUniqueDevice(AddedDevice d) {
        if (d.ipAddress.trim().isEmpty && d.name.trim().isEmpty) return;
        
        final String ipKey = d.ipAddress.trim().toUpperCase();
        final String nameKey = d.name.trim().toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
        
        // Resolve location name to match master data if possible
        final matchedOption = matchMasterLocationOption(
          masterOptions, 
          d.locationName,
          currentContainerYard: d.containerYard,
        );
        
        final String effectiveLocationName = matchedOption != null 
            ? (matchedOption['label'] ?? d.locationName) 
            : d.locationName;
        
        final String locKey = normalizeLocationMatchKey(effectiveLocationName);
        
        // Include both IP/Name AND device name/ID to allow multiple devices at same location
        // This prevents AP 02 and AP 03 (both at RTG-RTG2) from being deduplicated
        // Include type in key to prevent MMTs from being deduplicated if they share IP/Name with a Tower/CCTV
        final String key = (ipKey.isNotEmpty && ipKey != '0.0.0.0' && ipKey != '127.0.0.1')
            ? 'IP|${d.type}|$ipKey|$locKey|$nameKey'
            : 'NAME|${d.type}|$nameKey|$locKey|${d.id}';

        if (seenDeviceKeys.add(key)) {
          devices.add(AddedDevice(
            id: d.id,
            type: d.type,
            name: d.name,
            ipAddress: d.ipAddress,
            locationName: effectiveLocationName,
            latitude: d.latitude,
            longitude: d.longitude,
            containerYard: d.containerYard,
            createdAt: d.createdAt,
            status: d.status,
          ));
        }
      }

      for (final Tower tower in updatedTowers) { 
        final bool isAP = tower.towerId.toUpperCase().startsWith('AP') || 
                         tower.location.toUpperCase().contains('AP');
        
        final String effectiveType = isAP ? 'Access Point' : 'Tower';
        final String displayName = tower.towerId; 

        addUniqueDevice(AddedDevice(
          id: 'tower_${tower.id}',
          type: effectiveType,
          name: displayName,
          ipAddress: tower.ipAddress,
          locationName: tower.location,
          latitude: tower.latitude ?? 0.0,
          longitude: tower.longitude ?? 0.0,
          containerYard: tower.containerYard,
          createdAt: DateTime.tryParse(tower.createdAt) ?? DateTime.now(),
          status: tower.status,
        ));
      }
      for (final Camera camera in updatedCameras) {
        addUniqueDevice(AddedDevice(
          id: 'camera_${camera.id}',
          type: 'CCTV',
          name: camera.cameraId,
          ipAddress: camera.ipAddress,
          locationName: camera.location,
          latitude: camera.latitude ?? 0.0,
          longitude: camera.longitude ?? 0.0,
          containerYard: camera.containerYard,
          createdAt: DateTime.tryParse(camera.createdAt) ?? DateTime.now(),
          status: camera.status,
        ));
      }
      for (final MMT mmt in fetchedMmts) {
        // Force type to 'MMT' for all items from the MMT table to ensure 
        // they are counted correctly in the MMT Monitoring card.
        String displayType = 'MMT';
        
        addUniqueDevice(AddedDevice(
          id: 'mmt_${mmt.id}',
          type: displayType,
          name: mmt.mmtId,
          ipAddress: mmt.ipAddress,
          locationName: mmt.location,
          latitude: 0.0,
          longitude: 0.0,
          containerYard: mmt.containerYard,
          createdAt: DateTime.tryParse(mmt.createdAt) ?? DateTime.now(),
          status: deviceStatuses[mmt.mmtId] ?? mmt.status,
        ));
      }

      for (final NVR nvr in fetchedNvrs) {
        addUniqueDevice(AddedDevice(
          id: 'nvr_${nvr.id}',
          type: 'NVR',
          name: nvr.nvrId,
          ipAddress: nvr.ipAddress,
          locationName: nvr.location,
          latitude: nvr.latitude ?? 0.0,
          longitude: nvr.longitude ?? 0.0,
          containerYard: nvr.containerYard,
          createdAt: DateTime.tryParse(nvr.createdAt) ?? DateTime.now(),
          status: nvr.status,
        ));
      }

      for (final SwitchModel sw in fetchedSwitches) {
        addUniqueDevice(AddedDevice(
          id: 'switch_${sw.id}',
          type: 'SWITCH',
          name: sw.switchId,
          ipAddress: sw.ipAddress,
          locationName: sw.location,
          latitude: sw.latitude ?? 0.0,
          longitude: sw.longitude ?? 0.0,
          containerYard: sw.containerYard,
          createdAt: DateTime.tryParse(sw.createdAt) ?? DateTime.now(),
          status: sw.status,
        ));
      }

      final fetchedAlerts = (alertsResponse['alerts'] as List? ?? [])
          .map((e) => e is Alert ? e : Alert.fromJson(e as Map<String, dynamic>))
          .toList();
      
      final activeAlertsList = await apiService.filterActiveAlerts(
        fetchedAlerts,
        effectiveTowers,
        effectiveCameras,
        devices,
      );

      if (mounted) {
        setState(() {
          cameras = effectiveCameras;
          towers = effectiveTowers;
          masterLocations = fetchedMasterLocations;
          addedDevices = devices;

          // Calculate stats locally from fetched data for consistency
          totalTowers = effectiveTowers.length;
          totalOnlineTowers = effectiveTowers.where((t) => !isDownStatus(t.status)).length;
          totalDownTowers = (totalTowers - totalOnlineTowers).clamp(0, 999999);

          totalUpCameras = effectiveCameras.where((c) => !isDownStatus(c.status)).length;
          totalDownCameras = (effectiveCameras.length - totalUpCameras).clamp(0, 999999);

          totalUpMMT = fetchedMmts.where((m) => !isDownStatus(deviceStatuses[m.mmtId] ?? m.status)).length;
          totalDownMMT = (fetchedMmts.length - totalUpMMT).clamp(0, 999999);

          totalUpNVR = fetchedNvrs.where((n) => !isDownStatus(n.status)).length;
          totalDownNVR = (fetchedNvrs.length - totalUpNVR).clamp(0, 999999);

          totalUpSwitch = fetchedSwitches.where((s) => !isDownStatus(s.status)).length;
          totalDownSwitch = (fetchedSwitches.length - totalUpSwitch).clamp(0, 999999);

          final combined = [...activeAlertsList, ...generatedAlerts];
          final uniqueAlerts = <String, Alert>{};
          for (final a in combined) {
            String devName = a.title;
            if (devName.contains(' - ')) {
              devName = devName.split(' - ').last.trim();
            }
            devName = devName.replaceAll(RegExp(r'(Access\sPoint|CCTV|MMT|NVR|SWITCH)\s+DOWN\s+-\s+', caseSensitive: false), '').trim();
            if (!uniqueAlerts.containsKey(devName) || a.severity == 'critical') {
              uniqueAlerts[devName] = a;
            }
          }
          alerts = uniqueAlerts.values.toList()..sort((a, b) => b.timestamp.compareTo(a.timestamp));
          totalWarnings = alerts.length;
        });
      }
    } catch (e) {
      debugPrint('Error loading dashboard data: $e');
    } finally {
      _isLoadingDashboard = false;
    }
  }

  Future<void> _updateDeviceLocationStatuses() async {
    try {
      final response = await http.get(Uri.parse('${ApiService.baseUrl}?endpoint=mmt&action=all'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final List<dynamic> mmtList = data['data'];
          deviceStatuses.clear();
          final mmtStatusByIp = <String, String>{};

          for (var mmt in mmtList) {
            final mmtId = mmt['mmt_id']?.toString() ?? '';
            final id = mmtId.isNotEmpty ? mmtId : (mmt['id']?.toString() ?? '');
            final ip = mmt['ip_address']?.toString() ?? '';
            final status = mmt['status']?.toString().toUpperCase() ?? 'DOWN';
            
            if (id.isNotEmpty) {
              deviceStatuses[id] = status;
            }
            if (ip.isNotEmpty) {
              _mergeIpStatus(mmtStatusByIp, ip, status);
            }
          }

          _mmtStatusByIp = mmtStatusByIp;
        }
      }
    } catch (e) {
      debugPrint('Error updating MMT statuses: $e');
    }
  }

  Future<void> _triggerPingCheck({bool force = false}) async {
    final now = DateTime.now();
    if (_isPingInProgress || (!force && _lastPingCheckAt != null && now.difference(_lastPingCheckAt!) < _pingCheckInterval)) {
      return;
    }
    
    _isPingInProgress = true;
    _lastPingCheckAt = now;
    try {
      await http.get(Uri.parse('${ApiService.baseUrl}?endpoint=realtime&action=all')).timeout(const Duration(seconds: 10));
    } catch (e) {
      debugPrint('Ping check failed: $e');
    } finally {
      _isPingInProgress = false;
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════

  void _mergeIpStatus(Map<String, String> map, String ip, String status) {
    if (ip.isEmpty) return;
    final normalized = status.toUpperCase();
    if (normalized == 'UP' || map[ip] == null) {
      map[ip] = normalized;
    }
  }

  Map<String, String> _buildIpStatusMap(List<Tower> towers, List<Camera> cameras, List<NVR> nvrs, List<SwitchModel> switches) {
    final map = <String, String>{};
    for (var t in towers) {
      _mergeIpStatus(map, t.ipAddress.trim(), t.status);
    }
    for (var c in cameras) {
      _mergeIpStatus(map, c.ipAddress.trim(), c.status);
    }
    for (var n in nvrs) {
      _mergeIpStatus(map, n.ipAddress.trim(), n.status);
    }
    for (var s in switches) {
      _mergeIpStatus(map, s.ipAddress.trim(), s.status);
    }
    _mmtStatusByIp.forEach((ip, status) => _mergeIpStatus(map, ip, status));
    return map;
  }

  List<Tower> _applyIpStatusToTowers(List<Tower> towers, Map<String, String> ipStatus) {
    return towers.map((t) {
      final forced = ipStatus[t.ipAddress.trim()];
      return forced != null && t.status.toUpperCase() != forced ? Tower(
        id: t.id, towerId: t.towerId, towerNumber: t.towerNumber, location: t.location,
        ipAddress: t.ipAddress, status: forced, containerYard: t.containerYard,
        createdAt: t.createdAt, updatedAt: t.updatedAt, latitude: t.latitude, longitude: t.longitude,
      ) : t;
    }).toList();
  }

  List<Camera> _applyIpStatusToCameras(List<Camera> cameras, Map<String, String> ipStatus) {
    return cameras.map((c) {
      final forced = ipStatus[c.ipAddress.trim()];
      return forced != null && c.status.toUpperCase() != forced ? Camera(
        id: c.id, cameraId: c.cameraId, location: c.location, ipAddress: c.ipAddress,
        status: forced, type: c.type, containerYard: c.containerYard, areaType: c.areaType,
        createdAt: c.createdAt, updatedAt: c.updatedAt, latitude: c.latitude, longitude: c.longitude,
      ) : c;
    }).toList();
  }

  List<AddedDevice> _buildLayoutDevices() {
    final merged = <AddedDevice>[...addedDevices];
    final existingKeys = merged.map((d) => '${d.type.toUpperCase()}|${d.ipAddress.trim().toUpperCase()}|${d.locationName.toUpperCase()}').toSet();

    for (final camera in cameras) {
      if (camera.location.trim().isEmpty) continue;
      final dev = AddedDevice(
        id: 'camera_${camera.id}', type: 'CCTV', name: camera.cameraId, ipAddress: camera.ipAddress,
        locationName: camera.location, latitude: camera.latitude ?? 0, longitude: camera.longitude ?? 0,
        containerYard: camera.containerYard, createdAt: DateTime.tryParse(camera.createdAt) ?? DateTime.now(), status: camera.status,
      );
      if (existingKeys.add('${dev.type.toUpperCase()}|${dev.ipAddress.trim().toUpperCase()}|${dev.locationName.toUpperCase()}')) merged.add(dev);
    }
    return merged;
  }

  // ═══════════════════════════════════════════════════════════════
  // HANDLERS
  // ═══════════════════════════════════════════════════════════════

  void _handleAreaPickedForTower(String areaId, double relX, double relY) {
    if (!_isPickTowerMode || (_pickTowerYard != null && _pickTowerYard != areaId)) return;
    
    // Return picked position to the caller (e.g. TowerManagement)
    Navigator.pop(context, {
      'lat': relX,
      'lng': relY,
      'containerYard': areaId,
    });
  }

  Future<void> _handleTowerPositionUpdate(String towerId, double lat, double lon) async {
    final idx = towers.indexWhere((t) => t.towerId == towerId);
    if (idx == -1) return;
    
    final tower = towers[idx];
    final validation = await apiService.validateTowerPosition(tower.containerYard, lat, lon);
    if (validation['success'] == true && validation['valid'] == false) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚠️ Position outside bounds'), backgroundColor: Colors.orange));
      return;
    }

    setState(() {
      towers[idx] = Tower(
        id: tower.id, towerId: tower.towerId, towerNumber: tower.towerNumber, location: tower.location,
        ipAddress: tower.ipAddress, status: tower.status, containerYard: tower.containerYard,
        createdAt: tower.createdAt, updatedAt: tower.updatedAt, latitude: lat, longitude: lon,
      );
    });
    await apiService.updateTowerPositionWithHistory(tower.id, lat, lon, changedBy: 'map_drag');
  }

  Future<void> _handleMasterPositionUpdate(MasterLocation master, double lat, double lon) async {
    final itemId = master.itemId;
    if (itemId == null) return;
    
    setState(() {
      final idx = masterLocations.indexWhere((m) => m['item_id']?.toString() == itemId);
      if (idx != -1) masterLocations[idx] = {...masterLocations[idx], 'latitude': lat, 'longitude': lon};
    });
    await apiService.updateMasterLocationPosition(int.parse(itemId), lat, lon);
  }

  void _navigateAddedDevice(BuildContext context, AddedDevice device) {
    String route = '';
    if (device.type == 'Tower' || device.type == 'Access Point') {
      route = device.containerYard == 'CY2' ? '/network-cy2' : (device.containerYard == 'CY3' ? '/network-cy3' : '/network');
    } else if (device.type == 'CCTV') {
      final loc = device.locationName.toLowerCase();
      if (loc.contains('gate')) {
        route = '/cctv-gate';
      } else if (loc.contains('parking')) {
        route = '/cctv-parking';
      } else {
        route = device.containerYard == 'CY2' ? '/cctv-cy2' : (device.containerYard == 'CY3' ? '/cctv-cy3' : '/cctv');
      }
    } else if (device.type == 'NVR') {
      final yard = device.containerYard.toLowerCase().replaceAll(' ', '');
      route = '/nvr-monitoring-$yard';
    } else if (device.type == 'Switch' || device.type == 'SWITCH') {
      final yard = device.containerYard.toLowerCase().replaceAll(' ', '');
      route = '/switch-monitoring-$yard';
    }

    if (route.isNotEmpty) {
      Navigator.pushNamed(context, route);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${device.name} (${device.type}) - ${device.status}'), backgroundColor: device.status == 'UP' ? Colors.green : Colors.red));
    }
  }

  bool isMobileScreen(BuildContext context) => MediaQuery.of(context).size.width < 600;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppDropdownStyle.standardPageBackground,
      body: Column(
        children: [
          const GlobalHeaderBar(currentRoute: '/dashboard'),
          Expanded(child: _buildContent(context)),
          const GlobalFooter(),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final isMobile = isMobileScreen(context);
    return GlobalSidebarNav(
      currentRoute: '/dashboard',
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 12.0 : 24.0),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final mapHeight = isMobile ? 450.0 : (constraints.maxWidth > 1400 ? 520.0 : 450.0);
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: mapHeight,
                    child: LiveTerminalMap(
                      devices: _buildLayoutDevices(), 
                      towers: towers, 
                      masterLocations: masterLocations.map((m) => MasterLocation.fromMap(m)).toList(),
                      isPickMode: _isPickTowerMode, 
                      pickYardFilter: _pickTowerYard,
                      onAreaPicked: _handleAreaPickedForTower, 
                      onTowerMoved: _handleTowerPositionUpdate,
                      onMasterMoved: _handleMasterPositionUpdate, 
                      onTriggerPingCheck: _triggerPingCheck,
                      onLoadDashboardData: _loadDashboardData,
                      onDeviceTap: (device) => _navigateAddedDevice(context, device),
                    ),
                  ),
                  const SizedBox(height: 24),
                  DashboardStatsGrid(
                    totalTowers: totalTowers,
                    totalOnlineTowers: totalOnlineTowers,
                    totalDownTowers: totalDownTowers,
                    totalUpCameras: totalUpCameras,
                    totalDownCameras: totalDownCameras,
                    totalUpMMT: totalUpMMT,
                    totalDownMMT: totalDownMMT,
                    totalUpNVR: totalUpNVR,
                    totalDownNVR: totalDownNVR,
                    totalUpSwitch: totalUpSwitch,
                    totalDownSwitch: totalDownSwitch,
                    totalWarnings: totalWarnings,
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
