import 'dart:ui';
import 'package:flutter/material.dart';
import 'main.dart';
import 'services/api_service.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';

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
    final screenSize = MediaQuery.of(context).size;
    final glassWidth = (screenSize.width * 0.9).clamp(320.0, 500.0);
    final glassHeight = (screenSize.height * 0.9).clamp(650.0, 750.0);

    return Scaffold(
      body: LiquidGlassView(
        backgroundWidget: Stack(
          children: [
            // Background Image
            Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/background.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),

            // Dark Overlay
            Container(
              color: Colors.black.withOpacity(0.4),
            ),

            // Logo Danantara Indonesia - Kiri Atas
            Positioned(
              left: isMobile ? 10 : 20,
              top: isMobile ? 10 : 20,
              child: Image.asset(
                'assets/images/logo_danantara.png',
                width: isMobile ? 140 : 180,
                height: isMobile ? 50 : 70,
                fit: BoxFit.contain,
              ),
            ),

            // Logo Pelindo - Kanan Atas
            Positioned(
              right: 20,
              top: 20,
              child: Image.asset(
                'assets/images/logo_pelindo.png',
                width: isMobile ? 140 : 180,
                height: isMobile ? 50 : 70,
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
        // Content
        children: [
          LiquidGlass(
            width: glassWidth,
            height: glassHeight,
            position: const LiquidGlassAlignPosition(alignment: Alignment.center),
            distortion: 0.35,
            distortionWidth: 45,
            refractionMode: LiquidGlassRefractionMode.shapeRefraction,
            blur: const LiquidGlassBlur(sigmaX: 15, sigmaY: 15),
            color: Colors.white.withOpacity(0.1),
            shape: const RoundedRectangleShape(cornerRadius: 24, borderWidth: 1.5, borderColor: Colors.white30),
            child: Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: glassWidth,
                    ),
                    padding: const EdgeInsets.all(40),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Form(
                      key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Back Button & Icon
                             Align(
                              alignment: Alignment.centerLeft,
                              child: IconButton(
                                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 24),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Icon(
                              Icons.vpn_key_rounded,
                              size: 50,
                              color: Colors.white,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Reset Password',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                shadows: [
                                  Shadow(color: Colors.black38, blurRadius: 4, offset: Offset(0, 2)),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Create a strong new password to secure your account',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                                fontWeight: FontWeight.w500,
                              ),
                            ),

                            const SizedBox(height: 40),

                            // New Password Field with local Stack for Requirements
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                TextFormField(
                                  controller: _newPasswordController,
                                  focusNode: _passwordFocusNode,
                                  obscureText: _obscureNewPassword,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    hintText: 'New Password',
                                    hintStyle: const TextStyle(color: Colors.white60),
                                    prefixIcon: const Icon(Icons.lock_outline, color: Colors.white70),
                                    filled: true,
                                    fillColor: Colors.black.withOpacity(0.45),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.blue, width: 1.5)),
                                    suffixIcon: IconButton(
                                      icon: Icon(_obscureNewPassword ? Icons.visibility_off : Icons.visibility, color: Colors.white70),
                                      onPressed: () => setState(() => _obscureNewPassword = !_obscureNewPassword),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) return 'Please Enter New Password';
                                    if (!_hasMinLength || !_hasUppercase || !_hasLowercase || !_hasNumber) return 'Requirements Not Met';
                                    return null;
                                  },
                                ),
                                
                                // Floating Requirements Hint
                                if (_showPasswordRequirements)
                                  Positioned(
                                    bottom: 70, 
                                    left: 0, 
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 15, offset: Offset(0, 5))],
                                        border: Border.all(color: Colors.blue.withOpacity(0.5), width: 1.5),
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('Password Requirements:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 13)),
                                          const SizedBox(height: 8),
                                          _buildPasswordRequirement('8 Characters', _hasMinLength),
                                          _buildPasswordRequirement('Uppercase Letter', _hasUppercase),
                                          _buildPasswordRequirement('Lowercase Letter', _hasLowercase),
                                          _buildPasswordRequirement('Number', _hasNumber),
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
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: 'Confirm New Password',
                                hintStyle: const TextStyle(color: Colors.white60),
                                prefixIcon: const Icon(Icons.lock_reset_outlined, color: Colors.white70),
                                filled: true,
                                fillColor: Colors.black.withOpacity(0.45),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.blue, width: 1.5)),
                                suffixIcon: IconButton(
                                  icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility, color: Colors.white70),
                                  onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) return 'Confirm Your Password';
                                if (value != _newPasswordController.text) return 'Password Does Not Match';
                                return null;
                              },
                            ),

                            const SizedBox(height: 40),

                            // Reset Button
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF1976D2), Color(0xFF0D47A1)],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF1976D2).withOpacity(0.5),
                                    blurRadius: 15,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _handleResetPassword,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  padding: const EdgeInsets.symmetric(vertical: 18),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 24, width: 24,
                                        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                                      )
                                    : const Text(
                                        'Reset Password',
                                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
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