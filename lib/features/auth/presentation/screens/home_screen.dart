import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
      if (_selected.contains(item)) {
        _selected.remove(item);
      } else {
        _selected.add(item);
      }
    });
  }

  void _submit() {
    // TODO: handle selected project types
  }

  void _skip() {
    // TODO: navigate to next screen
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),
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
              _buildBottomActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomActions() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 24, 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFCED8E0),
                  foregroundColor: const Color(0xFF2B3A47),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 36,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Submit',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              TextButton(
                onPressed: _skip,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white70,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                ),
                child: Text(
                  'Skip',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFFCED8E0),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DiamondGrid extends StatelessWidget {
  final List<String> items;
  final Set<String> selected;
  final void Function(String) onToggle;

  // Absolute (left, top) pixel positions matching the design coordinates.
  // The items list order must match _positions order below.
  static const _positions = [
    (261.91, 44.0), // Bathroom Renovation
    (-8.94, 105.86), // Kitchen Renovation
    (145.24, 151.71), // Floor Renovation
    (39.57, 248.86), // Roof Repair
    (248.15, 243.14), // Interior Painting
    (163.67, 367.07), // Electrical Installation
    (-29.11, 396.36), // Plumbing Installation
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
        final (x, y) = _positions[i];
        return Positioned(
          left: x,
          top: y,
          child: _DiamondButton(
            label: items[i],
            isSelected: selected.contains(items[i]),
            onTap: () => onToggle(items[i]),
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

  static const double _squareSize = 98.0;
  static const double _boxSize = _squareSize * sqrt2; // ≈ 138.6

  const _DiamondButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: _boxSize,
        height: _boxSize,
        child: Center(
          child: Transform.rotate(
            angle: pi / 4,
            child: Container(
              width: _squareSize,
              height: _squareSize,
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
                      ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0xFF000000),
                    blurRadius: 10,
                    offset: Offset(3, 6),
                  ),
                  BoxShadow(
                    color: Color(0xE6EDE4D4),
                    blurRadius: 6,
                    spreadRadius: -4,
                    offset: Offset(-2, -3),
                  ),
                ],
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
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
