import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:monitoring/theme/app_dropdown_style.dart';
import 'utils/auth_helper.dart';
import 'services/api_service.dart';
import 'pages/dashboard/dashboard.dart';
import 'pages/network/network.dart';
import 'pages/network/network_cy2.dart';
import 'pages/network/network_cy3.dart';
import 'pages/cctv/cctv.dart';
import 'pages/cctv/cctv_cy2.dart';
import 'pages/cctv/cctv_cy3.dart';
import 'pages/cctv/cctv_parking.dart';
import 'pages/cctv/cctv_gate.dart';
import 'pages/cctv/cctv_fullscreen.dart';
import 'pages/alerts/alerts.dart';
import 'login.dart';
import 'signup.dart';
import 'forgot_password.dart';
import 'forgot_password_verify.dart';
import 'reset_password.dart';
import 'pages/profile/profile.dart';
import 'pages/profile/edit_profile.dart';
import 'pages/profile/change_password.dart';
import 'pages/devices/add_device.dart';
import 'pages/report/report_page.dart';
import 'pages/network/tower_management.dart';
import 'pages/mmt/mmt_monitoring.dart';
import 'pages/mmt/mmt_monitoring_cy2.dart';
import 'pages/mmt/mmt_monitoring_cy3.dart';
import 'pages/network/network_gate.dart';
import 'pages/network/network_parking.dart';
import 'package:monitoring/pages/mmt/mmt_monitoring_gate.dart';
import 'package:monitoring/pages/mmt/mmt_monitoring_parking.dart';
import 'package:monitoring/pages/nvr/nvr_cy1.dart';
import 'package:monitoring/pages/nvr/nvr_cy2.dart';
import 'package:monitoring/pages/nvr/nvr_cy3.dart';
import 'package:monitoring/pages/nvr/nvr_gate.dart';
import 'package:monitoring/pages/nvr/nvr_parking.dart';
import 'package:monitoring/pages/switch/switch_cy1.dart';
import 'package:monitoring/pages/switch/switch_cy2.dart';
import 'package:monitoring/pages/switch/switch_cy3.dart';
import 'package:monitoring/pages/switch/switch_gate.dart';
import 'package:monitoring/pages/switch/switch_parking.dart';
import 'pages/diagnostics/device_diagnostics_page.dart';
import 'pages/diagnostics/global_diagnostics_page.dart';
import 'pages/diagnostics/device_performance_page.dart';
import 'pages/pc/pc_monitoring_cy1.dart';
import 'pages/pc/pc_monitoring_cy2.dart';
import 'pages/pc/pc_monitoring_cy3.dart';
import 'pages/pc/pc_monitoring_gate.dart';
import 'pages/pc/pc_monitoring_parking.dart';
export 'utils/ui_utils.dart';

final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}


// Custom Animated Dropdown Widget
class AnimatedDropdownButton extends StatefulWidget {
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final Color backgroundColor;

  const AnimatedDropdownButton({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.backgroundColor = const Color(0xFF4A5F7F),
  });

  @override
  State<AnimatedDropdownButton> createState() => _AnimatedDropdownButtonState();
}

