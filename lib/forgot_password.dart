import 'package:flutter/material.dart';
import 'main.dart';
import 'services/api_service.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  late ApiService apiService;

  @override
  void initState() {
    super.initState();
    apiService = ApiService();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _handleSendOtp() async {
    if (_formKey.currentState!.validate()) {
      final normalizedEmail = _emailController.text.trim().toLowerCase();

      setState(() {
        _isLoading = true;
      });

      try {
        final response = await apiService.sendForgotPasswordOtp(normalizedEmail);

        setState(() {
          _isLoading = false;
        });

        if (response['success'] == true) {
          if (mounted) {
            final String? devOtp = response['otp'];

            if (devOtp != null) {
              await showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('OTP Generated'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Development Mode - Your OTP:'),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          devOtp,
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 8,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        response['note'] ?? '',
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            }

            Navigator.pushNamed(
              context,
              '/forgot-password-verify',
              arguments: {
                'email': normalizedEmail,
                'expires_in': response['expires_in'] ?? 600,
              },
            );
          }
        } else {
          if (mounted) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Invalid OTP Sending'),
                content: Text(response['message'] ?? 'Failed to send OTP'),
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

  @override
  Widget build(BuildContext context) {
    final isMobile = isMobileScreen(context);
    final screenSize = MediaQuery.of(context).size;
    final topPadding = MediaQuery.of(context).padding.top;
    
    // Adjusted dimensions for mobile
    final glassWidth = isMobile 
        ? (screenSize.width * 0.92).clamp(300.0, 420.0)
        : (screenSize.width * 0.35).clamp(380.0, 420.0);
        
    final glassHeight = isMobile
        ? (screenSize.height * 0.82).clamp(500.0, 600.0)
        : (screenSize.height * 0.86).clamp(520.0, 620.0);

    return Scaffold(
      body: LiquidGlassView(
        backgroundWidget: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/background.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Container(
              color: Colors.black.withValues(alpha: 0.45),
            ),
            
            // Logos in a responsive Row with SafeArea consideration
            Positioned(
              top: topPadding + (isMobile ? 8 : 20),
              left: 0,
              right: 0,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 32),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Logo Danantara
                    Image.asset(
                      'assets/images/logo_danantara.png',
                      width: isMobile ? 110 : 180,
                      height: isMobile ? 40 : 70,
                      fit: BoxFit.contain,
                    ),
                    // Logo Pelindo/Nilam
                    Image.asset(
                      'assets/images/logo_nilam.png',
                      width: isMobile ? 140 : 240,
                      height: isMobile ? 55 : 100,
                      fit: BoxFit.contain,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        children: [
          LiquidGlass(
            width: glassWidth,
            height: glassHeight,
            position:
                const LiquidGlassAlignPosition(alignment: Alignment.center),
            distortion: 0.35,
            distortionWidth: 45,
            refractionMode: LiquidGlassRefractionMode.shapeRefraction,
            blur: const LiquidGlassBlur(sigmaX: 15, sigmaY: 15),
            color: Colors.white.withValues(alpha: 0.1),
            shape: const RoundedRectangleShape(
              cornerRadius: 24,
              borderWidth: 1.5,
              borderColor: Colors.white30,
            ),
            child: Stack(
              children: [
                Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24.0, vertical: 20.0),
                    child: Container(
                      constraints: BoxConstraints(maxWidth: glassWidth),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 40, vertical: 20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(height: 10),
                            Icon(
                              Icons.lock_reset_rounded,
                              size: isMobile ? 50 : 40,
                              color: Colors.white,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Forgot Password',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: isMobile ? 26 : 30,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                shadows: const [
                                  Shadow(
                                    color: Colors.black38,
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Enter your registered email address to receive an OTP for password reset',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: isMobile ? 13 : 14,
                                color: Colors.white70,
                                height: 1.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: isMobile ? 24 : 32),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: 'Email Address',
                                hintStyle:
                                    const TextStyle(color: Colors.white60),
                                prefixIcon: const Icon(
                                  Icons.email_outlined,
                                  color: Colors.white70,
                                ),
                                filled: true,
                                fillColor: Colors.black.withValues(alpha: 0.45),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none,
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(
                                    color: Colors.blue,
                                    width: 1.5,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 18,
                                ),
                              ),
                              validator: (value) {
                                final email = value?.trim() ?? '';
                                if (email.isEmpty) {
                                  return 'Please Enter Your Email';
                                }
                                if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                                    .hasMatch(email)) {
                                  return 'Enter A Valid Email';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 40),
                            SizedBox(
                              width: double.infinity,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF1976D2),
                                      Color(0xFF0D47A1),
                                    ],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF1976D2)
                                          .withValues(alpha: 0.5),
                                      blurRadius: 15,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed:
                                      _isLoading ? null : _handleSendOtp,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 18,
                                    ),
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
                                          'Send OTP Code',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.topLeft,
                  child: SafeArea(
                    child: Padding(
                      padding: EdgeInsets.all(isMobile ? 8 : 16),
                      child: IconButton(
                        icon: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                          size: isMobile ? 22 : 26,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}