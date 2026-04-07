import 'package:flutter/material.dart';

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
  static const double _expandedWidth = 210;
  static const _bgColor = Color(0xFF151C2C);
  static const _activeColor = Color(0xFF3B82F6);

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
    return false;
  }

  void _navigate(String route) {
    if (!_isActiveRoute(widget.currentRoute, route)) {
      Navigator.pushReplacementNamed(context, route);
    } else {
      setState(() => _isExpanded = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // When disabled (mobile), just show content full-width
    if (!widget.enabled) {
      return widget.child;
    }

    return Stack(
      children: [
        // Content with left padding for sidebar space
        Padding(
          padding: const EdgeInsets.only(left: _collapsedWidth),
          child: widget.child,
        ),
        // Scrim overlay when expanded
        if (_isExpanded)
          Positioned.fill(
            child: GestureDetector(
              onTap: () => setState(() => _isExpanded = false),
              child: Container(color: Colors.black.withOpacity(0.3)),
            ),
          ),
        // Sidebar panel (always on top)
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          child: _isExpanded ? _buildExpandedPanel() : _buildCollapsedPanel(),
        ),
      ],
    );
  }

  Widget _buildCollapsedPanel() {
    return Material(
      elevation: 2,
      shadowColor: Colors.black26,
      color: _bgColor,
      child: SizedBox(
        width: _collapsedWidth,
        child: Column(
          children: [
            const SizedBox(height: 8),
            _buildToggle(),
            const Divider(
                color: Colors.white10, height: 20, indent: 10, endIndent: 10),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: _navItems.map((item) {
                    final isActive =
                        _isActiveRoute(widget.currentRoute, item.route);
                    return Tooltip(
                      message: item.label,
                      preferBelow: false,
                      waitDuration: const Duration(milliseconds: 400),
                      textStyle: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A3650),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: InkWell(
                        onTap: () => _navigate(item.route),
                        child: Container(
                          width: _collapsedWidth,
                          height: 46,
                          alignment: Alignment.center,
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: isActive
                                  ? _activeColor.withOpacity(0.2)
                                  : Colors.transparent,
                            ),
                            child: Icon(item.icon,
                                color: isActive ? _activeColor : Colors.white54,
                                size: 21),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedPanel() {
    return Material(
      elevation: 16,
      shadowColor: Colors.black54,
      color: _bgColor,
      child: SizedBox(
        width: _expandedWidth,
        child: Column(
          children: [
            const SizedBox(height: 8),
            _buildToggle(),
            const Divider(
                color: Colors.white10, height: 20, indent: 12, endIndent: 12),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: _navItems.map((item) {
                    final isActive =
                        _isActiveRoute(widget.currentRoute, item.route);
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      child: InkWell(
                        onTap: () => _navigate(item.route),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          height: 44,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: isActive
                                ? _activeColor.withOpacity(0.12)
                                : Colors.transparent,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color: isActive
                                      ? _activeColor.withOpacity(0.2)
                                      : Colors.transparent,
                                ),
                                child: Icon(item.icon,
                                    color: isActive
                                        ? _activeColor
                                        : Colors.white54,
                                    size: 21),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  item.label,
                                  style: TextStyle(
                                    color: isActive
                                        ? Colors.white
                                        : Colors.white70,
                                    fontSize: 14,
                                    fontWeight: isActive
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isActive)
                                Container(
                                  width: 4,
                                  height: 18,
                                  decoration: BoxDecoration(
                                    color: _activeColor,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: InkWell(
        onTap: () => setState(() => _isExpanded = !_isExpanded),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 38,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Colors.white.withOpacity(0.06),
          ),
          child: Row(
            mainAxisAlignment: _isExpanded
                ? MainAxisAlignment.spaceBetween
                : MainAxisAlignment.center,
            children: [
              if (_isExpanded) ...[
                const Padding(
                  padding: EdgeInsets.only(left: 12),
                  child: Text('Navigation',
                      style: TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5)),
                ),
                const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: Icon(Icons.close_rounded,
                      color: Colors.white54, size: 18),
                ),
              ] else
                const Icon(Icons.menu_rounded, color: Colors.white60, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
