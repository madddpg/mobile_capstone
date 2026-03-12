import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/email_service.dart';
import 'login_screen.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;
  final String verificationToken;

  const ResetPasswordScreen({
    super.key,
    required this.email,
    required this.verificationToken,
  });

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final EmailService _emailService = EmailService();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _loading = false;
  String? _passwordError;
  String? _confirmError;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
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

  void _validateConfirm(String value) {
    setState(() {
      if (value.isEmpty) {
        _confirmError = 'Please confirm your password';
      } else if (value != _passwordController.text) {
        _confirmError = 'Passwords do not match';
      } else {
        _confirmError = null;
      }
    });
  }

  Future<void> _handleReset() async {
    final password = _passwordController.text;
    final confirm = _confirmController.text;
    _validatePassword(password);
    _validateConfirm(confirm);
    if (_passwordError != null || _confirmError != null) return;

    setState(() => _loading = true);
    try {
      await _emailService.resetPassword(
        email: widget.email,
        verificationToken: widget.verificationToken,
        newPassword: password,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset successfully. Please log in.'),
        ),
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => route.isFirst,
      );
    } on EmailApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to reset password. Please try again.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF22384C), Color(0xFF334F6E), Color(0xFF78A0CA)],
            stops: [0, 0.58, 1],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Reset Password',
                            style: GoogleFonts.poppins(
                              fontSize: 34,
                              height: 1.1,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFFF1E7D6),
                              shadows: const [
                                Shadow(
                                  color: Color(0x5C000000),
                                  offset: Offset(0, 5),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Create a new password securely.',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              fontStyle: FontStyle.italic,
                              color: const Color(0xFFEADFD0),
                            ),
                          ),
                          const SizedBox(height: 36),
                          _ResetField(
                            label: 'Enter new password',
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            errorText: _passwordError,
                            onChanged: _validatePassword,
                            textInputAction: TextInputAction.next,
                            trailing: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_rounded
                                    : Icons.visibility_rounded,
                                color: const Color(0xFF42566C),
                                size: 22,
                              ),
                              onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _ResetField(
                            label: 'Confirm new password',
                            controller: _confirmController,
                            obscureText: _obscureConfirm,
                            errorText: _confirmError,
                            onChanged: _validateConfirm,
                            textInputAction: TextInputAction.done,
                            trailing: IconButton(
                              icon: Icon(
                                _obscureConfirm
                                    ? Icons.visibility_off_rounded
                                    : Icons.visibility_rounded,
                                color: const Color(0xFF42566C),
                                size: 22,
                              ),
                              onPressed: () => setState(
                                () => _obscureConfirm = !_obscureConfirm,
                              ),
                            ),
                          ),
                          const SizedBox(height: 44),
                          Center(
                            child: SizedBox(
                              width: 164,
                              height: 48,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF26394D),
                                  borderRadius: BorderRadius.circular(15),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x4F000000),
                                      offset: Offset(0, 10),
                                      blurRadius: 18,
                                    ),
                                  ],
                                ),
                                child: TextButton(
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                  ),
                                  onPressed: _loading ? null : _handleReset,
                                  child: _loading
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
                                          'Confirm',
                                          style: GoogleFonts.poppins(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                          ),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ResetField extends StatelessWidget {
  final String label;
  final bool obscureText;
  final Widget? trailing;
  final TextEditingController? controller;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final TextInputAction? textInputAction;

  const _ResetField({
    required this.label,
    this.obscureText = false,
    this.trailing,
    this.controller,
    this.errorText,
    this.onChanged,
    this.textInputAction,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      onChanged: onChanged,
      textInputAction: textInputAction,
      style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF1E242B)),
      decoration: InputDecoration(
        hintText: label,
        hintStyle: GoogleFonts.poppins(
          color: const Color(0xFF6F665A),
          fontSize: 13.5,
          fontWeight: FontWeight.w500,
        ),
        errorText: errorText,
        errorStyle: GoogleFonts.poppins(color: Colors.white, fontSize: 11),
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
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF648DB6), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
      ),
    );
  }
}
