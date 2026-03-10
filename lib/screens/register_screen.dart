import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
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
                  const _RegisterField(label: 'First Name'),
                  const SizedBox(height: 16),
                  const _RegisterField(label: 'Last Name'),
                  const SizedBox(height: 16),
                  const _RegisterField(label: 'Email'),
                  const SizedBox(height: 16),
                  const _RegisterField(label: 'Password', obscureText: true),
                  const SizedBox(height: 16),
                  const _RegisterField(
                    label: 'Confirm Password',
                    obscureText: true,
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
                          onPressed: () {
                            // TODO: handle registration logic.
                          },
                          child: Text(
                            'Register',
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

  const _RegisterField({required this.label, this.obscureText = false});

  @override
  Widget build(BuildContext context) {
    return TextField(
      obscureText: obscureText,
      decoration: InputDecoration(
        hintText: label,
        hintStyle: GoogleFonts.inter(
          color: const Color(0xFF6B5C46),
          fontSize: 13,
        ),
        filled: true,
        fillColor: const Color(0xFFE8D8BF),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
      style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF1E242B)),
    );
  }
}
