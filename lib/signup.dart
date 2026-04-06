import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _passwordFocusNode = FocusNode();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  bool _showPasswordRequirements = false;
  bool _showEmailError = false;

  // Password requirements tracking
  bool _hasMinLength = false;
  bool _hasUppercase = false;
  bool _hasLowercase = false;
  bool _hasNumber = false;

  late ApiService apiService;

  @override
  void initState() {
    super.initState();
    apiService = ApiService();

    _passwordFocusNode.addListener(() {
      setState(() {
        _showPasswordRequirements = _passwordFocusNode.hasFocus;
      });
    });

    _passwordController.addListener(() {
      setState(() {
        final password = _passwordController.text;
        _hasMinLength = password.length >= 8;
        _hasUppercase = RegExp(r'[A-Z]').hasMatch(password);
        _hasLowercase = RegExp(r'[a-z]').hasMatch(password);
        _hasNumber = RegExp(r'[0-9]').hasMatch(password);
      });
    });

    _emailController.addListener(() {
      final email = _emailController.text.trim();
      final hasTypedSomething = email.isNotEmpty;
      final isInvalidFormat =
          !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);

      if (hasTypedSomething && isInvalidFormat) {
        if (!_showEmailError) {
          setState(() {
            _showEmailError = true;
          });
        }
      } else {
        if (_showEmailError) {
          setState(() {
            _showEmailError = false;
          });
        }
      }
    });
  }

  void _showPasswordRequirementsDialog() {
    setState(() {
      _showPasswordRequirements = true;
    });

    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.3),
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.orange.withOpacity(0.5),
                width: 2,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Password Requirements:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () {
                        Navigator.of(context).pop();
                        setState(() {
                          _showPasswordRequirements = false;
                        });
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildPasswordRequirement(
                    'Minimum 8 Characters', _hasMinLength),
                _buildPasswordRequirement(
                    'Contains Uppercase Letter (A-Z)', _hasUppercase),
                _buildPasswordRequirement(
                    'Contains Lowercase Letter (a-z)', _hasLowercase),
                _buildPasswordRequirement('Contains Number (0-9)', _hasNumber),
              ],
            ),
          ),
        );
      },
    ).then((_) {
      setState(() {
        _showPasswordRequirements = false;
      });
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  void _handleSignUp() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final response = await apiService.register(
          _usernameController.text.trim(),
          _emailController.text.trim(),
          _passwordController.text.trim(),
          _nameController.text.trim(),
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
                content: const Text('Account Successfully Created'),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pushReplacementNamed(context, '/login');
                    },
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          }
        } else {
          if (mounted) {
            _showSignUpErrorDialog(response);
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
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      }
    } else {
      _showValidationErrorDialog();
    }
  }

  void _showValidationErrorDialog() {
    List<String> errorFields = [];

    if (_usernameController.text.isEmpty) {
      errorFields.add('Username Must Be Filled');
    }
    if (_nameController.text.isEmpty) {
      errorFields.add('Full Name Must Be Filled');
    }
    if (_emailController.text.isEmpty) {
      errorFields.add('Email Must Be Filled');
    } else if (!_emailController.text.endsWith('@gmail.com')) {
      errorFields.add('Email Must Be In @gmail.com Format');
    }
    if (_passwordController.text.isEmpty) {
      errorFields.add('Password Must Be Filled');
    } else if (_passwordController.text.length < 8) {
      errorFields.add('Password Minimum 8 Characters');
    } else if (!RegExp(r'[A-Z]').hasMatch(_passwordController.text)) {
      errorFields.add('Password Must Contain Uppercase Letter');
    } else if (!RegExp(r'[a-z]').hasMatch(_passwordController.text)) {
      errorFields.add('Password Must Contain Lowercase Letter');
    } else if (!RegExp(r'[0-9]').hasMatch(_passwordController.text)) {
      errorFields.add('Password Must Contain Number');
    }
    if (_confirmPasswordController.text != _passwordController.text) {
      errorFields.add('Confirm Password Does Not Match');
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420, minWidth: 300),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: Colors.red.withOpacity(0.5), width: 2),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.error_outline,
                              color: Colors.red, size: 24),
                          SizedBox(width: 12),
                          Text('Data Not Valid',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red)),
                        ],
                      ),
                      IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () => Navigator.of(context).pop()),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Please Correct The Following Fields:',
                      style: TextStyle(fontSize: 13, color: Colors.black54)),
                  const SizedBox(height: 12),
                  ...errorFields.map((error) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.check_circle,
                                color: Colors.red, size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                                child: Text(error,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        color: Colors.red,
                                        fontWeight: FontWeight.w500))),
                          ],
                        ),
                      )),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Repair Data',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showSignUpErrorDialog(Map<String, dynamic> response) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420, minWidth: 300),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: Colors.red.withOpacity(0.5), width: 2),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.error_outline,
                              color: Colors.red, size: 24),
                          SizedBox(width: 12),
                          Text('Signup Failed',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red)),
                        ],
                      ),
                      IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () => Navigator.of(context).pop()),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                      response['message'] ??
                          'An Error Occurred While Registering',
                      style:
                          const TextStyle(fontSize: 13, color: Colors.black54)),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('OK',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _handleBackToLogin() {
    Navigator.pop(context);
  }

  Widget _buildPasswordRequirement(String text, bool isMet) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(isMet ? Icons.check_circle : Icons.circle,
              size: isMet ? 18 : 8,
              color: isMet ? Colors.green : Colors.black87),
          const SizedBox(width: 8),
          Text(text,
              style: TextStyle(
                  fontSize: 13,
                  color: isMet ? Colors.green : Colors.black87,
                  fontWeight: isMet ? FontWeight.w600 : FontWeight.normal)),
        ],
      ),
    );
  }

  bool get _isPasswordValid {
    return _hasMinLength && _hasUppercase && _hasLowercase && _hasNumber;
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    final screenSize = MediaQuery.of(context).size;
    final glassWidth = (screenSize.width * 0.9).clamp(320.0, 520.0);
    final glassHeight = (screenSize.height * 0.9).clamp(540.0, 740.0);

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
              color: Colors.black.withOpacity(0.4),
            ),
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
            Positioned(
              right: isMobile ? 12 : 24,
              top: isMobile ? 12 : 24,
              child: Image.asset(
                'assets/images/logo_nilam.png',
                width: isMobile ? 180 : 240,
                height: isMobile ? 70 : 100,
                fit: BoxFit.contain,
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
            distortion: 0.25,
            distortionWidth: 40,
            refractionMode: LiquidGlassRefractionMode.shapeRefraction,
            blur: const LiquidGlassBlur(sigmaX: 15, sigmaY: 15),
            color: Colors.white.withOpacity(0.1),
            shape: const RoundedRectangleShape(
              cornerRadius: 24,
              borderWidth: 1.5,
              borderColor: Colors.white30,
            ),
            child: Center(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 8),
                      const Text('Registration',
                          style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1.2)),
                      const SizedBox(height: 8),
                      Text('Enter your details for new account',
                          style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.7))),
                      const SizedBox(height: 32),
                      _buildTextField(
                        controller: _usernameController,
                        hint: 'Username',
                        icon: Icons.person_outline,
                        validator: (value) => (value == null || value.isEmpty)
                            ? 'Please enter your username'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _nameController,
                        hint: 'Full Name',
                        icon: Icons.badge_outlined,
                        validator: (value) => (value == null || value.isEmpty)
                            ? 'Please enter your full name'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _emailController,
                        hint: 'Email Address',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                              .hasMatch(value)) {
                            return 'Invalid email format';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _passwordController,
                        focusNode: _passwordFocusNode,
                        hint: 'Password',
                        icon: Icons.lock_outline,
                        obscureText: _obscurePassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.white70),
                          onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          if (value.length < 8) {
                            return 'Min 8 characters required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _confirmPasswordController,
                        hint: 'Confirm Password',
                        icon: Icons.lock_reset_outlined,
                        obscureText: _obscureConfirmPassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.white70),
                          onPressed: () => setState(() =>
                              _obscureConfirmPassword =
                                  !_obscureConfirmPassword),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Confirm your password';
                          }
                          if (value != _passwordController.text) {
                            return 'Password does not match';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 28),
                      _isLoading
                          ? const CircularProgressIndicator()
                          : SizedBox(
                              width: double.infinity,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF1976D2),
                                      Color(0xFF0D47A1)
                                    ],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF1976D2)
                                          .withOpacity(0.5),
                                      blurRadius: 15,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: _handleSignUp,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 18),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: const Text(
                                    'CREATE ACCOUNT',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                      const SizedBox(height: 20),
                      TextButton(
                        onPressed: _handleBackToLogin,
                        child: RichText(
                          text: const TextSpan(
                            text: 'Already have an account? ',
                            style: TextStyle(color: Colors.white70),
                            children: [
                              TextSpan(
                                  text: 'Sign In',
                                  style: TextStyle(
                                      color: Color.fromARGB(255, 255, 255, 255),
                                      fontWeight: FontWeight.bold)),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    Widget? suffixIcon,
    FocusNode? focusNode,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white60),
        prefixIcon: Icon(icon, color: Colors.white70),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.black.withOpacity(0.45),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.blue, width: 1.5)),
        errorStyle: const TextStyle(color: Color(0xFFFF8A80)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      ),
      validator: validator,
    );
  }
}
