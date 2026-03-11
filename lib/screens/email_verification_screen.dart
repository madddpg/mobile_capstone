import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/email_service.dart';
import 'login_screen.dart';

Future<bool?> showEmailVerificationOtpModal(
  BuildContext context, {
  required String email,
  Future<void> Function()? onVerified,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: _EmailVerificationPanel(
        email: email,
        modalMode: true,
        onVerified: () async {
          Navigator.of(dialogContext).pop(true);
          if (onVerified != null) {
            await onVerified();
          }
        },
      ),
    ),
  );
}

class EmailVerificationScreen extends StatefulWidget {
  final String email;

  const EmailVerificationScreen({super.key, required this.email});

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
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
              constraints: BoxConstraints(minHeight: height - 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8D8BF),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                      color: const Color(0xFF1E2833),
                    ),
                  ),
                  const SizedBox(height: 42),
                  Text(
                    'Verify Email',
                    style: GoogleFonts.inter(
                      fontSize: 38,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'We sent a verification message to your email. Confirm your account to continue.',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      height: 1.5,
                      color: const Color(0xFFE5E0D5),
                    ),
                  ),
                  const SizedBox(height: 28),
                  _VerificationEmailCard(email: widget.email),
                  const SizedBox(height: 24),
                  _EmailVerificationPanel(email: widget.email),
                  const SizedBox(height: 22),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8D8BF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.mark_email_read_outlined,
                            color: Color(0xFF243749),
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Tip: enter the latest 6-digit OTP from your inbox. If it expires, resend a fresh code.',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              height: 1.5,
                              color: const Color(0xFFE5E0D5),
                            ),
                          ),
                        ),
                      ],
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

class _EmailVerificationPanel extends StatefulWidget {
  final String email;
  final bool modalMode;
  final Future<void> Function()? onVerified;

  const _EmailVerificationPanel({
    required this.email,
    this.modalMode = false,
    this.onVerified,
  });

  @override
  State<_EmailVerificationPanel> createState() =>
      _EmailVerificationPanelState();
}

class _EmailVerificationPanelState extends State<_EmailVerificationPanel> {
  final EmailService _emailService = EmailService();
  late final List<TextEditingController> _otpControllers;
  late final List<FocusNode> _otpFocusNodes;

  bool _checkingVerification = false;
  bool _resendingEmail = false;

  @override
  void initState() {
    super.initState();
    _otpControllers = List.generate(6, (_) => TextEditingController());
    _otpFocusNodes = List.generate(6, (_) => FocusNode());
  }

  @override
  void dispose() {
    for (final controller in _otpControllers) {
      controller.dispose();
    }
    for (final focusNode in _otpFocusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  String get _enteredOtp =>
      _otpControllers.map((controller) => controller.text).join();

  void _onOtpChanged(int index, String value) {
    final sanitized = value.replaceAll(RegExp(r'\D'), '');
    if (sanitized != value) {
      _otpControllers[index].text = sanitized;
      _otpControllers[index].selection = TextSelection.collapsed(
        offset: sanitized.length,
      );
    }

    if (sanitized.isNotEmpty && index < _otpFocusNodes.length - 1) {
      _otpFocusNodes[index + 1].requestFocus();
    }

    if (sanitized.isEmpty && index > 0) {
      _otpFocusNodes[index - 1].requestFocus();
    }
  }

  Future<void> _resendVerificationEmail() async {
    FocusScope.of(context).unfocus();
    setState(() => _resendingEmail = true);

    try {
      final result = await _emailService.sendOtp(email: widget.email);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.message)));
    } on EmailApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to resend the verification email.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _resendingEmail = false);
      }
    }
  }

  Future<void> _checkVerification() async {
    FocusScope.of(context).unfocus();
    if (!RegExp(r'^\d{6}$').hasMatch(_enteredOtp)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter the 6-digit OTP code first.')),
      );
      return;
    }
    setState(() => _checkingVerification = true);

    try {
      final result = await _emailService.verifyOtp(
        email: widget.email,
        otp: _enteredOtp,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.message)));

      if (widget.onVerified != null) {
        await widget.onVerified!.call();
        return;
      }

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
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
          content: Text('Could not confirm your verification status.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _checkingVerification = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final panel = Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 20),
      decoration: BoxDecoration(
        color: const Color(0xFFF1E6D4),
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 24,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.modalMode) ...[
            Align(
              alignment: Alignment.centerRight,
              child: InkWell(
                onTap: _checkingVerification || _resendingEmail
                    ? null
                    : () => Navigator.of(context).pop(false),
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE3D4BF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    color: Color(0xFF243749),
                    size: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          Text(
            'OTP Verification',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF243749),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.modalMode
                ? 'Enter the 6-digit code from your email, then submit to confirm.'
                : 'Enter the 6-digit code we emailed to you to verify this account.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 11,
              height: 1.45,
              color: const Color(0xFF556273),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(
              _otpControllers.length,
              (index) => _OtpDigitField(
                controller: _otpControllers[index],
                focusNode: _otpFocusNodes[index],
                onChanged: (value) => _onOtpChanged(index, value),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 4,
            children: [
              Text(
                'Did not receive the email?',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: const Color(0xFF556273),
                ),
              ),
              TextButton(
                onPressed: _resendingEmail ? null : _resendVerificationEmail,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: _resendingEmail
                    ? SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF243749),
                          ),
                        ),
                      )
                    : Text(
                        'Resend',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF243749),
                        ),
                      ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFF263646),
                borderRadius: BorderRadius.circular(18),
              ),
              child: TextButton(
                onPressed: _checkingVerification ? null : _checkVerification,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: _checkingVerification
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : Text(
                        'Submit',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );

    if (!widget.modalMode) {
      return panel;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: panel,
      ),
    );
  }
}

class _VerificationEmailCard extends StatelessWidget {
  final String email;

  const _VerificationEmailCard({required this.email});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFE8D8BF),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x35000000),
            blurRadius: 20,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFF263646),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.alternate_email_rounded,
              color: Color(0xFFF1E6D4),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Verification Email',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF556273),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  email,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E2833),
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

class _OtpDigitField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;

  const _OtpDigitField({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 42,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        onChanged: onChanged,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        maxLength: 1,
        style: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF1E2833),
        ),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFD9CCB7)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF4B73A5), width: 1.4),
          ),
        ),
      ),
    );
  }
}
