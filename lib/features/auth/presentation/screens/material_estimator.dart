import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:iconstruct/features/auth/presentation/screens/cost_estimation.dart'
    show AddedTileSelection, AddedPlumbingSelection;

class MaterialEstimatorScreen extends StatefulWidget {
  final String projectName;
  final List<AddedTileSelection> tiles;
  final List<AddedPlumbingSelection> plumbingMaterials;

  const MaterialEstimatorScreen({
    super.key,
    required this.projectName,
    this.tiles = const [],
    this.plumbingMaterials = const [],
  });

  @override
  State<MaterialEstimatorScreen> createState() =>
      _MaterialEstimatorScreenState();
}

class _MaterialEstimatorScreenState extends State<MaterialEstimatorScreen> {
  String? _selectedBudget;

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
            colors: [Color(0xFFE0D7C9), Color(0xFF2C3E50), Color(0xFF648DB6)],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              _buildBackgroundPanel(context),
              _buildHeader(context),
              _buildContentCard(context),
              _buildBottomNav(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackgroundPanel(BuildContext context) {
    return const Positioned(
      left: 0,
      top: -200,
      width: 393,
      height: 585,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Color(0xFFEDE4D4),
          borderRadius: BorderRadius.all(Radius.circular(50)),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Positioned(
      top: 10,
      left: 20,
      child: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            color: Color(0xFF2C3E50),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildContentCard(BuildContext context) {
    return Positioned(
      top: 110,
      right: 0,
      left: 72,
      bottom: 80,
      child: Container(
        padding: const EdgeInsets.only(
          left: 24,
          top: 32,
          right: 24,
          bottom: 20,
        ),
        decoration: const BoxDecoration(
          color: Color(0xFF2C3E50),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(60),
            bottomLeft: Radius.circular(60),
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Material\nEstimator',
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  height: 1.2,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              const Divider(color: Color(0xFFEDE4D4), thickness: 1),
              const SizedBox(height: 16),
              Text(
                'Project Details',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              _buildInputLabel('Project Name:'),
              _buildTextField('e.g., Living Room Renovation'),
              const SizedBox(height: 16),
              _buildInputLabel('Project Type:'),
              _buildTextField(
                'e.g., Window Installation',
                initialValue: widget.projectName,
              ),
              const SizedBox(height: 16),
              _buildInputLabel('Project Area:\n(sq meters)', maxLines: 2),
              _buildTextField('0.00'),
              const SizedBox(height: 16),
              _buildInputLabel('Budget Range:'),
              _buildDropdownField(),
              const SizedBox(height: 24),
              _buildInputLabel('Selected Materials:'),
              const SizedBox(height: 10),
              if (widget.tiles.isEmpty && widget.plumbingMaterials.isEmpty)
                Text(
                  'No materials selected.',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: const Color(0xFFE0D7C9),
                  ),
                )
              else ...[
                for (final tile in widget.tiles)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: _buildTileCard(tile),
                  ),
                for (final plumbing in widget.plumbingMaterials)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: _buildPlumbingCard(plumbing),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputLabel(String label, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 13,
          color: const Color(0xFFE0D7C9),
        ),
      ),
    );
  }

  Widget _buildTextField(String hintText, {String? initialValue}) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDE4D4), width: 1),
      ),
      child: TextField(
        controller: initialValue != null
            ? TextEditingController(text: initialValue)
            : null,
        style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 0,
          ),
          border: InputBorder.none,
          hintText: hintText,
          hintStyle: GoogleFonts.poppins(
            color: const Color(0xFFEDE4D4).withAlpha(153),
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownField() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDE4D4), width: 1),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedBudget,
          isExpanded: true,
          dropdownColor: const Color(0xFF2C3E50),
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Colors.white,
          ),
          hint: Text(
            'Select budget range',
            style: GoogleFonts.poppins(
              color: const Color(0xFFEDE4D4).withAlpha(153),
              fontSize: 14,
            ),
          ),
          items: ['Low Budget', 'Mid Budget', 'High Budget'].map((
            String value,
          ) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(
                value,
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
              ),
            );
          }).toList(),
          onChanged: (newValue) {
            setState(() {
              _selectedBudget = newValue;
            });
          },
        ),
      ),
    );
  }

  Widget _buildTileCard(AddedTileSelection tile) {
    return SelectedMaterialCard(
      name: tile.tileTypeName,
      category: 'Tiles',
      kind: tile.tileSizeGroup,
      size: tile.tileSizeName,
      quantity: tile.quantity,
    );
  }

  Widget _buildPlumbingCard(AddedPlumbingSelection plumbing) {
    return SelectedMaterialCard(
      name: plumbing.materialName,
      category: plumbing.categoryTitle,
      kind: plumbing.kind,
      size: plumbing.size,
      length: plumbing.length,
      quantity: plumbing.quantity,
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        height: 72,
        margin: const EdgeInsets.only(bottom: 24),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFEDE4D4),
          borderRadius: BorderRadius.circular(40),
          boxShadow: const [
            BoxShadow(
              color: Colors.black54,
              blurRadius: 16,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _BottomIconButton(icon: Icons.home_rounded),
            const SizedBox(width: 10),
            const _BottomIconButton(imagePath: 'assets/images/hammer.png'),
            const SizedBox(width: 10),
            const _BottomNavItem(
              icon: Icons.calculate_rounded,
              label: 'Calculate',
              isActive: true,
            ),
            const SizedBox(width: 10),
            const _BottomIconButton(icon: Icons.folder_rounded),
          ],
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;

  const _BottomNavItem({
    required this.icon,
    required this.label,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF2C3E50) : Colors.transparent,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 22,
            color: isActive ? const Color(0xFFEDE4D4) : const Color(0xFF2C3E50),
          ),
          if (isActive) ...[
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFFEDE4D4),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BottomIconButton extends StatelessWidget {
  final IconData? icon;
  final String? imagePath;
  final VoidCallback? onTap;

  const _BottomIconButton({this.icon, this.imagePath, this.onTap})
    : assert(icon != null || imagePath != null);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        color: Colors.transparent,
        child: Center(
          child: imagePath != null
              ? Image.asset(
                  imagePath!,
                  width: 24,
                  height: 24,
                  fit: BoxFit.contain,
                  color: const Color(0xFF2C3E50),
                )
              : Icon(icon, size: 24, color: const Color(0xFF2C3E50)),
        ),
      ),
    );
  }
}

