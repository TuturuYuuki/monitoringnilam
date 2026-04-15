import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:monitoring/utils/auth_helper.dart';
import 'package:monitoring/widgets/global_sidebar_nav.dart';

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
        content: const Text('Are You Sure To Logout?'),
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
    final isMobile = MediaQuery.of(context).size.width < 768;

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
            color: const Color(0xFF1976D2).withOpacity(0.78),
            boxShadow: const [
              BoxShadow(
                  color: Colors.black26, blurRadius: 8, offset: Offset(0, 2)),
            ],
            border: Border(
              bottom: BorderSide(color: Colors.white.withOpacity(0.12)),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Row(
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isMobile)
                      IconButton(
                        onPressed: () {
                          GlobalSidebarNav.scaffoldKey.currentState?.openDrawer();
                        },
                        icon: const Icon(
                          Icons.menu,
                          color: Colors.white,
                          size: 22,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    if (isMobile) const SizedBox(width: 8),
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
                SizedBox(width: isMobile ? 2 : 8),
                IconButton(
                  onPressed: _logout,
                  splashRadius: isMobile ? 18 : 22,
                  icon: Icon(
                    Icons.logout,
                    color: Colors.white,
                    size: isMobile ? 20 : 22,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
