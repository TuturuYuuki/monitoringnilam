import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:monitoring/theme/app_dropdown_style.dart';
import 'package:monitoring/utils/ui_utils.dart';
import 'package:monitoring/route_proxy_page.dart';
class _NavItem {
  final IconData icon;
  final String label;
  final String route;
  const _NavItem(this.icon, this.label, this.route);
}

/// A wrapper widget that renders a collapsible sidebar on the left
/// and places [child] content to the right with proper spacing.
///
/// When [enabled] is false (e.g. on mobile), the sidebar is hidden
/// and the [child] fills the full width.
class GlobalSidebarNav extends StatefulWidget {
  final String currentRoute;
  final Widget child;
  final bool enabled;

  const GlobalSidebarNav({
    super.key,
    required this.currentRoute,
    required this.child,
    this.enabled = true,
  });

  /// The width of the collapsed sidebar strip.
  static const double collapsedWidth = 52;

  @override
  State<GlobalSidebarNav> createState() => _GlobalSidebarNavState();
}

class _GlobalSidebarNavState extends State<GlobalSidebarNav> {
  bool _isExpanded = false;

  static const double _collapsedWidth = GlobalSidebarNav.collapsedWidth;
  static const double _expandedWidth = 52;
  static const _bgColor = Color(0xFF1976D2);
  static const _activeColor = AppDropdownStyle.accentColor;

  static const List<_NavItem> _navItems = [
    _NavItem(Icons.dashboard_outlined, 'Dashboard', '/dashboard'),
    _NavItem(Icons.storage_outlined, 'Master Data', '/tower-management'),
    _NavItem(Icons.add_circle_outline, 'Add Device', '/add-device'),
    _NavItem(Icons.router_outlined, 'Access Point', '/network'),
    _NavItem(Icons.videocam_outlined, 'CCTV', '/cctv'),
    _NavItem(Icons.monitor_outlined, 'MMT', '/mmt-monitoring'),
    _NavItem(Icons.warning_amber_outlined, 'Alerts', '/alerts'),
    _NavItem(Icons.assessment_outlined, 'Report', '/report'),
    _NavItem(Icons.speed_outlined, 'Performance', '/global-diagnostics'),
    _NavItem(Icons.person_outline, 'Profile', '/profile'),
  ];

  static bool _isActiveRoute(String current, String target) {
    if (current == target) return true;
    if (target == '/network') {
      return [
        '/network',
        '/network-cy2',
        '/network-cy3',
        '/network-gate',
        '/network-parking'
      ].contains(current);
    }
    if (target == '/cctv') {
      return [
        '/cctv',
        '/cctv-cy2',
        '/cctv-cy3',
        '/cctv-gate',
        '/cctv-parking',
        '/cctv-fullscreen'
      ].contains(current);
    }
    if (target == '/mmt-monitoring') {
      return [
        '/mmt-monitoring',
        '/mmt-monitoring-cy2',
        '/mmt-monitoring-cy3',
        '/mmt-monitoring-gate',
        '/mmt-monitoring-parking',
        '/mmt-cy2',
        '/mmt-cy3'
      ].contains(current);
    }
    if (target == '/profile') {
      return ['/profile', '/edit-profile', '/change-password']
          .contains(current);
    }
    if (target == '/global-diagnostics') {
      return [
        '/global-diagnostics',
        '/device-diagnostics',
        '/device-performance'
      ].contains(current);
    }
    if (target != '/' && target != '/dashboard' && current.startsWith(target)) {
      return true;
    }
    return false;
  }

  void _navigate(String route) {
    if (!_isActiveRoute(widget.currentRoute, route)) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          settings: RouteSettings(name: route),
          pageBuilder: (context, animation, secondaryAnimation) =>
              RouteProxyPage(route),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.01, 0),
                  end: Offset.zero,
                ).animate(
                    CurvedAnimation(parent: animation, curve: Curves.easeOut)),
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 350),
        ),
      );
    } else {
      setState(() => _isExpanded = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = isMobileScreen(context);
    
    if (!widget.enabled || isMobile) {
      return widget.child;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSidebarPanel(),
        Expanded(child: widget.child),
      ],
    );
  }

  Widget _buildSidebarPanel() {
    return Container(
      width: _collapsedWidth,
      decoration: BoxDecoration(
        color: AppDropdownStyle.menuBackground,
        border: Border(
          right: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              itemCount: _navItems.length,
              itemBuilder: (context, index) {
                final item = _navItems[index];
                final isActive = _isActiveRoute(widget.currentRoute, item.route);
                
                // Variabel lokal untuk menyimpan GlobalKey tooltip
                final tooltipKey = GlobalKey<TooltipState>();

                return Tooltip(
                  key: tooltipKey,
                  message: item.label,
                  waitDuration: Duration.zero,
                  triggerMode: TooltipTriggerMode.manual,
                  margin: const EdgeInsets.only(left: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A3650),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white10),
                  ),
                  textStyle: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                  child: GestureDetector(
                    onTap: () {
                      tooltipKey.currentState?.ensureTooltipVisible();
                      _navigate(item.route);
                    },
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                      height: 40,
                      decoration: BoxDecoration(
                        color: isActive ? AppDropdownStyle.accentColor.withValues(alpha: 0.2) : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        item.icon,
                        color: isActive ? AppDropdownStyle.accentColor : Colors.white70,
                        size: 22,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