class SelectedMaterialCard extends StatelessWidget {
  final String name;
  final String category;
  final String? kind;
  final String? size;
  final String? length;
  final double quantity;

  const SelectedMaterialCard({
    super.key,
    required this.name,
    required this.category,
    this.kind,
    this.size,
    this.length,
    required this.quantity,
  });

  String getUnit(String category) {
    if (category.toLowerCase().contains('plumb')) return 'meters';
    switch (category.toLowerCase()) {
      case 'tiles':
      case 'flooring':
      case 'floor surface':
        return 'sqm';
      case 'plumbing':
      case 'pipes':
      case 'wiring':
        return 'meters';
      case 'fixtures':
        return 'pcs';
      case 'paint':
        return 'liters';
      default:
        return 'pcs';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDE4D4), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Side: Material Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  kind != null && kind!.isNotEmpty
                      ? '$category • $kind'
                      : category,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: const Color(0xFFE0D7C9).withAlpha(204),
                  ),
                ),
                const SizedBox(height: 12),
                if (size != null && size!.isNotEmpty)
                  Text(
                    'Size: $size',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: const Color(0xFFE0D7C9),
                    ),
                  ),
                if (length != null && length!.isNotEmpty)
                  Text(
                    'Length: $length',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: const Color(0xFFE0D7C9),
                    ),
                  ),
                const SizedBox(height: 6),
                Text(
                  quantity > 0
                      ? 'Qty: ${quantity.toStringAsFixed(quantity.truncateToDouble() == quantity ? 0 : 2)} ${getUnit(category)}'
                      : 'Qty: Not set',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFEDE4D4),
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
