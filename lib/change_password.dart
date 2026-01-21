import 'package:flutter/material.dart';
import 'main.dart';
import 'services/api_service.dart';
import 'utils/auth_helper.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({Key? key}) : super(key: key);

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
    setState(() {
      _userId = int.tryParse(user['user_id'] ?? '');
    });
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

  void _changePassword() async {
    if (_formKey.currentState!.validate()) {
      // Validasi additional
      if (!_confirmMatch) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password baru dan konfirmasi tidak cocok!'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      final newPwd = _newPasswordController.text;

      if (!_ruleLength) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password harus minimal 8 karakter!'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      if (!(_ruleUpper && _ruleLower && _ruleDigit)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Password harus mengandung huruf besar, huruf kecil, dan angka'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User ID tidak ditemukan. Silakan login ulang.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      try {
        final res = await apiService.changePassword(
          _userId!,
          _currentPasswordController.text,
          _newPasswordController.text,
        );

        setState(() {
          _isLoading = false;
        });

        if (res['success'] == true) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(res['message'] ?? 'Password berhasil diubah!'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.pop(context, true);
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(res['message'] ?? 'Gagal mengubah password'),
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
          'Ubah Password',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Perbarui password Anda dengan yang baru untuk keamanan lebih baik',
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
                _buildPasswordField(
                  'Password Saat Ini',
                  _currentPasswordController,
                  _showCurrentPassword,
                  () {
                    setState(() {
                      _showCurrentPassword = !_showCurrentPassword;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Password saat ini tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                _buildPasswordField(
                  'Password Baru',
                  _newPasswordController,
                  _showNewPassword,
                  () {
                    setState(() {
                      _showNewPassword = !_showNewPassword;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Password baru tidak boleh kosong';
                    }
                    if (value.length < 8) {
                      return 'Password minimal harus 8 karakter';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                _buildPasswordField(
                  'Konfirmasi Password Baru',
                  _confirmPasswordController,
                  _showConfirmPassword,
                  () {
                    setState(() {
                      _showConfirmPassword = !_showConfirmPassword;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Konfirmasi password tidak boleh kosong';
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
                        'Password baru dan konfirmasi harus sama',
                        style: TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                // Password Requirements
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2C3E50).withOpacity(0.5),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.orange.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Persyaratan Password:',
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildRequirement('Minimal 8 karakter', _ruleLength),
                      _buildRequirement(
                          'Mengandung huruf besar (A-Z)', _ruleUpper),
                      _buildRequirement(
                          'Mengandung huruf kecil (a-z)', _ruleLower),
                      _buildRequirement('Mengandung angka (0-9)', _ruleDigit),
                    ],
                  ),
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
                            : const Text('Ubah Password'),
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
