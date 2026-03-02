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
    final cachedData = await AuthHelper.getUserData();
    setState(() {
      _userId = int.tryParse(cachedData['user_id'] ?? '');
      _nameController.text = cachedData['fullname'] ?? '';
      _usernameController.text = cachedData['username'] ?? '';
      _emailController.text = cachedData['email'] ?? '';
     _phoneController.text = (cachedData['phone'] == null || cachedData['phone'] == '') 
        ? '-' : cachedData['phone']!;
    _divisionController.text = (cachedData['division'] == null || cachedData['division'] == '') 
        ? '-' : cachedData['division']!;
        
    _locationController.text = cachedData['location'] ?? '';
    _currentEmail = cachedData['email'] ?? '';
    _emailVerified = true;
    });

    try {
      final userId = _userId;
      if (userId != null) {
        print('Loading Profile From Database For user_id: $userId');
        final response = await apiService.getUserProfile(userId);

        if (response['success'] == true && response['data'] != null) {
          final profileData = response['data'];
          print('Profile Data Loaded From API: $profileData');

          if (!mounted) return;
          setState(() {
            _nameController.text = profileData['fullname'] ?? '';
            _usernameController.text = profileData['username'] ?? '';
            _emailController.text = profileData['email'] ?? '';
            _phoneController.text = profileData['phone'] ?? '';
            _locationController.text = profileData['location'] ?? '';
            _divisionController.text =
                profileData['division']?.isNotEmpty == true
                    ? profileData['division']!
                    : (profileData['role'] ?? '');
            _currentEmail = profileData['email'] ?? '';
            _emailVerified = true;
          });
          return;
        }
      }
    } catch (e) {
      print('Error Loading Profile From API: $e');
    }
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
          content: Text('Email Not Empty'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(newEmail)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid Email Format'),
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
              Text('The Email Is The Same As Your Current Email. No Verification Required'),
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

        print('OTP Sent Successfully To $newEmail');

        // Show OTP input dialog
        if (mounted) {
          _showOtpInputDialog(newEmail, response['debug_otp']);
        }
      } else {
        setState(() {
          _isLoading = false;
        });

        print('OTP Request Failed: ${response['message']}');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'Failed To Send OTP'),
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
          'Email Verification',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Verification Code Has Been Sent To:',
              style: TextStyle(color: Colors.white70, fontSize: 14),
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
            const Text(
              'Please Enter The OTP Code You Received:',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: otpController,
              style: const TextStyle(color: Colors.white),
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                labelText: 'OTP Code (6 Digits)',
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
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () async {
              final otp = otpController.text.trim();
              if (otp.isEmpty || otp.length != 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please Enter 6 Digit OTP Code'),
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
            child: const Text('Verify'),
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
                  'Email Successfully Verified! You Can Now Save Your Changes'),
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
                  'OTP Verification Failed. Please Try Again'),
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
            content: Text('User ID Not Found. Please Login Again'),
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
                  'Please Verify Your Email First By Clicking The Verify Email Button'),
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
                content: Text('OTP Code (Demo): ${response['debug_otp']}'),
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
                'Email Verification',
                style: TextStyle(color: Colors.white),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Verification Code Has Been Sent To $newEmail',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: otpController,
                    style: const TextStyle(color: Colors.white),
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    decoration: InputDecoration(
                      labelText: 'OTP Code',
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
                  child: const Text('Cancel'),
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
                  child: const Text('Verify'),
                ),
              ],
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'Failed to send OTP'),
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
              content: Text(response['message'] ?? 'Verification Failed'),
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
    // Bersihkan data: jika isinya '-' ubah jadi string kosong sebelum dikirim ke DB
    String finalPhone = _phoneController.text.trim();
    String finalDivision = _divisionController.text.trim();
    
    if (finalPhone == '-') finalPhone = '';
    if (finalDivision == '-') finalDivision = '';

    final updateData = {
      'fullname': _nameController.text.trim(),
      'email': _emailController.text.trim(),
      'username': _usernameController.text.trim(),
      'phone': finalPhone,
      'location': _locationController.text.trim(),
      'division': finalDivision,
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
        print('Primary Method Failed, Trying Field-By-Field Approach...');
        response =
            await apiService.updateProfileFieldByField(_userId!, updateData);
        print('Field-By-Field Response: $response');
      }

      setState(() {
        _isLoading = false;
      });

      if (response['success'] == true || response['success'] == 1) {
        print('Update Successfully, Saving To SharedPreferences');

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
        print('Data Saved To SharedPreferences: $updatedData');

        // Fetch fresh profile from backend to confirm persistence and update cache
        try {
          final profile = await apiService.getProfile(_userId!);
          if (profile != null) {
            print('Fresh Profile From Backend: ${profile.toJson()}');
            await AuthHelper.saveUserData(profile.toJson());
          }
        } catch (e) {
          print('Failed To Fetch Fresh Profile: $e');
          // Tetap lanjut karena data sudah disimpan di SharedPreferences
        }

        if (mounted) {
          const message =
              'Profile Successfully Updated!';

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(message),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );

          // Kembali ke halaman profil dan trigger refresh dengan data baru
          Navigator.pop(context, updatedData);
        }
      } else {
        print('Update Failed: ${response['message'] ?? 'Unknown error'}');
        print('Response keys: ${response.keys}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'Failed To Update Profile'),
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
      child: const Row(
        children: [
          Text(
            'Terminal Nilam',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          Spacer(),
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
          'Edit Profile',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Update Your Profile Information',
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
                  'Full Name',
                  _nameController,
                  Icons.person,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Name Not Empty';
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
                      return 'Username Not Empty';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                _buildEmailFieldWithVerification(),
                const SizedBox(height: 20),
                _buildTextField(
                  'Phone Number',
                  _phoneController,
                  Icons.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Phone Number Not Empty';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  'Location',
                  _locationController,
                  Icons.location_on,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Location Not Empty';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  'Division',
                  _divisionController,
                  Icons.domain,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Division Not Empty';
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
                        child: const Text('Cancel'),
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
                            : const Text('Save Changes'),
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
        const Text(
          'Email',
          style: TextStyle(
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
                    return 'Email Not Empty';
                  }
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                    return 'Invalid Email Format';
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
                  prefixIcon: const Icon(Icons.email, color: Color(0xFF1976D2)),
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
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Colors.orange,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Click The Verify Button To Send An OTP Code To Your New Email Address',
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (isVerified)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  size: 16,
                  color: Colors.green,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Email Successfully Verified!',
                    style: TextStyle(
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
      padding: const EdgeInsets.all(16),
      color: Colors.black.withOpacity(0.8),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '©2026 TPK Nilam Monitoring System',
            style: TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
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
          content: Text('New OTP Code Has Been Sent!'),
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
                child: const Column(
                  children: [
                    Icon(
                      Icons.lock_outline,
                      color: Colors.white,
                      size: 48,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Verify Your Email',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
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
                      'You Have Created A Request To Change Your Email Address To This Email Address. To Continue, Please Use The Following OTP Code',
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
                            'YOUR OTP CODE',
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
                        labelText: 'Enter OTP Code (6 Digits)',
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
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Color(0xFFCC9900),
                                size: 20,
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Important:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFCC9900),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12),
                          Text(
                            '• This Code Is Valid For 15 Minutes\n'
                            '• Enter The Code In The App To Complete Verification\n'
                            '• Do Not Share This Code With Anyone',
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
                                  'Remaining Time: ${_formatTime(_remainingSeconds)}',
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
                                        ? 'Sending...'
                                        : 'Resend Code',
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
                              'Cancel',
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
                                      'Please Enter A 6 Digit OTP Code',
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
                              'Verify',
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
