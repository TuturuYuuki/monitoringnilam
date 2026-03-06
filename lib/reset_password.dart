import 'package:flutter/material.dart';
import 'main.dart';
import 'services/api_service.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _passwordFocusNode = FocusNode(); // TAMBAHAN: Untuk deteksi fokus
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  bool _showPasswordRequirements = false; // TAMBAHAN: Kontrol overlay

  // TAMBAHAN: Variabel pengecekan password
  bool _hasMinLength = false;
  bool _hasUppercase = false;
  bool _hasLowercase = false;
  bool _hasNumber = false;

  late ApiService apiService;

  String email = '';
  String otp = '';

  @override
  void initState() {
    super.initState();
    apiService = ApiService();

    // TAMBAHAN: Listener untuk memunculkan overlay saat fokus
    _passwordFocusNode.addListener(() {
      setState(() {
        _showPasswordRequirements = _passwordFocusNode.hasFocus;
      });
    });

    // TAMBAHAN: Listener untuk validasi password secara real-time
    _newPasswordController.addListener(() {
      setState(() {
        final password = _newPasswordController.text;
        _hasMinLength = password.length >= 8;
        _hasUppercase = RegExp(r'[A-Z]').hasMatch(password);
        _hasLowercase = RegExp(r'[a-z]').hasMatch(password);
        _hasNumber = RegExp(r'[0-9]').hasMatch(password);
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      email = args['email'] ?? '';
      otp = args['otp'] ?? '';
    }
  }

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _passwordFocusNode.dispose(); // TAMBAHAN
    super.dispose();
  }

  // TAMBAHAN: Widget pembangun baris requirement
  Widget _buildPasswordRequirement(String text, bool isMet) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle : Icons.circle,
            size: isMet ? 18 : 8,
            color: isMet ? Colors.green : Colors.black87,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: isMet ? Colors.green : Colors.black87,
              fontWeight: isMet ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  void _handleResetPassword() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final response = await apiService.resetPassword(
          email,
          otp,
          _newPasswordController.text,
        );

        setState(() {
          _isLoading = false;
        });

        if (response['success'] == true) {
          if (mounted) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => AlertDialog(
                title: const Text('Success'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 64),
                    const SizedBox(height: 16),
                    Text(response['message'] ?? 'Password Successfully Changed', textAlign: TextAlign.center),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false),
                    child: const Text('Login Now'),
                  ),
                ],
              ),
            );
          }
        } else {
          _showError(response['message'] ?? 'Failed to Change Password');
        }
      } catch (e) {
        setState(() => _isLoading = false);
        _showError('Error: $e');
      }
    }
  }

  void _showError(String message) {
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Failed'),
          content: Text(message),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = isMobileScreen(context);
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(image: AssetImage('assets/images/background.png'), fit: BoxFit.cover),
            ),
          ),
          Container(color: Colors.black.withOpacity(0.3)),
          // ... Logo Section Tetap Sama ...
          Positioned(
            left: isMobile ? 10 : 20, top: isMobile ? 10 : 20,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.5), borderRadius: BorderRadius.circular(12)),
              child: Image.asset('assets/images/logo_danantara.png', width: 180, height: 70, fit: BoxFit.contain),
            ),
          ),
          Positioned(
            right: 20, top: 20,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.5), borderRadius: BorderRadius.circular(12)),
              child: Image.asset('assets/images/logo_pelindo.png', width: 180, height: 70, fit: BoxFit.contain),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        constraints: const BoxConstraints(maxWidth: 700),
                        padding: const EdgeInsets.all(40),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(50),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10))],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                decoration: BoxDecoration(color: const Color(0xFF1976D2), borderRadius: BorderRadius.circular(50)),
                                child: const Text('Reset Password', textAlign: TextAlign.center, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                              ),
                              const SizedBox(height: 40),
                              
                              // New Password Field with Stack for Requirements
                              Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  TextFormField(
                                    controller: _newPasswordController,
                                    focusNode: _passwordFocusNode, // TAMBAHAN
                                    obscureText: _obscureNewPassword,
                                    decoration: InputDecoration(
                                      hintText: 'New Password',
                                      filled: true,
                                      fillColor: Colors.grey[100],
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(50), borderSide: BorderSide.none),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                                      prefixIcon: const Icon(Icons.lock),
                                      suffixIcon: IconButton(
                                        icon: Icon(_obscureNewPassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                                        onPressed: () => setState(() => _obscureNewPassword = !_obscureNewPassword),
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) return 'Please Enter New Password';
                                      if (!_hasMinLength || !_hasUppercase || !_hasLowercase || !_hasNumber) return 'Password Must Meet Requirements';
                                      return null;
                                    },
                                  ),
                                  
                                  // TAMBAHAN: Requirements Overlay
                                  if (_showPasswordRequirements)
                                    Positioned(
                                      top: -160, left: 0, right: 0,
                                      child: Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: Colors.orange.withOpacity(0.5), width: 2),
                                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 10, offset: const Offset(0, 4))],
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Text('Password Requirements:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.orange)),
                                            const SizedBox(height: 8),
                                            _buildPasswordRequirement('Minimum 8 Characters', _hasMinLength),
                                            _buildPasswordRequirement('Contains Uppercase (A-Z)', _hasUppercase),
                                            _buildPasswordRequirement('Contains Lowercase (a-z)', _hasLowercase),
                                            _buildPasswordRequirement('Contains Number (0-9)', _hasNumber),
                                          ],
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 20),

                              // Confirm Password Field
                              TextFormField(
                                controller: _confirmPasswordController,
                                obscureText: _obscureConfirmPassword,
                                decoration: InputDecoration(
                                  hintText: 'Confirm New Password',
                                  filled: true,
                                  fillColor: Colors.grey[100],
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(50), borderSide: BorderSide.none),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  suffixIcon: IconButton(
                                    icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                                    onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) return 'Please Confirm Your Password';
                                  if (value != _newPasswordController.text) return 'Password Do Not Match';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 40),
                              
                              // Reset Button
                              SizedBox(
                                width: double.infinity,
                                height: 55,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _handleResetPassword,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF1976D2),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                                    elevation: 5,
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                      : const Text('Reset Password', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}