import 'package:flutter/material.dart';
import 'package:monitoring/main.dart';
import 'package:monitoring/utils/ui_utils.dart';
import 'package:monitoring/utils/auth_helper.dart';
import 'package:monitoring/services/api_service.dart';
import 'package:monitoring/widgets/global_header_bar.dart';
import 'package:monitoring/widgets/global_sidebar_nav.dart';
import 'package:monitoring/widgets/global_footer.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _currentPasswordController;
  late TextEditingController _newPasswordController;
  late TextEditingController _confirmPasswordController;

  bool _showCurrentPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;
  bool _isLoading = false;

  bool _ruleLength = false;
  bool _ruleUpper = false;
  bool _ruleLower = false;
  bool _ruleDigit = false;
  bool _confirmMatch = true;

  int? _userId;
  late ApiService apiService;

  @override
  void initState() {
    super.initState();
    apiService = ApiService();
    _currentPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
    _newPasswordController.addListener(_validateNewPassword);
    _confirmPasswordController.addListener(_validateConfirmPassword);
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await AuthHelper.getUserData();
    final userIdStr = user['user_id'] ?? user['id']?.toString() ?? '';
    final parsedId = int.tryParse(userIdStr);

    print('=== Loading User for Change Password ===');
    print('User data: $user');
    print('User ID string: $userIdStr');
    print('Parsed User ID: $parsedId');

    setState(() {
      _userId = parsedId;
    });

    if (_userId == null) {
      print('WARNING: User ID Is Null! Cannot Change Password.');
    }
  }

  @override
  void dispose() {
    _newPasswordController.removeListener(_validateNewPassword);
    _confirmPasswordController.removeListener(_validateConfirmPassword);
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _validateNewPassword() {
    final pwd = _newPasswordController.text;
    setState(() {
      _ruleLength = pwd.length >= 8;
      _ruleUpper = RegExp(r'[A-Z]').hasMatch(pwd);
      _ruleLower = RegExp(r'[a-z]').hasMatch(pwd);
      _ruleDigit = RegExp(r'[0-9]').hasMatch(pwd);
    });
    _validateConfirmPassword();
  }

  void _validateConfirmPassword() {
    setState(() {
      _confirmMatch =
          _confirmPasswordController.text == _newPasswordController.text;
    });
  }

  Future<void> _testConnection() async {
    print('\\n=== User Triggered Connection Test ===');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Testing Connection To Backend...'),
          ],
        ),
      ),
    );

    final result = await apiService.testConnection();

    if (mounted) {
      Navigator.pop(context); // Close loading dialog

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(
                result['success'] ? Icons.check_circle : Icons.error,
                color: result['success'] ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 8),
              Text(result['success']
                  ? 'Connection Successful'
                  : 'Connection Failed'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(result['message'] ?? 'Unknown'),
              if (result['responseTime'] != null)
                Text('\\nTime Respons: ${result['responseTime']}ms'),
              if (!result['success']) ...[
                const SizedBox(height: 16),
                const Text(
                  'Possible Issues:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const Text('• Backend Not Running (Check XAMPP Apache)'),
                const Text('• Firewall Blocking Connection'),
                const Text('• Wrong URL (Localhost vs 127.0.0.1)'),
              ],
            ],
          ),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  void _changePassword() async {
    if (_formKey.currentState!.validate()) {
      // Validasi additional
      if (!_confirmMatch) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            content: const Text('Password Not Match'),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'))
            ],
          ),
        );
        return;
      }

      if (!_ruleLength) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            content: const Text('Minimum 8 Characters'),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'))
            ],
          ),
        );
        return;
      }

      if (!(_ruleUpper && _ruleLower && _ruleDigit)) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            content:
                const Text('Must Contain Uppercase, Lowercase, And Number'),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'))
            ],
          ),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      if (_userId == null) {
        setState(() {
          _isLoading = false;
        });
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            content: const Text('Login Again Required'),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'))
            ],
          ),
        );
        return;
      }

      try {
        print('=== Starting Change Password ===');
        print('User ID: $_userId');
        print(
            'Current Password: ${_currentPasswordController.text.isNotEmpty ? "[PROVIDED]" : "[EMPTY]"}');
        print(
            'New Password: ${_newPasswordController.text.isNotEmpty ? "[PROVIDED]" : "[EMPTY]"}');

        final res = await apiService.changePassword(
          _userId!,
          _currentPasswordController.text,
          _newPasswordController.text,
        );

        print('Change Password Result: $res');

        setState(() {
          _isLoading = false;
        });

        if (res['success'] == true) {
          if (mounted) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Success'),
                  ],
                ),
                content:
                    Text(res['message'] ?? 'Password Successfully Changed'),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                actions: [
                  TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pop(context, true);
                      },
                      child: const Text('OK'))
                ],
              ),
            );
          }
        } else {
          // Show specific error message from backend
          final errorMessage = res['message'] ?? 'Failed to Change Password';
          print('Error Message: $errorMessage');

          if (mounted) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Row(
                  children: [
                    Icon(Icons.error, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Failed'),
                  ],
                ),
                content: Text(errorMessage),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'))
                ],
              ),
            );
          }
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              content: Text('Error: $e'),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('OK'))
              ],
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = isMobileScreen(context);
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Column(
        children: [
          const GlobalHeaderBar(currentRoute: '/change-password'),
          Expanded(
            child: GlobalSidebarNav(
                currentRoute: '/change-password',
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
                )),
          ),
          const GlobalFooter(),
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
          'Change Password',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Update Your password',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _buildPasswordField(
                  'Password Now',
                  _currentPasswordController,
                  _showCurrentPassword,
                  () {
                    setState(() {
                      _showCurrentPassword = !_showCurrentPassword;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Password Now Cannot Be Empty';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                _buildPasswordField(
                  'New Password',
                  _newPasswordController,
                  _showNewPassword,
                  () {
                    setState(() {
                      _showNewPassword = !_showNewPassword;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'New Password Cannot Be Empty';
                    }
                    if (value.length < 8) {
                      return 'New Password Must Be At Least 8 Characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                _buildPasswordField(
                  'Confirm New Password',
                  _confirmPasswordController,
                  _showConfirmPassword,
                  () {
                    setState(() {
                      _showConfirmPassword = !_showConfirmPassword;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Confirm New Password Cannot Be Empty';
                    }
                    return null;
                  },
                ),
                if (!_confirmMatch)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'New Password and Confirm New Password Must Be Same',
                        style: TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                // Password Requirements
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.orange.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Password Requirements:',
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildRequirement('Minimum 8 Characters', _ruleLength),
                      _buildRequirement(
                          'Contains Uppercase Letters (A-Z)', _ruleUpper),
                      _buildRequirement(
                          'Contains Lowercase Letters (a-z)', _ruleLower),
                      _buildRequirement('Contains Numbers (0-9)', _ruleDigit),
                    ],
                  ),
                ),

                const SizedBox(height: 24), // Action Buttons
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
                        onPressed: _isLoading ? null : _changePassword,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF27AE60),
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
                            : const Text('Change Password'),
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

  Widget _buildPasswordField(
    String label,
    TextEditingController controller,
    bool showPassword,
    VoidCallback onVisibilityToggle, {
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
          obscureText: !showPassword,
          validator: validator,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.lock, color: Color(0xFF1976D2)),
            suffixIcon: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: onVisibilityToggle,
                child: Icon(
                  showPassword ? Icons.visibility : Icons.visibility_off,
                  color: const Color(0xFF1976D2),
                ),
              ),
            ),
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

  Widget _buildRequirement(String requirement, bool passed) {
    final color = passed ? Colors.green : Colors.white70;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            passed ? Icons.check_circle : Icons.radio_button_unchecked,
            color: color,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            requirement,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: passed ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
