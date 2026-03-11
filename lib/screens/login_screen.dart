import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/email_service.dart';
import 'email_verification_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final EmailService _emailService = EmailService();

  bool _obscurePassword = true;
  bool _loading = false;
  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
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

  Future<void> _handleLogin() async {
    final email = _emailController.text;
    final password = _passwordController.text;

    _validateEmail(email);
    _validatePassword(password);
    if (_emailError != null || _passwordError != null) {
      return;
    }

    setState(() => _loading = true);

    try {
      final credential = await _emailService.login(
        email: email,
        password: password,
      );
      await credential.user?.reload();
      final verified = credential.user?.emailVerified ?? false;
      if (!verified) {
        await _emailService.sendCurrentUserOtp();
        if (!mounted) return;
        final otpVerified = await showEmailVerificationOtpModal(
          context,
          email: email.trim(),
        );
        if (!mounted) return;
        if (otpVerified == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Logged in successfully.')),
          );
          return;
        }

        await _emailService.logout();
        return;
      }

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Logged in successfully.')));
    } on EmailApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login failed. Please try again.')),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
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
              constraints: BoxConstraints(minHeight: height - 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back button
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEFE3CF),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.arrow_back, size: 20),
                      color: const Color(0xFF1E2833),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Login',
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Welcome back—let's build smarter.",
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFFE5E0D5),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: 40),
                        _LoginField(
                          label: 'Email',
                          controller: _emailController,
                          errorText: _emailError,
                          onChanged: _validateEmail,
                          prefixIcon: Icons.alternate_email_rounded,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 16),
                        _LoginField(
                          label: 'Password',
                          obscureText: _obscurePassword,
                          controller: _passwordController,
                          errorText: _passwordError,
                          onChanged: _validatePassword,
                          prefixIcon: Icons.lock_outline_rounded,
                          textInputAction: TextInputAction.done,
                          trailing: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_rounded
                                  : Icons.visibility_rounded,
                              color: const Color(0xFF1E2833),
                            ),
                            onPressed: () {
                              setState(
                                () => _obscurePassword = !_obscurePassword,
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              // TODO: Forgot password flow.
                            },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              'Forgot Password?',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFFE5E0D5),
                                fontWeight: FontWeight.w700,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
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
                                onPressed: _loading ? null : _handleLogin,
                                child: _loading
                                    ? const SizedBox(
                                        height: 18,
                                        width: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text(
                                        'Login',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginField extends StatelessWidget {
  final String label;
  final bool obscureText;
  final Widget? trailing;
  final TextEditingController? controller;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final IconData? prefixIcon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;

  const _LoginField({
    required this.label,
    this.obscureText = false,
    this.trailing,
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
      style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF1E242B)),
      decoration: InputDecoration(
        hintText: label,
        hintStyle: GoogleFonts.inter(
          color: const Color(0xFF6B5C46),
          fontSize: 13,
        ),
        errorText: errorText,
        errorStyle: GoogleFonts.inter(color: Colors.white, fontSize: 11),
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
        suffixIcon: trailing,
      ),
    );
  }
}
