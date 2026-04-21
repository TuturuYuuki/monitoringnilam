import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:monitoring/utils/auth_helper.dart';
import 'package:monitoring/theme/app_dropdown_style.dart';
import 'package:monitoring/utils/ui_utils.dart';
import 'package:monitoring/route_proxy_page.dart';

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
    Navigator.pushReplacementNamed(context, '/profile');
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

  void _showNavMenu(BuildContext context) {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay =
        Navigator.of(context).overlay!.context.findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset(0, button.size.height + 4),
            ancestor: overlay),
        button.localToGlobal(
            Offset(button.size.width, button.size.height + 4),
            ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    showMenu<String>(
      context: context,
      position: position,
      constraints: const BoxConstraints(minWidth: 52, maxWidth: 52),
      elevation: 12,
      color: AppDropdownStyle.menuBackground,
      shape: RoundedRectangleBorder(
        borderRadius: AppDropdownStyle.menuBorderRadius,
        side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
      ),
      items: _mobileNavItems.map((item) {
        final isActive = widget.currentRoute == item.route;
        final tooltipKey = GlobalKey<TooltipState>();

        return PopupMenuItem<String>(
          value: item.route,
          padding: EdgeInsets.zero,
          child: Tooltip(
            key: tooltipKey,
            message: item.label,
            waitDuration: Duration.zero,
            triggerMode: TooltipTriggerMode.manual,
            preferBelow: false,
            child: InkWell(
              onTap: () {
                tooltipKey.currentState?.ensureTooltipVisible();
                // Tunggu sebentar agar tooltip terlihat sebelum menu tertutup
                Future.delayed(const Duration(milliseconds: 100), () {
                  if (context.mounted) Navigator.pop(context, item.route);
                });
              },
              child: Center(
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppDropdownStyle.accentColor.withValues(alpha: 0.2)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    item.icon,
                    color: isActive ? AppDropdownStyle.accentColor : Colors.white70,
                    size: 22,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    ).then((route) {
      if (route != null && route != widget.currentRoute) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            settings: RouteSettings(name: route),
            pageBuilder: (context, animation, secondaryAnimation) =>
                RouteProxyPage(route),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
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
      }
    });
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
            child: Row(
              children: [
                // Logo + title
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.warehouse,
                      color: Colors.white,
                      size: isMobile ? 22 : 30,
                    ),
                    SizedBox(width: isMobile ? 8 : 12),
                    Text(
                      'TPK Nilam',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isMobile ? 16 : 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                // Right-side controls: profile + ⋮ + logout
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
                    // ⋮ Nav menu (mobile only)
                    if (isMobile)
                      Builder(
                        builder: (btnCtx) => IconButton(
                          onPressed: () => _showNavMenu(btnCtx),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          icon: const Icon(
                            Icons.more_vert,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    // Logout
                    IconButton(
                      onPressed: _logout,
                      padding: EdgeInsets.only(left: isMobile ? 2 : 8),
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      splashRadius: isMobile ? 18 : 22,
                      icon: Icon(
                        Icons.logout,
                        color: Colors.white,
                        size: isMobile ? 20 : 22,
                      ),
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

