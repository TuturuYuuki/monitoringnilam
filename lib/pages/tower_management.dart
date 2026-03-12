import 'package:flutter/material.dart';
import 'package:monitoring/models/tower_model.dart';
import 'package:monitoring/services/api_service.dart';
import '../main.dart';
import '../utils/device_icon_resolver.dart';
import '../widgets/global_header_bar.dart';
import '../widgets/global_sidebar_nav.dart';

class TowerManagementPage extends StatefulWidget {
  const TowerManagementPage({super.key});

  @override
  State<TowerManagementPage> createState() => _TowerManagementPageState();
}

class _TowerManagementPageState extends State<TowerManagementPage> {
  final ApiService _apiService = ApiService();

  final _towerIdController = TextEditingController();
  String _selectedMasterType = 'TOWER';
  String _selectedYard = 'CY1';
  double? _selectedLat;
  double? _selectedLng;

  List<Tower> _towers = [];
  List<Map<String, dynamic>> _masterLocations = [];
  bool _isLoading = true;
  final int itemsPerPage = 10;
  int _currentPage = 1;
  DateTime? _lastRefreshTime;

  @override
  void initState() {
    super.initState();
    _loadTowers();
    _loadNonTowerMasters();
  }

  @override
  void dispose() {
    _towerIdController.dispose();
    super.dispose();
  }

