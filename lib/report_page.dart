import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:intl/intl.dart';
import 'services/api_service.dart';
import 'models/alert_model.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'dashboard.dart';
import 'network.dart';
import 'cctv.dart';
import 'add_device.dart';
import 'alerts.dart';
import 'profile.dart';
import 'main.dart';
import 'pages/tower_management.dart';
import 'pages/mmt_monitoring.dart';
import 'widgets/global_header_bar.dart';
import 'widgets/global_sidebar_nav.dart';

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  final ApiService apiService = ApiService();
  List<Alert> reportAlerts = [];
  bool isLoading = false;

  DateTimeRange _selectedRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 30)),
    end: DateTime.now(),
  );
  String _statusFilter = 'ALL';
  String _selectedDeviceType = 'ALL'; // Filter: ALL, AP, CCTV, MMT

  @override
  void initState() {
    super.initState();
    _fetchReportData();
  }

  Future<void> _fetchReportData() async {
    setState(() => isLoading = true);
    try {
      final results = await apiService.getAlertsReport(
        startDate: _selectedRange.start,
        endDate: _selectedRange.end,
        status: _statusFilter,
      );
      setState(() {
        reportAlerts = results;
        isLoading = false;
      });
    } catch (e) {
      print("Fetch Report Error: $e");
      setState(() => isLoading = false);
    }
  }

  Future<void> _generateReportPdf() async {
    if (reportAlerts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("No Data Found"), backgroundColor: Colors.orange),
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
      
      final uniqueDevices = <String, Alert>{};
      for (final a in filteredAlerts) {
        final devName = _cleanDeviceName(a.title);
        if (!uniqueDevices.containsKey(devName)) {
          uniqueDevices[devName] = a;
        }
      }

      final upAlerts = uniqueDevices.values.where((a) => !_isDownAlert(a)).toList();
      final downAlerts = uniqueDevices.values.where((a) => _isDownAlert(a)).toList();
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
        'No', 'Device', 'Status', 'IP', 'Location', 'Timestamp'
      ];

      pw.Widget pageHeader(String sectionTitle, PdfColor titleBg) =>
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(vertical: 6),
                child: pw.Text(
                  'ALERT MONITORING REPORT',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ),
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
          header: (_) => pageHeader('Device UP ($upCount)', PdfColors.green100),
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
                    headerStyle:
                        pw.TextStyle(fontWeight: pw.FontWeight.bold),
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
              pageHeader('Device DOWN ($downCount)', PdfColors.red100),
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
                    headerStyle:
                        pw.TextStyle(fontWeight: pw.FontWeight.bold),
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

  String _extractIpFromDescription(String description) {
    // Description format: "DeviceId, IP, Location, Date, Time"
    final parts = description.split(',');
    if (parts.length >= 2) return parts[1].trim();
    return '-';
  }

  String _extractDeviceType(Alert alert) {
    if (alert.deviceType != null && alert.deviceType!.isNotEmpty) {
       final dt = alert.deviceType!.toLowerCase();
       if (dt.contains('tower') || dt.contains('ap')) return 'AP';
       if (dt.contains('camera') || dt.contains('cctv')) return 'CCTV';
       if (dt.contains('mmt')) return 'MMT';
    }

    final src =
        '${alert.title} ${alert.description} ${alert.lokasi ?? ''}'
            .toUpperCase();
    if (RegExp(r'\b(AP|TOWER)\b').hasMatch(src)) return 'AP';
    if (RegExp(r'\b(CAM|CCTV)\b').hasMatch(src)) return 'CCTV';
    if (RegExp(r'\bMMT\b').hasMatch(src)) return 'MMT';
    return 'Other';
  }

  List<Alert> _filterByDeviceType(List<Alert> list) {
    if (_selectedDeviceType == 'ALL') return list;
    return list
        .where((a) => _extractDeviceType(a) == _selectedDeviceType)
        .toList();
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
      backgroundColor: const Color(0xFF2C3E50),
      body: Column(
        children: [
          const GlobalHeaderBar(currentRoute: '/report'),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isMobile) const GlobalSidebarNav(currentRoute: '/report'),
                if (!isMobile) const SizedBox(width: 12),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(isMobile ? 12 : 24),
                    child: Column(
                      children: [
                        _buildDeviceTypeFilter(),
                        const SizedBox(height: 12),
                        _buildFilterBar(),
                        const SizedBox(height: 20),
                        _buildReportTable(),
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
                    _buildHeaderOpenButton('Dashboard', const DashboardPage()),
                    const SizedBox(width: 12),
                    _buildHeaderOpenButton('Access Point', const NetworkPage()),
                    const SizedBox(width: 12),
                    _buildHeaderOpenButton('CCTV', const CCTVPage()),
                    const SizedBox(width: 12),
                    _buildHeaderOpenButton('MMT', const MMTMonitoringPage()),
                    const SizedBox(width: 12),
                    _buildHeaderOpenButton('Alert', const AlertsPage()),
                    const SizedBox(width: 12),
                    _buildHeaderOpenButton('Alert Report', const ReportPage(),
                        isActive: true),
                    const SizedBox(width: 12),
                    _buildHeaderButton(
                        'Logout', () => showLogoutDialog(context)),
                    const SizedBox(width: 12),
                    _buildProfileIcon(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderOpenButton(String text, Widget openPage,
      {bool isActive = false}) {
    return buildLiquidGlassButton(
        text,
        () => Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => openPage)),
        isActive: isActive);
  }

  Widget _buildHeaderButton(String text, VoidCallback onPressed) {
    return buildLiquidGlassButton(text, onPressed);
  }

  Widget _buildProfileIcon() {
    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (context) => const ProfilePage())),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9), shape: BoxShape.circle),
        child: const Icon(Icons.person, color: Color(0xFF1976D2), size: 24),
      ),
    );
  }

  Widget _buildDeviceTypeFilter() {
    final filterOptions = ['ALL', 'AP', 'CCTV', 'MMT'];
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: filterOptions.map((type) {
          final isSelected = _selectedDeviceType == type;
          return FilterChip(
            label: Text(type),
            selected: isSelected,
            onSelected: (selected) {
              setState(() {
                _selectedDeviceType = type;
              });
            },
            selectedColor: const Color(0xFF1976D2).withOpacity(0.2),
            checkmarkColor: const Color(0xFF1976D2),
            backgroundColor: Colors.white.withOpacity(0.7),
            labelStyle: TextStyle(
              color: isSelected ? const Color(0xFF1976D2) : Colors.black87,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFilterBar() {
    final isMobile = isMobileScreen(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _pickDateRange,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_month,
                            size: 16, color: Colors.blue),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "${DateFormat('dd/MM').format(_selectedRange.start)} - ${DateFormat('dd/MM').format(_selectedRange.end)}",
                            style: const TextStyle(fontSize: 12),
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
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _statusFilter,
                      isExpanded: true,
                      style: const TextStyle(fontSize: 12, color: Colors.black),
                      items: ['ALL', 'UP', 'DOWN']
                          .map((s) => DropdownMenuItem(
                                value: s,
                                child: SizedBox(
                                  width: double.infinity,
                                  child: Text(s),
                                ),
                              ))
                          .toList(),
                      onChanged: (val) {
                        setState(() => _statusFilter = val!);
                        _fetchReportData();
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _generateReportPdf,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                          print("DEBUG: Date range clicked!");
                          _pickDateRange();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.grey.shade400),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_month,
                                  size: 16, color: Colors.blue),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "${DateFormat('dd/MM').format(_selectedRange.start)} - ${DateFormat('dd/MM').format(_selectedRange.end)}",
                                  style: const TextStyle(fontSize: 12),
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
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _statusFilter,
                          isExpanded: true,
                          style:
                              const TextStyle(fontSize: 12, color: Colors.black),
                          items: ['ALL', 'UP', 'DOWN']
                              .map((s) => DropdownMenuItem(
                                    value: s,
                                    child: SizedBox(
                                      width: double.infinity,
                                      child: Text(s),
                                    ),
                                  ))
                              .toList(),
                          onChanged: (val) {
                            print("DEBUG: Dropdown changed to $val");
                            if (val != null) {
                              setState(() => _statusFilter = val);
                              _fetchReportData();
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () {
                      print("DEBUG: Export PDF clicked!");
                      _generateReportPdf();
                    },
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
        return Center(
          child: Container(
            constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width > 600
                    ? 450
                    : double.infinity),
            child: Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(
                    primary: Color(0xFF1976D2),
                    onPrimary: Colors.white,
                    surface: Colors.white,
                    onSurface: Colors.black),
                dialogTheme: DialogTheme(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16))),
              ),
              child: child!,
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
            child: Text("No Data Found",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500))),
      );
    }

    // Sort by timestamp (newest first)
    final sortedAlerts = reportAlerts.toList()
      ..sort((a, b) {
        final aTime = DateTime.tryParse(a.timestamp);
        final bTime = DateTime.tryParse(b.timestamp);
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return bTime.compareTo(aTime); // Descending (newest first)
      });

    final filteredAlerts = _filterByDeviceType(sortedAlerts);
    
    // Deduplicate to count unique UP/DOWN devices to match Dashboard
    final uniqueDevices = <String, Alert>{};
    for (final a in filteredAlerts) {
      final devName = _cleanDeviceName(a.title);
      if (!uniqueDevices.containsKey(devName)) {
        uniqueDevices[devName] = a;
      }
    }

    final upCount = filteredAlerts.where((a) => !_isDownAlert(a)).length;
    final downCount = filteredAlerts.where((a) => _isDownAlert(a)).length;
    final totalCount = filteredAlerts.length;
    final isMobile = isMobileScreen(context);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.94),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: const BoxDecoration(
              color: Color(0xFF1976D2),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Wrap(
              spacing: 12,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text(
                  'Unified Device Report',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                _buildReportSummaryChip('TOTAL EVENTS', totalCount, Colors.white),
                _buildReportSummaryChip('UP EVENTS', upCount, const Color(0xFF2E7D32)),
                _buildReportSummaryChip('DOWN EVENTS', downCount, const Color(0xFFC62828)),
              ],
            ),
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final minW = isMobile ? 920.0 : 1120.0;
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
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    width: double.infinity,
                    color: const Color(0xFFC6B430),
                    child: const Row(
                      children: [
                        Expanded(flex: 1, child: _ReportHeaderText('NO')),
                        Expanded(flex: 3, child: _ReportHeaderText('DEVICE')),
                        Expanded(flex: 2, child: _ReportHeaderText('STATUS')),
                        Expanded(flex: 3, child: _ReportHeaderText('IP ADDRESS')),
                        Expanded(flex: 4, child: _ReportHeaderText('LOCATION')),
                        Expanded(flex: 3, child: _ReportHeaderText('TIMESTAMP')),
                      ],
                    ),
                  ),
                  ...filteredAlerts.asMap().entries.map((entry) {
                    final index = entry.key + 1;
                    final a = entry.value;
                    final isDown = _isDownAlert(a);
                    final statusText = isDown ? 'DOWN' : 'UP';
                    final statusColor = isDown ? Colors.red : Colors.green;

                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8D5C4),
                        border: Border(
                          bottom: BorderSide(color: Colors.grey[300]!, width: 1),
                        ),
                      ),
                      child: Row(
                        children: [
                          _buildReportValueCell(index.toString(), flex: 1),
                          _buildReportValueCell(
                            _cleanDeviceName(a.title),
                            flex: 3,
                            fontWeight: FontWeight.w800,
                            align: TextAlign.center,
                          ),
                          Expanded(
                            flex: 2,
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(color: statusColor.withOpacity(0.7)),
                                ),
                                child: Text(
                                  statusText,
                                  style: TextStyle(
                                    color: statusColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          _buildReportValueCell(
                            _extractIpFromDescription(a.description),
                            flex: 3,
                          ),
                          _buildReportValueCell(
                            a.lokasi?.isNotEmpty == true ? a.lokasi! : '-',
                            flex: 4,
                            fontWeight: FontWeight.w700,
                            align: TextAlign.center,
                          ),
                          _buildReportValueCell(
                            '${a.tanggal ?? '-'} ${a.waktu ?? '-'}',
                            flex: 3,
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
        color: isWhite ? Colors.white.withOpacity(0.18) : accent.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isWhite ? Colors.white.withOpacity(0.45) : accent.withOpacity(0.5),
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
  }) {
    return Expanded(
      flex: flex,
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
        border: Border.all(color: tone.withOpacity(0.35)),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: tone.withOpacity(0.08),
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
                      color: tone.withOpacity(0.1),
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

  // FUNGSI FOOTER DIPINDAHKAN KE LUAR build()
  Widget _buildFooter() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: Colors.black.withOpacity(0.8),
      child: const Align(
        alignment: Alignment.centerLeft,
        child: Text(
          '©2026 TPK Nilam Monitoring System',
          style: TextStyle(color: Colors.white, fontSize: 12),
        ),
      ),
    );
  }
}

class _ReportHeaderText extends StatelessWidget {
  final String text;

  const _ReportHeaderText(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: Colors.black,
        fontWeight: FontWeight.bold,
        fontSize: 13,
      ),
    );
  }
}
