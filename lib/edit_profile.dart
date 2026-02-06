import 'dart:async';
import 'package:flutter/material.dart';
import 'main.dart';
import 'utils/auth_helper.dart';
import 'services/api_service.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _usernameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _locationController;
  late TextEditingController _divisionController;

  bool _isLoading = false;
  int? _userId;
  late ApiService apiService;

  // Email verification state
  bool _emailVerified = false;
  String _emailInVerification = '';
  String _currentEmail = '';

  @override
  void initState() {
    super.initState();
    apiService = ApiService();
    _nameController = TextEditingController();
    _usernameController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _locationController = TextEditingController();
    _divisionController = TextEditingController();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      // First, get user_id from SharedPreferences
      final userData = await AuthHelper.getUserData();
      final userId = int.tryParse(userData['user_id'] ?? '');

      if (userId != null) {
        // Try to fetch fresh data from database via API
        print('Loading profile from database for user_id: $userId');
        final response = await apiService.getUserProfile(userId);

        if (response['success'] == true && response['data'] != null) {
          final profileData = response['data'];
          print('Profile data loaded from API: $profileData');

          setState(() {
            _userId = userId;
            _nameController.text = profileData['fullname'] ?? '';
            _usernameController.text = profileData['username'] ?? '';
            _emailController.text = profileData['email'] ?? '';
            _phoneController.text = profileData['phone'] ?? '';
            _locationController.text = profileData['location'] ?? '';
            _divisionController.text =
                profileData['division']?.isNotEmpty == true
                    ? profileData['division']!
                    : (profileData['role'] ?? '');

            // Set current email for comparison
            _currentEmail = profileData['email'] ?? '';
            _emailVerified = true;
          });
          return;
        }
      }
    } catch (e) {
      print('Error loading profile from API: $e');
    }

    // Fallback: Load from SharedPreferences if API fails
    print('Fallback: Loading profile from SharedPreferences');
    final userData = await AuthHelper.getUserData();
    setState(() {
      _userId = int.tryParse(userData['user_id'] ?? '');
      _nameController.text = userData['fullname'] ?? '';
      _usernameController.text = userData['username'] ?? '';
      _emailController.text = userData['email'] ?? '';
      _phoneController.text = userData['phone'] ?? '';
      _locationController.text = userData['location'] ?? '';
      _divisionController.text = userData['division']?.isNotEmpty == true
          ? userData['division']!
          : (userData['role'] ?? '');

      // Set current email for comparison
      _currentEmail = userData['email'] ?? '';
      _emailVerified = true; // Current email is verified
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _divisionController.dispose();
    super.dispose();
  }

  Future<void> _handleEmailVerification() async {
    final newEmail = _emailController.text.trim();

    // Validate email format
    if (newEmail.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email tidak boleh kosong'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(newEmail)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Format email tidak valid'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check if email is same as current
    if (newEmail == _currentEmail) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Email sama dengan email saat ini. Tidak perlu verifikasi.'),
          backgroundColor: Colors.green,
        ),
      );
      setState(() {
        _emailVerified = true;
        _emailInVerification = newEmail;
      });
      return;
    }

    // Request OTP
    setState(() {
      _isLoading = true;
    });

    print('=== REQUEST OTP ===');
    print('User ID: $_userId');
    print('New Email: $newEmail');

    try {
      final response =
          await apiService.requestEmailChangeOtp(_userId!, newEmail);

      print('=== OTP RESPONSE ===');
      print('Response: $response');

      if (response['success'] == true) {
        setState(() {
          _emailInVerification = newEmail;
          _isLoading = false;
        });

        print('OTP sent successfully to $newEmail');

        // Show OTP input dialog
        if (mounted) {
          _showOtpInputDialog(newEmail, response['debug_otp']);
        }
      } else {
        setState(() {
          _isLoading = false;
        });

        print('OTP request failed: ${response['message']}');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'Gagal mengirim kode OTP'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showOtpInputDialog(String newEmail, String? debugOtp) async {
    final otpController = TextEditingController();

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _OtpDialog(
        newEmail: newEmail,
        debugOtp: debugOtp,
        otpController: otpController,
        onVerify: (otp) async {
          Navigator.pop(context);
          await _verifyOtpAndMarkEmail(newEmail, otp);
        },
        onCancel: () {
          Navigator.pop(context);
          setState(() {
            _emailVerified = false;
          });
        },
        onResend: () async {
          // Resend OTP
          await _handleEmailVerification();
        },
      ),
    );
  }

  Future<void> _showOtpInputDialogOld(String newEmail, String? debugOtp) async {
    final otpController = TextEditingController();

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF34495E),
        title: const Text(
          'Verifikasi Email',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kode verifikasi telah dikirim ke:',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF2C3E50),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                newEmail,
                style: const TextStyle(
                  color: Color(0xFF1976D2),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Silakan masukkan kode OTP yang Anda terima:',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: otpController,
              style: const TextStyle(color: Colors.white),
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                labelText: 'Kode OTP (6 angka)',
                labelStyle: const TextStyle(color: Colors.white70),
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.white30),
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Color(0xFF1976D2)),
                  borderRadius: BorderRadius.circular(8),
                ),
                counterStyle: const TextStyle(color: Colors.white70),
              ),
            ),
            if (debugOtp != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.2),
                    border: Border.all(color: Colors.orange),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Demo OTP: $debugOtp',
                    style: const TextStyle(color: Colors.orange, fontSize: 12),
                  ),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              otpController.dispose();
              Navigator.pop(context);
              setState(() {
                _emailVerified = false;
              });
            },
            child: const Text('Batal', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () async {
              final otp = otpController.text.trim();
              if (otp.isEmpty || otp.length != 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Silakan masukkan kode OTP 6 digit'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              Navigator.pop(context);
              otpController.dispose();
              await _verifyOtpAndMarkEmail(newEmail, otp);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1976D2),
            ),
            child: const Text('Verifikasi'),
          ),
        ],
      ),
    );
  }

  Future<void> _verifyOtpAndMarkEmail(String email, String otp) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response =
          await apiService.verifyEmailChangeOtp(_userId!, email, otp);

      if (response['success'] == true) {
        setState(() {
          _emailVerified = true;
          _emailInVerification = email;
          _isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Email berhasil diverifikasi! Sekarang Anda dapat menyimpan perubahan.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        setState(() {
          _isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ??
                  'Verifikasi OTP gagal. Silakan coba lagi.'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      if (_userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User ID tidak ditemukan. Silakan login ulang.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Check if email is changed
      final newEmail = _emailController.text.trim();

      if (newEmail != _currentEmail) {
        // Email changed, need verification
        if (!_emailVerified || _emailInVerification != newEmail) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Silakan verifikasi email terlebih dahulu dengan mengklik tombol Verifikasi Email'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
          return;
        }
      }

      _performUpdate();
    }
  }

  void _showOtpDialog(String newEmail) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Request OTP
      final response =
          await apiService.requestEmailChangeOtp(_userId!, newEmail);

      setState(() {
        _isLoading = false;
      });

      if (response['success'] == true) {
        // Show OTP input dialog
        if (mounted) {
          final otpController = TextEditingController();

          // For demo purposes, show OTP in snackbar (remove in production)
          if (response['debug_otp'] != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Kode OTP (Demo): ${response['debug_otp']}'),
                duration: const Duration(seconds: 10),
              ),
            );
          }

          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              backgroundColor: const Color(0xFF34495E),
              title: const Text(
                'Verifikasi Email',
                style: TextStyle(color: Colors.white),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Kode verifikasi telah dikirim ke $newEmail',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: otpController,
                    style: const TextStyle(color: Colors.white),
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    decoration: InputDecoration(
                      labelText: 'Kode OTP',
                      labelStyle: const TextStyle(color: Colors.white70),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.white30),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Color(0xFF1976D2)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final otp = otpController.text.trim();
                    if (otp.isEmpty) return;

                    Navigator.pop(context); // Close dialog
                    _verifyOtpAndSave(newEmail, otp);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1976D2),
                  ),
                  child: const Text('Verifikasi'),
                ),
              ],
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'Gagal mengirim OTP'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _verifyOtpAndSave(String newEmail, String otp) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response =
          await apiService.verifyEmailChangeOtp(_userId!, newEmail, otp);

      if (response['success'] == true) {
        // Email verified and updated, now update other fields
        _performUpdate();
      } else {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'Verifikasi gagal'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _performUpdate() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final updateData = {
        'fullname': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'username': _usernameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'location': _locationController.text.trim(),
        'division': _divisionController.text.trim(),
      };

      print('=== Update Profile Request ===');
      print('User ID: $_userId');
      print('Update Data: $updateData');

      // Call API to update profile
      dynamic response = await apiService.updateProfile(_userId!, updateData);

      print('=== Primary Update Response ===');
      print('Response: $response');

      // If primary method fails, try field-by-field approach
      if (response['success'] != true && response['success'] != 1) {
        print('Primary method failed, trying field-by-field approach...');
        response =
            await apiService.updateProfileFieldByField(_userId!, updateData);
        print('Field-by-field response: $response');
      }

      setState(() {
        _isLoading = false;
      });

      if (response['success'] == true || response['success'] == 1) {
        print('Update berhasil, menyimpan ke SharedPreferences');

        // Update SharedPreferences with new data
        final currentData = await AuthHelper.getUserData();

        // Prepare updated user data
        final Map<String, dynamic> updatedData = {
          'id': _userId,
          'username': updateData['username'],
          'email': updateData['email'],
          'fullname': updateData['fullname'],
          'role': currentData['role'] ?? 'user',
          'phone': updateData['phone'],
          'location': updateData['location'],
          'division': updateData['division'],
        };

        // Save to SharedPreferences
        await AuthHelper.saveUserData(updatedData);
        print('Data tersimpan di SharedPreferences: $updatedData');

        // Verify each critical field was actually updated in database
        print('\n=== VERIFYING DATABASE UPDATES ===');
        bool allVerified = true;

        final fieldsToVerify = [
          'fullname',
          'email',
          'username',
          'phone',
          'location',
          'division'
        ];
        for (var field in fieldsToVerify) {
          final verifyResult = await apiService.verifyProfileUpdate(
              _userId!, field, updateData[field] ?? '');

          if (verifyResult['matched'] == true) {
            print('✓ $field verified: ${updateData[field]}');
          } else {
            print(
                '✗ $field NOT verified! Expected: ${updateData[field]}, Got: ${verifyResult['actual']}');
            allVerified = false;
          }
        }

        print('=== VERIFICATION COMPLETE ===');
        print('All fields verified: $allVerified\n');

        // Fetch fresh profile from backend to confirm persistence and update cache
        try {
          final profile = await apiService.getProfile(_userId!);
          if (profile != null) {
            print('Fresh profile dari backend: ${profile.toJson()}');
            await AuthHelper.saveUserData(profile.toJson());
          }
        } catch (e) {
          print('Failed to fetch fresh profile: $e');
          // Tetap lanjut karena data sudah disimpan di SharedPreferences
        }

        if (mounted) {
          String message = allVerified
              ? 'Profil berhasil diperbarui dan tersimpan di database!'
              : 'Profil diperbarui, tapi beberapa field mungkin tidak tersimpan di database. Cek log backend.';

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: allVerified ? Colors.green : Colors.orange,
              duration: const Duration(seconds: 3),
            ),
          );

          // Kembali ke halaman profil dan trigger refresh dengan data baru
          Navigator.pop(context, updatedData);
        }
      } else {
        print('Update gagal: ${response['message'] ?? 'Unknown error'}');
        print('Response keys: ${response.keys}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'Gagal memperbarui profil'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('=== Exception saat update ===');
      print('Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = isMobileScreen(context);
    return Scaffold(
      backgroundColor: const Color(0xFF2C3E50),
      body: Column(
        children: [
          // Header
          _buildHeader(context),
          // Content
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(isMobile ? 8 : 24.0),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                        maxWidth: isMobile ? double.infinity : 600),
                    child: _buildContent(),
                  ),
                ),
              ),
            ),
          ),
          // Footer
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      color: const Color(0xFF1976D2),
      child: Row(
        children: [
          const Text(
            'Terminal Nilam',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () {
                Navigator.pop(context);
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1.5,
                  ),
                ),
                child: const Text(
                  'Kembali',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        const Text(
          'Edit Profil',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Perbarui informasi profil Anda',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 32),
        // Form
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF34495E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF1976D2).withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _buildTextField(
                  'Nama Lengkap',
                  _nameController,
                  Icons.person,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Nama tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  'Username',
                  _usernameController,
                  Icons.account_circle,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Username tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                _buildEmailFieldWithVerification(),
                const SizedBox(height: 20),
                _buildTextField(
                  'Nomor Telepon',
                  _phoneController,
                  Icons.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Nomor telepon tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  'Lokasi',
                  _locationController,
                  Icons.location_on,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Lokasi tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  'Divisi',
                  _divisionController,
                  Icons.domain,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Divisi tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading
                            ? null
                            : () {
                                Navigator.pop(context);
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Batal'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveChanges,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1976D2),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : const Text('Simpan Perubahan'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmailFieldWithVerification() {
    final newEmail = _emailController.text.trim();
    final isEmailChanged = newEmail != _currentEmail;
    final isVerified =
        isEmailChanged && _emailVerified && _emailInVerification == newEmail;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Email',
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _emailController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Email tidak boleh kosong';
                  }
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                    return 'Format email tidak valid';
                  }
                  return null;
                },
                onChanged: (value) {
                  // Reset verification when email changes
                  if (value.trim() != _emailInVerification) {
                    setState(() {
                      _emailVerified = false;
                    });
                  }
                },
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.email, color: const Color(0xFF1976D2)),
                  suffixIcon: isEmailChanged
                      ? (isVerified
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : null)
                      : null,
                  filled: true,
                  fillColor: const Color(0xFF2C3E50),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: Color(0xFF1976D2),
                      width: 1.5,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color:
                          isVerified ? Colors.green : const Color(0xFF1976D2),
                      width: 1.5,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color:
                          isVerified ? Colors.green : const Color(0xFF1976D2),
                      width: 2,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: Colors.red,
                      width: 1.5,
                    ),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: Colors.red,
                      width: 2,
                    ),
                  ),
                  errorStyle: const TextStyle(color: Colors.red),
                ),
              ),
            ),
            if (isEmailChanged)
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: SizedBox(
                  width: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleEmailVerification,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isVerified ? Colors.green : const Color(0xFF1976D2),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : (isVerified
                            ? const Icon(Icons.check, size: 20)
                            : const Icon(Icons.security, size: 20)),
                  ),
                ),
              ),
          ],
        ),
        if (isEmailChanged && !isVerified)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Colors.orange,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Klik tombol Verifikasi untuk mengirim kode OTP ke email baru Anda',
                    style: const TextStyle(
                      color: Colors.orange,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (isVerified)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle,
                  size: 16,
                  color: Colors.green,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Email berhasil diverifikasi!',
                    style: const TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    IconData icon, {
    required String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: const Color(0xFF1976D2)),
            filled: true,
            fillColor: const Color(0xFF2C3E50),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: Color(0xFF1976D2),
                width: 1.5,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: Color(0xFF1976D2),
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: Color(0xFF1976D2),
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: Colors.red,
                width: 1.5,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: Colors.red,
                width: 2,
              ),
            ),
            errorStyle: const TextStyle(color: Colors.red),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      color: const Color(0xFF1A252F),
      child: const Center(
        child: Text(
          '© 2024 Terminal Nilam. All rights reserved.',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

// ==================== OTP DIALOG WITH TIMER ====================

class _OtpDialog extends StatefulWidget {
  final String newEmail;
  final String? debugOtp;
  final TextEditingController otpController;
  final Function(String) onVerify;
  final VoidCallback onCancel;
  final VoidCallback onResend;

  const _OtpDialog({
    required this.newEmail,
    this.debugOtp,
    required this.otpController,
    required this.onVerify,
    required this.onCancel,
    required this.onResend,
  });

  @override
  State<_OtpDialog> createState() => _OtpDialogState();
}

class _OtpDialogState extends State<_OtpDialog> {
  int _remainingSeconds = 900; // 15 minutes
  bool _canResend = false;
  bool _isResending = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    setState(() {
      _remainingSeconds = 900; // 15 minutes
      _canResend = false;
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        setState(() {
          _canResend = true;
        });
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _handleResend() async {
    setState(() {
      _isResending = true;
    });

    widget.onResend();

    setState(() {
      _isResending = false;
    });

    _startTimer();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kode OTP baru telah dikirim!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int secs = seconds % 60;
    return '$minutes:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Blue Header
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1976D2), Color(0xFF1565C0)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Icon(
                      Icons.lock_outline,
                      color: Colors.white,
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Verifikasi Email Anda',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Monitoring System',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Description
                    const Text(
                      'Anda telah membuat untuk mengubah email Anda ke alamat email ini. Untuk melanjutkan, silakan gunakan kode OTP berikut.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF333333),
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // OTP Code Box (Dashed Border)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: const Color(0xFF1976D2),
                          width: 2,
                          strokeAlign: BorderSide.strokeAlignOutside,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'KODE OTP ANDA',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF666666),
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            widget.otpController.text.isEmpty
                                ? '_ _ _ _ _ _'
                                : widget.otpController.text.split('').join(' '),
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1976D2),
                              letterSpacing: 8,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // OTP Input Field
                    TextField(
                      controller: widget.otpController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      textAlign: TextAlign.center,
                      onChanged: (value) {
                        setState(() {});
                      },
                      decoration: InputDecoration(
                        labelText: 'Masukkan Kode OTP (6 angka)',
                        labelStyle: const TextStyle(
                          color: Color(0xFF666666),
                          fontSize: 14,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(
                            color: Color(0xFFDDDDDD),
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(
                            color: Color(0xFF1976D2),
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        counterText: '',
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1976D2),
                        letterSpacing: 4,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Yellow Warning Box
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8DC),
                        border: Border.all(
                          color: const Color(0xFFFFD700),
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.info_outline,
                                color: Color(0xFFCC9900),
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Penting:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFCC9900),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            '• Kode ini berlaku selama 15 menit\n'
                            '• Masukkan kode di aplikasi untuk menyelesaikan verifikasi\n'
                            '• Jangan bagikan kode ini kepada siapapun',
                            style: TextStyle(
                              color: Color(0xFFCC9900),
                              fontSize: 12,
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Timer Info
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          if (!_canResend) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.schedule,
                                  size: 16,
                                  color: Color(0xFF666666),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Waktu tersisa: ${_formatTime(_remainingSeconds)}',
                                  style: const TextStyle(
                                    color: Color(0xFF666666),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ] else ...[
                            GestureDetector(
                              onTap: _isResending ? null : _handleResend,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (_isResending)
                                    const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          Color(0xFF1976D2),
                                        ),
                                      ),
                                    )
                                  else
                                    const Icon(
                                      Icons.refresh,
                                      size: 16,
                                      color: Color(0xFF1976D2),
                                    ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _isResending
                                        ? 'Mengirim...'
                                        : 'Kirim Ulang Kode',
                                    style: const TextStyle(
                                      color: Color(0xFF1976D2),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              widget.otpController.dispose();
                              widget.onCancel();
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: const BorderSide(
                                color: Color(0xFFDDDDDD),
                                width: 1,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Batal',
                              style: TextStyle(
                                color: Color(0xFF666666),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              final otp = widget.otpController.text.trim();
                              if (otp.isEmpty || otp.length != 6) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Silakan masukkan kode OTP 6 digit',
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }

                              widget.otpController.dispose();
                              await widget.onVerify(otp);
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              backgroundColor: const Color(0xFF1976D2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Verifikasi',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Debug Info
                    if (widget.debugOtp != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          border: Border.all(
                            color: Colors.orange.withOpacity(0.3),
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.bug_report,
                              color: Colors.orange,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Demo OTP: ${widget.debugOtp}',
                                style: const TextStyle(
                                  color: Colors.orange,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
