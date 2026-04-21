import 'package:flutter/material.dart';
import 'package:monitoring/theme/app_dropdown_style.dart';
import 'utils/auth_helper.dart';
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
import 'pages/mmt/mmt_monitoring_gate.dart';
import 'pages/mmt/mmt_monitoring_parking.dart';
import 'pages/diagnostics/device_diagnostics_page.dart';
import 'pages/diagnostics/global_diagnostics_page.dart';
import 'pages/diagnostics/device_performance_page.dart';
export 'utils/ui_utils.dart';

final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

void main() {
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

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, size.height),
          child: FadeTransition(
            opacity: _animationController,
            child: Material(
              elevation: 1000,
              borderRadius: BorderRadius.circular(12),
              color: Colors.transparent,
              child: Container(
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  color: widget.backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: widget.items.map((item) {
                    return MouseRegion(
                      onEnter: (_) {
                        setState(() {
                          _hoveredItem = item;
                        });
                      },
                      onExit: (_) {
                        setState(() {
                          _hoveredItem = null;
                        });
                      },
                      cursor: SystemMouseCursors.click,
                      child: InkWell(
                        onTap: () => _selectItem(item),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: _hoveredItem == item
                                ? Colors.blue.withValues(alpha: 0.6)
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
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Icon(
                Icons.arrow_drop_down,
                color: Colors.white,
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
        '/device-diagnostics': (context) => const DeviceDiagnosticsPage(),
        '/global-diagnostics': (context) => const GlobalDiagnosticsPage(),
        '/device-performance': (context) => const DevicePerformancePage(),
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
  late Future<bool> _isLoggedInFuture;

  @override
  void initState() {
    super.initState();
    _isLoggedInFuture = AuthHelper.isLoggedIn();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _isLoggedInFuture,
      builder: (context, snapshot) {
        // Load state: show loading screen
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  const Color(0xFF1976D2).withValues(alpha: 0.7),
                ),
              ),
            ),
          );
        }

        // Error state: default to login
        if (snapshot.hasError) {
          return const LoginPage();
        }

        // Jika sudah login, tampilkan dashboard
        if (snapshot.data == true) {
          return const DashboardPage();
        }

        // Jika belum login, tampilkan login page
        return const LoginPage();
      },
    );
  }
}