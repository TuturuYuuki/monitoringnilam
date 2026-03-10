import 'package:flutter/material.dart';

class GlobalSidebarNav extends StatelessWidget {
  final String currentRoute;

  const GlobalSidebarNav({
    super.key,
    required this.currentRoute,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 900;
    final items = _items;

    if (isMobile) {
      return Container(
        height: 64,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            final isActive = _isActiveRoute(currentRoute, item.route);
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _buildItem(context, item, isActive, compact: true),
            );
          },
        ),
      );
    }

    return Container(
      width: 188,
      margin: const EdgeInsets.only(left: 12, top: 8),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: items.map((item) {
            final isActive = _isActiveRoute(currentRoute, item.route);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildItem(context, item, isActive),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildItem(
    BuildContext context,
    _SidebarNavItem item,
    bool isActive, {
    bool compact = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (!_isActiveRoute(currentRoute, item.route)) {
            Navigator.pushReplacementNamed(context, item.route);
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 12 : 14,
            vertical: compact ? 10 : 12,
          ),
          decoration: BoxDecoration(
            color: isActive ? item.color : const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive ? Colors.white38 : const Color(0xFF334155),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(item.icon, color: Colors.white, size: compact ? 18 : 20),
              SizedBox(width: compact ? 8 : 10),
              Text(
                item.label,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: compact ? 12 : 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isActiveRoute(String current, String target) {
    if (current == target) return true;
    if (target == '/network') {
      return current == '/network' ||
          current == '/network-cy2' ||
          current == '/network-cy3' ||
          current == '/network-gate' ||
          current == '/network-parking';
    }
    if (target == '/cctv') {
      return current == '/cctv' ||
          current == '/cctv-cy2' ||
          current == '/cctv-cy3' ||
          current == '/cctv-gate' ||
          current == '/cctv-parking' ||
          current == '/cctv-fullscreen';
    }
    if (target == '/mmt-monitoring') {
      return current == '/mmt-monitoring' ||
          current == '/mmt-monitoring-cy2' ||
          current == '/mmt-monitoring-cy3' ||
          current == '/mmt-monitoring-gate' ||
          current == '/mmt-monitoring-parking' ||
          current == '/mmt-cy2' ||
          current == '/mmt-cy3';
    }
    return false;
  }

  static final List<_SidebarNavItem> _items = [
    const _SidebarNavItem(
      icon: Icons.dashboard,
      label: 'Dashboard',
      route: '/dashboard',
      color: Color(0xFF1976D2),
    ),
    const _SidebarNavItem(
      icon: Icons.storage,
      label: 'Master Data',
      route: '/tower-management',
      color: Color(0xFF607D8B),
    ),
    const _SidebarNavItem(
      icon: Icons.add_circle,
      label: 'Add Device',
      route: '/add-device',
      color: Color(0xFFFB8C00),
    ),
    const _SidebarNavItem(
      icon: Icons.router,
      label: 'Access Point',
      route: '/network',
      color: Color(0xFF546E7A),
    ),
    const _SidebarNavItem(
      icon: Icons.videocam,
      label: 'CCTV',
      route: '/cctv',
      color: Color(0xFF00897B),
    ),
    const _SidebarNavItem(
      icon: Icons.monitor,
      label: 'MMT',
      route: '/mmt-monitoring',
      color: Color(0xFF43A047),
    ),
    const _SidebarNavItem(
      icon: Icons.warning,
      label: 'Alerts',
      route: '/alerts',
      color: Color(0xFFE53935),
    ),
    const _SidebarNavItem(
      icon: Icons.assessment,
      label: 'Alert Report',
      route: '/report',
      color: Color(0xFF8E24AA),
    ),
    const _SidebarNavItem(
      icon: Icons.settings,
      label: 'Settings',
      route: '/profile',
      color: Color(0xFF607D8B),
    ),
  ];
}

class _SidebarNavItem {
  final IconData icon;
  final String label;
  final String route;
  final Color color;

  const _SidebarNavItem({
    required this.icon,
    required this.label,
    required this.route,
    required this.color,
  });
}
