import 'package:flutter/material.dart';
import 'package:animations/animations.dart';
import 'package:monitoring/main.dart';
import 'package:monitoring/utils/ui_utils.dart';
import 'package:monitoring/utils/auth_helper.dart';
import 'package:monitoring/route_proxy_page.dart';
import 'package:monitoring/services/api_service.dart';
import 'package:monitoring/widgets/global_header_bar.dart';
import 'package:monitoring/widgets/global_sidebar_nav.dart';
import 'package:monitoring/widgets/global_footer.dart';
import 'package:monitoring/theme/app_dropdown_style.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late ApiService apiService;
  String fullname = 'Loading...';
  String username = 'Loading...';
  String email = 'Loading...';
  String division = 'Loading...';
  String phone = 'Loading...';
  String location = 'Loading...';

  @override
  void initState() {
    super.initState();
    apiService = ApiService();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final userData = await AuthHelper.getUserData();
    // First show cached data quickly
    setState(() {
      fullname =
          userData['fullname']!.isEmpty ? 'No Name' : userData['fullname']!;
      username =
          userData['username']!.isEmpty ? 'No Username' : userData['username']!;
      email = userData['email']!.isEmpty ? 'No Email' : userData['email']!;
      division = userData['division']!.isEmpty
          ? (userData['role']!.isEmpty ? 'Division' : userData['role']!)
          : userData['division']!;
      phone = userData['phone']!.isEmpty ? '-' : userData['phone']!;
      location = userData['location']!.isEmpty ? '-' : userData['location']!;
    });

    // Then fetch fresh profile from API (sync with DB)
    final idStr = userData['user_id'] ?? '';
    if (idStr.isNotEmpty) {
      final userId = int.tryParse(idStr);
      if (userId != null) {
        final profile = await apiService.getProfile(userId);
        if (profile != null && mounted) {
          setState(() {
            fullname = profile.fullname.isEmpty ? fullname : profile.fullname;
            username = profile.username.isEmpty ? username : profile.username;
            email = profile.email.isEmpty ? email : profile.email;
            division = profile.division.isEmpty
                ? (profile.role.isEmpty ? division : profile.role)
                : profile.division;
            phone = profile.phone.isEmpty ? phone : profile.phone;
            location = profile.location.isEmpty ? location : profile.location;
          });
          // Update local cache so other pages stay in sync
          await AuthHelper.saveUserData(profile.toJson());
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = isMobileScreen(context);
    return Scaffold(
      backgroundColor: AppDropdownStyle.standardPageBackground,
      body: Stack(
        children: [
          Column(
            children: [
              const GlobalHeaderBar(currentRoute: '/profile'),
              Expanded(
                child: GlobalSidebarNav(
                    currentRoute: '/profile',
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: EdgeInsets.all(isMobile ? 12 : 24),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ConstrainedBox(
                              constraints: BoxConstraints(
                                  maxWidth: isMobile ? double.infinity : 800),
                              child: _buildContent(context),
                            ),
                          ],
                        ),
                      ),
                    )),
              ),
              const GlobalFooter(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    final isMobile = isMobileScreen(context);

    return Container(
      width: screenWidth,
      padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 12 : 24, vertical: isMobile ? 12 : 16),
      color: const Color(0xFF1976D2),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Terminal Nilam',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () {},
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(50),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.person,
                            color: Color(0xFF1976D2),
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ScrollConfiguration(
                  behavior: ScrollConfiguration.of(context)
                      .copyWith(scrollbars: false),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildHeaderOpenButton('Add New Device', '/add-device',
                            isActive: false),
                        const SizedBox(width: 8),
                        _buildHeaderOpenButton('Dashboard', '/dashboard',
                            isActive: false),
                        const SizedBox(width: 8),
                        _buildHeaderOpenButton('AP', '/network',
                            isActive: false),
                        const SizedBox(width: 8),
                        _buildHeaderOpenButton('CCTV', '/cctv',
                            isActive: false),
                        const SizedBox(width: 8),
                        _buildHeaderOpenButton(
                            'MMT Monitoring', '/mmt-monitoring',
                            isActive: false),
                        const SizedBox(width: 8),
                        _buildHeaderOpenButton('Alert', '/alerts',
                            isActive: false),
                        const SizedBox(width: 8),
                        _buildHeaderOpenButton('Alert Report', '/report',
                            isActive: false),
                        const SizedBox(width: 8),
                        _buildHeaderOpenButton(
                            'Master Tower', '/tower-management',
                            isActive: false),
                        const SizedBox(width: 8),
                        _buildHeaderLogoutButton(),
                      ],
                    ),
                  ),
                ),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Terminal Nilam - FIXED
                const Text(
                  'Terminal Nilam',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 30),
                // Buttons + Profile - SCROLL HORIZONTAL
                Expanded(
                  child: ScrollConfiguration(
                    behavior: ScrollConfiguration.of(context)
                        .copyWith(scrollbars: false),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildHeaderOpenButton(
                              'Add New Device', '/add-device',
                              isActive: false),
                          const SizedBox(width: 12),
                          _buildHeaderOpenButton(
                              'Master Data', '/tower-management',
                              isActive: false),
                          const SizedBox(width: 12),
                          _buildHeaderOpenButton('Dashboard', '/dashboard',
                              isActive: false),
                          const SizedBox(width: 12),
                          _buildHeaderOpenButton('AP', '/network',
                              isActive: false),
                          const SizedBox(width: 12),
                          _buildHeaderOpenButton('CCTV', '/cctv',
                              isActive: false),
                          const SizedBox(width: 12),
                          _buildHeaderOpenButton('MMT', '/mmt-monitoring',
                              isActive: false),
                          const SizedBox(width: 12),
                          _buildHeaderOpenButton('Alert', '/alerts',
                              isActive: false),
                          const SizedBox(width: 12),
                          _buildHeaderOpenButton('Alert Report', '/report',
                              isActive: false),
                          const SizedBox(width: 12),
                          _buildHeaderLogoutButton(),
                          const SizedBox(width: 12),
                          MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              onTap: () {},
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  borderRadius: BorderRadius.circular(50),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.1),
                                      blurRadius: 8,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.person,
                                  color: Color(0xFF1976D2),
                                  size: 24,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildHeaderButton(String text, VoidCallback onPressed) {
    return buildLiquidGlassButton(text, onPressed, isActive: false);
  }

  Widget _buildHeaderOpenButton(String text, String route,
      {bool isActive = false}) {
    return OpenContainer(
      transitionDuration: const Duration(milliseconds: 550),
      transitionType: ContainerTransitionType.fadeThrough,
      closedElevation: 0,
      closedColor: Colors.transparent,
      closedShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      openElevation: 0,
      openBuilder: (context, _) => RouteProxyPage(route),
      closedBuilder: (context, openContainer) {
        return buildLiquidGlassButton(text, openContainer, isActive: isActive);
      },
    );
  }

  Widget _buildHeaderLogoutButton() {
    return buildLiquidGlassButton('Logout', () => _showLogoutDialog(context),
        isActive: false);
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout', style: TextStyle(color: Colors.black87)),
        content: const Text('Are you sure you want to logout?',
            style: TextStyle(color: Colors.black87)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text('Cancel', style: TextStyle(color: Colors.black87)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              AuthHelper.clearUserData();
              Navigator.pushReplacementNamed(context, '/login');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderButtonOld(String text, VoidCallback onPressed) {
    return buildLiquidGlassButton(text, onPressed, isActive: false);
  }

  Widget _buildContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Profile Header Card
        _buildProfileHeaderCard(context),
        const SizedBox(height: 32),
        // Profile Information Section
        _buildProfileInfoSection(),
        const SizedBox(height: 32),
        // Contact Information Section
        _buildContactInfoSection(),
        const SizedBox(height: 32),
        // Action Buttons
        _buildActionButtons(context),
      ],
    );
  }

  Widget _buildProfileHeaderCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Avatar
          GestureDetector(
            onTap: () => _showProfilePhotoDialog(context),
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFF1976D2),
                borderRadius: BorderRadius.circular(60),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1976D2).withValues(alpha: 0.4),
                    blurRadius: 16,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: const Icon(
                Icons.person,
                color: Colors.white,
                size: 60,
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Name
          Text(
            fullname,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          // Role
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1976D2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              division.isEmpty ? 'Division' : division,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildProfileInfoSection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Profile Information',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Table(
            columnWidths: const {
              0: FixedColumnWidth(28), // Icon
              1: FixedColumnWidth(85), // Diperkecil agar value bergeser ke kiri
              2: FlexColumnWidth(), // Value
            },
            defaultVerticalAlignment: TableCellVerticalAlignment.top,
            children: [
              _buildContactTableRow(Icons.badge_outlined, 'Full Name', fullname),
              _buildContactTableRow(Icons.alternate_email, 'Username', username),
              _buildContactTableRow(Icons.business_center_outlined, 'Division', division),
            ],
          ),
        ],
      ),
    );
  }

  TableRow _buildTableRow(String label, String value) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContactInfoSection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Contact Information',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Table(
            columnWidths: const {
              0: FixedColumnWidth(28), // Icon
              1: FixedColumnWidth(85), // Diperkecil agar value bergeser ke kiri
              2: FlexColumnWidth(), // Value
            },
            defaultVerticalAlignment: TableCellVerticalAlignment.top,
            children: [
              _buildContactTableRow(Icons.email, 'Email', email),
              _buildContactTableRow(Icons.phone, 'Phone Number', phone),
              _buildContactTableRow(Icons.location_on, 'Location', location),
            ],
          ),
        ],
      ),
    );
  }

  TableRow _buildContactTableRow(IconData icon, String label, String value) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Icon(
              icon,
              color: const Color(0xFF1976D2),
              size: 20,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }


  Widget _buildActionButtons(BuildContext context) {
    final isMobile = isMobileScreen(context);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 0 : 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () async {
                final result =
                    await Navigator.pushNamed(context, '/edit-profile');
                if (result != null && mounted) {
                  _loadUserData();
                }
              },
              icon: const Icon(Icons.edit, size: 20),
              label: Text(
                'Edit Profile',
                style: TextStyle(fontSize: isMobile ? 13 : 14),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1976D2),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/change-password');
              },
              icon: const Icon(Icons.security, size: 20),
              label: Text(
                'Change Password',
                style: TextStyle(fontSize: isMobile ? 12 : 14),
                overflow: TextOverflow.ellipsis,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF27AE60),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showProfilePhotoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(
              parent: ModalRoute.of(context)!.animation!,
              curve: Curves.elasticOut,
            ),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF34495E),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 16,
                  spreadRadius: 2,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Profile Photo',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.7, end: 1.0),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.elasticOut,
                  builder: (context, scale, child) {
                    return Transform.scale(
                      scale: scale,
                      child: child,
                    );
                  },
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1976D2),
                      borderRadius: BorderRadius.circular(100),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1976D2).withValues(alpha: 0.4),
                          blurRadius: 20,
                          spreadRadius: 4,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 120,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  fullname,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 20),
                TextButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white),
                  label: const Text(
                    'Close',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    backgroundColor: Colors.white.withValues(alpha: 0.08),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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