  Future<void> _loadTowers() async {
    try {
      final towers = await _apiService.getAllTowers();
      if (!mounted) return;
      setState(() {
        _towers = towers;
        _isLoading = false;
        _lastRefreshTime = DateTime.now();
        _currentPage = 1; // Reset to first page when loading new data
      });
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadNonTowerMasters() async {
    try {
      final all = await _apiService.getAllMasterLocations();
      if (!mounted) return;
      setState(() {
        _masterLocations = all;
      });
    } catch (_) {
      // keep silent to avoid noisy UX when optional data fails
    }
  }

  Future<void> _openPositionPicker({String? preferredYard}) async {
    final result = await Navigator.pushNamed(
      context,
      '/dashboard',
      arguments: {
        'pickTowerPosition': true,
        'yard': preferredYard ?? _selectedYard,
      },
    );

    if (!mounted || result is! Map) return;

    final lat = double.tryParse(result['lat'].toString());
    final lng = double.tryParse(result['lng'].toString());
    final yard = result['containerYard']?.toString();

    if (lat != null && lng != null) {
      setState(() {
        _selectedLat = lat;
        _selectedLng = lng;
        if (yard != null && yard.isNotEmpty) {
          _selectedYard = yard;
        }
      });
    }
  }

  String _getExampleForType(String type) {
    switch (type) {
      case 'TOWER':
        return 'Tower ID (Example: T01)';
      case 'RTG':
        return 'RTG ID (Example: RTG01)';
      case 'RS':
        return 'RS ID (Example: RS01)';
      case 'CC':
        return 'CC ID (Example: CC01)';
      default:
        return 'Code (Example: ${type}01)';
    }
  }

  IconData _getIconForType(String type) {
    return DeviceIconResolver.iconForType(type);
  }

  Map<String, int> _countMastersByLocation() {
    final counts = {
      'CY1': 0,
      'CY2': 0,
      'CY3': 0,
      'GATE': 0,
      'PARKING': 0,
    };

    for (final master in _masterLocations) {
      final normalizedYard = (master['container_yard'] ?? '')
          .toString()
          .toUpperCase()
          .replaceAll(' ', '');
      if (counts.containsKey(normalizedYard)) {
        counts[normalizedYard] = (counts[normalizedYard] ?? 0) + 1;
      }
    }

    return counts;
  }

  List<Map<String, dynamic>> _getUnifiedMasterList() {
    final unified = <Map<String, dynamic>>[];

    for (final master in _masterLocations) {
      unified.add({
        'type': (master['location_type'] ?? 'OTHER').toString().toUpperCase(),
        'code': master['location_code'] ?? '-',
        'yard': master['container_yard'] ?? '-',
        'id': int.tryParse((master['item_id'] ?? '').toString()) ?? -1,
        'source': 'master_location_point',
        ...master,
      });
    }

    unified
        .sort((a, b) => a['code'].toString().compareTo(b['code'].toString()));
    return unified;
  }

  Future<void> _submitForm() async {
    if (_towerIdController.text.trim().isEmpty ||
        _selectedLat == null ||
        _selectedLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${_selectedMasterType == 'TOWER' ? 'Tower ID' : 'Location code'} dan posisi wajib diisi.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final code = _towerIdController.text.trim().toUpperCase();
    final response = await _apiService.createMasterLocation(
      locationType: _selectedMasterType,
      locationCode: code,
      locationName: code,
      containerYard: _selectedYard,
      latitude: _selectedLat!,
      longitude: _selectedLng!,
    );

    if (!mounted) return;

    if (response['success'] == true) {
      _towerIdController.clear();
      setState(() {
        _selectedLat = null;
        _selectedLng = null;
      });
      await _loadNonTowerMasters();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _selectedMasterType == 'TOWER'
                ? 'Master Tower berhasil disimpan.'
                : 'Master $_selectedMasterType berhasil disimpan.',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response['message']?.toString() ??
              'Gagal menyimpan master location.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteTower(Tower tower) async {
    final response = await _apiService.deleteMasterLocation(tower.id);
    if (!mounted) return;

    if (response['success'] == true) {
      await _loadTowers();
      await _loadNonTowerMasters();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tower berhasil dihapus.'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(response['message']?.toString() ?? 'Gagal menghapus tower.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showDeleteDialog(Tower tower) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Delete ${tower.towerId}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteTower(tower);
    }
  }

  Future<void> _showEditDialog(Tower tower) async {
    final idController = TextEditingController(text: tower.towerId);
    String selectedType = 'TOWER';
    String selectedYard =
        tower.containerYard.isEmpty ? 'CY1' : tower.containerYard;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocalState) => AlertDialog(
          title: Text('Edit ${tower.towerId}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: const InputDecoration(labelText: 'Location Type'),
                  items: const ['TOWER']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setLocalState(() => selectedType = value);
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: idController,
                  decoration: const InputDecoration(labelText: 'Nama'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedYard,
                  decoration: const InputDecoration(labelText: 'Lokasi'),
                  items: ['CY1', 'CY2', 'CY3', 'GATE', 'PARKING']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setLocalState(() => selectedYard = value);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final payload = <String, dynamic>{
                  'tower_id': idController.text.trim(),
                  'container_yard': selectedYard,
                };
                Navigator.pop(context, {
                  ...payload,
                });
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1976D2)),
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );

    idController.dispose();
    if (result == null) return;

    final masterPayload = <String, dynamic>{
      'location_type': 'TOWER',
      'location_code': (result['tower_id'] ?? '').toString(),
      'location_name': (result['tower_id'] ?? '').toString(),
      'container_yard': (result['container_yard'] ?? '').toString(),
    };
    final response =
        await _apiService.updateMasterLocation(tower.id, masterPayload);
    if (!mounted) return;

    if (response['success'] == true) {
      await _loadTowers();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Tower berhasil diupdate.'),
            backgroundColor: Colors.green),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(response['message']?.toString() ?? 'Gagal update tower.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = isMobileScreen(context);
    return Scaffold(
      backgroundColor: const Color(0xFF2C3E50),
      body: Column(
        children: [
          const GlobalHeaderBar(currentRoute: '/tower-management'),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sidebar (Kiri) — hidden on mobile
                if (!isMobile)
                  const GlobalSidebarNav(currentRoute: '/tower-management'),
                if (!isMobile) const SizedBox(width: 12),
                // Content (Kanan)
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(isMobile ? 10 : 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInventoryStats(),
                        const SizedBox(height: 24),
                        _buildAddTowerForm(),
                        const SizedBox(height: 28),
                        const Text(
                          'All Master Location',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _buildUnifiedMasterTable(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildInventoryStats() {
    final counts = _countMastersByLocation();
    final items = [
      {'label': 'Container Yard 1', 'value': '${counts['CY1'] ?? 0}', 'color': const Color(0xFF1976D2)},
      {'label': 'Container Yard 2', 'value': '${counts['CY2'] ?? 0}', 'color': Colors.orange},
      {'label': 'Container Yard 3', 'value': '${counts['CY3'] ?? 0}', 'color': Colors.teal},
      {'label': 'Gate',             'value': '${counts['GATE'] ?? 0}', 'color': Colors.purple},
      {'label': 'Parking',          'value': '${counts['PARKING'] ?? 0}', 'color': Colors.pink},
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final perRow = w < 400 ? 2 : w < 780 ? 3 : 5;
        const spacing = 16.0;
        final boxWidth = (w - spacing * (perRow - 1)) / perRow;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: items.map((item) => SizedBox(
            width: boxWidth,
            child: _statBox(
              item['label'] as String,
              item['value'] as String,
              item['color'] as Color,
            ),
          )).toList(),
        );
      },
    );
  }

  Widget _statBox(String title, String value, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.82),
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: color, width: 6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.black54,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddTowerForm() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.82),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _selectedMasterType == 'TOWER'
                    ? 'Register New Master Data'
                    : 'Register New Master ${_selectedMasterType.toLowerCase()}',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              if (_lastRefreshTime != null)
                Text(
                  'Sync: ${_lastRefreshTime!.hour.toString().padLeft(2, '0')}:${_lastRefreshTime!.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedMasterType,
                  decoration: const InputDecoration(
                    labelText: 'Master Type',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  items: const ['TOWER', 'RTG', 'RS', 'CC']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedMasterType = val);
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: _buildTextField(
                  _getExampleForType(_selectedMasterType),
                  _towerIdController,
                  _getIconForType(_selectedMasterType),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedYard,
                  decoration: const InputDecoration(
                    labelText: 'Yard Area',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.grid_view),
                  ),
                  items: ['CY1', 'CY2', 'CY3', 'GATE', 'PARKING']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedYard = val);
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildPositionStatus()),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () => _openPositionPicker(),
                icon: const Icon(Icons.place_outlined),
                label: const Text('Pick Position'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueGrey[700],
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1976D2),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 34, vertical: 18),
                ),
                child: const Text('SAVE',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
      String label, TextEditingController ctrl, IconData icon) {
    return TextField(
      controller: ctrl,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        border: const OutlineInputBorder(),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _buildPositionStatus() {
    final hasPos = _selectedLat != null && _selectedLng != null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: hasPos ? Colors.green[50] : Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: hasPos ? Colors.green[200]! : Colors.orange[200]!),
      ),
      child: Row(
        children: [
          Icon(
            hasPos ? Icons.check_circle : Icons.info_outline,
            size: 16,
            color: hasPos ? Colors.green : Colors.orange,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              hasPos
                  ? 'Selected: ${_selectedLat!.toStringAsFixed(5)}, ${_selectedLng!.toStringAsFixed(5)}'
                  : 'Belum pilih posisi di area CY',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: hasPos ? Colors.green[800] : Colors.orange[800],
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteNonTowerMaster(Map<String, dynamic> item) async {
    final id = int.tryParse((item['item_id'] ?? '').toString());
    if (id == null) return;

    final response = await _apiService.deleteMasterLocation(id);
    if (!mounted) return;

    if (response['success'] == true) {
      await _loadNonTowerMasters();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Master Location berhasil dihapus.'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response['message']?.toString() ??
              'Failed To Delete Master Location.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showEditNonTowerDialog(Map<String, dynamic> item) async {
    final locType = (item['location_type'] ?? '').toString();
    final locCode = (item['location_code'] ?? '').toString();
    final locName = (item['location_name'] ?? '').toString();
    final locYard = (item['container_yard'] ?? '').toString();
    final itemId = int.tryParse((item['item_id'] ?? '').toString());

    final nameController = TextEditingController(text: locName);
    final codeController = TextEditingController(text: locCode);
    String selectedType = locType;
    String selectedYard = locYard.isEmpty ? 'CY1' : locYard;

    if (itemId == null) return;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocalState) => AlertDialog(
          title: Text('Edit $locType'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: const InputDecoration(labelText: 'Location Type'),
                  items: ['TOWER', 'RTG', 'RS', 'CC']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setLocalState(() => selectedType = value);
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Location Name'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedYard,
                  decoration: const InputDecoration(labelText: 'Location'),
                  items: ['CY1', 'CY2', 'CY3', 'GATE', 'PARKING']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setLocalState(() => selectedYard = value);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final payload = <String, dynamic>{
                  'location_type': selectedType,
                  'location_code': codeController.text
                      .trim()
                      .toUpperCase()
                      .replaceAll(' ', '_'),
                  'location_name': nameController.text.trim(),
                  'container_yard': selectedYard,
                };
                Navigator.pop(context, payload);
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1976D2)),
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );

    nameController.dispose();
    codeController.dispose();

    if (result == null) return;

    final response = await _apiService.updateMasterLocation(itemId, result);
    if (!mounted) return;

    if (response['success'] == true) {
      await _loadNonTowerMasters();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Master Location Successfully Updated'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response['message']?.toString() ??
              'Gagal update master location.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  bool _isUpStatus(String status) {
    final normalized = status.trim().toUpperCase();
    return normalized == 'UP' || normalized == 'ONLINE';
  }

  Future<void> _showMasterDetailDialog(Map<String, dynamic> item) async {
    final type = (item['type'] ?? item['location_type'] ?? 'OTHER')
        .toString()
        .toUpperCase();
    final code = (item['code'] ?? item['location_code'] ?? '-').toString();
    final name = (item['location_name'] ?? code).toString();
    final yard = (item['yard'] ?? item['container_yard'] ?? '-')
        .toString()
        .toUpperCase();

    final towers = await _apiService.getAllTowers();
    final mmts = await _apiService.getAllMMTs();
    final cameras = await _apiService.getAllCameras();

    bool matchByLocation(String location) {
      final loc = location.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
      final codeNorm = code.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
      final nameNorm = name.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
      final byCode = codeNorm.isNotEmpty && loc.contains(codeNorm);
      final byName = nameNorm.isNotEmpty && loc.contains(nameNorm);
      return byCode || byName;
    }

    final devices = <Map<String, String>>[];

    for (final tower in towers) {
      if ((type == 'TOWER' &&
              tower.towerId.toUpperCase() == code.toUpperCase()) ||
          (type != 'TOWER' && matchByLocation(tower.location))) {
        devices.add({
          'type': 'TOWER',
          'name': tower.towerId,
          'status': tower.status,
          'ip': tower.ipAddress,
          'location': tower.location,
        });
      }
    }

    for (final mmt in mmts) {
      if (matchByLocation(mmt.location)) {
        devices.add({
          'type': 'MMT',
          'name': mmt.mmtId,
          'status': mmt.status,
          'ip': mmt.ipAddress,
          'location': mmt.location,
        });
      }
    }

    for (final camera in cameras) {
      if (matchByLocation(camera.location)) {
        devices.add({
          'type': 'CCTV',
          'name': camera.cameraId,
          'status': camera.status,
          'ip': camera.ipAddress,
          'location': camera.location,
        });
      }
    }

    final upCount = devices.where((d) => _isUpStatus(d['status'] ?? '')).length;
    final downCount = devices.length - upCount;

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Detail $type - $code'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Location: $yard',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              Row(
                children: [
                  _buildSummaryChip(
                      'Total', devices.length.toString(), Colors.blueGrey),
                  const SizedBox(width: 8),
                  _buildSummaryChip('UP', upCount.toString(), Colors.green),
                  const SizedBox(width: 8),
                  _buildSummaryChip('DOWN', downCount.toString(), Colors.red),
                ],
              ),
              const SizedBox(height: 14),
              if (devices.isEmpty)
                const Text('No Device Have Been Detected At This Location')
              else
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 220),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: devices.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final d = devices[index];
                      final isUp = _isUpStatus(d['status'] ?? '');
                      return Container(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Icon(
                                DeviceIconResolver.iconForType(d['type'] ?? ''),
                                color: DeviceIconResolver.colorForType(
                                    d['type'] ?? ''),
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${d['name']} (${d['type']})',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700),
                                  ),
                                  Text('IP: ${d['ip'] ?? '-'}',
                                      style: const TextStyle(fontSize: 11)),
                                  Text('Lokasi: ${d['location'] ?? '-'}',
                                      style: const TextStyle(fontSize: 11)),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: (isUp ? Colors.green : Colors.red)
                                    .withOpacity(0.12),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                    color: isUp ? Colors.green : Colors.red),
                              ),
                              child: Text(
                                (d['status'] ?? '-').toUpperCase(),
                                style: TextStyle(
                                  color: isUp ? Colors.green : Colors.red,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.6)),
      ),
      child: Text(
        '$label: $value',
        style:
            TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  Widget _buildUnifiedMasterTable() {
    final unified = _getUnifiedMasterList();

    final totalPages = (unified.length / itemsPerPage).ceil();
    if (totalPages > 0 && _currentPage > totalPages) {
      _currentPage = totalPages;
    }

    final startIndex = (_currentPage - 1) * itemsPerPage;
    final endIndex = (startIndex + itemsPerPage).clamp(0, unified.length);
    final data = unified.sublist(startIndex, endIndex);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white
            .withOpacity(0.9), // Sedikit lebih solid agar teks jelas
        borderRadius: BorderRadius.circular(16), // Border radius lebih lembut
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // HEADER TABEL
          Container(
            color: const Color(0xFF1976D2),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: const Row(
              children: [
                Expanded(
                    flex: 2,
                    child: Text('TYPE',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            letterSpacing: 1))),
                Expanded(
                    flex: 4,
                    child: Text('NAME / ID',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            letterSpacing: 1))),
                Expanded(
                    flex: 2,
                    child: Text('LOCATION',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            letterSpacing: 1))),
                Expanded(
                    flex: 2,
                    child: Center(
                        child: Text('ACTIONS',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                letterSpacing: 1)))),
              ],
            ),
          ),

          if (data.isEmpty)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Text('Belum ada data Master.',
                  style: TextStyle(color: Colors.grey)),
            )
          else
            // BODY TABEL
            ...data.map((item) {
              final bool isLast = data.last == item;
              return Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isLast ? Colors.transparent : Colors.grey.shade200,
                      width: 1,
                    ),
                  ),
                ),
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                child: Row(
                  children: [
                    // Kolom Type dengan Badge
                    Expanded(
                      flex: 2,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getTypeColor(item['type'].toString())
                                .withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            item['type'].toString(),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _getTypeColor(item['type'].toString()),
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Kolom Name
                    Expanded(
                      flex: 4,
                      child: Text(
                        (item['location_name'] ?? item['code'] ?? '-')
                            .toString(),
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: Colors.black87),
                      ),
                    ),

                    // Kolom Yard
                    Expanded(
                      flex: 2,
                      child: Row(
                        children: [
                          const Icon(Icons.grid_view_rounded,
                              size: 14, color: Colors.grey),
                          const SizedBox(width: 6),
                          Text(
                            (item['yard'] ?? '-').toString(),
                            style: const TextStyle(
                                fontSize: 13,
                                color: Colors.black54,
                                fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),

                    // Kolom Action
                    Expanded(
                      flex: 2,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildActionBtn(Icons.info_outline, Colors.teal,
                              () => _showMasterDetailDialog(item)),
                          const SizedBox(width: 8),
                          _buildActionBtn(Icons.edit_outlined, Colors.blue,
                              () => _showEditNonTowerDialog(item)),
                          const SizedBox(width: 8),
                          _buildActionBtn(Icons.delete_outline, Colors.red,
                              () => _showDeleteNonTowerDialog(item)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),

          // FOOTER / PAGINATION
          if (unified.length > itemsPerPage)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Page $_currentPage of $totalPages  •  Total ${unified.length} items',
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.blueGrey.shade700,
                        fontWeight: FontWeight.w500),
                  ),
                  Row(
                    children: [
                      _buildPageBtn(
                          Icons.chevron_left,
                          _currentPage > 1
                              ? () => setState(() => _currentPage--)
                              : null),
                      const SizedBox(width: 12),
                      _buildPageBtn(
                          Icons.chevron_right,
                          _currentPage < totalPages
                              ? () => setState(() => _currentPage++)
                              : null),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

// Helper Widget untuk Tombol Aksi agar seragam
  Widget _buildActionBtn(IconData icon, Color color, VoidCallback onTap) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
      ),
    );
  }

// Helper Widget untuk Tombol Navigasi Halaman
  Widget _buildPageBtn(IconData icon, VoidCallback? onTap) {
    bool isDisabled = onTap == null;
    return MouseRegion(
      cursor: isDisabled ? SystemMouseCursors.basic : SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDisabled ? Colors.grey.shade200 : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: isDisabled ? Colors.transparent : Colors.grey.shade300),
          ),
          child: Icon(icon,
              color: isDisabled ? Colors.grey : Colors.blueAccent, size: 20),
        ),
      ),
    );
  }

  Color _getTypeColor(String type) {
    return DeviceIconResolver.colorForType(type);
  }

  Future<void> _showDeleteNonTowerDialog(Map<String, dynamic> item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Delete ${item['location_code'] ?? '-'}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteNonTowerMaster(item);
    }
  }

  Future<void> _showPositionHistory(Tower tower) async {
    final result = await _apiService.getTowerPositionHistory(tower.id);

    if (!mounted) return;

    if (result['success'] == true) {
      final history =
          (result['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Position History - ${tower.towerId}'),
          content: SizedBox(
            width: 500,
            child: ListView.builder(
              itemCount: history.length,
              itemBuilder: (context, index) {
                final entry = history[index];
                final oldPos = entry['old_latitude'] != null &&
                        entry['old_longitude'] != null
                    ? '${double.parse(entry['old_latitude'].toString()).toStringAsFixed(5)}, ${double.parse(entry['old_longitude'].toString()).toStringAsFixed(5)}'
                    : 'N/A';
                final newPos =
                    '${double.parse(entry['new_latitude'].toString()).toStringAsFixed(5)}, ${double.parse(entry['new_longitude'].toString()).toStringAsFixed(5)}';
                final date = DateTime.tryParse(entry['created_at'] ?? '')
                        ?.toString()
                        .split('.')[0] ??
                    entry['created_at'];

                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$date - ${entry['changed_by'] ?? 'Unknown'}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text('From: $oldPos',
                          style: const TextStyle(fontSize: 11)),
                      Text('To: $newPos',
                          style: const TextStyle(
                              fontSize: 11,
                              color: Colors.green,
                              fontWeight: FontWeight.w600)),
                      if (entry['change_reason'] != null)
                        Text('Reason: ${entry['change_reason']}',
                            style: const TextStyle(
                                fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load history: ${result['message']}'),
        ),
      );
    }
  }

  Widget _buildHeader(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Container(
      width: screenWidth,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      color: const Color(0xFF1976D2),
      child: Row(
        children: [
          const Text(
            'Terminal Nilam',
            style: TextStyle(
                color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
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
                    _buildHeaderOpenButton('Add New Device', '/add-device'),
                    const SizedBox(width: 12),
                    _buildHeaderOpenButton('Master Data', '/tower-management',
                        isActive: true),
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
                    GestureDetector(
                      onTap: () => Navigator.pushNamed(context, '/profile'),
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
                          child: const Icon(Icons.person,
                              color: Color(0xFF1976D2), size: 24),
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

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.black.withOpacity(0.8),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '©2026 TPK Nilam Monitoring System',
            style: TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderOpenButton(String text, String route,
      {bool isActive = false}) {
    return buildLiquidGlassButton(
      text,
      () => Navigator.pushNamed(context, route),
      isActive: isActive,
    );
  }

  Widget _buildHeaderButton(String text, VoidCallback onPressed,
      {bool isActive = false}) {
    return buildLiquidGlassButton(text, onPressed, isActive: isActive);
  }

  void _showLogoutDialog(BuildContext context) {
    showLogoutDialog(context);
  }
}
