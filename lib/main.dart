import 'package:flutter/material.dart';
import 'dart:ui';
import 'utils/auth_helper.dart';
import 'dashboard.dart';
import 'network.dart';
import 'network_cy2.dart';
import 'network_cy3.dart';
import 'cctv.dart';
import 'cctv_cy2.dart';
import 'cctv_cy3.dart';
import 'cctv_parking.dart';
import 'cctv_gate.dart';
import 'cctv_fullscreen.dart';
import 'alerts.dart';
import 'login.dart';
import 'signup.dart';
import 'profile.dart';
import 'edit_profile.dart';
import 'change_password.dart';
import 'add_device.dart';

void main() {
  runApp(const MyApp());
}

// Helper function untuk navigasi dengan loading animation
Future<void> navigateWithLoading(BuildContext context, String routeName) async {
  final rootNav = Navigator.of(context, rootNavigator: true);
  showDialog(
    context: context,
    useRootNavigator: true,
    barrierDismissible: false,
    builder: (context) => WillPopScope(
      onWillPop: () async => false,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1976D2)),
            ),
          ),
        ),
      ),
    ),
  );

  await Future.delayed(const Duration(milliseconds: 500));

  try {
    if (rootNav.canPop()) {
      rootNav.pop();
    }
    rootNav.pushReplacementNamed(routeName);
  } catch (e) {
    if (rootNav.canPop()) {
      rootNav.pop();
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Navigasi gagal: $routeName'),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.red,
      ),
    );
  }
}

// Global logout dialog function with AuthHelper
void showLogoutDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Logout', style: TextStyle(color: Colors.black87)),
      content: const Text('Apakah Anda yakin ingin logout?',
          style: TextStyle(color: Colors.black87)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal', style: TextStyle(color: Colors.black87)),
        ),
        ElevatedButton(
          onPressed: () async {
            // Clear user data using AuthHelper
            await AuthHelper.clearUserData();

            if (context.mounted) {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/login');
            }
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

// Helper function untuk membuat liquid glass button dengan hover effect
Widget buildLiquidGlassButton(String text, VoidCallback onPressed,
    {bool isActive = false}) {
  return MouseRegion(
    cursor: SystemMouseCursors.click,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
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
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(25),
              splashColor: Colors.white.withOpacity(0.3),
              highlightColor: Colors.white.withOpacity(0.2),
              hoverColor: Colors.white.withOpacity(0.15),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
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
        ),
      ),
    ),
  );
}

// Show alert dialog with fade animation
void showFadeAlertDialog({
  required BuildContext context,
  required String title,
  required Widget content,
  required List<Widget> actions,
  bool barrierDismissible = true,
  ShapeBorder? shape,
}) {
  showGeneralDialog(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 400),
    pageBuilder: (context, animation, secondaryAnimation) {
      return AlertDialog(
        title: Text(title),
        content: content,
        actions: actions,
        shape: shape ??
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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

// Responsive helper functions
bool isMobileScreen(BuildContext context) {
  return MediaQuery.of(context).size.width < 600;
}

double getResponsivePadding(BuildContext context) {
  final isMobile = isMobileScreen(context);
  return isMobile ? 8.0 : 16.0;
}

double getResponsiveFontSize(
    BuildContext context, double mobileSize, double desktopSize) {
  final isMobile = isMobileScreen(context);
  return isMobile ? mobileSize : desktopSize;
}

int getResponsiveGridColumns(BuildContext context,
    {int mobileColumns = 1, int desktopColumns = 3}) {
  final isMobile = isMobileScreen(context);
  return isMobile ? mobileColumns : desktopColumns;
}

double getResponsiveChildAspectRatio(BuildContext context,
    {double mobileRatio = 0.9, double desktopRatio = 1.2}) {
  final isMobile = isMobileScreen(context);
  return isMobile ? mobileRatio : desktopRatio;
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
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
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
                                ? Colors.blue.withOpacity(0.6)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            item,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: item == widget.value
                                  ? FontWeight.bold
                                  : FontWeight.normal,
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
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
      ),
      initialRoute: '/',
      home: const AuthWrapper(),
      routes: {
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignUpPage(),
        '/dashboard': (context) => const DashboardPage(),
        '/add-device': (context) => const AddDevicePage(),
        '/network': (context) => const NetworkPage(),
        '/network-cy2': (context) => const NetworkCY2Page(),
        '/network-cy3': (context) => const NetworkCY3Page(),
        '/cctv': (context) => const CCTVPage(),
        '/cctv-cy2': (context) => const CCTVCy2Page(),
        '/cctv-cy3': (context) => const CCTVCy3Page(),
        '/cctv-gate': (context) => const GateCCTVPage(),
        '/cctv-parking': (context) => const ParkingCCTVPage(),
        '/cctv-fullscreen': (context) => const CCTVFullscreenPage(),
        '/alerts': (context) => const AlertsPage(),
        '/profile': (context) => const ProfilePage(),
        '/edit-profile': (context) => const EditProfilePage(),
        '/change-password': (context) => const ChangePasswordPage(),
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
                  const Color(0xFF1976D2).withOpacity(0.7),
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
