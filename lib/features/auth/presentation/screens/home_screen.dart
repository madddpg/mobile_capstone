import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'cost_estimation.dart';
import 'main_home_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const List<String> _items = [
    'Bathroom\nRenovation',
    'Kitchen\nRenovation',
    'Floor\nRenovation',
    'Roof\nRepair',
    'Interior\nPainting',
    'Electrical\nInstallation',
    'Plumbing\nInstallation',
  ];

  final Set<String> _selected = {};

  void _toggle(String item) {
    setState(() {
      // Allow only a single selected project at a time.
      if (_selected.contains(item)) {
        // Tapping the same item again will clear the selection.
        _selected.clear();
      } else {
        _selected
          ..clear()
          ..add(item);
      }
    });
  }

  void _submit() {
    if (_selected.isEmpty) {
      return;
    }

    final selected = _selected.first.replaceAll('\n', ' ');

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CostEstimationScreen(projectName: selected),
      ),
    );
  }

  void _skip() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainHomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0.0, 0.56, 1.0],
            colors: [Color(0xFF2C3E50), Color(0xFF2C3E50), Color(0xFF648DB6)],
          ),
        ),
        child: SafeArea(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 80),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Text(
                      'Current project\nplans?',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 36,
                        fontWeight: FontWeight.w700, // already bold
                        color: Color(0xFFEDE4D4),
                        height: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _DiamondGrid(
                      items: _items,
                      selected: _selected,
                      onToggle: _toggle,
                    ),
                  ),
                  const SizedBox(height: 90),
                ],
              ),
              Positioned(right: -50, bottom: 20, child: _buildBottomActions()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 190,
          child: ElevatedButton(
            onPressed: _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEDE4D4),
              foregroundColor: const Color(0xFF2B3A47),
              minimumSize: const Size(170, 46),
              shape: const StadiumBorder(),
              elevation: 8,
              shadowColor: Colors.black.withAlpha(102),
            ),
            child: Text(
              'Submit',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: 170,
          child: ElevatedButton(
            onPressed: _skip,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEDE4D4),
              foregroundColor: const Color(0xFF2B3A47),
              minimumSize: const Size(150, 46),
              shape: const StadiumBorder(),
              elevation: 8,
              shadowColor: Colors.black.withAlpha(102),
            ),
            child: Text(
              'Skip',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DiamondGrid extends StatelessWidget {
  final List<String> items;
  final Set<String> selected;
  final void Function(String) onToggle;

  // Absolute (left, top, width, height) pixel values from the design.
  // Order matches `_items` in _HomeScreenState.
  static const _layout = [
    (261.91, 38.0, 126.0, 126.0), // Bathroom Renovation
    (10.94, 90.86, 126.0, 126.0), // Kitchen Renovation
    (150.24, 152.71, 126.0, 126.0), // Floor Renovation
    (70.00, 300.86, 126.0, 126.0), // Roof Repair
    (248.15, 240.14, 126.0, 126.0), // Interior Painting
    (220.67, 390.07, 126.0, 126.0), // Electrical Installation
    (20.94, 450.36, 126.0, 126.0), // Plumbing Installation
  ];

  const _DiamondGrid({
    required this.items,
    required this.selected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: List.generate(items.length, (i) {
        final (baseX, y, w, h) = _layout[i];
        // Shift most diamonds slightly to the right, but keep
        // Kitchen Renovation (index 1) and Plumbing Installation (index 6)
        // exactly at their original coordinates.
        const double shiftX = 18.0;
        double x;
        if (i == 1 || i == 6) {
          x = baseX;
        } else if (i == 4) {
          // Push Interior Painting further right for the edge "glitch" look.
          x = baseX + shiftX + 26.0;
        } else {
          x = baseX + shiftX;
        }
        return Positioned(
          left: x,
          top: y,
          width: w,
          height: h,
          child: _DiamondButton(
            label: items[i],
            isSelected: selected.contains(items[i]),
            onTap: () => onToggle(items[i]),
            width: w,
            height: h,
          ),
        );
      }),
    );
  }
}

class _DiamondButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final double width;
  final double height;

  const _DiamondButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    // Use the provided bounding box to derive the inner square size
    // so the diamond fits within the design width/height.
    const double scale = 1.25; // make the diamonds larger while keeping x/y
    final double baseSquare = min(width, height) / sqrt2;
    final double squareSize = baseSquare * scale;
    final double outerSquareSize = squareSize + 18;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: width,
        height: height,
        child: Center(
          child: Transform.rotate(
            angle: pi / 4,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer diamond with design gradient and strong drop shadow
                Container(
                  width: outerSquareSize,
                  height: outerSquareSize,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF000000), // 0% @ 100%
                        Color(0xE6EDE4D4), // 78% @ 90%
                      ],
                      stops: [0.0, 0.78],
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0xFF000000),
                        blurRadius: 14,
                        offset: Offset(4, 8),
                      ),
                    ],
                  ),
                ),
                // Inner diamond that changes with selection state
                Container(
                  width: squareSize,
                  height: squareSize,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: isSelected
                        ? const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF5B85C4), Color(0xFF3A62A0)],
                          )
                        : const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFFEDE4D4), Color(0xFF707070)],
                            stops: [0.35, 1.0],
                          ),
                  ),
                  child: Transform.rotate(
                    angle: -pi / 4,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Text(
                          label,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue.shade900,
                            height: 1.4,
                            shadows: [
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.6),
                                offset: Offset(1.2, 1.4),
                                blurRadius: 3,
                              ),
                            ],
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
    );
  }
}
