import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:monitoring/utils/auth_helper.dart';
import 'package:monitoring/utils/ui_utils.dart';

class _NavEntry {
  final IconData icon;
  final String label;
  final String route;
  const _NavEntry(this.icon, this.label, this.route);
}

const _mobileNavItems = [
  _NavEntry(Icons.dashboard_outlined, 'Dashboard', '/dashboard'),
  _NavEntry(Icons.storage_outlined, 'Master Data', '/tower-management'),
  _NavEntry(Icons.add_circle_outline, 'Add Device', '/add-device'),
  _NavEntry(Icons.router_outlined, 'Access Point', '/network'),
  _NavEntry(Icons.videocam_outlined, 'CCTV', '/cctv'),
  _NavEntry(Icons.monitor_outlined, 'MMT', '/mmt-monitoring'),
  _NavEntry(Icons.warning_amber_outlined, 'Alerts', '/alerts'),
  _NavEntry(Icons.assessment_outlined, 'Report', '/report'),
  _NavEntry(Icons.speed_outlined, 'Performance', '/global-diagnostics'),
  _NavEntry(Icons.person_outline, 'Profile', '/profile'),
];

class GlobalHeaderBar extends StatefulWidget {
  final String currentRoute;

  const GlobalHeaderBar({
    super.key,
    required this.currentRoute,
  });

  @override
  State<GlobalHeaderBar> createState() => _GlobalHeaderBarState();
}

class _GlobalHeaderBarState extends State<GlobalHeaderBar> {
  String _name = 'User';

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final userData = await AuthHelper.getUserData();
    if (!mounted) return;
    setState(() {
      final fullname = (userData['fullname'] ?? '').trim();
      final username = (userData['username'] ?? '').trim();
      _name = fullname.isNotEmpty
          ? fullname
          : (username.isNotEmpty ? username : 'User');
    });
  }

  void _openProfile() {
    if (widget.currentRoute == '/profile') return;
    Navigator.pushNamed(context, '/profile');
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await AuthHelper.clearUserData();
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/login');
    }
  }



  @override
  Widget build(BuildContext context) {
    final isMobile = isMobileScreen(context);

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 10 : 16,
            vertical: isMobile ? 6 : 8,
          ),
          clipBehavior: Clip.none,
          decoration: BoxDecoration(
            color: const Color(0xFF1976D2).withValues(alpha: 0.78),
            boxShadow: const [
              BoxShadow(
                  color: Colors.black26, blurRadius: 8, offset: Offset(0, 2)),
            ],
            border: Border(
              bottom: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (isMobile)
                  const Text(
                    'TPK Nilam',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                // Left & Right controls
                Row(
                  children: [
                    if (isMobile)
                      IconButton(
                        icon: const Icon(Icons.menu, color: Colors.white, size: 26),
                        onPressed: () {
                          sidebarExpandedNotifier.value = !sidebarExpandedNotifier.value;
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                        splashRadius: 22,
                      )
                    else
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.home, color: Colors.white, size: 26),
                            onPressed: () {
                              if (widget.currentRoute != '/dashboard') {
                                Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (route) => false);
                              }
                            },
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                            splashRadius: 22,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Monitoring Dashboard',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    const Spacer(),
                    // Right-side controls: profile + logout + ⋮
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Profile avatar
                        InkWell(
                          onTap: _openProfile,
                          borderRadius: BorderRadius.circular(30),
                          child: Row(
                            children: [
                              if (!isMobile)
                                Text(
                                  _name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                  ),
                                ),
                              if (!isMobile) const SizedBox(width: 10),
                              CircleAvatar(
                                radius: isMobile ? 15 : 18,
                                backgroundColor: Colors.white24,
                                child: Icon(
                                  Icons.person,
                                  color: Colors.white,
                                  size: isMobile ? 17 : 20,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Logout
                        IconButton(
                          onPressed: _logout,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                          splashRadius: 20,
                          icon: Icon(
                            Icons.logout,
                            color: Colors.white.withValues(alpha: 0.9),
                            size: isMobile ? 19 : 22,
                          ),
                        ),
                        const SizedBox(width: 4),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}