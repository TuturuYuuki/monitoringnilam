import 'package:flutter/material.dart';
import 'dart:ui';
import 'dashboard.dart';
import 'network.dart';
import 'network_cy2.dart';
import 'network_cy3.dart';
import 'cctv.dart';
import 'cctv_cy2.dart';
import 'cctv_cy3.dart';
import 'cctv_parking.dart';
import 'cctv_gate.dart';
import 'alerts.dart';
import 'login.dart';
import 'signup.dart';
import 'profile.dart';
import 'edit_profile.dart';
import 'change_password.dart';

void main() {
  runApp(const MyApp());
}

// Helper function untuk navigasi dengan loading animation
Future<void> navigateWithLoading(BuildContext context, String routeName) async {
  showDialog(
    context: context,
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

  // Delay 1 detik
  await Future.delayed(const Duration(milliseconds: 500));

  // Navigator back dan ganti route
  Navigator.pop(context);
  Navigator.pushReplacementNamed(context, routeName);
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
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
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

// Liquid Header dengan animated indicator seperti iOS
class LiquidHeaderButtons extends StatefulWidget {
  final int activeIndex;
  final List<String> buttonLabels;
  final List<VoidCallback> onPressedCallbacks;

  const LiquidHeaderButtons({
    Key? key,
    required this.activeIndex,
    required this.buttonLabels,
    required this.onPressedCallbacks,
  }) : super(key: key);

  @override
  State<LiquidHeaderButtons> createState() => _LiquidHeaderButtonsState();
}

class _LiquidHeaderButtonsState extends State<LiquidHeaderButtons> {
  int? _hoverIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(widget.buttonLabels.length, (index) {
        final isActive = widget.activeIndex == index;
        final isHovered = _hoverIndex == index;

        return Padding(
          padding: const EdgeInsets.only(right: 12),
          child: MouseRegion(
            onEnter: (_) => setState(() => _hoverIndex = index),
            onExit: (_) => setState(() => _hoverIndex = null),
            cursor: SystemMouseCursors.click,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(25),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    decoration: BoxDecoration(
                      color: isActive
                          ? Colors.white.withOpacity(0.9)
                          : isHovered
                              ? Colors.white.withOpacity(0.6)
                              : Colors.white.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1.5,
                      ),
                      boxShadow: isHovered
                          ? [
                              BoxShadow(
                                color: Colors.white.withOpacity(0.3),
                                blurRadius: 12,
                                spreadRadius: 2,
                              ),
                            ]
                          : [],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: widget.onPressedCallbacks[index],
                        borderRadius: BorderRadius.circular(25),
                        splashColor: Colors.white.withOpacity(0.3),
                        highlightColor: Colors.white.withOpacity(0.2),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                          child: Text(
                            widget.buttonLabels[index],
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight:
                                  isActive ? FontWeight.bold : FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

// Custom Animated Dropdown Widget
class AnimatedDropdownButton extends StatefulWidget {
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final Color backgroundColor;

  const AnimatedDropdownButton({
    Key? key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.backgroundColor = const Color(0xFF4A5F7F),
  }) : super(key: key);

  @override
  State<AnimatedDropdownButton> createState() => _AnimatedDropdownButtonState();
}

class _AnimatedDropdownButtonState extends State<AnimatedDropdownButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _rotationAnimation;
  late Animation<double> _opacityAnimation;
  bool _isOpen = false;
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _rotationAnimation = Tween<double>(begin: 0, end: 0.5).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _opacityAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
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
          child: AnimatedBuilder(
            animation: _opacityAnimation,
            builder: (context, child) {
              return Material(
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
                  child: Opacity(
                    opacity: _opacityAnimation.value,
                    child: Transform.translate(
                      offset: Offset(0, -10 * (1 - _opacityAnimation.value)),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: widget.items.map((item) {
                          return InkWell(
                            onTap: () => _selectItem(item),
                            splashColor: Colors.white.withOpacity(0.3),
                            highlightColor: Colors.white.withOpacity(0.1),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
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
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              );
            },
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
              AnimatedBuilder(
                animation: _rotationAnimation,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _rotationAnimation.value * 3.14159,
                    child: Icon(
                      Icons.arrow_drop_down,
                      color: Colors.white,
                    ),
                  );
                },
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
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignUpPage(),
        '/': (context) => const DashboardPage(),
        '/dashboard': (context) => const DashboardPage(),
        '/network': (context) => const NetworkPage(),
        '/network-cy2': (context) => const NetworkCY2Page(),
        '/network-cy3': (context) => const NetworkCY3Page(),
        '/cctv': (context) => const CCTVPage(),
        '/cctv-cy2': (context) => const CCTVCy2Page(),
        '/cctv-cy3': (context) => const CCTVCy3Page(),
        '/parking-cctv': (context) => const ParkingCCTVPage(),
        '/gate-cctv': (context) => const GateCCTVPage(),
        '/alerts': (context) => const AlertsPage(),
        '/profile': (context) => const ProfilePage(),
        '/edit-profile': (context) => const EditProfilePage(),
        '/change-password': (context) => const ChangePasswordPage(),
      },
    );
  }
}
