import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:monitoring/main.dart';
import 'package:monitoring/theme/app_dropdown_style.dart';
import 'package:monitoring/services/api_service.dart';
import 'package:monitoring/models/alert_model.dart';
import 'package:monitoring/models/tower_model.dart';
import 'package:monitoring/widgets/global_header_bar.dart';
import 'package:monitoring/widgets/global_sidebar_nav.dart';
import 'package:monitoring/widgets/global_footer.dart';
import 'package:monitoring/utils/location_label_utils.dart';


class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  final ApiService apiService = ApiService();
  List<Alert> reportAlerts = [];
  List<Alert> _allReportAlerts = [];
  bool isLoading = false;
  Set<String> _activeDeviceKeys = {};
  final Map<String, String> _currentDeviceIps = {};
  bool _deviceInventoryLoaded = false;

  DateTimeRange _selectedRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 30)),
    end: DateTime.now(),
  );
  String _statusFilter = 'ALL';
  String _selectedDeviceType = 'ALL'; // Filter: ALL, AP, CCTV, MMT, NVR, SWITCH

  int _currentPage = 1;
  final int _itemsPerPage = 10;

  @override
  void initState() {
    super.initState();
    _fetchReportData();
  }

  Future<void> _fetchReportData() async {
    setState(() => isLoading = true);
    try {
      final resultsFuture = apiService.getAlertsReport(
        startDate: _selectedRange.start,
        endDate: _selectedRange.end,
        status: _statusFilter,
      );
      final activeDeviceKeysFuture = _loadActiveDeviceKeys();

      final results = await resultsFuture;
      final activeDeviceKeys = await activeDeviceKeysFuture;
      final syncedResults = await _syncReportAlertsWithDeviceData(results);
      final uniqueResults = _dedupeAlertsByDevice(syncedResults);

      final normalized = uniqueResults;

      setState(() {
        _activeDeviceKeys = activeDeviceKeys;
        _deviceInventoryLoaded = true;
        _allReportAlerts = normalized;
        reportAlerts = normalized;
        isLoading = false;
      });
    } catch (e) {
      print("Fetch Report Error: $e");
      debugPrint('Fetch Report Error: $e');
    }
  }


  Future<List<Alert>> _syncReportAlertsWithDeviceData(List<Alert> alerts) async {
    try {
      final towers = await apiService.getAllTowers();
      final cameras = await apiService.getAllCameras();
      final mmts = await apiService.getAllMMTs();
      final nvrs = await apiService.getAllNVRs();
      final switches = await apiService.getAllSwitches();
      // Fetch master location points to resolve full labels (RTG / TOWER formatting)
      final masterRows = await apiService.getAllMasterLocations();
      final masterOptions = buildMasterLocationOptions(masterRows);

      final Map<String, Tower> towerMap = {};
      for (final tower in towers) {
        if (tower.towerId.trim().isEmpty) continue;
        towerMap[_deviceKey('AP ${tower.towerNumber}')] = tower;
        towerMap[_deviceKey('AP${tower.towerNumber}')] = tower;
        towerMap[_deviceKey(tower.towerId)] = tower;
      }

      final cameraMap = {
        for (final camera in cameras)
          if (camera.cameraId.trim().isNotEmpty) _deviceKey(camera.cameraId): camera
      };
      final mmtMap = {
        for (final mmt in mmts)
          if (mmt.mmtId.trim().isNotEmpty) _deviceKey(mmt.mmtId): mmt
      };
      final nvrMap = {
        for (final nvr in nvrs)
          if (nvr.nvrId.trim().isNotEmpty) _deviceKey(nvr.nvrId): nvr
      };
      final switchMap = {
        for (final sw in switches)
          if (sw.switchId.trim().isNotEmpty) _deviceKey(sw.switchId): sw
      };

      // Populate current IP map for dynamic lookup
      _currentDeviceIps.clear();
      for (final t in towers) {
        if (t.towerId.trim().isNotEmpty) {
          _currentDeviceIps[_buildDeviceKey('AP', t.towerId)] = t.ipAddress;
        }
      }
      for (final c in cameras) {
        if (c.cameraId.trim().isNotEmpty) {
          final camType = c.type.toUpperCase().contains('CC') ? 'CC' : 'CCTV';
          _currentDeviceIps[_buildDeviceKey(camType, c.cameraId)] = c.ipAddress;
          _currentDeviceIps[_buildDeviceKey('CCTV', c.cameraId)] = c.ipAddress;
          _currentDeviceIps[_buildDeviceKey('CC', c.cameraId)] = c.ipAddress;
        }
      }
      for (final m in mmts) {
        if (m.mmtId.trim().isNotEmpty) {
          _currentDeviceIps[_buildDeviceKey('MMT', m.mmtId)] = m.ipAddress;
        }
      }
      for (final nvr in nvrs) {
        if (nvr.nvrId.trim().isNotEmpty) {
          _currentDeviceIps[_buildDeviceKey('NVR', nvr.nvrId)] = nvr.ipAddress;
        }
      }
      for (final sw in switches) {
        if (sw.switchId.trim().isNotEmpty) {
          _currentDeviceIps[_buildDeviceKey('SWITCH', sw.switchId)] = sw.ipAddress;
        }
      }

      return alerts.map((alert) {
        var newLocation = alert.lokasi;
        var newDeviceType = alert.deviceType;
        var isDeletedDevice = alert.isDeviceDeleted;
        final searchName = _deviceKey(_cleanDeviceName(alert.title));

        if (towerMap.containsKey(searchName)) {
          final tower = towerMap[searchName]!;
          newLocation = resolveFullLocationLabel(masterOptions, tower.location, currentContainerYard: tower.containerYard);
          newDeviceType = 'AP';
          isDeletedDevice = false;
        } else if (cameraMap.containsKey(searchName)) {
          final camera = cameraMap[searchName]!;
          newLocation = resolveFullLocationLabel(masterOptions, camera.location, currentContainerYard: camera.containerYard);
          newDeviceType = 'CCTV';
          isDeletedDevice = false;
        } else if (mmtMap.containsKey(searchName)) {
          final mmt = mmtMap[searchName]!;
          newLocation = resolveFullLocationLabel(masterOptions, mmt.location, currentContainerYard: mmt.containerYard);
          newDeviceType = 'MMT';
          isDeletedDevice = false;
        } else if (nvrMap.containsKey(searchName)) {
          final nvr = nvrMap[searchName]!;
          newLocation = resolveFullLocationLabel(masterOptions, nvr.location, currentContainerYard: nvr.containerYard);
          newDeviceType = 'NVR';
          isDeletedDevice = false;
        } else if (switchMap.containsKey(searchName)) {
          final sw = switchMap[searchName]!;
          newLocation = resolveFullLocationLabel(masterOptions, sw.location, currentContainerYard: sw.containerYard);
          newDeviceType = 'SWITCH';
          isDeletedDevice = false;
        } else {
          isDeletedDevice = true;
        }

        return alert.syncWithCurrentDeviceData(
          newLocation: newLocation,
          newDeviceType: newDeviceType,
          isDeviceDeleted: isDeletedDevice,
        );
      }).toList(growable: false);
    } catch (e) {
      debugPrint('Report alert sync failed: $e');
      return alerts;
    }
  }

  List<Alert> _dedupeAlertsByDevice(List<Alert> alerts) {
    final Map<String, Alert> latestByDevice = {};

    for (final alert in alerts) {
      final deviceKey = _alertDeviceKey(alert);
      final existing = latestByDevice[deviceKey];

      if (existing == null) {
        latestByDevice[deviceKey] = alert;
        continue;
      }

      final currentTime = DateTime.tryParse(alert.timestamp) ??
          DateTime.tryParse('${alert.tanggal ?? ''} ${alert.waktu ?? ''}');
      final existingTime = DateTime.tryParse(existing.timestamp) ??
          DateTime.tryParse('${existing.tanggal ?? ''} ${existing.waktu ?? ''}');

      final shouldReplace = currentTime == null
          ? false
          : (existingTime == null || currentTime.isAfter(existingTime));

      if (shouldReplace) {
        latestByDevice[deviceKey] = alert;
      }
    }

    final deduped = latestByDevice.values.toList();
    deduped.sort((a, b) {
      final aTime = DateTime.tryParse(a.timestamp) ??
          DateTime.tryParse('${a.tanggal ?? ''} ${a.waktu ?? ''}');
      final bTime = DateTime.tryParse(b.timestamp) ??
          DateTime.tryParse('${b.tanggal ?? ''} ${b.waktu ?? ''}');
      if (aTime == null && bTime == null) return 0;
      if (aTime == null) return 1;
      if (bTime == null) return -1;
      return bTime.compareTo(aTime);
    });

    return deduped;
  }

  Future<void> _generateReportPdf() async {
    if (reportAlerts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No data available"), backgroundColor: Colors.orange),
      );
      return;
    }

    try {
      final pdf = pw.Document();
      final sortedAlerts = reportAlerts.toList()
        ..sort((a, b) {
          final aTime = DateTime.tryParse(a.timestamp);
          final bTime = DateTime.tryParse(b.timestamp);
          if (aTime == null && bTime == null) return 0;
          if (aTime == null) return 1;
          if (bTime == null) return -1;
          return bTime.compareTo(aTime);
        });

      final filteredAlerts = _filterByDeviceType(sortedAlerts);

      final upAlerts = filteredAlerts.where((a) => !_isDownAlert(a)).toList();
      final downAlerts = filteredAlerts.where((a) => _isDownAlert(a)).toList();
      final upCount = upAlerts.length;
      final downCount = downAlerts.length;

      List<List<String>> buildRows(List<Alert> list) =>
          list.asMap().entries.map((entry) {
            final a = entry.value;
            return [
              (entry.key + 1).toString(),
              _cleanDeviceName(a.title),
              _isDownAlert(a) ? 'DOWN' : 'UP',
              _extractIpFromDescription(a.description),
              a.lokasi ?? '-',
              '${a.tanggal ?? '-'} ${a.waktu ?? '-'}',
            ];
          }).toList(growable: false);

      const tableHeaders = [
        'No',
        'Device',
        'Status',
        'IP Address',
        'Location',
        'Timestamp'
      ];

      pw.Widget pageHeader(String sectionTitle, PdfColor titleBg) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(vertical: 8),
                decoration: pw.BoxDecoration(color: titleBg),
                child: pw.Text(
                  sectionTitle,
                  style: pw.TextStyle(
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Filter Device Type: $_selectedDeviceType',
                style: const pw.TextStyle(fontSize: 10),
                textAlign: pw.TextAlign.center,
              ),
              pw.Divider(),
            ],
          );

      // ── Section 1: Device UP ──────────────────────────────────
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          header: (_) => pageHeader('Devices UP ($upCount)', PdfColors.green100),
          build: (_) => upAlerts.isEmpty
              ? [
                  pw.Center(
                    child: pw.Padding(
                      padding: const pw.EdgeInsets.only(top: 24),
                      child: pw.Text('No UP devices found',
                          style: const pw.TextStyle(fontSize: 12)),
                    ),
                  ),
                ]
              : [
                  pw.TableHelper.fromTextArray(
                    headers: tableHeaders,
                    data: buildRows(upAlerts),
                    headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    headerDecoration:
                        const pw.BoxDecoration(color: PdfColors.green200),
                    cellAlignment: pw.Alignment.center,
                    cellStyle: const pw.TextStyle(fontSize: 9),
                  ),
                ],
        ),
      );

      // ── Section 2: Device DOWN ────────────────────────────────
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          header: (_) =>
              pageHeader('Devices DOWN ($downCount)', PdfColors.red100),
          build: (_) => downAlerts.isEmpty
              ? [
                  pw.Center(
                    child: pw.Padding(
                      padding: const pw.EdgeInsets.only(top: 24),
                      child: pw.Text('No DOWN devices found',
                          style: const pw.TextStyle(fontSize: 12)),
                    ),
                  ),
                ]
              : [
                  pw.TableHelper.fromTextArray(
                    headers: tableHeaders,
                    data: buildRows(downAlerts),
                    headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    headerDecoration:
                        const pw.BoxDecoration(color: PdfColors.red200),
                    cellAlignment: pw.Alignment.center,
                    cellStyle: const pw.TextStyle(fontSize: 9),
                  ),
                ],
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'Alert_Report_${DateFormat('ddMMyy').format(DateTime.now())}',
      );
    } catch (e) {
      debugPrint("Error PDF: $e");
    }
  }

  // ==================== UI COMPONENTS ====================

  String _cleanDeviceName(String rawTitle) {
    var cleaned = rawTitle.trim();
    cleaned = cleaned.replaceAll(
        RegExp(r'\s+is\s+now\s+(up|down)\b', caseSensitive: false), '');
    cleaned = cleaned.replaceAll(
        RegExp(r'\s+is\s+(up|down)\b', caseSensitive: false), '');
    return cleaned.trim();
  }

  String _deviceKey(String raw) {
    final s = raw.trim().toLowerCase();
    return s.replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  String _extractIpFromDescription(String description) {
    // Description format: "DeviceId, IP, Location, Date, Time"
    final parts = description.split(',');
    if (parts.length >= 2) return parts[1].trim();
    return '-';
  }

  /// Unified device type normalization — used by both extraction and key building.
  String _normalizeToDeviceType(String raw) {
    final t = raw.trim().toUpperCase();
    if (t.contains('TOWER') || t == 'AP' || t.contains('ACCESS')) return 'AP';
    if (t.contains('CAM') || t.contains('CCTV')) return 'CCTV';
    if (t == 'CC' || t.contains(' CC') || RegExp(r'\bCC\d*\b').hasMatch(t)) return 'CC';
    if (t.contains('MMT')) return 'MMT';
    if (t.contains('NVR')) return 'NVR';
    if (t.contains('SWITCH')) return 'SWITCH';
    return t;
  }

  String _extractDeviceType(Alert alert) {
    if (alert.deviceType != null && alert.deviceType!.isNotEmpty) {
      final result = _normalizeToDeviceType(alert.deviceType!);
      if (result != alert.deviceType!.trim().toUpperCase()) return result;
      // Fallback: check lowercase contains for db values like 'towers', 'cameras'
      final dt = alert.deviceType!.toLowerCase();
      if (dt.contains('tower') || dt.contains('ap') || dt.contains('access')) return 'AP';
      if (dt.contains('camera') || dt.contains('cctv')) return 'CCTV';
      if (dt.contains('mmt')) return 'MMT';
      if (dt.contains('nvr')) return 'NVR';
      if (dt.contains('switch')) return 'SWITCH';
    }

    final src = '${alert.title} ${alert.description} ${alert.lokasi ?? ''}'
        .toUpperCase();
    if (RegExp(r'\b(AP|TOWER)\b').hasMatch(src)) return 'AP';
    if (RegExp(r'\b(CAM|CCTV)\b').hasMatch(src)) return 'CCTV';
    if (RegExp(r'\bMMT\b').hasMatch(src)) return 'MMT';
    if (RegExp(r'\bNVR\b').hasMatch(src)) return 'NVR';
    if (RegExp(r'\bSWITCH\b').hasMatch(src)) return 'SWITCH';
    if (RegExp(r'\bCC\d*\b').hasMatch(src)) return 'CC';
    return 'Other';
  }

  List<Alert> _filterByDeviceType(List<Alert> list) {
    if (_selectedDeviceType == 'ALL') return list;
    return list
        .where((a) => _extractDeviceType(a) == _selectedDeviceType)
        .toList();
  }

  Future<Set<String>> _loadActiveDeviceKeys() async {
    try {
      final towersFuture = apiService.getAllTowers();
      final camerasFuture = apiService.getAllCameras();
      final mmtsFuture = apiService.getAllMMTs();
      final nvrsFuture = apiService.getAllNVRs();
      final switchesFuture = apiService.getAllSwitches();

      final towers = await towersFuture;
      final cameras = await camerasFuture;
      final mmts = await mmtsFuture;
      final nvrs = await nvrsFuture;
      final switches = await switchesFuture;

      final keys = <String>{};

      for (final t in towers) {
        if (t.towerId.trim().isNotEmpty) {
          keys.add(_buildDeviceKey('AP', t.towerId));
        }
      }

      for (final c in cameras) {
        if (c.cameraId.trim().isEmpty) continue;
        final camType = c.type.toUpperCase().contains('CC') ? 'CC' : 'CCTV';
        keys.add(_buildDeviceKey(camType, c.cameraId));
        // Keep compatibility if historical rows use CCTV while inventory device is CC.
        keys.add(_buildDeviceKey('CCTV', c.cameraId));
        keys.add(_buildDeviceKey('CC', c.cameraId));
      }

      for (final m in mmts) {
        if (m.mmtId.trim().isNotEmpty) {
          keys.add(_buildDeviceKey('MMT', m.mmtId));
        }
      }

      for (final nvr in nvrs) {
        if (nvr.nvrId.trim().isNotEmpty) {
          keys.add(_buildDeviceKey('NVR', nvr.nvrId));
        }
      }

      for (final sw in switches) {
        if (sw.switchId.trim().isNotEmpty) {
          keys.add(_buildDeviceKey('SWITCH', sw.switchId));
        }
      }

      return keys;
    } catch (e) {
      debugPrint('Active device inventory load failed: $e');
      return <String>{};
    }
  }

  // Unified normalization — delegates to _normalizeToDeviceType
  String _normalizeDeviceTypeLabel(String raw) => _normalizeToDeviceType(raw);

  String _buildDeviceKey(String type, String id) {
    return '${_normalizeDeviceTypeLabel(type)}:${id.trim().toUpperCase()}';
  }

  String _resolveAlertDeviceId(Alert alert) {
    if (alert.deviceId != null && alert.deviceId!.trim().isNotEmpty) {
      return alert.deviceId!.trim();
    }

    final src = '${alert.title} ${alert.description}';
    final regex = RegExp(r'\b(?:AP|TOWER|CCTV|CAM|CC|MMT)[-_]?\d+\b',
        caseSensitive: false);
    final match = regex.firstMatch(src);
    if (match != null) {
      return match.group(0)!.toUpperCase();
    }

    final cleaned = _cleanDeviceName(alert.title);
    return cleaned.isEmpty ? '-' : cleaned;
  }

  String _alertDeviceKey(Alert alert) {
    final resolvedType = _extractDeviceType(alert);
    final resolvedId = _resolveAlertDeviceId(alert);
    return _buildDeviceKey(resolvedType, resolvedId);
  }

  bool _isDeletedDevice(Alert alert) {
    if (alert.isDeviceDeleted) {
      return true;
    }
    if (!_deviceInventoryLoaded || _activeDeviceKeys.isEmpty) {
      return false;
    }
    return !_activeDeviceKeys.contains(_alertDeviceKey(alert));
  }

  bool _isDownAlert(Alert alert) {
    final titleLower = alert.title.toLowerCase();
    final descLower = alert.description.toLowerCase();
    final combinedText = '$titleLower $descLower';

    // Check if explicitly mentions DOWN or offline
    if (combinedText.contains(' down') ||
        combinedText.contains('is down') ||
        combinedText.contains('offline') ||
        combinedText.contains('unreachable')) {
      return true;
    }

    // Critical severity with no explicit UP mention
    if (alert.severity.toLowerCase() == 'critical' &&
        !combinedText.contains(' up') &&
        !combinedText.contains('is up')) {
      return true;
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = isMobileScreen(context);
    return Scaffold(
      backgroundColor: AppDropdownStyle.standardPageBackground,
      body: Column(
        children: [
          const GlobalHeaderBar(currentRoute: '/report'),
          Expanded(
            child: GlobalSidebarNav(
                currentRoute: '/report',
                enabled: !isMobile,
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(isMobile ? 12 : 24),
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      _buildFilterBar(),
                      const SizedBox(height: 20),
                      _buildReportTable(),
                    ],
                  ),
                )),
          ),
          const GlobalFooter(),
        ],
      ),
    );
  }


  Widget _buildFilterBar() {
    final isMobile = isMobileScreen(context);
    return liquidGlassCard(
      borderRadius: 18,
      blurSigma: 16,
      padding: const EdgeInsets.all(12),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _pickDateRange,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                    decoration: appGlassFieldDecoration(radius: 16),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_month,
                            size: 16, color: Colors.white.withValues(alpha: 0.85)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "${DateFormat('dd/MM').format(_selectedRange.start)} - ${DateFormat('dd/MM').format(_selectedRange.end)}",
                            style: const TextStyle(
                                fontSize: 12, color: Colors.white),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: appGlassFieldDecoration(radius: 16),
                  child: AnimatedDropdownButton(
                    value: _statusFilter,
                    items: const ['ALL', 'UP', 'DOWN'],
                    backgroundColor: AppDropdownStyle.menuBackground,
                    onChanged: (String? val) {
                      if (val != null) {
                        setState(() => _statusFilter = val);
                        _fetchReportData();
                      }
                    },
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _generateReportPdf,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.picture_as_pdf, size: 18, color: Colors.white),
                      SizedBox(width: 8),
                      Text("Export PDF",
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12)),
                    ],
                  ),
                ),
              ],
            )
          : Row(
              children: [
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 44,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          _pickDateRange();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: appGlassFieldDecoration(radius: 16),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_month,
                                  size: 16,
                                  color: Colors.white.withValues(alpha: 0.85)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "${DateFormat('dd/MM').format(_selectedRange.start)} - ${DateFormat('dd/MM').format(_selectedRange.end)}",
                                  style: const TextStyle(
                                      fontSize: 12, color: Colors.white),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: SizedBox(
                    height: 44,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: appGlassFieldDecoration(radius: 16),
                      child: AnimatedDropdownButton(
                        value: _statusFilter,
                        items: const ['ALL', 'UP', 'DOWN'],
                        backgroundColor: AppDropdownStyle.menuBackground,
                        onChanged: (String? val) {
                          if (val != null) {
                            setState(() => _statusFilter = val);
                            _fetchReportData();
                          }
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    onPressed: _generateReportPdf,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.picture_as_pdf,
                            size: 18, color: Colors.white),
                        SizedBox(width: 8),
                        Text("Export PDF",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Future<void> _pickDateRange() async {
    DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: _selectedRange,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
      builder: (context, child) {
        final bool isMobile = MediaQuery.of(context).size.width < 600;
        // App Core Colors
        const Color primaryBlue = Color(0xFF1976D2);
        const Color backgroundDark = Color(0xFF2C3E50);
        const Color surfaceDark = Color(0xFF34495E);

        return Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isMobile ? 300 : 550,
              maxHeight: isMobile ? 315 : 600,
            ),
            child: Container(
              margin: EdgeInsets.all(isMobile ? 4 : 24),
              decoration: BoxDecoration(
                boxShadow: isMobile ? [] : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(isMobile ? 12 : 28),
                child: Theme(
                  data: Theme.of(context).copyWith(
                    brightness: Brightness.dark,
                    colorScheme: ColorScheme.dark(
                      primary: primaryBlue,
                      onPrimary: Colors.white,
                      surface: backgroundDark.withValues(alpha: 1.0),
                      onSurface: Colors.white,
                      secondary: const Color(0xFF64B5F6),
                      onSecondary: Colors.white,
                      surfaceContainerHighest: surfaceDark.withValues(alpha: 0.8),
                    ),
                    secondaryHeaderColor: Colors.white,
                    appBarTheme: const AppBarTheme(
                      backgroundColor: primaryBlue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      centerTitle: false,
                      iconTheme: IconThemeData(color: Colors.white),
                    ),
                    dialogTheme: DialogThemeData(
                      backgroundColor: backgroundDark,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(isMobile ? 16 : 28),
                      ),
                    ),
                    inputDecorationTheme: InputDecorationTheme(
                      labelStyle: const TextStyle(color: Colors.white70),
                      hintStyle: const TextStyle(color: Colors.white38),
                      suffixIconColor: Colors.white70,
                      prefixIconColor: Colors.white70,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.white38),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.white24),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF00D9FF)),
                      ),
                    ),
                    datePickerTheme: DatePickerThemeData(
                      backgroundColor: Colors.transparent,
                      headerBackgroundColor: primaryBlue,
                      headerForegroundColor: Colors.white,
                      rangeSelectionBackgroundColor:
                          primaryBlue.withValues(alpha: 0.45),
                      rangePickerHeaderBackgroundColor: primaryBlue,
                      rangePickerHeaderForegroundColor: Colors.white,
                      rangePickerSurfaceTintColor: Colors.transparent,
                      surfaceTintColor: Colors.transparent,
                      rangePickerHeaderHeadlineStyle: TextStyle(
                        fontSize: isMobile ? 14 : 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      rangePickerHeaderHelpStyle: TextStyle(
                        fontSize: isMobile ? 8 : 12,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                      dayStyle: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: isMobile ? 8 : 14,
                      ),
                      weekdayStyle: TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.bold,
                        fontSize: isMobile ? 8 : 12,
                      ),
                      dayForegroundColor:
                          WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.disabled)) {
                          return Colors.white24;
                        }
                        return Colors.white;
                      }),
                      todayForegroundColor:
                          WidgetStateProperty.all(const Color(0xFFFFD54F)),
                      todayBorder: const BorderSide(
                          color: Color(0xFFFFD54F), width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(isMobile ? 16 : 28),
                      ),
                    ),
                    textButtonTheme: TextButtonThemeData(
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                        padding: isMobile ? const EdgeInsets.symmetric(horizontal: 12, vertical: 8) : null,
                        textStyle: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: isMobile ? 11 : 14),
                      ),
                    ),
                  ),
                  child: Transform.scale(
                    scale: isMobile ? 0.82 : 1.0,
                    child: Material(
                      color: backgroundDark,
                      child: child,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedRange = picked);
      _fetchReportData();
    }
  }

  Widget _buildReportTable() {
    if (isLoading) return const Center(child: CircularProgressIndicator());
    if (reportAlerts.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 100),
        child: Center(
            child: Text("No data available",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500))),
      );
    }

    final filteredAlerts = _filterByDeviceType(_allReportAlerts);
    final totalCount = filteredAlerts.length;
    final isMobile = isMobileScreen(context);

    return liquidGlassCard(
      borderRadius: 18,
      blurSigma: 16,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: const BoxDecoration(
              color: Color(0xFF1976D2),
              borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 20,
              runSpacing: 12,
              children: [
                const Text(
                  'Alert List',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    letterSpacing: 0.5,
                  ),
                ),
                if (isMobile)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      _buildHeaderFilters(),
                      const SizedBox(height: 12),
                      _buildHeaderPagination(totalCount),
                    ],
                  )
                else
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_deviceInventoryLoaded && _activeDeviceKeys.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: Text(
                            'Inventori tidak tersedia',
                            style: TextStyle(
                              color: Colors.orange.shade100,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      _buildHeaderFilters(),
                      const SizedBox(width: 24),
                      _buildHeaderPagination(totalCount),
                    ],
                  ),
              ],
            ),
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final minW = isMobile ? 800.0 : 1000.0;
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: minW,
                    maxWidth: math.max(constraints.maxWidth, minW),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 14),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFFC6B430).withValues(alpha: 0.8),
                              const Color(0xFFC6B430).withValues(alpha: 0.4),
                            ],
                          ),
                        ),
                        child: const Row(
                          children: [
                            Expanded(
                                flex: 3,
                                child: _ReportHeaderText('DEVICE',
                                    color: Colors.white)),
                            Expanded(
                                flex: 4,
                                child: _ReportHeaderText('LOCATION',
                                    color: Colors.white)),
                            Expanded(
                                flex: 3,
                                child: _ReportHeaderText('IP ADDRESS',
                                    color: Colors.white)),
                            Expanded(
                                flex: 2,
                                child: _ReportHeaderText('STATUS',
                                    color: Colors.white)),
                            Expanded(
                                flex: 3,
                                child: _ReportHeaderText('TIMESTAMP',
                                    color: Colors.white)),
                            Expanded(
                                flex: 2,
                                child: _ReportHeaderText('ACTION',
                                    color: Colors.white)),
                          ],
                        ),
                      ),
                      ...filteredAlerts
                      .skip((_currentPage - 1) * _itemsPerPage)
                          .take(_itemsPerPage)
                          .map((a) {
                        final isDown = _isDownAlert(a);
                        final statusText = isDown ? 'DOWN' : 'UP';
                        final statusColor = isDown
                            ? const Color(0xFFFF5252)
                            : const Color(0xFF69F0AE);

                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            border: Border(
                              bottom: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.05),
                                  width: 1),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border(
                                      right: BorderSide(
                                        color: Colors.white.withValues(alpha: 0.1),
                                        width: 0.8,
                                      ),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        _cleanDeviceName(a.title),
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      if (_isDeletedDevice(a))
                                        Container(
                                          margin: const EdgeInsets.only(top: 4),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.orange.withValues(alpha: 0.2),
                                            borderRadius:
                                                BorderRadius.circular(999),
                                            border: Border.all(
                                              color:
                                                  Colors.orange.withValues(alpha: 0.75),
                                              width: 1,
                                            ),
                                          ),
                                          child: const Text(
                                            'Deleted Device',
                                            style: TextStyle(
                                              color: Colors.orangeAccent,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 10,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              _buildReportValueCell(
                                a.lokasi ?? '-',
                                flex: 4,
                                fontWeight: FontWeight.w700,
                                align: TextAlign.center,
                                color: Colors.white.withValues(alpha: 0.9),
                                hasDivider: true,
                              ),
                              (() {
                                final originalIp = _extractIpFromDescription(a.description);
                                final deviceKey = _alertDeviceKey(a);
                                final currentIp = _currentDeviceIps[deviceKey];
                                final isDeleted = _isDeletedDevice(a);

                                return Expanded(
                                  flex: 3,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: Border(
                                        right: BorderSide(
                                          color: Colors.white.withValues(alpha: 0.1),
                                          width: 0.8,
                                        ),
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          currentIp ?? originalIp,
                                          style: TextStyle(
                                            color: Colors.white.withValues(alpha: 0.7),
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        if (isDeleted && currentIp == null)
                                          Text(
                                            'Historical',
                                            style: TextStyle(
                                              color: Colors.white.withValues(alpha: 0.3),
                                              fontSize: 9,
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              })(),
                              Expanded(
                                flex: 2,
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border(
                                      right: BorderSide(
                                        color: Colors.white.withValues(alpha: 0.1),
                                        width: 0.8,
                                      ),
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      statusText,
                                      style: TextStyle(
                                        color: statusColor,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 13,
                                        letterSpacing: 0.6,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              _buildReportValueCell(
                                '${a.tanggal ?? ''} ${a.waktu ?? ''}',
                                flex: 3,
                                color: Colors.white.withValues(alpha: 0.6),
                                hasDivider: true,
                              ),
                              Expanded(
                                flex: 2,
                                child: Center(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.delete,
                                            color: Colors.red, size: 20),
                                        onPressed: () => _confirmDeleteAlert(a),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildReportSummaryChip(String label, int value, Color accent) {
    final isWhite = accent == Colors.white;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color:
            isWhite ? Colors.white.withValues(alpha: 0.18) : accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isWhite
              ? Colors.white.withValues(alpha: 0.45)
              : accent.withValues(alpha: 0.5),
        ),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          color: isWhite ? Colors.white : accent,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildReportValueCell(
    String text, {
    required int flex,
    FontWeight fontWeight = FontWeight.w600,
    Color color = Colors.black87,
    TextAlign align = TextAlign.center,
    bool hasDivider = false,
  }) {
    return Expanded(
      flex: flex,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            right: hasDivider
                ? BorderSide(
                    color: Colors.white.withValues(alpha: 0.1),
                    width: 0.8,
                  )
                : BorderSide.none,
          ),
        ),
        child: Text(
          text,
          textAlign: align,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: color,
            fontWeight: fontWeight,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildReportStatusTable({
    required String title,
    required List<Alert> data,
    required bool isDownTable,
  }) {
    final tone = isDownTable ? Colors.red : Colors.green;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tone.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: tone.withValues(alpha: 0.08),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15),
                ),
                Text('${data.length} device',
                    style: const TextStyle(color: Colors.black54)),
              ],
            ),
          ),
          if (data.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text('No Data', style: TextStyle(color: Colors.black54)),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: data.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final a = data[index];
                return ListTile(
                  leading: Icon(
                    isDownTable ? Icons.cloud_off : Icons.cloud_done,
                    color: tone,
                    size: 24,
                  ),
                  title: Text(
                    _cleanDeviceName(a.title),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('${a.lokasi} | ${a.tanggal} ${a.waktu}'),
                  trailing: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: tone.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isDownTable ? 'DOWN' : 'UP',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: tone,
                        fontSize: 12,
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteAlert(Alert alert) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete confirmation'),
        content: Text('Delete log report for ${alert.title}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await apiService.deleteAlert(alert.id);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Log successfully deleted'),
              backgroundColor: Colors.green),
        );
        _fetchReportData();
      }
    }
  }

  Widget _buildHeaderFilters() {
    final filterOptions = ['ALL', 'AP', 'CCTV', 'MMT', 'NVR', 'SWITCH'];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: filterOptions.map((type) {
        final isSelected = _selectedDeviceType == type;
        return InkWell(
          onTap: () => setState(() {
            _selectedDeviceType = type;
            _currentPage = 1;
          }),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.white.withValues(alpha: 0.2)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color:
                    isSelected ? Colors.white : Colors.white.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isSelected)
                  const Icon(Icons.check, color: Colors.white, size: 14),
                if (isSelected) const SizedBox(width: 4),
                Text(
                  type,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildHeaderPagination(int totalCount) {
    final totalPagesCount = math.max(1, (totalCount / _itemsPerPage).ceil());

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: Colors.white, size: 20),
            onPressed:
                _currentPage > 1 ? () => setState(() => _currentPage--) : null,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 4),
          for (int i = 1; i <= totalPagesCount; i++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: InkWell(
                onTap: () => setState(() => _currentPage = i),
                child: Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color:
                        _currentPage == i ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '$i',
                    style: TextStyle(
                      color: _currentPage == i
                          ? const Color(0xFF1976D2)
                          : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(width: 4),
          IconButton(
            icon:
                const Icon(Icons.chevron_right, color: Colors.white, size: 20),
            onPressed: _currentPage < totalPagesCount
                ? () => setState(() => _currentPage++)
                : null,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

class _ReportHeaderText extends StatelessWidget {
  final String text;

  final Color color;

  const _ReportHeaderText(this.text, {this.color = Colors.white});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: color,
        fontWeight: FontWeight.bold,
        fontSize: 13,
        letterSpacing: 0.5,
      ),
    );
  }
}
