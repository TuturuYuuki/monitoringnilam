import 'dart:async';
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:monitoring/main.dart';
import 'package:monitoring/models/camera_model.dart';
import 'package:monitoring/models/device_model.dart';
import 'package:monitoring/models/mmt_model.dart';
import 'package:monitoring/models/tower_model.dart';
import 'package:monitoring/services/api_service.dart';
import 'package:monitoring/services/device_storage_service.dart';
import 'package:monitoring/theme/app_dropdown_style.dart';
import 'package:monitoring/utils/device_icon_resolver.dart';
import 'package:monitoring/utils/location_label_utils.dart';
import 'package:monitoring/widgets/global_header_bar.dart';
import 'package:monitoring/widgets/global_sidebar_nav.dart';
import 'package:monitoring/widgets/global_footer.dart';

class AddDevicePage extends StatefulWidget {
  const AddDevicePage({super.key});

  @override
  State<AddDevicePage> createState() => _AddDevicePageState();
}

class _AddDevicePageState extends State<AddDevicePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _ipAddressController;
  late ApiService apiService;
  Timer? _nameDebounce;
  bool _isCheckingName = false;
  String? _nameError;
  bool _isLoadingUsedNames = false;
  List<String> _usedNamesForType = [];
  bool _isLoadingLocations = false;

  String _selectedDeviceType = 'Access Point';
  String _selectedLocation = '';

  final List<String> deviceTypes = ['Access Point', 'CCTV', 'MMT', 'NVR', 'Switch'];

  @override
  void initState() {
    super.initState();
    apiService = ApiService();
    _nameController = TextEditingController();
    _ipAddressController = TextEditingController();
    _loadLocationOptions();
    _loadUsedNamesForType();
  }

  @override
  void dispose() {
    _nameDebounce?.cancel();
    _nameController.dispose();
    _ipAddressController.dispose();
    super.dispose();
  }

  final Map<String, Map<String, dynamic>> _locationData = {};

  Future<void> _loadLocationOptions() async {
    if (!mounted) return;
    setState(() {
      _isLoadingLocations = true;
    });

    try {
      final locations = await apiService.getAllMasterLocations();
      final map = <String, Map<String, dynamic>>{};

      for (final loc in locations) {
        final locationType =
            (loc['location_type'] ?? '').toString().toUpperCase();
        final locationCode = (loc['location_code'] ?? '').toString();
        final containerYard = (loc['container_yard'] ?? '').toString();
        final locationName = (loc['location_name'] ?? '').toString();

        final label = buildMasterLocationLabel(
          locationType: locationType,
          locationCode: locationCode,
          locationName: locationName,
          containerYard: containerYard,
        );

        map[label] = {
          'lat': double.tryParse((loc['latitude'] ?? 0).toString()) ?? 0.0,
          'lng': double.tryParse((loc['longitude'] ?? 0).toString()) ?? 0.0,
          'cy': containerYard,
          'location_type': locationType,
          'location_code': locationCode,
        };
      }

      final sortedEntries = map.entries.toList()
        ..sort((a, b) => a.key.toLowerCase().compareTo(b.key.toLowerCase()));

      if (!mounted) return;
      setState(() {
        _locationData
          ..clear()
          ..addEntries(sortedEntries);
        if (_locationData.isNotEmpty) {
          _resetLocationToDefaultForType();
        } else {
          _selectedLocation = '';
        }
        _isLoadingLocations = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingLocations = false;
      });
      // print removed
    }
  }

  IconData _getLocationIcon(String locationName) {
    return DeviceIconResolver.iconForLocationName(locationName);
  }

  String _getDeviceNameExample(String deviceType) {
    switch (deviceType) {
      case 'Access Point':
        return 'AP 01';
      case 'CCTV':
        return 'CAM 01';
      case 'MMT':
        return 'MMT 01';
      case 'NVR':
        return 'NVR 01';
      case 'Switch':
        return 'SW 01';
      default:
        return '';
    }
  }

  IconData _getDeviceIcon(String deviceType) {
    return DeviceIconResolver.iconForType(deviceType);
  }

  void _onNameChanged(String value) {
    _nameDebounce?.cancel();
    _nameDebounce = Timer(const Duration(milliseconds: 450), () {
      _checkNameAvailability(value);
    });
  }

  Future<void> _loadUsedNamesForType() async {
    if (!mounted) return;
    setState(() {
      _isLoadingUsedNames = true;
    });

    try {
      final results = await Future.wait([
        apiService.getAllCameras(),
        apiService.getAllMMTs(),
        apiService.getAllTowers(),
        DeviceStorageService.getDevices(),
      ]);

      final cameras = results[0] as List<Camera>;
      final mmts = results[1] as List<MMT>;
      final towers = results[2] as List<Tower>;
      final addedDevices = results[3] as List<AddedDevice>;

      final names = <String>{};
      if (_selectedDeviceType == 'Access Point') {
        names.addAll(towers.map((t) => t.towerId));
        names.addAll(addedDevices
            .where((d) => d.type == 'Access Point')
            .map((d) => d.name));
      } else if (_selectedDeviceType == 'CCTV') {
        names.addAll(cameras.map((c) => c.cameraId));
        names.addAll(addedDevices
            .where((d) =>
                d.type == 'CCTV' &&
                !cameras.any(
                    (c) => c.cameraId.toLowerCase() == d.name.toLowerCase()))
            .map((d) => d.name));
      } else if (_selectedDeviceType == 'MMT') {
        names.addAll(mmts.map((m) => m.mmtId));
        names.addAll(addedDevices
            .where((d) =>
                d.type == 'MMT' &&
                !mmts.any((m) => m.mmtId.toLowerCase() == d.name.toLowerCase()))
            .map((d) => d.name));
      } else if (_selectedDeviceType == 'NVR') {
        final nvrs = await apiService.getAllNVRs();
        names.addAll(nvrs.map((n) => n.nvrId));
      } else if (_selectedDeviceType == 'Switch') {
        final switches = await apiService.getAllSwitches();
        names.addAll(switches.map((s) => s.switchId));
      }

      final nameList = names.where((n) => n.trim().isNotEmpty).toList();

      // ===== PERBAIKAN LOGIKA SORTING DI SINI =====
      nameList.sort((a, b) {
        // Fungsi untuk mengambil angka dari string (Contoh: "AP 32" -> 32)
        int extractNumber(String s) {
          final match = RegExp(r'\d+').firstMatch(s);
          return match != null ? int.parse(match.group(0)!) : 0;
        }

        int numA = extractNumber(a);
        int numB = extractNumber(b);

        // Jika keduanya punya angka, bandingkan angkanya
        if (numA != numB) {
          return numA.compareTo(numB);
        }
        // Jika angka sama atau tidak ada angka, bandingkan teksnya secara normal
        return a.toLowerCase().compareTo(b.toLowerCase());
      });
      // ===========================================

      if (!mounted) return;
      setState(() {
        _usedNamesForType = nameList;
        _isLoadingUsedNames = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingUsedNames = false;
      });
      // print removed
    }
  }

  void _showAllUsedNames() {
    if (_usedNamesForType.isEmpty) return;
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: const Color(0xFF1E293B), // Dark theme color
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 24,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360), // Shrink slightly
            child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.list_alt_rounded, color: Colors.blue, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Name List',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  _selectedDeviceType,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white.withValues(alpha: 0.5),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close_rounded, color: Colors.white54, size: 20),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'TOTAL RECORDS',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.4),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                            Text(
                              '${_usedNamesForType.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 300),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: _usedNamesForType.length,
                            itemBuilder: (context, index) {
                              final name = _usedNamesForType[index];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.03),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: ListTile(
                                  dense: true,
                                  visualDensity: VisualDensity.compact,
                                  leading: Icon(
                                    Icons.label_important_outline_rounded,
                                    size: 16,
                                    color: Colors.blue.withValues(alpha: 0.6),
                                  ),
                                  title: Text(
                                    name,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
      },
    );
  }

  Future<void> _checkNameAvailability(String rawName) async {
    final name = rawName.trim();
    if (name.isEmpty) {
      if (!mounted) return;
      setState(() {
        _nameError = null;
        _isCheckingName = false;
      });
      return;
    }

    if (!mounted) return;
    setState(() {
      _isCheckingName = true;
      _nameError = null;
    });

    try {
      final results = await Future.wait([
        apiService.getAllCameras(),
        apiService.getAllMMTs(),
        apiService.getAllTowers(),
        DeviceStorageService.getDevices(),
      ]);

      final cameras = results[0] as List<Camera>;
      final mmts = results[1] as List<MMT>;
      final towers = results[2] as List<Tower>;
      final addedDevices = results[3] as List<AddedDevice>;

      // Get all DB device names for comparison
      final dbNames = <String>{};
      if (_selectedDeviceType == 'Access Point') {
        dbNames.addAll(towers.map((t) => t.towerId.toLowerCase()));
        dbNames.addAll(
          addedDevices
              .where((d) => d.type == 'Access Point')
              .map((d) => d.name.toLowerCase()),
        );
      } else if (_selectedDeviceType == 'CCTV') {
        dbNames.addAll(cameras.map((c) => c.cameraId.toLowerCase()));
      } else if (_selectedDeviceType == 'MMT') {
        dbNames.addAll(mmts.map((m) => m.mmtId.toLowerCase()));
      } else if (_selectedDeviceType == 'NVR') {
        final nvrs = await apiService.getAllNVRs();
        dbNames.addAll(nvrs.map((n) => n.nvrId.toLowerCase()));
      } else if (_selectedDeviceType == 'Switch') {
        final switches = await apiService.getAllSwitches();
        dbNames.addAll(switches.map((s) => s.switchId.toLowerCase()));
      }

      // Only include local storage devices that don't exist in DB
      // This prevents stale local data from blocking device names
      final pendingDeviceNames = addedDevices
          .where((d) => d.type == _selectedDeviceType)
          .where((d) => !dbNames.contains(d.name.toLowerCase()))
          .map((d) => d.name.toLowerCase());

      final existingNames = <String>{
        ...dbNames,
        ...pendingDeviceNames,
      };

      final isTaken = existingNames.contains(name.toLowerCase());
      if (!mounted) return;
      setState(() {
        _isCheckingName = false;
        _nameError = isTaken ? 'The device name is already in use' : null;
      });
      _formKey.currentState?.validate();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isCheckingName = false;
      });
    }
  }

  void _submitForm() async {
    // First validate name (quick check)
    await _checkNameAvailability(_nameController.text);
    if (_nameError != null) {
      return;
    }
    if (_selectedLocation.isEmpty ||
        !_locationData.containsKey(_selectedLocation)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Location not available. Please add a master tower first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final locationInfo = _locationData[_selectedLocation];
      final latitude = locationInfo?['lat'] ?? 0.0;
      final longitude = locationInfo?['lng'] ?? 0.0;
      final containerYard = locationInfo?['cy'] ?? '';
      
      // Persist the canonical full location label so all downstream tables stay consistent.
      final savedLocationName = buildMasterLocationLabel(
        locationType: (locationInfo?['location_type'] ?? '').toString(),
        locationCode: locationInfo?['location_code']?.toString() ?? normalizeLocationLabel(_selectedLocation),
        locationName: locationInfo?['location_name']?.toString() ?? '',
        containerYard: containerYard,
      );

      // Auto-fill fields sesuai template
      String deviceId = _nameController.text;
      String status = 'DOWN';
      String type = 'Fixed';
      int deviceCount = 1;
      String areaType = 'Warehouse'; // Default

      // Set areaType based on master location type/name for CCTV
      if (_selectedDeviceType == 'CCTV') {
        final locationLower = _selectedLocation.toLowerCase();
        final locType =
            (locationInfo?['location_type'] ?? '').toString().toUpperCase();
        if (locationLower.contains('gate')) {
          areaType = 'Gate';
        } else if (locationLower.contains('parking')) {
          areaType = 'Parking';
        } else if (locType == 'RTG') {
          areaType = 'RTG';
        } else if (locType == 'CC') {
          areaType = 'CC';
        } else if (locType == 'RS') {
          areaType = 'RS';
        }
      }

      // Save to local storage
      final newDevice = AddedDevice(
        id: const Uuid().v4(),
        type: _selectedDeviceType,
        name: deviceId,
        ipAddress: _ipAddressController.text,
        locationName: savedLocationName,
        latitude: latitude,
        longitude: longitude,
        containerYard: containerYard,
        createdAt: DateTime.now(),
      );

      final saveFuture =
          DeviceStorageService.addDevice(newDevice).catchError((e) {
        // print removed
      });

      // Prepare API request data
      String deviceIpAddress = _ipAddressController.text;
      Future<Map<String, dynamic>>? createFuture;

      // print removed
      // print removed
      // print removed
      // print removed
      // print removed
      // print removed

      // Execute API call (non-blocking) - don't await for dialog
      if (_selectedDeviceType == 'Access Point') {

        createFuture = apiService.createTower(
          towerId: deviceId,
          location: savedLocationName,
          ipAddress: deviceIpAddress,
          containerYard: containerYard,
          latitude: latitude,
          longitude: longitude,
          deviceCount: deviceCount,
          status: status,
        );
        createFuture.then((result) {
          if (result['success'] == true) {
            // print removed
            // print removed
          } else {
            // print removed
            // print removed
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      'G??n+? Gagal simpan ke database: ${result['message']}'),
                  backgroundColor: Colors.orange,
                  duration: const Duration(seconds: 5),
                ),
              );
            }
          }
        }).catchError((e) {
          // print removed
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('G?? Error API: $e'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 5),
              ),
            );
          }
        });
      } else if (_selectedDeviceType == 'CCTV') {

        createFuture = apiService.createCamera(
          cameraId: deviceId,
          location: savedLocationName,
          ipAddress: deviceIpAddress,
          containerYard: containerYard,
          latitude: latitude,
          longitude: longitude,
          status: status,
          type: type,
          areaType: areaType,
        );
        createFuture.then((result) {
          if (result['success'] == true) {
            // print removed
          } else {
            // print removed
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      'G??n+? Gagal simpan ke database: ${result['message']}'),
                  backgroundColor: Colors.orange,
                  duration: const Duration(seconds: 5),
                ),
              );
            }
          }
        }).catchError((e) {
          // print removed
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('G?? Error API: $e'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 5),
              ),
            );
          }
        });
      } else if (_selectedDeviceType == 'MMT') {

        createFuture = apiService.createMMT(
          mmtId: deviceId,
          location: savedLocationName,
          ipAddress: deviceIpAddress,
          containerYard: containerYard,
          status: status,
          type: type,
          deviceCount: deviceCount,
        );
        createFuture.then((result) {
          if (result['success'] == true) {
            // print removed
          } else {
            // print removed
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      'G??n+? Gagal simpan ke database: ${result['message']}'),
                  backgroundColor: Colors.orange,
                  duration: const Duration(seconds: 5),
                ),
              );
            }
          }
        }).catchError((e) {
          // print removed
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('G?? Error API: $e'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 5),
              ),
            );
          }
        });
      } else if (_selectedDeviceType == 'NVR') {
        createFuture = apiService.createNVR({
          'nvr_id': deviceId,
          'location': savedLocationName,
          'ip_address': deviceIpAddress,
          'container_yard': containerYard,
          'latitude': latitude,
          'longitude': longitude,
          'status': status,
          'type': type,
        });
      } else if (_selectedDeviceType == 'Switch') {
        createFuture = apiService.createSwitch({
          'switch_id': deviceId,
          'location': savedLocationName,
          'ip_address': deviceIpAddress,
          'container_yard': containerYard,
          'latitude': latitude,
          'longitude': longitude,
          'status': status,
          'type': type,
        });
      }

      // Show success dialog IMMEDIATELY (no waiting)
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF1E293B),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.green, size: 28),
                SizedBox(width: 12),
                Text(
                  'Success',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Device has been successfully registered.',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  _buildInfoRow('DEVICE ID', deviceId),
                  const SizedBox(height: 12),
                  _buildInfoRow('DEVICE TYPE', _selectedDeviceType),
                  const SizedBox(height: 12),
                  _buildInfoRow('LOCATION', _selectedLocation.split(' ').skip(1).join(' ')),
                  const SizedBox(height: 12),
                  _buildInfoRow('IP ADDRESS', _ipAddressController.text),
                  const SizedBox(height: 12),
                  _buildInfoRow('CONTAINER YARD', containerYard),
                  if (_selectedDeviceType == 'Access Point') ...[
                    const SizedBox(height: 12),
                    _buildInfoRow('DEVICE COUNT', deviceCount.toString()),
                  ],
                  if (_selectedDeviceType == 'CCTV') ...[
                    const SizedBox(height: 12),
                    _buildInfoRow('AREA TYPE', areaType),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _resetForm();
                },
                child: const Text(
                  'Add Another',
                  style: TextStyle(color: Colors.white60, fontWeight: FontWeight.bold),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  try {
                    // Wait for save operations to complete
                    await saveFuture
                        .timeout(const Duration(seconds: 3))
                        .catchError((_) {
                      return null;
                    });

                    final pendingCreate = createFuture;
                    if (pendingCreate != null) {
                      await pendingCreate
                          .timeout(const Duration(seconds: 8))
                          .catchError((_) {
                        return <String, dynamic>{};
                      });
                    }

                    await Future.delayed(const Duration(milliseconds: 500));
                  } catch (_) {}

                  if (!context.mounted) return;

                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/dashboard',
                    (route) => false,
                    arguments: {'Refresh': true},
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1976D2),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  'Dashboard',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      }
    }
  }

  void _resetForm() {
    _formKey.currentState!.reset();
    setState(() {
      _selectedDeviceType = 'Access Point';
      _resetLocationToDefaultForType();
      _nameController.clear();
      _ipAddressController.clear();
      _nameError = null;
      _isCheckingName = false;
    });
    _loadUsedNamesForType();
  }

  void _resetLocationToDefaultForType() {
    if (_locationData.isNotEmpty) {
      if (_selectedLocation.isEmpty || !_locationData.containsKey(_selectedLocation)) {
        _selectedLocation = _locationData.keys.first;
      }
    } else {
      _selectedLocation = '';
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 10,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = isMobileScreen(context);
    final isNarrowMobile = MediaQuery.of(context).size.width < 420;
    return Scaffold(
      backgroundColor: AppDropdownStyle.standardPageBackground,
      body: Stack(
        children: [
          Column(
            children: [
              const GlobalHeaderBar(currentRoute: '/add-device'),
              Expanded(
                child: GlobalSidebarNav(
                    currentRoute: '/add-device',
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(isMobile ? 12 : 24),
                      child: Center(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                            child: Container(
                              constraints: BoxConstraints(maxWidth: isMobile ? double.infinity : 480),
                              padding: EdgeInsets.all(isMobile ? 16 : 20),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.28),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.22),
                                    blurRadius: 24,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Theme(
                                data: Theme.of(context).copyWith(
                                  brightness: Brightness.dark,
                                  inputDecorationTheme: InputDecorationTheme(
                                    filled: true,
                                    fillColor: Colors.white.withValues(alpha: 0.06),
                                    labelStyle:
                                        const TextStyle(color: Colors.white70),
                                    floatingLabelStyle:
                                        const TextStyle(color: Colors.white70),
                                    hintStyle: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.45)),
                                    helperStyle: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.55)),
                                    errorStyle: const TextStyle(
                                        color: Color(0xFFFFAB91)),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                          color:
                                              Colors.white.withValues(alpha: 0.32)),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                          color:
                                              Colors.white.withValues(alpha: 0.32)),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: const BorderSide(
                                          color: Color(0xFF64B5F6), width: 2),
                                    ),
                                  ),
                                ),
                                child: Form(
                                  key: _formKey,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            width: 5,
                                            height: isMobile ? 24 : 20,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF1976D2),
                                              borderRadius:
                                                  BorderRadius.circular(2),
                                            ),
                                          ),
                                          SizedBox(
                                              width: isMobile ? 10 : 12),
                                          Expanded(
                                            child: Text(
                                            'Add New Device',
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                                fontSize:
                                                   isNarrowMobile ? 20 : (isMobile ? 24 : 20),
                                               fontWeight: FontWeight.w800,
                                               color: Colors.white,
                                               letterSpacing: 0.2,
                                            ),
                                          ),
                                          ),
                                        ],
                                      ),
                                       SizedBox(height: isMobile ? 20 : 20),

                                      // ===== TIPE DEVICE =====
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.08),
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Icon(
                                                _getDeviceIcon(_selectedDeviceType),
                                                color: const Color(0xFF90CAF9),
                                                size: 20,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'DEVICE TYPE',
                                                    style: TextStyle(
                                                      color: Colors.white.withValues(alpha: 0.6),
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                      letterSpacing: 1.5,
                                                    ),
                                                  ),
                                                  AnimatedDropdownButton(
                                                    value: _selectedDeviceType,
                                                    items: deviceTypes,
                                                    backgroundColor: AppDropdownStyle.menuBackground,
                                                    onChanged: (String? newValue) {
                                                      if (newValue != null) {
                                                        setState(() {
                                                          _selectedDeviceType = newValue;
                                                          _nameController.clear();
                                                          _nameError = null;
                                                          _isCheckingName = false;
                                                          
                                                          _resetLocationToDefaultForType();
                                                        });
                                                        _loadUsedNamesForType();
                                                      }
                                                    },
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                       SizedBox(height: isMobile ? 18 : 16),

                                      // ===== NAMA DEVICE =====
                                      TextFormField(
                                        controller: _nameController,
                                        onChanged: _onNameChanged,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        cursorColor: Colors.white,
                                        decoration: InputDecoration(
                                          labelText: 'Device Name',
                                          hintText: 'Enter device name',
                                          helperText:
                                              'Example: ${_getDeviceNameExample(_selectedDeviceType)}',
                                          prefixIcon: const Icon(
                                              Icons.label_outline,
                                              color: Color(0xFF90CAF9)),
                                          suffixIcon: _isCheckingName
                                              ? const Padding(
                                                  padding: EdgeInsets.all(12),
                                                  child: SizedBox(
                                                    width: 16,
                                                    height: 16,
                                                    child:
                                                        CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color: Colors.white54,
                                                    ),
                                                  ),
                                                )
                                              : (_nameController
                                                          .text.isNotEmpty &&
                                                      _nameError == null)
                                                  ? const Icon(
                                                      Icons.check_circle,
                                                      color: Colors.green,
                                                    )
                                                  : (_nameError != null)
                                                      ? const Icon(
                                                          Icons.error_outline,
                                                          color: Colors.red)
                                                      : null,
                                          border: const OutlineInputBorder(),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 14,
                                          ),
                                        ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Device name cannot be empty';
                                          }
                                          if (_nameError != null) {
                                            return _nameError;
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 8),
                                      if (_isLoadingUsedNames)
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const SizedBox(
                                              width: 14,
                                              height: 14,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                'Loading used name for $_selectedDeviceType...',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.white
                                                      .withValues(alpha: 0.65),
                                                ),
                                              ),
                                            ),
                                          ],
                                        )
                                      else if (_usedNamesForType.isNotEmpty)
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    'Used name for this type',
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: Colors.white
                                                          .withValues(alpha: 0.75),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                TextButton(
                                                  onPressed: _showAllUsedNames,
                                                  style: TextButton.styleFrom(
                                                    visualDensity:
                                                        VisualDensity.compact,
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                            horizontal: 4),
                                                    foregroundColor:
                                                        const Color(0xFF90CAF9),
                                                  ),
                                                  child: const Text('View All',
                                                      style: TextStyle(
                                                          fontSize: 11)),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            SizedBox(
                                              height: 32,
                                              child: ListView.separated(
                                                scrollDirection:
                                                    Axis.horizontal,
                                                itemCount:
                                                    _usedNamesForType.length,
                                                separatorBuilder: (_, __) =>
                                                    const SizedBox(width: 8),
                                                itemBuilder: (context, index) {
                                                  return Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 10,
                                                        vertical: 4),
                                                    decoration: BoxDecoration(
                                                      color: Colors.white
                                                          .withValues(alpha: 0.08),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              20),
                                                      border: Border.all(
                                                          color: Colors.white
                                                              .withValues(alpha: 0.22)),
                                                    ),
                                                    child: Center(
                                                      child: Text(
                                                        _usedNamesForType[
                                                            index],
                                                        style: const TextStyle(
                                                          fontSize: 11,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color:
                                                              Color(0xFF90CAF9),
                                                        ),
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                          ],
                                        )
                                      else
                                        Text(
                                          'No used device name available for this type',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color:
                                                Colors.white.withValues(alpha: 0.55),
                                          ),
                                        ),
                                       SizedBox(height: isMobile ? 18 : 16),

                                      // ===== IP ADDRESS =====
                                      TextFormField(
                                        controller: _ipAddressController,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        cursorColor: Colors.white,
                                        decoration: InputDecoration(
                                          labelText: 'IP Address',
                                          hintText: 'Enter an IP Address',
                                          helperText: isMobile
                                              ? 'Example: 10.2.71.60'
                                              : 'Example: 10.2.71.60',
                                          prefixIcon: const Icon(Icons.network_check,
                                              color: Color(0xFF90CAF9)),
                                          border: const OutlineInputBorder(),
                                          contentPadding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 14,
                                          ),
                                        ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'IP Address cannot be empty';
                                          }
                                          final ipRegex = RegExp(
                                              r'^(\d{1,3}\.){3}\d{1,3}$');
                                          if (!ipRegex.hasMatch(value)) {
                                            return 'Invalid IP Address format';
                                          }
                                          return null;
                                        },
                                      ),
                                       SizedBox(height: isMobile ? 18 : 16),

                                      // ===== LOKASI =====
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.08),
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Icon(
                                                _getLocationIcon(_selectedLocation.isEmpty ? '?' : _selectedLocation),
                                                color: const Color(0xFF90CAF9),
                                                size: 20,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'LOCATION',
                                                    style: TextStyle(
                                                      color: Colors.white.withValues(alpha: 0.6),
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                      letterSpacing: 1.5,
                                                    ),
                                                  ),
                                                  AnimatedDropdownButton(
                                                    value: _selectedLocation.isEmpty || !_locationData.containsKey(_selectedLocation)
                                                        ? 'Select Location'
                                                        : _selectedLocation,
                                                    items: _locationData.keys.toList(),
                                                    backgroundColor: AppDropdownStyle.menuBackground,
                                                    onChanged: (String? newValue) {
                                                      if (newValue != null && newValue != 'Select Location') {
                                                        setState(() {
                                                          _selectedLocation = newValue;
                                                        });
                                                      }
                                                    },
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (_isLoadingLocations)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 8),
                                          child: Text(
                                            'Loading location from unified master data...',
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.white
                                                    .withValues(alpha: 0.55)),
                                          ),
                                        ),
                                       SizedBox(height: isMobile ? 26 : 24),
                                      // ===== SUBMIT BUTTON =====
                                      SizedBox(
                                        width: double.infinity,
                                        height: 52,
                                        child: ElevatedButton(
                                          onPressed: _submitForm,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                const Color(0xFF1976D2),
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            elevation: 4,
                                          ),
                                          child: const Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.add),
                                              SizedBox(width: 8),
                                              Text(
                                                'Add New Device',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    )),
              ),
              const GlobalFooter(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFooterLink(String text) {
    return Text(
      text,
      style: TextStyle(
          color: Colors.white.withValues(alpha: 0.6),
          fontSize: 13,
          fontWeight: FontWeight.w500),
    );
  }
}
