import 'dart:async';
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:monitoring/main.dart';
import 'package:monitoring/utils/ui_utils.dart';
import 'package:monitoring/models/camera_model.dart';
import 'package:monitoring/models/device_model.dart';
import 'package:monitoring/models/mmt_model.dart';
import 'package:monitoring/services/api_service.dart';
import 'package:monitoring/services/device_storage_service.dart';
import 'package:monitoring/theme/app_dropdown_style.dart';
import 'package:monitoring/utils/navigation_helper.dart';
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

  final List<String> deviceTypes = ['Access Point', 'CCTV', 'MMT'];

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
          if (_selectedLocation.isEmpty ||
              !_locationData.containsKey(_selectedLocation)) {
            _selectedLocation = _locationData.keys.first;
          }
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
      print('Error loading location options from master location endpoint: $e');
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
        DeviceStorageService.getDevices(),
      ]);

      final cameras = results[0] as List<Camera>;
      final mmts = results[1] as List<MMT>;
      final addedDevices = results[2] as List<AddedDevice>;

      final names = <String>{};
      if (_selectedDeviceType == 'Access Point') {
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
      print('Error Loading Used Device Name: $e');
    }
  }

  void _showAllUsedNames() {
    if (_usedNamesForType.isEmpty) return;
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Device Name List',
      barrierColor: Colors.black26,
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (context, anim1, anim2) {
        return SafeArea(
          child: Center(
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Name List For $_selectedDeviceType',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                      Text(
                        'Total: ${_usedNamesForType.length} Name',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 360),
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: _usedNamesForType.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final name = _usedNamesForType[index];
                            return ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              leading:
                                  const Icon(Icons.label_outline, size: 18),
                              title: Text(
                                name,
                                style: const TextStyle(fontSize: 13),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
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
        DeviceStorageService.getDevices(),
      ]);

      final cameras = results[0] as List<Camera>;
      final mmts = results[1] as List<MMT>;
      final addedDevices = results[2] as List<AddedDevice>;

      // Get all DB device names for comparison
      final dbNames = <String>{};
      if (_selectedDeviceType == 'Access Point') {
        dbNames.addAll(
          addedDevices
              .where((d) => d.type == 'Access Point')
              .map((d) => d.name.toLowerCase()),
        );
      } else if (_selectedDeviceType == 'CCTV') {
        dbNames.addAll(cameras.map((c) => c.cameraId.toLowerCase()));
      } else if (_selectedDeviceType == 'MMT') {
        dbNames.addAll(mmts.map((m) => m.mmtId.toLowerCase()));
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
        _nameError = isTaken ? 'The Device Name Is Already In Use' : null;
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
              'Lokasi belum tersedia. Tambahkan master tower terlebih dahulu.'),
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
      final savedLocationName = normalizeLocationLabel(_selectedLocation);

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
        print('Error Saving To Local Storage: $e');
      });

      // Prepare API request data
      String deviceIpAddress = _ipAddressController.text;
      Future<Map<String, dynamic>>? createFuture;

      print('=== DEBUG: Saving Device ===');
      print('Device Type: $_selectedDeviceType');
      print('Device ID: $deviceId');
      print('IP Address From Input: $deviceIpAddress');
      print('Location: $savedLocationName');
      print('Container Yard: $containerYard');

      // Execute API call (non-blocking) - don't await for dialog
      if (_selectedDeviceType == 'Access Point') {
        print(
            '\nG??G??G??G??G??G??G??G??G??G??G??G??G??G??G??G??G??G??G??G??G??G??G??G??G??G??G??G??G??G??G??G??G??G??G??G??');
        print('=??? Creating Access Point (Tower)');
        print('Device ID: $deviceId');
        print('Location: $savedLocationName');
        print('IP: $deviceIpAddress');
        print('Container Yard: $containerYard');
        print(
            'G??G??G??G??G??G??G??G??G??G??G??G??G??G??G??G??G??G??G??G??G??G??G??G??G??G??G??G??G??G??G??G??G??G??G??G??\n');

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
            print('G?? SUCCESS: Tower created in database');
            print('Response: $result');
          } else {
            print('G?? FAILED: ${result['message'] ?? 'Unknown error'}');
            print('Full response: $result');
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
          print('G??G??G?? EXCEPTION: $e');
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
        print(
            '\nG??G??G??G??G??G??G??G??G??G??G??G??G??G??G??G??G??G??G??G??G??G??G??G??G??G??G??G??G??G??G??G??G??G??G??G??');
        print('=?? Creating CCTV (Camera)');
        print('Camera ID: $deviceId');
        print('Location: $savedLocationName');
        print('IP: $deviceIpAddress');
        print(
            'G??G??G??G??G??G??G??G??G??G??G??G??G??G??G??G??G??G??G??G??G??G??G??G??G??G??G??G??G??G??G??G??G??G??G??G??\n');

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
            print('G?? SUCCESS: Camera created in database');
          } else {
            print('G?? FAILED: ${result['message']}');
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
          print('G?? EXCEPTION: $e');
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
        print(
            '\nG??G??G??G??G??G??G??G??G??G??G??G??G??G??G??G??G??G??G??G??G??G??G??G??G??G??G??G??G??G??G??G??G??G??G??G??');
        print('=??? Creating MMT');
        print('MMT ID: $deviceId');
        print('Location: $savedLocationName');
        print('IP: $deviceIpAddress');
        print(
            'G??G??G??G??G??G??G??G??G??G??G??G??G??G??G??G??G??G??G??G??G??G??G??G??G??G??G??G??G??G??G??G??G??G??G??G??\n');

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
            print('G?? SUCCESS: MMT created in database');
          } else {
            print('G?? FAILED: ${result['message']}');
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
          print('G?? EXCEPTION: $e');
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
      }

      // Show success dialog IMMEDIATELY (no waiting)
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Perangkat berhasil ditambahkan'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      border: Border.all(color: Colors.green),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Perangkat tersimpan',
                            style:
                                TextStyle(fontSize: 12, color: Colors.black87),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow('Device ID:', deviceId),
                  const SizedBox(height: 8),
                  _buildInfoRow('Device Type:', _selectedDeviceType),
                  const SizedBox(height: 8),
                  _buildInfoRow('Location:', _selectedLocation),
                  const SizedBox(height: 8),
                  _buildInfoRow('IP Address:', _ipAddressController.text),
                  const SizedBox(height: 8),
                  _buildInfoRow('Container Yard:', containerYard),
                  if (_selectedDeviceType == 'Access Point') ...[
                    const SizedBox(height: 8),
                    _buildInfoRow('Device Count:', deviceCount.toString()),
                  ],
                  if (_selectedDeviceType == 'CCTV') ...[
                    const SizedBox(height: 8),
                    _buildInfoRow('Area Type:', areaType),
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
                child: const Text('Tambah perangkat lain'),
              ),
              ElevatedButton(
                onPressed: () async {
                  try {
                    // Wait for save operations to complete
                    await saveFuture
                        .timeout(const Duration(seconds: 3))
                        .catchError((_) {
                      print('Timeout Or Error Waiting For Save');
                    });

                    final pendingCreate = createFuture;
                    if (pendingCreate != null) {
                      await pendingCreate
                          .timeout(const Duration(seconds: 8))
                          .catchError((_) {
                        print('Timeout Or Error Waiting For Device Creation');
                        return <String, dynamic>{};
                      });
                    }

                    // Wait a moment for DB to settle
                    await Future.delayed(const Duration(milliseconds: 500));
                  } catch (e) {
                    print('Error Waiting For Device Creation: $e');
                  }

                  if (!context.mounted) return;

                  // Navigate back to dashboard
                  if (context.mounted) {
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      '/dashboard',
                      (route) => false,
                      arguments: {'Refresh': true},
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1976D2),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Kembali ke dashboard'),
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
      _selectedLocation =
          _locationData.isNotEmpty ? _locationData.keys.first : '';
      _nameController.clear();
      _ipAddressController.clear();
      _nameError = null;
      _isCheckingName = false;
    });
    _loadUsedNamesForType();
  }

  Widget _buildInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: Colors.grey[700],
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return Container(
      width: screenWidth,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      color: const Color(0xFF1976D2),
      child: Row(
        children: [
          const Text(
            'Terminal Nilam',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 30),
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
                    _buildHeaderOpenButton('Add New Device', '/add-device',
                        isActive: true),
                    const SizedBox(width: 12),
                    _buildHeaderOpenButton('Master Data', '/tower-management'),
                    const SizedBox(width: 12),
                    _buildHeaderOpenButton('Dashboard', '/dashboard'),
                    const SizedBox(width: 12),
                    _buildHeaderOpenButton('Access Point', '/network'),
                    const SizedBox(width: 12),
                    _buildHeaderOpenButton('CCTV', '/cctv'),
                    const SizedBox(width: 12),
                    _buildHeaderOpenButton('MMT', '/mmt-monitoring'),
                    const SizedBox(width: 12),
                    _buildHeaderOpenButton('Alert', '/alerts'),
                    const SizedBox(width: 12),
                    _buildHeaderOpenButton('Alert Report', '/report'),
                    const SizedBox(width: 12),
                    _buildHeaderButton(
                        'Logout', () => _showLogoutDialog(context)),
                    const SizedBox(width: 12),
                    // Profile Icon
                    GestureDetector(
                      onTap: () {
                        NavigationHelper.navigateTo(context, '/profile');
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
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            decoration: BoxDecoration(
              color: isActive
                  ? Colors.white.withOpacity(0.9)
                  : Colors.white.withOpacity(0.4),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1.5,
              ),
            ),
            child: Text(
              text,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderOpenButton(String text, String routeName,
      {bool isActive = false}) {
    return GestureDetector(
      onTap: () {
        NavigationHelper.navigateTo(context, routeName, replace: true);
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(25),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            decoration: BoxDecoration(
              color: isActive
                  ? Colors.white.withOpacity(0.9)
                  : Colors.white.withOpacity(0.4),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1.5,
              ),
            ),
            child: Text(
              text,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout',
            style: TextStyle(color: Colors.black87, fontSize: 20)),
        content: const Text('Are you sure you want to exit?',
            style: TextStyle(color: Colors.black87)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
                child: const Text('Cancel', style: TextStyle(color: Colors.black87)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = isMobileScreen(context);
    final isNarrowMobile = MediaQuery.of(context).size.width < 420;
    return Scaffold(
      backgroundColor: const Color(0xFF2C3E50),
      body: Stack(
        children: [
          Column(
            children: [
              const GlobalHeaderBar(currentRoute: '/add-device'),
              Expanded(
                child: GlobalSidebarNav(
                    currentRoute: '/add-device',
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                          isMobile ? 10 : 32,
                          isMobile ? 10 : 32,
                          isMobile ? 10 : 32,
                          isMobile ? 18 : 32),
                      child: Center(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                            child: Container(
                              constraints: const BoxConstraints(maxWidth: 600),
                              padding: EdgeInsets.all(isMobile ? 16 : 32),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.10),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.28),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.22),
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
                                    fillColor: Colors.white.withOpacity(0.06),
                                    labelStyle:
                                        const TextStyle(color: Colors.white70),
                                    floatingLabelStyle:
                                        const TextStyle(color: Colors.white70),
                                    hintStyle: TextStyle(
                                        color: Colors.white.withOpacity(0.45)),
                                    helperStyle: TextStyle(
                                        color: Colors.white.withOpacity(0.55)),
                                    errorStyle: const TextStyle(
                                        color: Color(0xFFFFAB91)),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                          color:
                                              Colors.white.withOpacity(0.32)),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                          color:
                                              Colors.white.withOpacity(0.32)),
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
                                            height: isMobile ? 24 : 28,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF1976D2),
                                              borderRadius:
                                                  BorderRadius.circular(2),
                                            ),
                                          ),
                                          SizedBox(
                                              width: isMobile ? 10 : 14),
                                          Expanded(
                                            child: Text(
                                            'Add New Device',
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize:
                                                  isNarrowMobile ? 20 : 24,
                                              fontWeight: FontWeight.w800,
                                              color: Colors.white,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: isMobile ? 20 : 32),

                                      // ===== TIPE DEVICE =====
                                      DropdownButtonFormField<String>(
                                        initialValue: _selectedDeviceType,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        dropdownColor:
                                            AppDropdownStyle.menuBackground,
                                        borderRadius:
                                            AppDropdownStyle.menuBorderRadius,
                                        iconEnabledColor: Colors.white70,
                                        decoration: InputDecoration(
                                          labelText: 'Device Type',
                                          prefixIcon: Icon(
                                              _getDeviceIcon(
                                                  _selectedDeviceType),
                                              color: const Color(0xFF90CAF9)),
                                          border: const OutlineInputBorder(),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 16, vertical: 16),
                                        ),
                                        onChanged: (String? newValue) {
                                          if (newValue != null) {
                                            setState(() {
                                              _selectedDeviceType = newValue;
                                              _nameController.clear();
                                              _nameError = null;
                                              _isCheckingName = false;
                                            });
                                            _loadUsedNamesForType();
                                          }
                                        },
                                        items: deviceTypes
                                            .map<DropdownMenuItem<String>>(
                                                (String value) {
                                          return DropdownMenuItem<String>(
                                            value: value,
                                            child: Text(value,
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white)),
                                          );
                                        }).toList(),
                                      ),
                                      SizedBox(height: isMobile ? 18 : 24),

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
                                          hintText: 'Enter Device Name',
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
                                            vertical: 16,
                                          ),
                                        ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Device Name Cannot Be Empty';
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
                                                'Loading Used Name For $_selectedDeviceType...',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.white
                                                      .withOpacity(0.65),
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
                                                    'Used Names For This Type',
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: Colors.white
                                                          .withOpacity(0.75),
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
                                                          .withOpacity(0.08),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              20),
                                                      border: Border.all(
                                                          color: Colors.white
                                                              .withOpacity(
                                                                  0.22)),
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
                                          'No Used Device Name Available For This Type',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color:
                                                Colors.white.withOpacity(0.55),
                                          ),
                                        ),
                                      SizedBox(height: isMobile ? 18 : 24),

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
                                          hintText: 'Entry An IP Address',
                                          helperText: isMobile
                                              ? 'Example: 10.2.71.60'
                                              : 'Example: 10.2.71.60',
                                          prefixIcon: const Icon(Icons.router,
                                              color: Color(0xFF90CAF9)),
                                          border: const OutlineInputBorder(),
                                          contentPadding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 16,
                                          ),
                                        ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'IP Address Cannot Be Empty';
                                          }
                                          final ipRegex = RegExp(
                                              r'^(\d{1,3}\.){3}\d{1,3}$');
                                          if (!ipRegex.hasMatch(value)) {
                                            return 'Invalid IP Address Format';
                                          }
                                          return null;
                                        },
                                      ),
                                      SizedBox(height: isMobile ? 18 : 24),

                                      // ===== LOKASI =====
                                      DropdownButtonFormField<String>(
                                        initialValue: _locationData
                                                .containsKey(_selectedLocation)
                                            ? _selectedLocation
                                            : null,
                                        isExpanded: true,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                        dropdownColor:
                                            AppDropdownStyle.menuBackground,
                                        borderRadius:
                                            AppDropdownStyle.menuBorderRadius,
                                        iconEnabledColor: Colors.white70,
                                        decoration: InputDecoration(
                                          labelText: 'Location',
                                          prefixIcon: Icon(
                                              _getLocationIcon(
                                                  _selectedLocation.isEmpty
                                                      ? '?'
                                                      : _selectedLocation),
                                              color: const Color(0xFF90CAF9)),
                                          border: const OutlineInputBorder(),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 16, vertical: 16),
                                          hintText: 'Select location',
                                        ),
                                        selectedItemBuilder: (context) {
                                          return _locationData.keys
                                              .map(
                                                (value) => Text(
                                                  value,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 13,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              )
                                              .toList();
                                        },
                                        onChanged: (String? newValue) {
                                          if (newValue != null) {
                                            setState(() {
                                              _selectedLocation = newValue;
                                            });
                                          }
                                        },
                                        items: _locationData.keys
                                            .map<DropdownMenuItem<String>>(
                                                (String value) {
                                          return DropdownMenuItem<String>(
                                            value: value,
                                            child: Text(
                                              value,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13,
                                                  color: Colors.white),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                      if (_isLoadingLocations)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 8),
                                          child: Text(
                                            'Loading Locations From Unified Master Data...',
                                            style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.white
                                                    .withOpacity(0.55)),
                                          ),
                                        ),
                                      SizedBox(height: isMobile ? 26 : 40),
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
          color: Colors.white.withOpacity(0.6),
          fontSize: 13,
          fontWeight: FontWeight.w500),
    );
  }
}
