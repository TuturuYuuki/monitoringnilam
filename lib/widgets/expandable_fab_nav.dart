import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';

class ExpandableFabNav extends StatefulWidget {
  final String currentRoute;
  final bool inHeader;

  const ExpandableFabNav({
    super.key,
    required this.currentRoute,
    this.inHeader = false,
  });

  @override
  State<ExpandableFabNav> createState() => _ExpandableFabNavState();
}

class _ExpandableFabNavState extends State<ExpandableFabNav>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _expandAnimation;
  bool _isExpanded = false;

  final List<_MenuItem> _menuItems = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutBack,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _menuItems.clear();
    _menuItems.addAll([
      _MenuItem(icon: Icons.dashboard, label: 'Dashboard', route: '/dashboard'),
      _MenuItem(icon: Icons.storage, label: 'Master Data', route: '/master-data'),
      _MenuItem(icon: Icons.add_circle, label: 'Add New Device', route: '/add-device'),
      _MenuItem(icon: Icons.router, label: 'Access Point', route: '/access-point'),
      _MenuItem(icon: Icons.videocam, label: 'CCTV', route: '/cctv'),
      _MenuItem(icon: Icons.monitor, label: 'MMT', route: '/mmt'),
      _MenuItem(icon: Icons.warning, label: 'Alerts', route: '/alerts'),
      _MenuItem(icon: Icons.assessment, label: 'Alert Report', route: '/alert-report'),
      _MenuItem(icon: Icons.settings, label: 'Settings', route: '/profile'),
    ]);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  void _go(String route) {
    // Jika rute sama, cukup tutup menu
    if (widget.currentRoute == route) {
      _toggle();
      return;
    }
    
    // Tutup menu sebelum pindah page agar tidak terjadi overlap state
    if (_isExpanded) {
      _controller.reverse();
      setState(() {
        _isExpanded = false;
      });
    }

    // Pastikan menggunakan pushReplacementNamed agar tumpukan page tetap rapi
    Navigator.pushReplacementNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.inHeader) return const SizedBox.shrink();

    return SizedBox(
      width: 56,
      height: 56,
      child: Stack(
        clipBehavior: Clip.none, 
        alignment: Alignment.center,
        children: [
          if (_isExpanded)
            Positioned(
              right: 0,
              top: 65, 
              child: Material(
                elevation: 24,
                color: Colors.transparent,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    // Batasi tinggi list menu (70% dari tinggi layar) agar bisa scroll
                    maxHeight: MediaQuery.of(context).size.height * 0.7,
                    maxWidth: 240,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          color: const Color(0xFF1E293B).withOpacity(0.8),
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.only(top: 12, bottom: 20, left: 8, right: 8),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: _buildMenuItems(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          _buildMainButton(),
        ],
      ),
    );
  }

  List<Widget> _buildMenuItems() {
    return List.generate(_menuItems.length, (index) {
      final item = _menuItems[index];
      final delay = index * 0.05;

      return AnimatedBuilder(
        animation: _expandAnimation,
        builder: (context, child) {
          final delayedValue = (_expandAnimation.value - delay).clamp(0.0, 1.0);
          final slideValue = Curves.easeOut.transform(delayedValue);

          return Transform.translate(
            offset: Offset(0, (1 - slideValue) * 15),
            child: Opacity(
              opacity: slideValue,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: child,
              ),
            ),
          );
        },
        child: _buildMenuItem(item),
      );
    });
  }

  Widget _buildMenuItem(_MenuItem item) {
    final isActive = widget.currentRoute == item.route;
    final baseColor = _colorForRoute(item.route);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _go(item.route),
        borderRadius: BorderRadius.circular(30),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? baseColor : const Color(0xFF0F172A).withOpacity(0.9),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: isActive ? Colors.white38 : const Color(0xFF334155),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(item.icon, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Text(
                item.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _colorForRoute(String route) {
    switch (route) {
      case '/dashboard': return const Color(0xFF1976D2);
      case '/alerts': return const Color(0xFFE53935);
      case '/alert-report': return const Color(0xFF8E24AA);
      case '/add-device': return const Color(0xFFFB8C00);
      case '/cctv': return const Color(0xFF00897B);
      case '/access-point': return const Color(0xFF546E7A);
      case '/mmt': return const Color(0xFF43A047);
      default: return const Color(0xFF607D8B);
    }
  }

  Widget _buildMainButton() {
    return GestureDetector(
      onTap: _toggle,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: _isExpanded ? Colors.white : const Color(0xFF0F172A), 
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white24, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Transform.rotate(
              angle: _expandAnimation.value * math.pi / 4,
              child: Icon(
                _isExpanded ? Icons.close : Icons.menu,
                color: _isExpanded ? Colors.black : Colors.white,
                size: 28,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final String route;
  _MenuItem({required this.icon, required this.label, required this.route});
}