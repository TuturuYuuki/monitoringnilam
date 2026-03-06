import 'package:flutter/material.dart';
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
    start: DateTime.now().subtract(const Duration(days: 7)),
    end: DateTime.now(),
  );
  String _statusFilter = 'ALL';

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
      setState(() => isLoading = false);
    }
  }

  Future<void> _generateReportPdf() async {
    if (reportAlerts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No Data Found"), backgroundColor: Colors.orange),
      );
      return;
    }

    try {
      final pdf = pw.Document();
      final List<List<String>> tableContent = [
        ['No', 'Device', 'Status', 'Location', 'Timestamp'],
        ...reportAlerts.asMap().entries.map((entry) {
          final index = entry.key + 1;
          final a = entry.value;
          final status = (a.severity.toLowerCase() == 'critical' || a.description.toLowerCase().contains('down')) ? 'DOWN' : 'UP';
          return [index.toString(), a.title, status, a.lokasi ?? '-', "${a.tanggal} ${a.waktu}"];
        }),
      ];

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) => [
            pw.Header(level: 0, child: pw.Text("ALERT MONITORING REPORT", style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
            pw.SizedBox(height: 20),
            pw.TableHelper.fromTextArray(
              headers: tableContent[0],
              data: tableContent.sublist(1),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
              cellAlignment: pw.Alignment.center,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2C3E50),
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  _buildFilterBar(),
                  const SizedBox(height: 20),
                  _buildReportTable(),
                ],
              ),
            ),
          ),
          _buildFooter(), // Footer sekarang dipanggil di sini
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
              behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildHeaderOpenButton('Add New Device', const AddDevicePage()),
                    const SizedBox(width: 12),
                    _buildHeaderOpenButton('Master Data', const TowerManagementPage()),
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
                    _buildHeaderOpenButton('Alert Report', const ReportPage(), isActive: true),
                    const SizedBox(width: 12),
                    _buildHeaderButton('Logout', () => showLogoutDialog(context)),
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

  Widget _buildHeaderOpenButton(String text, Widget openPage, {bool isActive = false}) {
    return buildLiquidGlassButton(text, () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => openPage)), isActive: isActive);
  }

  Widget _buildHeaderButton(String text, VoidCallback onPressed) {
    return buildLiquidGlassButton(text, onPressed);
  }

  Widget _buildProfileIcon() {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfilePage())),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), shape: BoxShape.circle),
        child: const Icon(Icons.person, color: Color(0xFF1976D2), size: 24),
      ),
    );
  }

  Widget _buildFilterBar() {
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.9),
      borderRadius: BorderRadius.circular(12),
    ),
    child: IntrinsicHeight( // Tambahkan ini agar semua anak Row tingginya sama
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch, // Paksa anak Row untuk mengisi tinggi maksimal
        children: [
          // 1. Kalender (Range Tanggal)
          Expanded(
            flex: 2,
            child: InkWell(
              onTap: _pickDateRange,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12), // Sesuaikan padding
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_month, size: 16, color: Colors.blue),
                    const SizedBox(width: 8),
                    Text(
                      "${DateFormat('dd/MM').format(_selectedRange.start)} - ${DateFormat('dd/MM').format(_selectedRange.end)}",
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // 2. Dropdown Status
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12), // Padding horizontal saja
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _statusFilter,
                  isExpanded: true, // Pastikan memenuhi ruang
                  style: const TextStyle(fontSize: 12, color: Colors.black),
                  items: ['ALL', 'UP', 'DOWN']
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (val) {
                    setState(() => _statusFilter = val!);
                    _fetchReportData();
                  },
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // 3. Tombol PDF
          ElevatedButton(
            onPressed: _generateReportPdf,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              padding: const EdgeInsets.symmetric(horizontal: 16), // Hapus padding vertikal agar diatur IntrinsicHeight
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
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
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
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width > 600 ? 450 : double.infinity),
            child: Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(primary: Color(0xFF1976D2), onPrimary: Colors.white, surface: Colors.white, onSurface: Colors.black),
                dialogTheme: DialogTheme(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
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
        child: Center(child: Text("No Data Found", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500))),
      );
    }
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: reportAlerts.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final a = reportAlerts[index];
          // Determine status based on description (DOWN/UP)
          final isDown = a.description.toLowerCase().contains('down') || a.severity.toLowerCase() == 'critical';
          return ListTile(
            leading: Icon(
              isDown ? Icons.cloud_off : Icons.cloud_done,
              color: isDown ? Colors.red : Colors.green,
              size: 28,
            ),
            title: Text(a.title, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text("${a.lokasi} | ${a.tanggal} ${a.waktu}"),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isDown ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                isDown ? 'DOWN' : 'UP',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDown ? Colors.red : Colors.green,
                  fontSize: 12,
                ),
              ),
            ),
          );
        },
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