import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'main.dart';
import 'services/api_service.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';

class ForgotPasswordVerifyPage extends StatefulWidget {
  const ForgotPasswordVerifyPage({super.key});

  @override
  State<ForgotPasswordVerifyPage> createState() =>
      _ForgotPasswordVerifyPageState();
}

class _ForgotPasswordVerifyPageState extends State<ForgotPasswordVerifyPage> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();
  bool _isLoading = false;
  late ApiService apiService;

  String email = '';
  int remainingSeconds = 600; // 10 minutes
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    apiService = ApiService();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Get email from route arguments
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      email = (args['email'] ?? '').toString().trim().toLowerCase();
      remainingSeconds = args['expires_in'] ?? 600;
      _startTimer();
    }
  }

  @override
  void dispose() {
    _otpController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel(); // Pastikan tidak ada timer ganda yang berjalan
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      // PERBAIKAN: Tambahkan cek mounted di sini
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (remainingSeconds > 0) {
        setState(() {
          remainingSeconds--;
        });
      } else {
        timer.cancel();
        // Cek mounted lagi sebelum menampilkan dialog
        if (mounted) {
          _showOtpExpiredDialog();
        }
      }
    });
  }

  void _showOtpExpiredDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('OTP Expired'),
        content:
            const Text('The OTP Code Has Expired. Please Request A New OTP'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Tutup Dialog
              Navigator.pop(context); // Kembali ke halaman sebelumnya
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  void _handleVerifyOtp() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final response = await apiService.verifyResetPasswordOtp(
            email, _otpController.text.trim());

        setState(() {
          _isLoading = false;
        });

        if (response['success'] == true) {
          // OTP verified, navigate to reset password page
          if (mounted) {
            Navigator.pushReplacementNamed(
              context,
              '/reset-password',
              arguments: {
                'email': email,
                'otp': _otpController.text,
              },
            );
          }
        } else {
          // Show error message
          if (mounted) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Invalid OTP'),
                content: Text(
                    response['message'] ?? 'Invalid OTP. Please Try Again.'),
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

  void _handleResendOtp() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await apiService.sendForgotPasswordOtp(email);

      setState(() {
        _isLoading = false;
      });

      if (response['success'] == true) {
        // Reset timer
        _timer?.cancel();
        setState(() {
          remainingSeconds = response['expires_in'] ?? 600;
          _otpController.clear();
        });
        _startTimer();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('New OTP Has Been Sent To Your Email'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Failed'),
              content: Text(response['message'] ?? 'Failed To Send New OTP'),
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

  @override
  Widget build(BuildContext context) {
    final isMobile = isMobileScreen(context);
    final screenSize = MediaQuery.of(context).size;
    final glassWidth = (screenSize.width * 0.9).clamp(320.0, 500.0);
    final glassHeight = (screenSize.height * 0.85).clamp(600.0, 750.0);

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
                'assets/images/logo_nilam.png',
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
            position:
                const LiquidGlassAlignPosition(alignment: Alignment.center),
            distortion: 0.35,
            distortionWidth: 45,
            refractionMode: LiquidGlassRefractionMode.shapeRefraction,
            blur: const LiquidGlassBlur(sigmaX: 15, sigmaY: 15),
            color: Colors.white.withOpacity(0.1),
            shape: const RoundedRectangleShape(
                cornerRadius: 24,
                borderWidth: 1.5,
                borderColor: Colors.white30),
            child: Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24.0, vertical: 40.0),
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
                              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                                  color: Colors.white, size: 24),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Icon(
                            Icons.mark_email_read_rounded,
                            size: 50,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Verification',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                    color: Colors.black38,
                                    blurRadius: 4,
                                    offset: Offset(0, 2)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'The OTP Code Has Been Sent To\n$email',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 15,
                              color: Colors.white70,
                              height: 1.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Timer
                          Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: remainingSeconds < 60
                                    ? Colors.redAccent.withOpacity(0.5)
                                    : Colors.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white24),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.timer_outlined,
                                      color: Colors.white, size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    _formatTime(remainingSeconds),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 40),

                          // OTP Field
                          TextFormField(
                            controller: _otpController,
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                letterSpacing: 8,
                                fontWeight: FontWeight.bold),
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: InputDecoration(
                              hintText: 'Enter OTP',
                              hintStyle: const TextStyle(
                                  color: Colors.white60,
                                  fontSize: 16,
                                  letterSpacing: 0),
                              filled: true,
                              fillColor: Colors.black.withOpacity(0.45),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide.none),
                              focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(
                                      color: Colors.blue, width: 1.5)),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 18),
                              counterText: '',
                            ),
                            validator: (value) {
                              final cleanText = value?.trim() ?? '';
                              if (cleanText.isEmpty) return 'Please Enter OTP';
                              if (cleanText.length != 6) {
                                return 'OTP Must Be Exactly 6 Digits';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 40),

                          // Verify Button
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
                                  color:
                                      const Color(0xFF1976D2).withOpacity(0.5),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleVerifyOtp,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 18),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16)),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Colors.white),
                                    )
                                  : const Text(
                                      'Verify OTP Code',
                                      style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white),
                                    ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Resend Logic
                          TextButton(
                            onPressed: _isLoading || remainingSeconds > 0
                                ? null
                                : _handleResendOtp,
                            child: Text(
                              remainingSeconds > 0
                                  ? 'Resend OTP available in ${_formatTime(remainingSeconds)}'
                                  : 'Resend OTP code',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: remainingSeconds > 0
                                    ? Colors.white54
                                    : Colors.white,
                                fontWeight: remainingSeconds > 0
                                    ? FontWeight.normal
                                    : FontWeight.bold,
                                decoration: remainingSeconds > 0
                                    ? null
                                    : TextDecoration.underline,
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
