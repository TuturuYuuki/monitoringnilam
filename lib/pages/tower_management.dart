import 'package:flutter/material.dart';
import 'package:monitoring/models/tower_model.dart';
import 'package:monitoring/services/api_service.dart';
import 'package:monitoring/services/device_storage_service.dart';
import 'dart:async';
import '../dashboard.dart';
import '../network.dart';
import '../cctv.dart';
import '../alerts.dart';
import '../report_page.dart';
import '../add_device.dart';
import '../profile.dart';
import '../main.dart';

class TowerManagementPage extends StatefulWidget {
  const TowerManagementPage({super.key});

  @override
  State<TowerManagementPage> createState() => _TowerManagementPageState();
}

class _TowerManagementPageState extends State<TowerManagementPage> {
  final ApiService _apiService = ApiService();

  List<Tower> _towers = [];
  bool _isLoading = true;
  int currentPage = 0;
  final int itemsPerPage = 5;
  Timer? _refreshTimer;
  DateTime? _lastRefreshTime;

  @override
  void initState() {
    super.initState();
    _loadTowers();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted) {
        _loadTowers();
      }
    });
  }

  int get totalTowers => _towers.length;
  int get onlineTowers => _towers.where((t) => t.status == 'UP').length;
  int get downTowers => _towers.where((t) => t.status != 'UP').length;

  List<Tower> get paginatedData {
    int start = currentPage * itemsPerPage;
    int end = (start + itemsPerPage > _towers.length)
        ? _towers.length
        : start + itemsPerPage;
    return _towers.sublist(start, end);
  }

  int get totalPages => (_towers.length / itemsPerPage).ceil();

  Future<void> _loadTowers() async {
    try {
      final towers = await _apiService.getAllTowers();
      if (mounted) {
        setState(() {
          _towers = towers;
          _isLoading = false;
          _lastRefreshTime = DateTime.now();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading towers: $e')),
        );
      }
    }
  }

  Future<void> _deleteTower(Tower tower) async {
    try {
      // Delete dari database via API (need to implement backend endpoint)
      await _apiService.deleteTower(tower.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tower ${tower.towerId} deleted')),
        );
        _loadTowers();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting tower: $e')),
        );
      }
    }
  }

  Future<void> _editTower(Tower tower) async {
    final towerIdController = TextEditingController(text: tower.towerId);
    final locationController = TextEditingController(text: tower.location);
    final ipController = TextEditingController(text: tower.ipAddress);
    String selectedYard = tower.containerYard;
    double selectedLat = tower.latitude ?? -7.209191;
    double selectedLng = tower.longitude ?? 112.725250;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: StatefulBuilder(
              builder: (context, setStateDialog) => Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Edit Tower',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Tower ID (editable)
                  TextField(
                    controller: towerIdController,
                    decoration: const InputDecoration(
                      labelText: 'Tower ID',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Location
                  TextField(
                    controller: locationController,
                    decoration: const InputDecoration(
                      labelText: 'Location Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // IP Address
                  TextField(
                    controller: ipController,
                    decoration: const InputDecoration(
                      labelText: 'IP Address',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Container Yard dropdown
                  DropdownButtonFormField<String>(
                    value: selectedYard,
                    decoration: const InputDecoration(
                      labelText: 'Container Yard',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'CY1', child: Text('CY1')),
                      DropdownMenuItem(value: 'CY2', child: Text('CY2')),
                      DropdownMenuItem(value: 'CY3', child: Text('CY3')),
                    ],
                    onChanged: (value) {
                      setStateDialog(() {
                        selectedYard = value ?? 'CY1';
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Position info
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Position',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Latitude: ${selectedLat.toStringAsFixed(6)}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Longitude: ${selectedLng.toStringAsFixed(6)}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: () async {
                            final result = await showDialog(
                              context: context,
                              builder: (context) => _buildMapPickerDialog(
                                initialLat: selectedLat,
                                initialLng: selectedLng,
                              ),
                            );
                            if (result != null) {
                              setStateDialog(() {
                                selectedLat = result['latitude'];
                                selectedLng = result['longitude'];
                              });
                            }
                          },
                          icon: const Icon(Icons.location_on),
                          label: const Text('Change Position'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            try {
                              await _apiService.updateTower(
                                tower.id,
                                {
                                  'ip_address': ipController.text,
                                  'location': locationController.text,
                                },
                              );
                              
                              // Update position if changed
                              await _apiService.updateTowerPosition(
                                tower.id,
                                selectedLat,
                                selectedLng,
                              );

                              if (mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('✅ Tower updated successfully'),
                                  ),
                                );
                                _loadTowers();
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error: $e')),
                                );
                              }
                            }
                          },
                          child: const Text('Update Tower'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showAddTowerDialog() {
    final towerIdController = TextEditingController();
    final locationController = TextEditingController();
    final ipController = TextEditingController();
    String selectedYard = 'CY1';
    double? selectedLat;
    double? selectedLng;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Add New Tower',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),

                // Tower ID (manual input)
                TextField(
                  controller: towerIdController,
                  decoration: const InputDecoration(
                    labelText: 'Tower ID (e.g., AP 01)',
                    hintText: 'Enter tower identifier',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                // Location
                TextField(
                  controller: locationController,
                  decoration: const InputDecoration(
                    labelText: 'Location Name',
                    hintText: 'e.g., Gate 1 - CY1',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                // IP Address
                TextField(
                  controller: ipController,
                  decoration: const InputDecoration(
                    labelText: 'IP Address',
                    hintText: '192.168.1.1',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),

                // Container Yard dropdown
                DropdownButtonFormField<String>(
                  value: selectedYard,
                  decoration: const InputDecoration(
                    labelText: 'Container Yard',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'CY1', child: Text('CY1')),
                    DropdownMenuItem(value: 'CY2', child: Text('CY2')),
                    DropdownMenuItem(value: 'CY3', child: Text('CY3')),
                  ],
                  onChanged: (value) {
                    selectedYard = value ?? 'CY1';
                  },
                ),
                const SizedBox(height: 16),

                // Position info
                StatefulBuilder(
                  builder: (context, setStateDialog) => Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Position',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (selectedLat != null && selectedLng != null)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Latitude: ${selectedLat!.toStringAsFixed(6)}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Longitude: ${selectedLng!.toStringAsFixed(6)}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              const SizedBox(height: 8),
                            ],
                          ),
                        ElevatedButton.icon(
                          onPressed: () async {
                            // Show map picker dialog
                            final result = await showDialog(
                              context: context,
                              builder: (context) => _buildMapPickerDialog(),
                            );
                            if (result != null) {
                              setStateDialog(() {
                                selectedLat = result['latitude'];
                                selectedLng = result['longitude'];
                              });
                            }
                          },
                          icon: const Icon(Icons.location_on),
                          label: const Text('Select Position'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          if (towerIdController.text.isEmpty ||
                              locationController.text.isEmpty ||
                              ipController.text.isEmpty ||
                              selectedLat == null ||
                              selectedLng == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please fill all fields'),
                              ),
                            );
                            return;
                          }

                          try {
                            final result =
                                await _apiService.createTower(
                              towerId: towerIdController.text,
                              location: locationController.text,
                              ipAddress: ipController.text,
                              containerYard: selectedYard,
                              latitude: selectedLat!,
                              longitude: selectedLng!,
                            );

                            if (mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('✅ Tower added successfully'),
                                ),
                              );
                              _loadTowers();
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          }
                        },
                        child: const Text('Add Tower'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMapPickerDialog({double? initialLat, double? initialLng}) {
    const mapMinLat = -7.212;
    const mapMaxLat = -7.205;
    const mapMinLng = 112.722;
    const mapMaxLng = 112.730;

    double selectedLat = initialLat ?? -7.209191;
    double selectedLng = initialLng ?? 112.725250;

    return StatefulBuilder(
      builder: (context, setStateDialog) => AlertDialog(
        title: const Text('Select Tower Position'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: Column(
            children: [
              const Text(
                'Tap on the map to select position',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: GestureDetector(
                  onTapDown: (details) {
                    const mapWidth = 300.0;
                    const mapHeight = 300.0;

                    final xPercent = details.localPosition.dx / mapWidth;
                    final yPercent = details.localPosition.dy / mapHeight;

                    final newLat = mapMaxLat -
                        (yPercent * (mapMaxLat - mapMinLat));
                    final newLng = mapMinLng +
                        (xPercent * (mapMaxLng - mapMinLng));

                    setStateDialog(() {
                      selectedLat = newLat;
                      selectedLng = newLng;
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.blue, width: 2),
                      color: const Color(0xFFF0F4F8),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Stack(
                      children: [
                        // Grid
                        CustomPaint(
                          painter: _GridPainter(),
                          size: Size.infinite,
                        ),
                        // Marker
                        Positioned(
                          left: ((selectedLng - mapMinLng) /
                                  (mapMaxLng - mapMinLng)) *
                              300,
                          top: ((mapMaxLat - selectedLat) /
                                  (mapMaxLat - mapMinLat)) *
                              300,
                          child: Transform.translate(
                            offset: const Offset(-15, -15),
                            child: Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.location_on,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Lat: ${selectedLat.toStringAsFixed(6)}, Lng: ${selectedLng.toStringAsFixed(6)}',
                style: const TextStyle(fontSize: 12),
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
            onPressed: () => Navigator.pop(
              context,
              {'latitude': selectedLat, 'longitude': selectedLng},
            ),
            child: const Text('Select'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2C3E50),
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : LayoutBuilder(
                    builder: (context, constraints) {
                      return _buildContent(context, constraints);
                    },
                  ),
          ),
          _buildFooter(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTowerDialog,
        backgroundColor: const Color(0xFF1976D2),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildContent(BuildContext context, BoxConstraints constraints) {
    final isMobile = constraints.maxWidth < 600;
    final cardWidth = isMobile ? double.infinity : (constraints.maxWidth - 48) / 3;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title and Last Update
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Master Tower',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Central Access Point Management Dashboard',
                    style: TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
              if (_lastRefreshTime != null)
                Text(
                  'Last Update: ${_lastRefreshTime!.hour.toString().padLeft(2, '0')}:${_lastRefreshTime!.minute.toString().padLeft(2, '0')}:${_lastRefreshTime!.second.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
            ],
          ),
          const SizedBox(height: 24),

          // Stat Cards
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _buildStatCard('Total Towers', '$totalTowers', const Color(0xFF1976D2), width: cardWidth),
              _buildStatCard('ONLINE', '$onlineTowers', const Color(0xFF4CAF50), width: cardWidth),
              _buildStatCard('DOWN', '$downTowers', Colors.red, width: cardWidth),
            ],
          ),
          const SizedBox(height: 16),

          // Refresh Button
          _buildRefreshButton(cardWidth),
          const SizedBox(height: 24),

          // Tower Table
          if (_towers.isEmpty)
            Center(
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  Icon(Icons.router, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text(
                    'No Towers Registered',
                    style: TextStyle(fontSize: 18, color: Colors.white70),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _showAddTowerDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('Add First Tower'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1976D2),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),
            )
          else
            _buildTowerTable(),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color, {double? width}) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          Container(
            width: 8,
            height: 60,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRefreshButton(double? width) {
    return SizedBox(
      width: width,
      child: ElevatedButton.icon(
        onPressed: _loadTowers,
        icon: const Icon(Icons.refresh, color: Colors.white),
        label: const Text(
          'Refresh Data',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4CAF50),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Widget _buildTowerTable() {
    return Column(
      children: [
        // Table Header Row
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFC6B430),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          ),
          child: Row(
            children: [
              _buildHeaderCell('Tower ID', flex: 2),
              _buildHeaderCell('Location', flex: 3),
              _buildHeaderCell('IP Address', flex: 2),
              _buildHeaderCell('Yard', flex: 1),
              _buildHeaderCell('Position', flex: 2),
              _buildHeaderCell('Status', flex: 1),
              _buildHeaderCell('Action', flex: 2, isLast: true),
            ],
          ),
        ),

        // Table Data Rows
        ...paginatedData.map((tower) => _buildTableRow(tower)),

        // Pagination
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(8)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: currentPage > 0
                    ? () => setState(() => currentPage--)
                    : null,
                icon: const Icon(Icons.chevron_left),
              ),
              ...List.generate(
                totalPages,
                (index) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ElevatedButton(
                    onPressed: () => setState(() => currentPage = index),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: currentPage == index
                          ? const Color(0xFF1976D2)
                          : Colors.grey[300],
                      foregroundColor: currentPage == index
                          ? Colors.white
                          : Colors.black,
                      minimumSize: const Size(40, 40),
                      padding: EdgeInsets.zero,
                    ),
                    child: Text('${index + 1}'),
                  ),
                ),
              ),
              IconButton(
                onPressed: currentPage < totalPages - 1
                    ? () => setState(() => currentPage++)
                    : null,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTableRow(Tower tower) {
    final statusColor = tower.status == 'UP' ? const Color(0xFF4CAF50) : Colors.red;
    
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFE8D5C4),
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!, width: 1),
        ),
      ),
      child: Row(
        children: [
          _buildTableCell(tower.towerId, flex: 2, fontWeight: FontWeight.bold),
          _buildTableCell(tower.location, flex: 3),
          _buildTableCell(tower.ipAddress, flex: 2),
          _buildTableCell(tower.containerYard, flex: 1),
          _buildTableCell('${(tower.latitude ?? 0).toStringAsFixed(4)}, ${(tower.longitude ?? 0).toStringAsFixed(4)}', flex: 2, fontSize: 11),
          _buildTableCell(
            tower.status,
            flex: 1,
            color: statusColor,
            fontWeight: FontWeight.bold,
          ),
          // Action buttons
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: () => _editTower(tower),
                    icon: const Icon(Icons.edit, color: Color(0xFF1976D2), size: 20),
                    tooltip: 'Edit',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => _confirmDelete(tower),
                    icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                    tooltip: 'Delete',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String label, {int flex = 1, bool isLast = false}) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          border: Border(
            right: isLast
                ? BorderSide.none
                : const BorderSide(color: Colors.white, width: 1),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            fontSize: 13,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildTableCell(String text, {
    int flex = 1,
    FontWeight fontWeight = FontWeight.normal,
    Color color = Colors.black87,
    double fontSize = 12,
  }) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Text(
          text,
          style: TextStyle(
            fontWeight: fontWeight,
            color: color,
            fontSize: fontSize,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  void _confirmDelete(Tower tower) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Tower?'),
        content: Text('Are you sure you want to delete ${tower.towerId}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteTower(tower);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: const Color(0xFF1976D2),
      child: const Center(
        child: Text(
          '©2026 TPK Nilam Monitoring System. All Rights Reserved.',
          style: TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      color: const Color(0xFF1976D2),
      child: Row(
        children: [
          const Text(
            'Terminal Nilam - Master Tower',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 30),
          Expanded(
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildHeaderOpenButton('+ Add New Device', const AddDevicePage()),
                    const SizedBox(width: 12),
                    _buildHeaderOpenButton('Dashboard', const DashboardPage()),
                    const SizedBox(width: 12),
                    _buildHeaderOpenButton('Access Point', const NetworkPage()),
                    const SizedBox(width: 12),
                    _buildHeaderOpenButton('CCTV', const CCTVPage()),
                    const SizedBox(width: 12),
                    _buildHeaderOpenButton('Alert', const AlertsPage()),
                    const SizedBox(width: 12),
                    _buildHeaderOpenButton('Alert Report', const ReportPage()),
                    const SizedBox(width: 12),
                    _buildHeaderButton('Master Tower', () {}, isActive: true),
                    const SizedBox(width: 12),
                    _buildHeaderButton('MMT Monitor', () => Navigator.pushNamed(context, '/mmt-monitoring')),
                    const SizedBox(width: 12),
                    _buildHeaderButton('Logout', () => showLogoutDialog(context)),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilePage())),
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

  Widget _buildHeaderOpenButton(String text, Widget page, {bool isActive = false}) {
    return buildLiquidGlassButton(text, () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => page)), isActive: isActive);
  }

  Widget _buildHeaderButton(String text, VoidCallback onPressed, {bool isActive = false}) {
    return buildLiquidGlassButton(text, onPressed, isActive: isActive);
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.3)
      ..strokeWidth = 1;

    for (double i = 0; i <= size.width; i += size.width / 4) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }

    for (double i = 0; i <= size.height; i += size.height / 4) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter oldDelegate) => false;
}
