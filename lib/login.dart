import 'dart:ui';
import 'package:flutter/material.dart';
import 'main.dart';
import 'services/api_service.dart';
import 'utils/auth_helper.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  late ApiService apiService;

  @override
  void initState() {
    super.initState();
    apiService = ApiService();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final response = await apiService.login(
          _usernameController.text,
          _passwordController.text,
        );

        setState(() {
          _isLoading = false;
        });

        if (response['success'] == true) {
          // Save minimal user data first
          await AuthHelper.saveUserData(response['data']);

          // Fetch full profile from API (to get phone/location/division) and update cache
          try {
            final userId = (response['data']?['id'] ?? 0) as int;
            if (userId > 0) {
              final profile = await apiService.getProfile(userId);
              if (profile != null) {
                await AuthHelper.saveUserData(profile.toJson());
              }
            }
          } catch (_) {}

          // Navigate to dashboard
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/dashboard');
          }
        } else {
          // Show error message
          if (mounted) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Login Failed'),
                content: Text(response['message'] ?? 'Login failed'),
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
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Error'),
              content: Text('Error: $e'),
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
    }
  }

  void _handleSignUp() {
    // Navigate to sign up page
    Navigator.pushNamed(context, '/signup');
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = isMobileScreen(context);
    return Scaffold(
      body: Stack(
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

          // Overlay Gelap Ringan
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
              'assets/images/logo_nilam.png',
              width: isMobile ? 140 : 180,
              height: isMobile ? 50 : 70,
              fit: BoxFit.contain,
            ),
          ),

          // Formulir Konten Utama
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24), // Sudut tidak terlalu bulat
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15), // Efek Glassmorphism nyata
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 450), // Dipersempit agar elegan
                        padding: const EdgeInsets.all(40),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15), // Transparansi kaca
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 30,
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Ikon Gembok sebagai aksen modern
                              const Icon(
                                Icons.lock_person_rounded,
                                size: 50,
                                color: Colors.white,
                              ),
                              const SizedBox(height: 16),
                              
                              // Judul "Welcome Back"
                              const Text(
                                'Welcome Back',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 1.2,
                                  shadows: [
                                    Shadow(color: Colors.black38, blurRadius: 4, offset: Offset(0, 2)),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Sign in to access your dashboard',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),

                              const SizedBox(height: 48),

                              // Username Field
                              TextFormField(
                                controller: _usernameController,
                                keyboardType: TextInputType.text,
                                style: const TextStyle(color: Colors.white, fontSize: 16),
                                decoration: InputDecoration(
                                  hintText: 'Username',
                                  hintStyle: const TextStyle(color: Colors.white60),
                                  prefixIcon: const Icon(Icons.person_outline, color: Colors.white70),
                                  errorStyle: const TextStyle(color: Color(0xFFFF8A80), fontSize: 13),
                                  filled: true,
                                  fillColor: Colors.black.withOpacity(0.2), // Input semi-transparent
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(color: Colors.blue.shade300, width: 2),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please Enter Your Username';
                                  }
                                  return null;
                                },
                              ),

                              const SizedBox(height: 20),

                              // Password Field
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                style: const TextStyle(color: Colors.white, fontSize: 16),
                                decoration: InputDecoration(
                                  hintText: 'Password',
                                  hintStyle: const TextStyle(color: Colors.white60),
                                  prefixIcon: const Icon(Icons.lock_outline, color: Colors.white70),
                                  errorStyle: const TextStyle(color: Color(0xFFFF8A80), fontSize: 13),
                                  filled: true,
                                  fillColor: Colors.black.withOpacity(0.2),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(color: Colors.blue.shade300, width: 2),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                      color: Colors.white70,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please Enter Your Password';
                                  }
                                  if (value.length < 6) {
                                    return 'Password Must Be At Least 6 Characters';
                                  }
                                  return null;
                                },
                              ),

                              const SizedBox(height: 12),

                              // Forgot Password Link
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: () {
                                    Navigator.pushNamed(context, '/forgot-password');
                                  },
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.white, // Efek ripple / teks modern
                                  ),
                                  child: const Text(
                                    'Forgot Password?',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      decoration: TextDecoration.underline,
                                      decorationColor: Colors.white70,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 32),

                              // Login Button
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
                                  onPressed: _isLoading ? null : _handleLogin,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent, // Uses container gradient
                                    shadowColor: Colors.transparent,
                                    padding: const EdgeInsets.symmetric(vertical: 18),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          height: 24,
                                          width: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Text(
                                          'Sign In',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            letterSpacing: 1,
                                          ),
                                        ),
                                ),
                              ),

                              const SizedBox(height: 32),

                              // Sign Up Section (Text Link instead of giant button)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    "Don't have an account?",
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: Colors.white70,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  InkWell(
                                    onTap: _handleSignUp,
                                    child: const Text(
                                      'Sign Up',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
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
