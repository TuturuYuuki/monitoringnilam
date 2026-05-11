import 'package:flutter/material.dart';
import 'package:monitoring/main.dart';
import 'package:monitoring/utils/ui_utils.dart';
import 'package:monitoring/utils/auth_helper.dart';
import 'package:monitoring/services/api_service.dart';
import 'package:monitoring/widgets/global_header_bar.dart';
import 'package:monitoring/widgets/global_sidebar_nav.dart';
import 'package:monitoring/widgets/global_footer.dart';
import 'package:monitoring/theme/app_dropdown_style.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';

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
  String? profilePhoto;
  bool isUploading = false;

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
      fullname = (userData['fullname'] ?? '').isEmpty ? 'No Name' : userData['fullname']!;
      username = (userData['username'] ?? '').isEmpty ? 'No Username' : userData['username']!;
      email = (userData['email'] ?? '').isEmpty ? 'No Email' : userData['email']!;
      division = (userData['division'] ?? '').isEmpty
          ? ((userData['role'] ?? '').isEmpty ? 'Division' : userData['role']!)
          : userData['division']!;
      phone = (userData['phone'] ?? '').isEmpty ? '-' : userData['phone']!;
      location = (userData['location'] ?? '').isEmpty ? '-' : userData['location']!;
      profilePhoto = userData['profile_photo'];
    });

    // Then fetch fresh profile from API (sync with DB)
    final idStr = (userData['id'] ?? userData['user_id'] ?? '').toString();
    if (idStr.isNotEmpty && idStr != '0') {
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
            profilePhoto = profile.profilePhoto;
          });
          // Update local cache so other pages stay in sync
          await AuthHelper.saveUserData(profile.toJson());
        }
      }
    }
  }

  Future<void> _pickAndUploadImage() async {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Opening file picker...'),
          duration: Duration(milliseconds: 800),
        ),
      );
    }
    
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );

      if (image != null) {
        // Step 2: Crop Image
        final croppedFile = await ImageCropper().cropImage(
          sourcePath: image.path,
          aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
          compressFormat: ImageCompressFormat.jpg,
          compressQuality: 80,
          uiSettings: [
            WebUiSettings(
              context: context,
              presentStyle: WebPresentStyle.dialog,
              size: const CropperSize(width: 250, height: 250),
            ),
          ],
        );

        if (croppedFile != null) {
          setState(() => isUploading = true);
          
          final userData = await AuthHelper.getUserData();
          final idStr = (userData['id'] ?? userData['user_id'] ?? '').toString();
          final userId = int.tryParse(idStr);
          
          if (userId != null && userId != 0) {
            final bytes = await croppedFile.readAsBytes();
            final fileName = croppedFile.path.split('/').last;
            final result = await apiService.uploadProfilePhoto(userId, bytes, fileName);
            
            if (result['success'] == true) {
              // Try to immediately reflect the returned/new filename (if server returns it)
              String? newFileName;
              if (result.containsKey('file')) newFileName = result['file']?.toString();
              if ((newFileName == null || newFileName.isEmpty) && result.containsKey('filename')) newFileName = result['filename']?.toString();
              if ((newFileName == null || newFileName.isEmpty) && result.containsKey('profile_photo')) newFileName = result['profile_photo']?.toString();
              if ((newFileName == null || newFileName.isEmpty) && result.containsKey('data') && result['data'] is Map) {
                newFileName = (result['data']['file'] ?? result['data']['filename'] ?? result['data']['profile_photo'])?.toString();
              }

              if (newFileName != null && newFileName.isNotEmpty) {
                // Evict any cached image for the old/new url to force refresh
                try {
                  final newUrl = ApiService.getPhotoUrl(newFileName);
                  final provider = NetworkImage(newUrl);
                  provider.evict();
                } catch (_) {}

                // Update local state + cache immediately so UI shows new image
                setState(() {
                  profilePhoto = newFileName;
                });

                // Persist to SharedPreferences for other pages
                try {
                  await AuthHelper.saveUserData({
                    'id': userId,
                    'username': username,
                    'email': email,
                    'fullname': fullname,
                    'role': division,
                    'profile_photo': newFileName,
                  });
                } catch (_) {}
              }

              // Still call full reload to sync any other fields
              await _loadUserData();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profile photo updated successfully!')),
                );
              }
            } else {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(result['message'] ?? 'Failed to upload photo')),
                );
              }
            }
          }
          if (mounted) {
            setState(() => isUploading = false);
          }
        }
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = isMobileScreen(context);
    return Scaffold(
      backgroundColor: AppDropdownStyle.standardPageBackground,
      body: Column(
        children: [
          const GlobalHeaderBar(currentRoute: '/profile'),
          Expanded(
            child: GlobalSidebarNav(
                currentRoute: '/profile',
                child: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.all(isMobile ? 12 : 32),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                            maxWidth: isMobile ? double.infinity : 1100),
                        child: _buildContent(context),
                      ),
                    ),
                  )),
            ),
          ),
          const GlobalFooter(),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final isMobile = isMobileScreen(context);
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildProfileHeaderCard(context),
          const SizedBox(height: 32),
          _buildProfileInfoSection(),
          const SizedBox(height: 32),
          _buildContactInfoSection(),
          const SizedBox(height: 32),
          _buildActionButtons(context),
        ],
      );
    } else {
      return _buildWebLayout(context);
    }
  }

  Widget _buildWebLayout(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
          child: Column(
            children: [
              _buildProfileHeaderCard(context, isWeb: true),
              const SizedBox(height: 24),
              _buildAccountStatusCard(),
            ],
          ),
        ),
        const SizedBox(width: 32),
        Expanded(
          flex: 7,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfileInfoSection(isWeb: true),
              const SizedBox(height: 24),
              _buildContactInfoSection(isWeb: true),
              const SizedBox(height: 32),
              _buildActionButtons(context, isWeb: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAccountStatusCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified_user_rounded, color: Colors.greenAccent, size: 18),
              const SizedBox(width: 8),
              Text(
                'ACCOUNT STATUS',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Active / Verified',
            style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: 1.0,
            backgroundColor: Colors.white10,
            color: Colors.greenAccent.withValues(alpha: 0.8),
            minHeight: 4,
            borderRadius: BorderRadius.circular(2),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeaderCard(BuildContext context, {bool isWeb = false}) {
    return Container(
      padding: EdgeInsets.all(isWeb ? 40 : 32),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1.5),
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
          GestureDetector(
            onTap: isUploading ? null : _pickAndUploadImage,
            behavior: HitTestBehavior.opaque,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Stack(
                children: [
                    Container(
                      key: ValueKey(profilePhoto ?? 'no-photo${DateTime.now().millisecondsSinceEpoch}'),
                      width: isWeb ? 160 : 120,
                      height: isWeb ? 160 : 120,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1976D2),
                        borderRadius: BorderRadius.circular(isWeb ? 80 : 60),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF1976D2).withValues(alpha: 0.4),
                            blurRadius: 20,
                            spreadRadius: 4,
                          ),
                        ],
                        border: Border.all(color: Colors.white, width: 4),
                        image: profilePhoto != null && profilePhoto!.isNotEmpty
                            ? DecorationImage(
                                image: NetworkImage(ApiService.getPhotoUrl(profilePhoto)),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                    child: profilePhoto == null || profilePhoto!.isEmpty
                        ? Icon(Icons.person, color: Colors.white, size: isWeb ? 80 : 60)
                        : null,
                  ),
                  if (isUploading)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black45,
                          borderRadius: BorderRadius.circular(isWeb ? 80 : 60),
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                      ),
                    ),
                  // Camera Icon Overlay
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFF1976D2),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                        ],
                      ),
                      child: Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: isWeb ? 24 : 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            fullname,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: isWeb ? 32 : 28,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1976D2),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1976D2).withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              division.isEmpty ? 'Division' : division,
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildProfileInfoSection({bool isWeb = false}) {
    return Container(
      padding: EdgeInsets.all(isWeb ? 32 : 24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.person_outline, color: Colors.blue, size: 22),
              ),
              const SizedBox(width: 16),
              const Text('Profile Information', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 32),
          Table(
            columnWidths: const {0: FixedColumnWidth(40), 1: FixedColumnWidth(120), 2: FlexColumnWidth()},
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
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

  Widget _buildContactInfoSection({bool isWeb = false}) {
    return Container(
      padding: EdgeInsets.all(isWeb ? 32 : 24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.contact_mail_outlined, color: Colors.orange, size: 22),
              ),
              const SizedBox(width: 16),
              const Text('Contact Information', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 32),
          Table(
            columnWidths: const {0: FixedColumnWidth(40), 1: FixedColumnWidth(120), 2: FlexColumnWidth()},
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: [
              _buildContactTableRow(Icons.email_outlined, 'Email', email),
              _buildContactTableRow(Icons.phone_outlined, 'Phone', phone),
              _buildContactTableRow(Icons.location_on_outlined, 'Location', location),
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
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Icon(icon, color: Colors.white.withValues(alpha: 0.4), size: 20),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 14, fontWeight: FontWeight.w600)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, {bool isWeb = false}) {
    final isMobile = isMobileScreen(context);
    return Row(
      mainAxisAlignment: isWeb ? MainAxisAlignment.start : MainAxisAlignment.center,
      children: [
        SizedBox(
          width: isWeb ? 220 : null,
          child: ElevatedButton.icon(
            onPressed: () async {
              final result = await Navigator.pushNamed(context, '/edit-profile');
              if (result != null && mounted) {
                _loadUserData();
              }
            },
            icon: const Icon(Icons.edit_rounded, size: 20),
            label: Text('Edit Profile', style: TextStyle(fontSize: isMobile ? 13 : 14, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1976D2),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
          ),
        ),
        const SizedBox(width: 16),
        SizedBox(
          width: isWeb ? 220 : null,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, '/change-password');
            },
            icon: const Icon(Icons.lock_reset_rounded, size: 22),
            label: Text('Password', style: TextStyle(fontSize: isMobile ? 12 : 14, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
              side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
          ),
        ),
      ],
    );
  }

}
