import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconstruct/features/auth/data/email_service.dart';
import 'package:iconstruct/features/auth/presentation/screens/email_verification_screen.dart';
import 'package:iconstruct/features/auth/presentation/screens/login_screen.dart';

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
  final ScrollController _scrollController = ScrollController();

  final EmailService _emailService = EmailService();

  bool _loading = false;
  bool _sendingOtp = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
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
    _scrollController.dispose();
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
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF24384C), Color(0xFF35516F), Color(0xFF7FA4CC)],
            stops: [0, 0.62, 1],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back button
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF1E7D6),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 18,
                    ),
                    color: const Color(0xFF32465C),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ),
                const SizedBox(height: 48),
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    padding: const EdgeInsets.only(bottom: 48),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Register',
                          style: GoogleFonts.poppins(
                            fontSize: 30,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Create an account to start smart planning.',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: const Color(0xFFB0C4D8),
                          ),
                        ),
                        const SizedBox(height: 22),
                        _RegisterField(
                          label: 'First Name',
                          controller: _firstNameController,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 12),
                        _RegisterField(
                          label: 'Last Name',
                          controller: _lastNameController,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 12),
                        _RegisterField(
                          label: 'Email',
                          controller: _emailController,
                          errorText: _emailError,
                          onChanged: _handleEmailChanged,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                        ),
                        if (_emailVerified &&
                            _verifiedEmail == _emailController.text.trim()) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Email verified. You can finish registration.',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFF7E4C6),
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        _RegisterField(
                          label: 'Password',
                          obscureText: _obscurePassword,
                          controller: _passwordController,
                          errorText: _passwordError,
                          onChanged: _validatePassword,
                          textInputAction: TextInputAction.next,
                          trailing: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_rounded
                                  : Icons.visibility_rounded,
                              color: const Color(0xFF42566C),
                              size: 20,
                            ),
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _RegisterField(
                          label: 'Confirm Password',
                          obscureText: _obscureConfirmPassword,
                          controller: _confirmPasswordController,
                          errorText: _confirmPasswordError,
                          onChanged: _validateConfirmPassword,
                          textInputAction: TextInputAction.done,
                          trailing: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility_off_rounded
                                  : Icons.visibility_rounded,
                              color: const Color(0xFF42566C),
                              size: 20,
                            ),
                            onPressed: () => setState(
                              () => _obscureConfirmPassword =
                                  !_obscureConfirmPassword,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Center(
                          child: RichText(
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: const Color(0xFFB0C4D8),
                              ),
                              children: [
                                const TextSpan(
                                  text:
                                      'By registration you have signed to our\n',
                                ),
                                TextSpan(
                                  text: 'Terms and Conditions',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    decoration: TextDecoration.underline,
                                    decorationColor: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: TextButton(
                            style: TextButton.styleFrom(
                              backgroundColor: const Color(0xFF1E3248),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
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
                                    'Register',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
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
    );
  }
}

class _RegisterField extends StatelessWidget {
  final String label;
  final bool obscureText;
  final Widget? trailing;
  final TextEditingController? controller;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;

  const _RegisterField({
    required this.label,
    this.obscureText = false,
    this.trailing,
    this.controller,
    this.errorText,
    this.onChanged,
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
      style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF1E242B)),
      decoration: InputDecoration(
        hintText: label,
        hintStyle: GoogleFonts.poppins(
          color: const Color(0xFF6F665A),
          fontSize: 13.5,
          fontWeight: FontWeight.w500,
        ),
        filled: true,
        fillColor: const Color(0xFFE9DECC),
        suffixIcon: trailing,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0x00FFFFFF)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF8DB3E0), width: 1.5),
        ),
        errorText: errorText,
        errorStyle: GoogleFonts.inter(
          color: const Color(0xFFFFD5D8),
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
