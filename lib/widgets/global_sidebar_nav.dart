import 'package:flutter/material.dart';
import 'package:monitoring/utils/ui_utils.dart';

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

  static const double _collapsedWidth = 68;
  static const double _expandedWidth = 260;
  static const _bgColor = Color(0xFF1E1F20); // Gemini-style dark background
  static const _activeColor = Color(0xFF3B4D63); // Muted highlight
  static const _accentColor = Color(0xFF8AB4F8); // Gemini blue accent

  static const List<_NavItem> _navItems = [
    _NavItem(Icons.dashboard_outlined, 'Dashboard', '/dashboard'),
    _NavItem(Icons.storage_outlined, 'Master Data', '/tower-management'),
    _NavItem(Icons.add_circle_outline, 'Add Device', '/add-device'),
    _NavItem(Icons.router_outlined, 'Access Point', '/network'),
    _NavItem(Icons.videocam_outlined, 'CCTV', '/cctv'),
    _NavItem(Icons.monitor_outlined, 'MMT', '/mmt-monitoring'),
    _NavItem(Icons.dns_outlined, 'NVR', '/nvr-monitoring-cy1'),
    _NavItem(Icons.device_hub_outlined, 'Switch', '/switch-monitoring-cy1'),
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
    if (target == '/nvr-monitoring-cy1') {
      return [
        '/nvr-monitoring-cy1',
        '/nvr-monitoring-cy2',
        '/nvr-monitoring-cy3',
        '/nvr-monitoring-gate',
        '/nvr-monitoring-parking'
      ].contains(current);
    }
    if (target == '/switch-monitoring-cy1') {
      return [
        '/switch-monitoring-cy1',
        '/switch-monitoring-cy2',
        '/switch-monitoring-cy3',
        '/switch-monitoring-gate',
        '/switch-monitoring-parking'
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

  @override
  void initState() {
    super.initState();
    _isExpanded = sidebarExpandedNotifier.value;
    sidebarExpandedNotifier.addListener(_syncExpansion);
  }

  @override
  void dispose() {
    sidebarExpandedNotifier.removeListener(_syncExpansion);
    super.dispose();
  }

  void _syncExpansion() {
    if (mounted) setState(() => _isExpanded = sidebarExpandedNotifier.value);
  }

  void _navigate(String route) {
    if (!_isActiveRoute(widget.currentRoute, route)) {
      sidebarExpandedNotifier.value = false;
      Navigator.pushReplacementNamed(context, route);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = isMobileScreen(context);

    if (!widget.enabled) {
      return widget.child;
    }

    if (isMobile) {
      return Stack(
        children: [
          widget.child,
          if (_isExpanded)
            GestureDetector(
              onTap: () => sidebarExpandedNotifier.value = false,
              child: Container(
                color: Colors.black54,
              ),
            ),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            left: _isExpanded ? 0 : -_expandedWidth,
            top: 0,
            bottom: 0,
            width: _expandedWidth,
            child: _buildSidebarPanel(isOverlay: true),
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSidebarPanel(),
        Expanded(child: widget.child),
      ],
    );
  }

  Widget _buildSidebarPanel({bool isOverlay = false}) {
    final width = _isExpanded ? _expandedWidth : _collapsedWidth;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      width: isOverlay ? _expandedWidth : width,
      decoration: BoxDecoration(
        color: _bgColor,
        border: Border(
          right: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: _navItems.length,
              itemBuilder: (context, index) {
                final item = _navItems[index];
                final isActive =
                    _isActiveRoute(widget.currentRoute, item.route);

                return _buildSidebarItem(item, isActive);
              },
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(_NavItem item, bool isActive) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Tooltip(
        message: _isExpanded ? '' : item.label,
        preferBelow: false,
        child: InkWell(
          onTap: () => _navigate(item.route),
          borderRadius: BorderRadius.circular(28),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 48,
            padding: EdgeInsets.symmetric(horizontal: _isExpanded ? 16 : 12),
            decoration: BoxDecoration(
              color: isActive ? _activeColor : Colors.transparent,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Row(
              children: [
                Icon(
                  item.icon,
                  color: isActive ? _accentColor : Colors.white70,
                  size: 22,
                ),
                if (_isExpanded) ...[
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isActive ? Colors.white : Colors.white70,
                        fontSize: 14,
                        fontWeight:
                            isActive ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
