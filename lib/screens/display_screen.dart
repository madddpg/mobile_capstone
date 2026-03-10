import 'dart:async';

import 'package:flutter/material.dart';

import 'main_display.dart';

class DisplayScreen extends StatefulWidget {
  const DisplayScreen({super.key});

  @override
  State<DisplayScreen> createState() => _DisplayScreenState();
}

class _DisplayScreenState extends State<DisplayScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  Timer? _navTimer;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _scale = Tween<double>(
      begin: 0.96,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward();

    _navTimer = Timer(const Duration(milliseconds: 3000), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainDisplayScreen()),
      );
    });
  }

  @override
  void dispose() {
    _navTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const _DisplayBackground(),
          SafeArea(
            child: Center(
              child: FadeTransition(
                opacity: _fade,
                child: ScaleTransition(
                  scale: _scale,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo mark
                      Container(
                        margin: const EdgeInsets.only(bottom: 18),
                        width: 82,
                        height: 58,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4E7CB),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Positioned(
                              bottom: 10,
                              left: 10,
                              right: 10,
                              child: Container(
                                height: 8,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF263645),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 18,
                              left: 12,
                              child: Container(
                                width: 12,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF263645),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 20,
                              left: 30,
                              child: Container(
                                width: 10,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF263645),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 22,
                              left: 46,
                              child: Container(
                                width: 10,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF263645),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 10,
                              left: 18,
                              child: Container(
                                width: 10,
                                height: 10,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF263645),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Text(
                        'iConstruct',
                        style: TextStyle(
                          color: Color(0xFFF4E7CB),
                          fontFamily: 'Poppins',
                          fontSize: 28,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Plan smarter. Build better.',
                        style: TextStyle(
                          color: Color(0xFFEADAC2),
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0.6,
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
}

class _DisplayBackground extends StatelessWidget {
  const _DisplayBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2F3E4F), Color(0xFF4F6B8A), Color(0xFF6F8FAF)],
          stops: [0, 0.55, 1],
        ),
      ),
      child: const SizedBox.expand(),
    );
  }
}
