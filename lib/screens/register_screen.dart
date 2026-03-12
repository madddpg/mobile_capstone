import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/email_service.dart';
import 'email_verification_screen.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final EmailService _emailService = EmailService();

  bool _loading = false;
  bool _sendingOtp = false;
  bool _emailVerified = false;
  String? _verifiedEmail;
  String? _verificationToken;
  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<bool> _sendOtpAndVerify(String email) async {
    _validateEmail(email);
    if (_emailError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a valid email before sending OTP.'),
        ),
      );
      return false;
    }

    setState(() => _sendingOtp = true);

    try {
      final result = await _emailService.sendOtp(email: email);
      if (!mounted) return false;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.message)));
      await _promptOtpVerification(email);
      return _emailVerified &&
          _verifiedEmail == email &&
          _verificationToken != null;
    } on EmailApiException catch (e) {
      if (!mounted) return false;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
      if (e.statusCode == 412) {
        await _promptOtpVerification(email);
        return _emailVerified &&
            _verifiedEmail == email &&
            _verificationToken != null;
      }
    } catch (e) {
      if (!mounted) return false;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to send OTP. $e')));
    } finally {
      if (mounted) {
        setState(() => _sendingOtp = false);
      }
    }

    return _emailVerified &&
        _verifiedEmail == email &&
        _verificationToken != null;
  }

  Future<void> _handleRegister() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;
    _validateEmail(email);
    _validatePassword(password);
    _validateConfirmPassword(confirmPassword);
    if (_emailError != null ||
        _passwordError != null ||
        _confirmPasswordError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please fix the highlighted errors before registering.',
          ),
        ),
      );
      return;
    }

    if (!_emailVerified ||
        _verifiedEmail != email ||
        _verificationToken == null) {
      final verificationCompleted = await _sendOtpAndVerify(email);
      if (!mounted || !verificationCompleted) {
        return;
      }
    }

    setState(() => _loading = true);

    try {
      await _emailService.register(
        email: email,
        password: password,
        verificationToken: _verificationToken!,
      );
      if (!mounted) return;
      await _emailService.logout();
      if (!mounted) return;
      await Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
    } on EmailApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      debugPrint('Register flow failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Registration failed. ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _promptOtpVerification(String email) async {
    final verificationResult = await showEmailVerificationOtpModal(
      context,
      email: email,
      finalizeForSignedInUser: false,
    );

    if (!mounted || verificationResult == null) {
      return;
    }

    if (verificationResult.success &&
        verificationResult.verificationToken != null) {
      setState(() {
        _emailVerified = true;
        _verifiedEmail = email;
        _verificationToken = verificationResult.verificationToken;
      });
    }
  }

  void _resetEmailVerificationIfNeeded(String email) {
    if (_verifiedEmail == email) {
      return;
    }

    setState(() {
      _emailVerified = false;
      _verifiedEmail = null;
      _verificationToken = null;
    });
  }

  void _handleEmailChanged(String value) {
    final trimmed = value.trim();
    _validateEmail(trimmed);
    _resetEmailVerificationIfNeeded(trimmed);
  }

  void _validateEmail(String value) {
    final trimmed = value.trim();
    const emailPattern = r'^[^@\s]+@[^@\s]+\.[^@\s]+$';
    setState(() {
      if (trimmed.isEmpty) {
        _emailError = 'Email is required';
      } else if (!RegExp(emailPattern).hasMatch(trimmed)) {
        _emailError = 'Enter a valid email address';
      } else {
        _emailError = null;
      }
    });
  }

  void _validatePassword(String value) {
    setState(() {
      if (value.isEmpty) {
        _passwordError = 'Password is required';
      } else if (value.length < 6) {
        _passwordError = 'Password must be at least 6 characters';
      } else {
        _passwordError = null;
      }
    });
  }

  void _validateConfirmPassword(String value) {
    setState(() {
      if (value.isEmpty) {
        _confirmPasswordError = 'Confirm your password';
      } else if (value != _passwordController.text) {
        _confirmPasswordError = 'Passwords do not match';
      } else {
        _confirmPasswordError = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1C2D3F), Color(0xFF2F4A67), Color(0xFF4B73A5)],
            stops: [0, 0.55, 1],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: height - 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 80),
                  Text(
                    'Register',
                    style: GoogleFonts.inter(
                      fontSize: 40,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create an account to start smart planning.',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: const Color(0xFFE5E0D5),
                    ),
                  ),
                  const SizedBox(height: 36),
                  _RegisterField(
                    label: 'First Name',
                    controller: _firstNameController,
                    prefixIcon: Icons.person_outline_rounded,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),
                  _RegisterField(
                    label: 'Last Name',
                    controller: _lastNameController,
                    prefixIcon: Icons.badge_outlined,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),
                  _RegisterField(
                    label: 'Email',
                    controller: _emailController,
                    errorText: _emailError,
                    onChanged: _handleEmailChanged,
                    prefixIcon: Icons.alternate_email_rounded,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                  ),
                  if (_emailVerified &&
                      _verifiedEmail == _emailController.text.trim()) ...[
                    const SizedBox(height: 10),
                    Text(
                      'Email verified. You can finish registration.',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFE8D8BF),
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 10),
                    Text(
                      'Tap Register to receive and verify your OTP in a modal.',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFE8D8BF),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  _RegisterField(
                    label: 'Password',
                    obscureText: true,
                    controller: _passwordController,
                    errorText: _passwordError,
                    onChanged: _validatePassword,
                    prefixIcon: Icons.lock_outline_rounded,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),
                  _RegisterField(
                    label: 'Confirm Password',
                    obscureText: true,
                    controller: _confirmPasswordController,
                    errorText: _confirmPasswordError,
                    onChanged: _validateConfirmPassword,
                    prefixIcon: Icons.verified_user_outlined,
                    textInputAction: TextInputAction.done,
                  ),
                  const SizedBox(height: 40),
                  Center(
                    child: Text(
                      'By registration you have signed to our',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: const Color(0xFFE5E0D5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Center(
                    child: Text(
                      'Terms and Conditions',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Center(
                    child: SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: const Color(0xFF263646),
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x66000000),
                              offset: Offset(0, 10),
                              blurRadius: 18,
                            ),
                          ],
                        ),
                        child: TextButton(
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                          ),
                          onPressed: _loading || _sendingOtp
                              ? null
                              : _handleRegister,
                          child: _loading || _sendingOtp
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : Text(
                                  _emailVerified &&
                                          _verifiedEmail ==
                                              _emailController.text.trim()
                                      ? 'Register'
                                      : 'Verify Email',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RegisterField extends StatelessWidget {
  final String label;
  final bool obscureText;
  final TextEditingController? controller;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final IconData? prefixIcon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;

  const _RegisterField({
    required this.label,
    this.obscureText = false,
    this.controller,
    this.errorText,
    this.onChanged,
    this.prefixIcon,
    this.keyboardType,
    this.textInputAction,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      onChanged: onChanged,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      decoration: InputDecoration(
        hintText: label,
        hintStyle: GoogleFonts.inter(
          color: const Color(0xFF6B5C46),
          fontSize: 13,
        ),
        filled: true,
        fillColor: const Color(0xFFE8D8BF),
        prefixIcon: prefixIcon == null
            ? null
            : Icon(prefixIcon, color: const Color(0xFF32475E), size: 20),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0x00FFFFFF)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF8DB3E0), width: 1.5),
        ),
        errorText: errorText,
        errorStyle: GoogleFonts.inter(color: Colors.white, fontSize: 11),
      ),
      style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF1E242B)),
    );
  }
}
