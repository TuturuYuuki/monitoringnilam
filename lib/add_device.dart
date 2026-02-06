import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'main.dart';
import 'dashboard.dart';
import 'network.dart';
import 'cctv.dart';
import 'alerts.dart';
import 'profile.dart';
import 'models/camera_model.dart';
import 'models/device_model.dart';
import 'models/mmt_model.dart';
import 'models/tower_model.dart';
import 'services/api_service.dart';
import 'services/device_storage_service.dart';

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

  String _selectedDeviceType = 'Access Point';
  String _selectedLocation = 'Tower 1 - CY2';

  final List<String> deviceTypes = ['Access Point', 'CCTV', 'MMT'];

  @override
  void initState() {
    super.initState();
    apiService = ApiService();
    _nameController = TextEditingController();
    _ipAddressController = TextEditingController();
    _loadUsedNamesForType();
  }

  @override
  void dispose() {
    _nameDebounce?.cancel();
    _nameController.dispose();
    _ipAddressController.dispose();
    super.dispose();
  }

  // Location data sesuai dengan tower points dan special locations
  final Map<String, Map<String, dynamic>> locationData = {
    // CY2 Towers
    'Tower 1 - CY2': {'lat': -7.209459, 'lng': 112.724717, 'cy': 'CY2'},
    'Tower 2 - CY2': {'lat': -7.209191, 'lng': 112.725250, 'cy': 'CY2'},
    'Tower 3 - CY2': {'lat': -7.208561, 'lng': 112.724946, 'cy': 'CY2'},
    'Tower 4 - CY2': {'lat': -7.208150, 'lng': 112.724395, 'cy': 'CY2'},
    'Tower 5 - CY2': {'lat': -7.208262, 'lng': 112.724161, 'cy': 'CY2'},
    'Tower 6 - CY2': {'lat': -7.208956, 'lng': 112.724173, 'cy': 'CY2'},
    // CY1 Towers
    'Tower 7 - CY1': {'lat': -7.207690, 'lng': 112.723693, 'cy': 'CY1'},
    'Tower 8 - CY1': {'lat': -7.207567, 'lng': 112.723945, 'cy': 'CY1'},
    'Tower 9 - CY1': {'lat': -7.207156, 'lng': 112.724302, 'cy': 'CY1'},
    'Tower 10 - CY1': {'lat': -7.204341, 'lng': 112.722956, 'cy': 'CY1'},
    'Tower 11 - CY1': {'lat': -7.204080, 'lng': 112.722354, 'cy': 'CY1'},
    'Tower 12A - CY1': {'lat': -7.204228, 'lng': 112.722045, 'cy': 'CY1'},
    'Tower 12 - CY1': {'lat': -7.204460, 'lng': 112.721970, 'cy': 'CY1'},
    'Tower 13 - CY1': {'lat': -7.205410, 'lng': 112.722386, 'cy': 'CY1'},
    'Tower 14 - CY1': {'lat': -7.206786, 'lng': 112.723023, 'cy': 'CY1'},
    'Tower 15 - CY1': {'lat': -7.207566, 'lng': 112.723469, 'cy': 'CY1'},
    'Tower 16 - CY1': {'lat': -7.207342, 'lng': 112.723059, 'cy': 'CY1'},
    'Tower 17 - CY1': {'lat': -7.209240, 'lng': 112.723915, 'cy': 'CY1'},
    // CY3 Towers
    'Tower 18 - CY3': {'lat': -7.210090, 'lng': 112.724321, 'cy': 'CY3'},
    'Tower 19 - CY3': {'lat': -7.210336, 'lng': 112.723639, 'cy': 'CY3'},
    'Tower 20 - CY3': {'lat': -7.210082, 'lng': 112.723303, 'cy': 'CY3'},
    'Tower 21 - CY3': {'lat': -7.209070, 'lng': 112.722914, 'cy': 'CY3'},
    'Tower 22 - CY3': {'lat': -7.208501, 'lng': 112.722942, 'cy': 'CY3'},
    'Tower 23 - CY3': {'lat': -7.208017, 'lng': 112.722195, 'cy': 'CY3'},
    'Tower 24 - CY3': {'lat': -7.207314, 'lng': 112.722005, 'cy': 'CY3'},
    'Tower 25 - CY3': {'lat': -7.207213, 'lng': 112.722232, 'cy': 'CY3'},
    'Tower 26 - CY3': {'lat': -7.207029, 'lng': 112.722613, 'cy': 'CY3'},
    // CC (CY1)
    'CC01 - CY1': {'lat': -7.204768, 'lng': 112.723299, 'cy': 'CY1'},
    'CC02 - CY1': {'lat': -7.205358, 'lng': 112.723571, 'cy': 'CY1'},
    'CC03 - CY1': {'lat': -7.205947, 'lng': 112.723840, 'cy': 'CY1'},
    'CC04 - CY1': {'lat': -7.206656, 'lng': 112.724164, 'cy': 'CY1'},
    // RTG
    'RTG01 - CY1': {'lat': -7.204805, 'lng': 112.722550, 'cy': 'CY1'},
    'RTG02 - CY1': {'lat': -7.205129, 'lng': 112.723000, 'cy': 'CY1'},
    'RTG03 - CY1': {'lat': -7.205998, 'lng': 112.722836, 'cy': 'CY1'},
    'RTG04 - CY1': {'lat': -7.206359, 'lng': 112.723258, 'cy': 'CY1'},
    'RTG05 - CY1': {'lat': -7.206749, 'lng': 112.723464, 'cy': 'CY1'},
    'RTG06 - CY1': {'lat': -7.207079, 'lng': 112.723899, 'cy': 'CY1'},
    'RTG07 - CY2': {'lat': -7.208641, 'lng': 112.724410, 'cy': 'CY2'},
    'RTG08 - CY2': {'lat': -7.208957, 'lng': 112.724877, 'cy': 'CY2'},
    // RS
    'RS - CY3': {'lat': -7.207700, 'lng': 112.723028, 'cy': 'CY3'},
    // Special Locations
    'Gate In/Out': {'lat': -7.2099123, 'lng': 112.7244489, 'cy': 'Special'},
    'Parking': {'lat': -7.209907, 'lng': 112.724877, 'cy': 'Special'},
  };

  IconData _getLocationIcon(String locationName) {
    if (locationName.startsWith('CC')) {
      return Icons.camera_alt;
    }
    if (locationName.startsWith('RTG')) {
      return Icons.local_shipping;
    }
    if (locationName.startsWith('RS')) {
      return Icons.construction;
    }
    if (locationName.startsWith('Tower')) {
      return Icons.router;
    }
    if (locationName == 'Gate In/Out') {
      return Icons.directions_walk;
    }
    if (locationName == 'Parking') {
      return Icons.local_parking;
    }
    return Icons.location_on;
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
    switch (deviceType) {
      case 'Access Point':
        return Icons.router;
      case 'CCTV':
        return Icons.videocam;
      case 'MMT':
        return Icons.table_chart;
      default:
        return Icons.device_unknown;
    }
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
        apiService.getAllTowers(),
        apiService.getAllCameras(),
        apiService.getAllMMTs(),
        DeviceStorageService.getDevices(),
      ]);

      final towers = results[0] as List<Tower>;
      final cameras = results[1] as List<Camera>;
      final mmts = results[2] as List<MMT>;
      final addedDevices = results[3] as List<AddedDevice>;

      final names = <String>{};
      if (_selectedDeviceType == 'Access Point') {
        names.addAll(towers.map((t) => t.towerId));
        names.addAll(addedDevices
            .where((d) => d.type == 'Access Point')
            .map((d) => d.name));
      } else if (_selectedDeviceType == 'CCTV') {
        names.addAll(cameras.map((c) => c.cameraId));
        names.addAll(
            addedDevices.where((d) => d.type == 'CCTV').map((d) => d.name));
      } else if (_selectedDeviceType == 'MMT') {
        names.addAll(mmts.map((m) => m.mmtId));
        names.addAll(
            addedDevices.where((d) => d.type == 'MMT').map((d) => d.name));
      }

      final nameList = names.where((n) => n.trim().isNotEmpty).toList();
      nameList.sort();

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
      print('Error loading used device names: $e');
    }
  }

  void _showAllUsedNames() {
    if (_usedNamesForType.isEmpty) return;
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Daftar Nama Device',
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
                              'Daftar Nama ${_selectedDeviceType}',
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
                        'Total: ${_usedNamesForType.length} nama',
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
        apiService.getAllTowers(),
        apiService.getAllCameras(),
        apiService.getAllMMTs(),
        DeviceStorageService.getDevices(),
      ]);

      final towers = results[0] as List<Tower>;
      final cameras = results[1] as List<Camera>;
      final mmts = results[2] as List<MMT>;
      final addedDevices = results[3] as List<AddedDevice>;

      final existingNames = <String>{
        ...towers.map((t) => t.towerId.toLowerCase()),
        ...cameras.map((c) => c.cameraId.toLowerCase()),
        ...mmts.map((m) => m.mmtId.toLowerCase()),
        ...addedDevices.map((d) => d.name.toLowerCase()),
      };

      final isTaken = existingNames.contains(name.toLowerCase());
      if (!mounted) return;
      setState(() {
        _isCheckingName = false;
        _nameError = isTaken ? 'Nama device sudah dipakai' : null;
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
    await _checkNameAvailability(_nameController.text);
    if (_nameError != null) {
      return;
    }
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final locationInfo = locationData[_selectedLocation];
      final latitude = locationInfo?['lat'] ?? 0.0;
      final longitude = locationInfo?['lng'] ?? 0.0;
      final containerYard = locationInfo?['cy'] ?? '';

      // Auto-fill fields sesuai template
      String deviceId = _nameController.text;
      String status = 'UP';
      String type = 'Fixed';
      int deviceCount = 1;
      String traffic = '0';
      String uptime = '0%';
      String areaType = 'Warehouse';

      // Buat device baru dengan UUID
      final newDevice = AddedDevice(
        id: const Uuid().v4(),
        type: _selectedDeviceType,
        name: deviceId,
        ipAddress: _ipAddressController.text,
        locationName: _selectedLocation,
        latitude: latitude,
        longitude: longitude,
        containerYard: containerYard,
        createdAt: DateTime.now(),
      );

      // Simpan ke storage
      await DeviceStorageService.addDevice(newDevice);

      // Simpan ke database API
      Map<String, dynamic> apiResult = {'success': false};
      String deviceIpAddress = _ipAddressController.text;

      print('=== DEBUG: Saving Device ===');
      print('Device Type: $_selectedDeviceType');
      print('Device ID: $deviceId');
      print('IP Address from input: $deviceIpAddress');
      print('Location: $_selectedLocation');
      print('Container Yard: $containerYard');

      if (_selectedDeviceType == 'Access Point') {
        print('DEBUG: Calling createTower with IP: $deviceIpAddress');
        apiResult = await apiService.createTower(
          towerId: deviceId,
          location: _selectedLocation,
          ipAddress: deviceIpAddress,
          containerYard: containerYard,
          deviceCount: deviceCount,
          status: status,
          traffic: traffic,
          uptime: uptime,
        );
        print('DEBUG: createTower response: $apiResult');
      } else if (_selectedDeviceType == 'CCTV') {
        print('DEBUG: Calling createCamera with IP: $deviceIpAddress');
        apiResult = await apiService.createCamera(
          cameraId: deviceId,
          location: _selectedLocation,
          ipAddress: deviceIpAddress,
          containerYard: containerYard,
          status: status,
          type: type,
          areaType: areaType,
        );
        print('DEBUG: createCamera response: $apiResult');
      } else if (_selectedDeviceType == 'MMT') {
        print('DEBUG: Calling createMMT with IP: $deviceIpAddress');
        apiResult = await apiService.createMMT(
          mmtId: deviceId,
          location: _selectedLocation,
          ipAddress: deviceIpAddress,
          containerYard: containerYard,
          status: status,
          type: type,
          deviceCount: deviceCount,
          traffic: traffic,
          uptime: uptime,
        );
        print('DEBUG: createMMT response: $apiResult');
      }

      // Test connectivity ke IP device dan update status secara realtime (background)
      if (apiResult['success'] == true && deviceIpAddress.isNotEmpty) {
        // Run connectivity test in background (fire-and-forget) to avoid UI blocking
        // This prevents delay in showing success notification
        apiService
            .testDeviceConnectivity(
          targetIp: deviceIpAddress,
        )
            .then((connectivityTest) {
          if (connectivityTest['success'] == true) {
            final testStatus = connectivityTest['data']['status'] ?? 'UP';
            print('Connectivity test status: $testStatus');

            // Update device status berdasarkan connectivity test result
            apiService
                .reportDeviceStatus(
              deviceType: _selectedDeviceType.toLowerCase(),
              deviceId: deviceId,
              status: testStatus,
              targetIp: deviceIpAddress,
            )
                .then((statusUpdateResult) {
              print('Status update result: $statusUpdateResult');
            }).catchError((e) {
              print('Error updating device status: $e');
            });
          }
        }).catchError((e) {
          print('Error testing device connectivity: $e');
        });
      }

      // Show success dialog immediately (no await on connectivity test)
      if (mounted) {
        final bool dbSuccess = apiResult['success'] == true;
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(dbSuccess
                ? 'Device Berhasil Ditambahkan!'
                : 'Device Ditambahkan ke Local Storage'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!dbSuccess) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        border: Border.all(color: Colors.orange),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning, color: Colors.orange),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Device tersimpan di local storage. ${apiResult['message'] ?? 'Database tidak dapat diakses'}',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.orange.shade900),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (dbSuccess) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        border: Border.all(color: Colors.green),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Device berhasil ditambahkan ke database!',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.green.shade900),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  _buildInfoRow('Device ID:', deviceId),
                  const SizedBox(height: 8),
                  _buildInfoRow('Tipe Device:', _selectedDeviceType),
                  const SizedBox(height: 8),
                  _buildInfoRow('Lokasi:', _selectedLocation),
                  const SizedBox(height: 8),
                  _buildInfoRow('IP Address:', _ipAddressController.text),
                  const SizedBox(height: 8),
                  _buildInfoRow('Status:', status),
                  const SizedBox(height: 8),
                  _buildInfoRow('Type:', type),
                  const SizedBox(height: 8),
                  _buildInfoRow('Container Yard:', containerYard),
                  if (_selectedDeviceType == 'Access Point') ...[
                    const SizedBox(height: 8),
                    _buildInfoRow('Device Count:', deviceCount.toString()),
                    const SizedBox(height: 8),
                    _buildInfoRow('Traffic:', traffic),
                    const SizedBox(height: 8),
                    _buildInfoRow('Uptime:', uptime),
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
                child: const Text('Tambah Device Lagi'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context, rootNavigator: true)
                      .pushNamedAndRemoveUntil('/dashboard', (route) => false);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1976D2),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Kembah ke Dashboard'),
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
      _selectedLocation = 'Tower 1 - CY2';
      _nameController.clear();
      _ipAddressController.clear();
      _nameError = null;
      _isCheckingName = false;
    });
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
    return Container(
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
          const Spacer(),
          _buildHeaderOpenButton(
            '+ Add Device',
            const AddDevicePage(),
            isActive: true,
          ),
          const SizedBox(width: 12),
          _buildHeaderOpenButton('Dashboard', const DashboardPage()),
          const SizedBox(width: 12),
          _buildHeaderOpenButton('Access Point', const NetworkPage()),
          const SizedBox(width: 12),
          _buildHeaderOpenButton('CCTV', const CCTVPage()),
          const SizedBox(width: 12),
          _buildHeaderOpenButton('Alerts', const AlertsPage()),
          const SizedBox(width: 12),
          _buildHeaderButton('Logout', () => _showLogoutDialog(context)),
          const SizedBox(width: 12),
          // Profile Icon
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfilePage()),
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
        content: const Text('Apakah Anda yakin ingin logout?',
            style: TextStyle(color: Colors.black87)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal', style: TextStyle(color: Colors.black87)),
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
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 600),
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tambah Device Baru',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // ===== TIPE DEVICE =====
                        const Text(
                          'Tipe Device',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.grey[300]!,
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.grey[50],
                          ),
                          child: DropdownButton<String>(
                            value: _selectedDeviceType,
                            isExpanded: true,
                            underline: const SizedBox(),
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
                                .map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Row(
                                  children: [
                                    Icon(
                                      _getDeviceIcon(value),
                                      color: const Color(0xFF1976D2),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(value),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // ===== NAMA DEVICE =====
                        const Text(
                          'Nama Device',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _nameController,
                          onChanged: _onNameChanged,
                          decoration: InputDecoration(
                            hintText: 'Masukkan nama device',
                            helperText:
                                'Contoh: ${_getDeviceNameExample(_selectedDeviceType)}',
                            suffixIcon: _isCheckingName
                                ? const Padding(
                                    padding: EdgeInsets.all(12),
                                    child: SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  )
                                : (_nameController.text.isNotEmpty &&
                                        _nameError == null)
                                    ? const Icon(
                                        Icons.check_circle,
                                        color: Colors.green,
                                      )
                                    : null,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: Color(0xFF1976D2),
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Nama Device tidak boleh kosong';
                            }
                            if (_nameError != null) {
                              return _nameError;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 8),
                        if (_isLoadingUsedNames)
                          const Row(
                            children: [
                              SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Memuat nama yang sudah digunakan...',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          )
                        else if (_usedNamesForType.isNotEmpty)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Nama ${_selectedDeviceType} yang sudah digunakan:',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black54,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: [
                                  ..._usedNamesForType
                                      .take(10)
                                      .map((name) => Chip(
                                            label: Text(
                                              name,
                                              style:
                                                  const TextStyle(fontSize: 11),
                                            ),
                                            backgroundColor:
                                                const Color(0xFFF1F3F4),
                                          )),
                                  if (_usedNamesForType.length > 10)
                                    ActionChip(
                                      label: Text(
                                        '+${_usedNamesForType.length - 10} lainnya',
                                        style: const TextStyle(fontSize: 11),
                                      ),
                                      backgroundColor: const Color(0xFFE0E0E0),
                                      onPressed: _showAllUsedNames,
                                    ),
                                ],
                              ),
                            ],
                          )
                        else
                          const Text(
                            'Belum ada nama device terpakai untuk tipe ini.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        const SizedBox(height: 24),

                        // ===== IP ADDRESS =====
                        const Text(
                          'IP Address',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _ipAddressController,
                          decoration: InputDecoration(
                            hintText: 'Masukkan IP address',
                            helperText:
                                'Format: xxx.xxx.xxx.xxx (Contoh: 10.2.71.60)',
                            prefixIcon: const Icon(Icons.router),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: Color(0xFF1976D2),
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'IP Address tidak boleh kosong';
                            }
                            final ipRegex = RegExp(r'^(\d{1,3}\.){3}\d{1,3}$');
                            if (!ipRegex.hasMatch(value)) {
                              return 'Format IP Address tidak valid';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),

                        // ===== LOKASI (DROPDOWN dari Tower Coordinates) =====
                        const Text(
                          'Lokasi',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.grey[300]!,
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.grey[50],
                          ),
                          child: DropdownButton<String>(
                            value: _selectedLocation,
                            isExpanded: true,
                            underline: const SizedBox(),
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  _selectedLocation = newValue;
                                });
                              }
                            },
                            items: locationData.keys
                                .map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Row(
                                  children: [
                                    Icon(
                                      _getLocationIcon(value),
                                      color: const Color(0xFF1976D2),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(child: Text(value)),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 40),

                        // ===== SUBMIT BUTTON =====
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _submitForm,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1976D2),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 4,
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add),
                                SizedBox(width: 8),
                                Text(
                                  'Tambah Device',
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
        ],
      ),
    );
  }
}
