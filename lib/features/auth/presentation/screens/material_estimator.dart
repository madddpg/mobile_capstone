import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:iconstruct/features/auth/presentation/screens/cost_estimation.dart'
    show AddedTileSelection, AddedPlumbingSelection, CostEstimationScreen;
import 'package:iconstruct/features/auth/presentation/screens/saved_projects.dart';
import 'package:iconstruct/features/auth/presentation/screens/main_home_screen.dart';

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
  double _projectArea = 0.0;
  final PageController _materialsPageController = PageController();

  int _currentMaterialPage = 0;

  @override
  void dispose() {
    _materialsPageController.dispose();
    super.dispose();
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
            colors: [Color(0xFFE0D7C9), Color(0xFF2C3E50), Color(0xFF648DB6)],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              _buildBackgroundPanel(context),
              Positioned.fill(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(72, 135, 0, 140),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildContentCard(context),
                      const SizedBox(height: 32),
                      _buildCostSummary(context),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
              _buildHeader(context),
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
    return Container(
      padding: const EdgeInsets.only(left: 24, top: 32, right: 24, bottom: 20),
      decoration: const BoxDecoration(
        color: Color(0xFF2C3E50),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(60),
          bottomLeft: Radius.circular(60),
        ),
      ),
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
          _buildTextField(
            '0.00',
            onChanged: (val) {
              setState(() {
                _projectArea = double.tryParse(val) ?? 0.0;
              });
            },
            keyboardType: TextInputType.number,
          ),
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
            _buildSelectedMaterialsSlider(),
          ],
        ],
      ),
    );
  }

  Widget _buildSelectedMaterialsSlider() {
    final List<Widget> allMaterials = [
      for (final tile in widget.tiles) _buildTileCard(tile),
      for (final plumbing in widget.plumbingMaterials)
        _buildPlumbingCard(plumbing),
    ];

    final int itemsPerPage = 4;
    final int pageCount = (allMaterials.length / itemsPerPage).ceil();

    return Column(
      children: [
        SizedBox(
          height:
              480, // Adjust height to fit up to 4 items per page comfortably
          child: PageView.builder(
            controller: _materialsPageController,
            onPageChanged: (index) {
              setState(() {
                _currentMaterialPage = index;
              });
            },
            itemCount: pageCount,
            itemBuilder: (context, pageIndex) {
              final startIndex = pageIndex * itemsPerPage;
              final endIndex = (startIndex + itemsPerPage < allMaterials.length)
                  ? startIndex + itemsPerPage
                  : allMaterials.length;
              final items = allMaterials.sublist(startIndex, endIndex);

              return Column(
                children: items
                    .map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: item,
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ),
        if (pageCount > 1) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              pageCount,
              (index) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentMaterialPage == index
                      ? const Color(0xFFEDE4D4)
                      : const Color(0xFFEDE4D4).withAlpha(100),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCostSummary(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF2C3E50),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(60),
          bottomLeft: Radius.circular(60),
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cost\nSummary',
            style: const TextStyle(
              fontFamily: 'Ramabhadra-Regular',
              fontSize: 30,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          const Divider(color: Color(0xFFEDE4D4), thickness: 1),
          const SizedBox(height: 16),

          _buildSummaryRow(
            'Materials:',
            '${widget.tiles.length + widget.plumbingMaterials.length} items',
          ),

          const SizedBox(height: 8),

          _buildSummaryRow(
            'Project Area:',
            _projectArea > 0
                ? '${_projectArea.toStringAsFixed(2)} sq.m'
                : '0 sq.m',
          ),

          const SizedBox(height: 16),
          const Divider(color: Color(0xFFEDE4D4), thickness: 1),
          const SizedBox(height: 16),

          Text(
            'Total Estimate:',
            style: const TextStyle(
              fontFamily: 'PoppinsCustom',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFFE0D7C9),
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'TBD',
            style: const TextStyle(
              fontFamily: 'PoppinsCustom',
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Color(0xFFEDE4D4),
            ),
          ),

          const SizedBox(height: 24),

          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SavedProjectsScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEDE4D4),
                    foregroundColor: const Color(0xFF2C3E50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    'Save Project',
                    style: TextStyle(
                      fontFamily: 'Ramabhadra-Regular',
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEDE4D4),
                    foregroundColor: const Color(0xFF2C3E50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    'Post',
                    style: TextStyle(
                      fontFamily: 'Ramabhadra-Regular',
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: const Color(0xFFE0D7C9),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ],
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

  Widget _buildTextField(
    String hintText, {
    String? initialValue,
    ValueChanged<String>? onChanged,
    TextInputType? keyboardType,
  }) {
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
        onChanged: onChanged,
        keyboardType: keyboardType,
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
      projectArea: _projectArea,
      onRemove: () {
        setState(() {
          widget.tiles.remove(tile);
        });
      },
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
      projectArea: _projectArea,
      onRemove: () {
        setState(() {
          widget.plumbingMaterials.remove(plumbing);
        });
      },
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
            _BottomIconButton(
              icon: Icons.home_rounded,
              onTap: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MainHomeScreen(),
                  ),
                  (route) => false,
                );
              },
            ),
            const SizedBox(width: 10),
            _BottomIconButton(
              imagePath: 'assets/images/hammer.png',
              onTap: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CostEstimationScreen(
                      projectName: 'Your Project Name',
                    ),
                  ),
                  (route) => false,
                );
              },
            ),
            const SizedBox(width: 10),
            const _BottomNavItem(
              icon: Icons.calculate_rounded,
              label: 'Calculate',
              isActive: true,
            ),
            const SizedBox(width: 10),
            _BottomIconButton(
              icon: Icons.folder_rounded,
              onTap: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SavedProjectsScreen(),
                  ),
                  (route) => false,
                );
              },
            ),
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
  final double projectArea;
  final VoidCallback? onRemove;

  const SelectedMaterialCard({
    super.key,
    required this.name,
    required this.category,
    this.kind,
    this.size,
    this.length,
    required this.quantity,
    this.projectArea = 0.0,
    this.onRemove,
  });

  double autoComputeQuantity() {
    if (projectArea <= 0) return 0;

    final cat = category.toLowerCase();
    if (cat == 'tiles' || cat == 'flooring' || cat == 'floor surface') {
      double tileWidth = 0.6;
      double tileHeight = 0.6;
      if (size != null && size!.trim().isNotEmpty) {
        final match = RegExp(r'(\d+)\s*[×xX]\s*(\d+)').firstMatch(size!);
        if (match != null) {
          tileWidth = (double.tryParse(match.group(1)!) ?? 600) / 1000;
          tileHeight = (double.tryParse(match.group(2)!) ?? 600) / 1000;
        }
      }
      double tileArea = tileWidth * tileHeight;
      if (tileArea == 0) return 0;
      double tilesNeeded = projectArea / tileArea;
      return (tilesNeeded * 1.10).ceilToDouble(); // 10% allowance
    } else if (cat.contains('plumb') ||
        cat.contains('pipes') ||
        cat.contains('wiring')) {
      return projectArea * 1.5;
    } else if (cat.contains('fixtures')) {
      return 1;
    }
    return 0;
  }

  double getFinalQuantity() {
    if (quantity > 0) {
      return quantity;
    } else {
      return autoComputeQuantity();
    }
  }

  String getUnit(String category) {
    if (category.toLowerCase().contains('plumb')) return 'meters';
    switch (category.toLowerCase()) {
      case 'tiles':
      case 'flooring':
      case 'floor surface':
        return 'pcs';
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              if (onRemove != null)
                GestureDetector(
                  onTap: onRemove,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Icon(
                      Icons.delete_outline_rounded,
                      size: 20,
                      color: Colors.redAccent.withAlpha(200),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            kind != null && kind!.isNotEmpty ? '$category • $kind' : category,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: Color(0xCCE0D7C9),
            ),
          ),
          const SizedBox(height: 12),

          if (size != null && size!.isNotEmpty) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Size: $size',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: Color(0xFFE0D7C9),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
          ],

          if (length != null && length!.isNotEmpty) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Length: $length',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: Color(0xFFE0D7C9),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
          ],

          Builder(
            builder: (context) {
              final finalQty = getFinalQuantity();

              if (finalQty > 0) {
                final qtyStr = finalQty.toStringAsFixed(
                  finalQty.truncateToDouble() == finalQty ? 0 : 2,
                );

                final isEstimated = quantity <= 0 && projectArea > 0;
                final estStr = isEstimated ? ' (estimated)' : '';

                return Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Quantity: $qtyStr',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFEDE4D4),
                        ),
                      ),
                    ),
                    Text(
                      '${getUnit(category)}$estStr',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: Color(0xCCEDE4D4),
                      ),
                    ),
                  ],
                );
              } else {
                return Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Quantity: Not set',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFEDE4D4),
                        ),
                      ),
                    ),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
