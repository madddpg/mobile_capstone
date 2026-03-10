import 'package:flutter/material.dart';

import 'register_screen.dart';
import 'login_screen.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _exitController;
  late final Animation<double> _fadeOut;
  late final Animation<Offset> _slideOut;
  bool _exiting = false;

  @override
  void initState() {
    super.initState();
    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _fadeOut = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeInOut),
    );
    _slideOut = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, 0.04),
    ).animate(CurvedAnimation(parent: _exitController, curve: Curves.easeIn));
  }

  @override
  void dispose() {
    _exitController.dispose();
    super.dispose();
  }

  Future<void> _runExit(
    VoidCallback action, {
    bool restoreIfStaying = true,
  }) async {
    if (_exiting) return;
    setState(() => _exiting = true);
    await _exitController.forward();
    if (!mounted) return;
    action();

    if (restoreIfStaying && mounted) {
      await _exitController.reverse();
      if (mounted) setState(() => _exiting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            const _LandingBackground(),
            FadeTransition(
              opacity: _fadeOut,
              child: SlideTransition(
                position: _slideOut,
                child: Align(
                  alignment: Alignment.center,
                  child: SizedBox(
                    width: size.width * 0.9,
                    height: size.height * 0.75,
                    child: _LandingCard(
                      onGetStarted: () {
                        _runExit(() {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const RegisterScreen(),
                            ),
                          );
                        }, restoreIfStaying: false);
                      },
                      onLogin: () {
                        _runExit(() {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const LoginScreen(),
                            ),
                          );
                        }, restoreIfStaying: false);
                      },
                    ),
                  ),
                ),
              ),
            ),
            FadeTransition(
              opacity: _fadeOut,
              child: SlideTransition(
                position: _slideOut,
                child: Positioned(
                  top: 95,
                  left: 30,
                  child: _FloatingBackButton(
                    onTap: () {
                      _runExit(() {
                        Navigator.of(context).maybePop();
                      });
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LandingBackground extends StatelessWidget {
  const _LandingBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2F3E4F), Color(0xFF4F6B8A), Color(0xFF6F8FAF)],
          stops: [0, 0.5, 1],
        ),
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _LandingCard extends StatelessWidget {
  final VoidCallback onGetStarted;
  final VoidCallback onLogin;

  const _LandingCard({required this.onGetStarted, required this.onLogin});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(45),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 40,
            spreadRadius: 2,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(45),
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFFFFFFFF), // #FFFFFF @ 100%
                      Color(0xCCEDE4D4), // #EDE4D4 @ 80%
                      Color(0x00648DB6), // #648DB6 @ 0%
                    ],
                    stops: [0.19, 0.65, 1.0],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),
                  const Text(
                    'Create an\nAccount',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 34,
                      height: 1.2,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2F3E4F),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Your projects starts with us.',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF5B6E80),
                    ),
                  ),
                  const Spacer(),
                  Align(
                    alignment: Alignment.center,
                    child: FractionallySizedBox(
                      widthFactor: 0.75,
                      child: SizedBox(
                        height: 55,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            padding: EdgeInsets.zero,
                            shadowColor: Colors.transparent,
                            backgroundColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          onPressed: onGetStarted,
                          child: Ink(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: [Color(0xFFD6CEC3), Color(0xFF7C9BC0)],
                              ),
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 25,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Text(
                                'Get Started',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF2F3E4F),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Already have an account? ',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.85),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        GestureDetector(
                          onTap: onLogin,
                          child: Text(
                            'Login',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.95),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FloatingBackButton extends StatelessWidget {
  final VoidCallback onTap;

  const _FloatingBackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 20,
            spreadRadius: 2,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(32),
          child: Ink(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              color: Color(0xFFE5E1DA),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Color(0xFF3A4D63),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