class _AnimatedDropdownButtonState extends State<AnimatedDropdownButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isOpen = false;
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();
  String? _hoveredItem;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _removeOverlay();
    _animationController.dispose();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _toggleDropdown() {
    if (_isOpen) {
      _animationController.reverse().then((_) => _removeOverlay());
    } else {
      _showOverlay();
      _animationController.forward();
    }
    setState(() {
      _isOpen = !_isOpen;
    });
  }

  void _showOverlay() {
    final overlay = Overlay.of(context);
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final buttonPosition = renderBox.localToGlobal(Offset.zero);
    final screenHeight = MediaQuery.of(context).size.height;

    // Ruang di bawah dan di atas button
    final spaceBelow = screenHeight - buttonPosition.dy - size.height;
    final spaceAbove = buttonPosition.dy;
    final maxMenuHeight = screenHeight * 0.4;

    // Buka ke atas jika ruang bawah tidak cukup dan ruang atas lebih besar
    final openUpward = spaceBelow < maxMenuHeight && spaceAbove > spaceBelow;
    final availableHeight = openUpward
        ? (spaceAbove - 8).clamp(100.0, maxMenuHeight)
        : (spaceBelow - 8).clamp(100.0, maxMenuHeight);

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: size.width < 180 ? 180 : size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          // Offset negatif = buka ke atas
          offset: openUpward
              ? Offset(0, -(availableHeight + 8))
              : Offset(0, size.height + 4),
          child: FadeTransition(
            opacity: _animationController,
            child: Material(
              elevation: 1000,
              borderRadius: BorderRadius.circular(12),
              color: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                  color: widget.backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: availableHeight),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: widget.items.map((item) {
                        return MouseRegion(
                          onEnter: (_) => setState(() => _hoveredItem = item),
                          onExit: (_) => setState(() => _hoveredItem = null),
                          cursor: SystemMouseCursors.click,
                          child: InkWell(
                            onTap: () => _selectItem(item),
                            splashColor: Colors.white.withValues(alpha: 0.1),
                            highlightColor: Colors.transparent,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: _hoveredItem == item
                                    ? const Color(0xFF2A3650)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                item,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(_overlayEntry!);
  }

  void _selectItem(String value) {
    _animationController.reverse().then((_) => _removeOverlay());
    setState(() {
      _isOpen = false;
    });

    Future.delayed(const Duration(milliseconds: 150), () {
      widget.onChanged(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: InkWell(
        onTap: _toggleDropdown,
        splashColor: Colors.white.withValues(alpha: 0.05),
        highlightColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          decoration: const BoxDecoration(
            color: Colors.transparent, // Removed background and border to tidy up the UI
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  widget.value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(
                Icons.arrow_drop_down,
                color: Colors.white,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Terminal Nilam',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Arial',
        canvasColor: AppDropdownStyle.menuBackground,
        shadowColor: Colors.transparent,
        popupMenuTheme: PopupMenuThemeData(
          color: AppDropdownStyle.menuBackground,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: AppDropdownStyle.menuBorderRadius,
            side: BorderSide(color: Colors.white.withValues(alpha: 0.22)),
          ),
          textStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        menuTheme: MenuThemeData(
          style: MenuStyle(
            backgroundColor: WidgetStateProperty.all(
              AppDropdownStyle.menuBackground,
            ),
            shape: WidgetStateProperty.all(
              RoundedRectangleBorder(
                borderRadius: AppDropdownStyle.menuBorderRadius,
                side: BorderSide(color: Colors.white.withValues(alpha: 0.22)),
              ),
            ),
          ),
        ),
      ),
      initialRoute: '/',
      home: const AuthWrapper(),
      navigatorObservers: [routeObserver],
      routes: {
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignUpPage(),
        '/dashboard': (context) => const DashboardPage(),
        '/add-device': (context) => const AddDevicePage(),
        '/network': (context) => const NetworkPage(),
        '/network-cy2': (context) => const NetworkCY2Page(),
        '/network-cy3': (context) => const NetworkCY3Page(),
        '/network-gate': (context) => const NetworkGatePage(),
        '/network-parking': (context) => const NetworkParkingPage(),
        '/cctv': (context) => const CCTVPage(),
        '/cctv-cy2': (context) => const CCTVCy2Page(),
        '/cctv-cy3': (context) => const CCTVCy3Page(),
        '/cctv-gate': (context) => const GateCCTVPage(),
        '/cctv-parking': (context) => const ParkingCCTVPage(),
        '/cctv-fullscreen': (context) => const CCTVFullscreenPage(),
        '/alerts': (context) => const AlertsPage(),
        '/alert-report': (context) => const ReportPage(),
        '/report': (context) => const ReportPage(),
        '/profile': (context) => const ProfilePage(),
        '/edit-profile': (context) => const EditProfilePage(),
        '/change-password': (context) => const ChangePasswordPage(),
        '/forgot-password': (context) => const ForgotPasswordPage(),
        '/forgot-password-verify': (context) =>
            const ForgotPasswordVerifyPage(),
        '/reset-password': (context) => const ResetPasswordPage(),
        '/tower-management': (context) => const TowerManagementPage(),
        '/mmt-monitoring': (context) => const MMTMonitoringPage(),
        '/mmt-monitoring-cy2': (context) => const MMTMonitoringCY2Page(),
        '/mmt-monitoring-cy3': (context) => const MMTMonitoringCY3Page(),
        '/mmt-monitoring-gate': (context) => const MMTMonitoringGatePage(),
        '/mmt-monitoring-parking': (context) => const MMTMonitoringParkingPage(),
        '/nvr-monitoring-cy1': (context) => const NVRPageCY1(),
        '/nvr-monitoring-cy2': (context) => const NVRPageCY2(),
        '/nvr-monitoring-cy3': (context) => const NVRPageCY3(),
        '/nvr-monitoring-gate': (context) => const NVRPageGATE(),
        '/nvr-monitoring-parking': (context) => const NVRPagePARKING(),
        '/switch-monitoring-cy1': (context) => const SwitchPageCY1(),
        '/switch-monitoring-cy2': (context) => const SwitchPageCY2(),
        '/switch-monitoring-cy3': (context) => const SwitchPageCY3(),
        '/switch-monitoring-gate': (context) => const SwitchPageGATE(),
        '/switch-monitoring-parking': (context) => const SwitchPagePARKING(),
        '/device-diagnostics': (context) => const DeviceDiagnosticsPage(),
        '/global-diagnostics': (context) => const GlobalDiagnosticsPage(),
        '/device-performance': (context) => const DevicePerformancePage(),
        '/pc-monitoring-cy1': (context) => const PCMonitoringCY1Page(),
        '/pc-monitoring-cy2': (context) => const PCMonitoringCY2Page(),
        '/pc-monitoring-cy3': (context) => const PCMonitoringCY3Page(),
        '/pc-monitoring-gate': (context) => const PCMonitoringGatePage(),
        '/pc-monitoring-parking': (context) => const PCMonitoringParkingPage(),
        '/pc-monitoring': (context) => const PCMonitoringCY1Page(),
      },
    );
  }
}

// Wrapper widget untuk cek authentication status
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  late Future<Map<String, dynamic>> _initFuture;

  @override
  void initState() {
    super.initState();
    _initFuture = _initApp();
  }

  Future<Map<String, dynamic>> _initApp() async {
    try {
      await ApiService.ensureInitialized();

      // Skip network connection test at startup — doing HTTP calls here on
      // Android can block the Dart event loop (especially localhost → IPv6)
      // and trigger an ANR dialog. Each page handles its own connection errors.
      bool isLoggedIn = false;
      try {
        isLoggedIn = await AuthHelper.isLoggedIn()
            .timeout(const Duration(seconds: 3), onTimeout: () => false);
      } catch (_) {
        isLoggedIn = false;
      }

      return {
        'isLoggedIn': isLoggedIn,
        'connection': {'success': true},
      };
    } catch (e) {
      return {
        'isLoggedIn': false,
        'connection': {'success': true},
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _initFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFF0F172A),
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Colors.blueAccent),
                  SizedBox(height: 24),
                  Text(
                    'INITIALIZING SYSTEM...',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.0,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: const Color(0xFF0F172A),
            body: Center(
              child: Text('Fatal error: ${snapshot.error}', style: const TextStyle(color: Colors.white)),
            ),
          );
        }

        final data = snapshot.data;
        if (data == null) {
          return const Scaffold(
            backgroundColor: Color(0xFF0F172A),
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final connection = data['connection'] as Map<String, dynamic>?;
        final isLoggedIn = data['isLoggedIn'] == true;

        // If connection failed and we are not on web (where localhost usually works)
        if (connection?['success'] != true && !kIsWeb) {
          return Scaffold(
            backgroundColor: const Color(0xFF0F172A),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_off_rounded, size: 80, color: Colors.redAccent),
                    const SizedBox(height: 24),
                    const Text(
                      'CONNECTION FAILED',
                      style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      connection?['message'] ?? 'Unable to reach backend server.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: () => setState(() {
                        _initFuture = _initApp();
                      }),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      ),
                      child: const Text('RETRY CONNECTION', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return isLoggedIn ? const DashboardPage() : const LoginPage();
      },
    );
  }
}