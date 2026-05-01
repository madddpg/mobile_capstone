import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:iconstruct/core/materials/material_recommendation_controller.dart';
import 'package:iconstruct/core/materials/models/material_category.dart';
import 'package:iconstruct/core/materials/models/material_item.dart';
import 'package:iconstruct/core/materials/services/firestore_materials_service.dart';
import 'package:iconstruct/core/materials/services/favorites_service.dart';
import 'package:iconstruct/core/widgets/user_avatar.dart';

import 'package:iconstruct/features/auth/presentation/screens/material_estimator.dart';
import 'package:iconstruct/features/auth/presentation/screens/saved_projects.dart';
import 'package:iconstruct/features/auth/presentation/screens/main_home_screen.dart';
import 'package:iconstruct/features/auth/presentation/screens/profile_screen.dart';

IconData getFilterIcon(String filter) {
  switch (filter.trim()) {
    case MaterialRecommendationController.filterAll:
      return Icons.list;
    case MaterialRecommendationController.filterFloor:
      return Icons.grid_view;
    case MaterialRecommendationController.filterWall:
      return Icons.view_agenda;
    default:
      return Icons.filter_list;
  }
}

class CostEstimationScreen extends StatefulWidget {
  final String projectName;
  final MaterialItem? preselectedMaterial;

  const CostEstimationScreen({
    super.key,
    required this.projectName,
    this.preselectedMaterial,
  });

  @override
  State<CostEstimationScreen> createState() => _CostEstimationScreenState();
}

class _CostEstimationScreenState extends State<CostEstimationScreen> {
  late final MaterialRecommendationController _materials;
  final ScrollController _materialsScrollController = ScrollController();
  final PageController _categoryPageController = PageController();

  final List<AddedPlumbingSelection> _selectedProducts =
      <AddedPlumbingSelection>[];

  @override
  void initState() {
    super.initState();

    final firestore = FirestoreMaterialsService();
    _materials = MaterialRecommendationController(firestore: firestore);
    _materials.addListener(_onMaterialsChanged);

    _loadProjectMaterials();
  }

  void _onMaterialsChanged() {
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _loadProjectMaterials() async {
    final projectQuery = widget.projectName
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    await _materials.loadForProject(projectQuery);

    if (!mounted) return;

    if (widget.preselectedMaterial != null) {
      final pm = widget.preselectedMaterial!;
      final catItems = _materials.getItemsByCategory(pm.category);

      final loadedItem = catItems.cast<MaterialItem?>().firstWhere(
        (element) => element?.name == pm.name,
        orElse: () => null,
      );

      if (loadedItem != null) {
        _onProductClicked(loadedItem.category, loadedItem);
      }
    }
  }

  @override
  void dispose() {
    _materials.removeListener(_onMaterialsChanged);
    _materialsScrollController.dispose();
    _categoryPageController.dispose();
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
              _buildBackgroundPanel(),
              _buildHeader(context),
              _buildContentCard(context),
              _buildFloatingFilter(),
              _buildBottomNav(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackgroundPanel() {
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
    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        height: 96,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: const BoxDecoration(color: Color(0xFFEDE4D4)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            UserAvatar(
              size: 36,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileScreen(),
                  ),
                );
              },
            ),
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.centerRight,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    width: 18,
                    height: 2.4,
                    color: const Color(0xFF2C3E50),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 14,
                    height: 2.4,
                    color: const Color(0xFF2C3E50),
                  ),
                ],
              ),
            ),
          ],
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
        padding: const EdgeInsets.fromLTRB(24, 28, 0, 32),
        decoration: const BoxDecoration(
          color: Color(0xFF1E3042),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(60),
            topRight: Radius.circular(60),
            bottomLeft: Radius.circular(60),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.projectName.contains('\n')
                  ? widget.projectName
                  : widget.projectName.replaceFirst(' ', '\n'),
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            const Divider(color: Color(0xFFEDE4D4), thickness: 1),
            const SizedBox(height: 12),
            Text(
              'Select products for your project.\nSizes will appear after clicking a product.',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: const Color(0xFFE0D7C9),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            const Divider(color: Color(0xFFEDE4D4), thickness: 1),
            const SizedBox(height: 14),
            Expanded(child: _buildMaterialsBody(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingFilter() {
    return Positioned(
      top: 360,
      left: 10,
      child: FloatingFilterRail(
        selectedFilter: _materials.selectedFilter,
        onChanged: _onFilterSelected,
      ),
    );
  }

  void _onFilterSelected(String value) {
    _materials.setSelectedFilter(value);

    if (_categoryPageController.hasClients) {
      _categoryPageController.jumpToPage(0);
    }

    if (!_materialsScrollController.hasClients) return;

    _materialsScrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
    );
  }

  IconData getCategoryIcon(String categoryTitle) {
    final t = categoryTitle.trim().toLowerCase();

    if (t.contains('floor')) return Icons.grid_view;
    if (t.contains('wall')) return Icons.view_agenda;
    if (t.contains('install')) return Icons.construction;
    if (t.contains('finish')) return Icons.brush;
    if (t.contains('plumb')) return Icons.plumbing;
    if (t.contains('electric')) return Icons.electrical_services;
    return Icons.category;
  }

  Widget _buildMaterialsBody(BuildContext context) {
    if (_materials.isLoading) {
      return const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: Color(0xFFEDE4D4),
          ),
        ),
      );
    }

    if (_materials.categories.isEmpty) {
      return Align(
        alignment: Alignment.topLeft,
        child: Text(
          _materials.errorMessage?.trim().isNotEmpty == true
              ? 'Could not load products.\n${_materials.errorMessage}'
              : 'No products available for this project yet.',
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: const Color(0xFFE0D7C9),
            height: 1.4,
          ),
        ),
      );
    }

    final slides = _materials.filteredCategories;

    if (slides.isEmpty) {
      return Align(
        alignment: Alignment.topLeft,
        child: Text(
          'No products match this filter.',
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: const Color(0xFFE0D7C9),
            height: 1.4,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: PageView.builder(
            controller: _categoryPageController,
            itemCount: slides.length,
            itemBuilder: (context, index) {
              final category = slides[index];
              final items = _materials.getItemsByCategory(category.title);
              final selectedName = _materials
                  .getSelectedForCategory(category.title)
                  ?.name;

              return SingleChildScrollView(
                controller: _materialsScrollController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _FilterSection(
                      title: category.title,
                      leadingIcon: getCategoryIcon(category.title),
                      items: items,
                      selectedName: selectedName,
                      onSelect: (item) =>
                          _onProductClicked(category.title, item),
                    ),

                    if (_selectedProducts.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      const Divider(color: Color(0xFFEDE4D4), thickness: 1),
                      const SizedBox(height: 12),
                      Text(
                        'Selected Products:',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFEDE4D4),
                        ),
                      ),
                      const SizedBox(height: 10),
                      for (final selected in _selectedProducts)
                        _AddedMaterialItem(
                          title: selected.materialName,
                          subtitle: selected.displayLabel
                              .replaceFirst(selected.materialName, '')
                              .replaceFirst(' • ', '')
                              .trim(),
                          unit: selected.unit,
                          qtyController: selected.qtyController,
                          onChanged: (val) {
                            selected.quantity = double.tryParse(val) ?? 0.0;
                          },
                          onRemove: () {
                            setState(() {
                              _selectedProducts.remove(selected);
                            });
                          },
                        ),
                    ],

                    const SizedBox(height: 20),
                  ],
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 20),

        Align(
          alignment: Alignment.centerRight,
          child: SizedBox(
            width: 100,
            height: 40,
            child: ElevatedButton(
              onPressed: () => _showNextMaterialSlide(slides.length),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEDE4D4),
                foregroundColor: const Color(0xFF1E3042),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 6,
                shadowColor: Colors.black.withAlpha(100),
              ),
              child: Text(
                'Next',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 10),

        Align(
          alignment: Alignment.centerRight,
          child: SizedBox(
            width: 150,
            height: 40,
            child: ElevatedButton(
              onPressed: _goToEstimator,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEDE4D4),
                foregroundColor: const Color(0xFF1E3042),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 6,
                shadowColor: Colors.black.withAlpha(100),
              ),
              child: Text(
                'Estimate Now',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 10),
      ],
    );
  }

  Future<void> _showNextMaterialSlide(int slideCount) async {
    if (slideCount <= 0) return;
    if (!_categoryPageController.hasClients) return;

    final current = (_categoryPageController.page ?? 0).round();
    final next = (current + 1) % slideCount;

    await _categoryPageController.animateToPage(
      next,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
    );

    if (!_materialsScrollController.hasClients) return;

    await _materialsScrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
    );
  }

  void _goToEstimator() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MaterialEstimatorScreen(
          projectName: widget.projectName,
          tiles: const [],
          plumbingMaterials: _selectedProducts,
        ),
      ),
    );
  }

  void _onProductClicked(String categoryTitle, MaterialItem item) {
    _materials.selectItemForCategory(categoryTitle, item);
    _showProductSelectionDialog(categoryTitle, item);
  }

  void _showProductSelectionDialog(String categoryTitle, MaterialItem item) {
    final sizes = item.sizes ?? const <String>[];
    String? selectedSize = sizes.isNotEmpty ? sizes.first : null;
    final qtyController = TextEditingController(text: '1');

    showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              backgroundColor: const Color(0xFFEDE4D4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              title: Text(
                item.name,
                style: GoogleFonts.poppins(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF2C3E50),
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (item.imageUrl.trim().isNotEmpty) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: Image.network(
                            item.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: const Color(0xFF2C3E50).withAlpha(15),
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.broken_image,
                                  color: Color(0xFF2C3E50),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    if (item.description.trim().isNotEmpty) ...[
                      Text(
                        item.description,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          height: 1.4,
                          color: const Color(0xFF2C3E50),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    Text(
                      'Unit: ${item.unit}',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF2C3E50),
                      ),
                    ),

                    if (sizes.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Text(
                        'Select size:',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF2C3E50),
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: selectedSize,
                        dropdownColor: const Color(0xFFEDE4D4),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        items: sizes.map((size) {
                          return DropdownMenuItem<String>(
                            value: size,
                            child: Text(size),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setModalState(() {
                            selectedSize = value;
                          });
                        },
                      ),
                    ],

                    const SizedBox(height: 14),

                    Text(
                      'Quantity:',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF2C3E50),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: qtyController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Enter quantity',
                        suffixText: item.unit,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF2C3E50),
                    ),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2C3E50),
                    foregroundColor: const Color(0xFFEDE4D4),
                  ),
                  onPressed: () {
                    final qty = double.tryParse(qtyController.text) ?? 1.0;

                    _addOrUpdateSelectedProduct(
                      categoryTitle: categoryTitle,
                      item: item,
                      selectedSize: selectedSize,
                      quantity: qty,
                    );

                    Navigator.pop(context);
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _addOrUpdateSelectedProduct({
    required String categoryTitle,
    required MaterialItem item,
    required String? selectedSize,
    required double quantity,
  }) {
    final selection = AddedPlumbingSelection(
      categoryTitle: categoryTitle,
      kind: (item.type ?? '').trim(),
      materialName: item.name,
      size: selectedSize,
      unit: item.unit,
      quantity: quantity,
    );

    setState(() {
      final index = _selectedProducts.indexWhere(
        (e) =>
            e.categoryTitle == selection.categoryTitle &&
            e.materialName == selection.materialName &&
            (e.size ?? '') == (selection.size ?? ''),
      );

      if (index != -1) {
        final existing = _selectedProducts[index];
        final updated = AddedPlumbingSelection(
          categoryTitle: selection.categoryTitle,
          kind: selection.kind,
          materialName: selection.materialName,
          size: selection.size,
          unit: selection.unit,
          quantity: selection.quantity,
        );
        updated.qtyController.text = quantity.toString();
        _selectedProducts[index] = updated;
        existing.qtyController.dispose();
      } else {
        selection.qtyController.text = quantity.toString();
        _selectedProducts.add(selection);
      }
    });
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
              onTap: () {},
            ),
            const SizedBox(width: 10),
            const _BottomNavItem(
              icon: Icons.calculate_rounded,
              label: 'Estimate',
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

class _FilterSection extends StatelessWidget {
  final String title;
  final IconData? leadingIcon;
  final List<MaterialItem> items;
  final String? selectedName;
  final void Function(MaterialItem) onSelect;

  const _FilterSection({
    required this.title,
    this.leadingIcon,
    required this.items,
    required this.selectedName,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Text(
        'No products in this category.',
        style: GoogleFonts.poppins(
          fontSize: 12,
          color: const Color(0xFFE0D7C9),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (leadingIcon != null) ...[
              Icon(leadingIcon, size: 16, color: const Color(0xFFEDE4D4)),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFEDE4D4),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Column(
          children: [
            for (int i = 0; i < items.length; i++) ...[
              _MaterialCardOption(
                item: items[i],
                isSelected: items[i].name == selectedName,
                onTap: () => onSelect(items[i]),
              ),
              if (i != items.length - 1) const SizedBox(height: 10),
            ],
          ],
        ),
      ],
    );
  }
}

class _MaterialCardOption extends StatelessWidget {
  final MaterialItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _MaterialCardOption({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = item.imageUrl.trim();
    final title = item.name.trim();
    final description = item.description.trim();

    final borderColor = isSelected
        ? const Color(0xFFEDE4D4)
        : const Color(0xFFEDE4D4).withAlpha(160);

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1E3042),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor, width: isSelected ? 2 : 1.2),
        ),
        child: Row(
          children: [
            _MaterialThumb(imageUrl: imageUrl),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title.isEmpty ? 'Unnamed Product' : title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFEDE4D4),
                    ),
                  ),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: const Color(0xFFE0D7C9),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            _FavoriteButton(item: item),
          ],
        ),
      ),
    );
  }
}

class _FavoriteButton extends StatelessWidget {
  final MaterialItem item;

  const _FavoriteButton({required this.item});

  @override
  Widget build(BuildContext context) {
    final service = FavoritesService();

    return StreamBuilder<bool>(
      stream: service.isFavorite(item),
      builder: (context, snapshot) {
        final isFavorite = snapshot.data ?? false;

        return IconButton(
          onPressed: () async {
            try {
              if (isFavorite) {
                await service.removeFavorite(item);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Removed from favorites'),
                      backgroundColor: Colors.red.shade400,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              } else {
                await service.addFavorite(item);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Added to favorites'),
                      backgroundColor: Colors.green.shade400,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              }
            } catch (_) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Failed to update favorites')),
                );
              }
            }
          },
          icon: Icon(
            isFavorite
                ? Icons.favorite_rounded
                : Icons.favorite_outline_rounded,
            color: isFavorite
                ? Colors.red.shade400
                : const Color(0xFFEDE4D4).withAlpha(160),
            size: 24,
          ),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        );
      },
    );
  }
}

class _MaterialThumb extends StatelessWidget {
  final String imageUrl;

  const _MaterialThumb({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 44,
        height: 44,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFFEDE4D4).withAlpha(30),
            border: Border.all(
              color: const Color(0xFFEDE4D4).withAlpha(90),
              width: 1,
            ),
          ),
          child: imageUrl.isEmpty
              ? const Icon(Icons.image, size: 18, color: Color(0xFFEDE4D4))
              : Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Icon(
                        Icons.broken_image,
                        size: 18,
                        color: Color(0xFFEDE4D4),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}

class _AddedMaterialItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final TextEditingController qtyController;
  final String unit;
  final ValueChanged<String> onChanged;
  final VoidCallback onRemove;

  const _AddedMaterialItem({
    required this.title,
    required this.subtitle,
    required this.qtyController,
    required this.unit,
    required this.onChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E3042),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFEDE4D4).withAlpha(80),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: const Color(0xFFE0D7C9),
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(width: 12),

          Container(
            width: 140,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFFEDE4D4).withAlpha(120),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: qtyController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onChanged: onChanged,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Enter quantity',
                      hintStyle: GoogleFonts.poppins(
                        color: Colors.white38,
                        fontSize: 10,
                      ),
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      border: InputBorder.none,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    unit,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: const Color(0xFFEDE4D4).withAlpha(180),
                    ),
                  ),
                ),
              ],
            ),
          ),

          IconButton(
            onPressed: onRemove,
            icon: const Icon(
              Icons.close_rounded,
              color: Color(0xFFEDE4D4),
              size: 18,
            ),
          ),
        ],
      ),
    );
  }
}

class FloatingFilterRail extends StatelessWidget {
  final String selectedFilter;
  final ValueChanged<String> onChanged;

  const FloatingFilterRail({
    super.key,
    required this.selectedFilter,
    required this.onChanged,
  });

  static const _filters = <String>[
    MaterialRecommendationController.filterAll,
    MaterialRecommendationController.filterFloor,
    MaterialRecommendationController.filterWall,
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFFEDE4D4),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 14,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final f in _filters) ...[
            _FloatingFilterButton(
              icon: getFilterIcon(f),
              isSelected: selectedFilter == f,
              onTap: () => onChanged(f),
            ),
            if (f != _filters.last) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _FloatingFilterButton extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _FloatingFilterButton({
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final background = isSelected ? const Color(0xFF2C3E50) : Colors.white;
    final foreground = isSelected ? Colors.white : const Color(0xFF2C3E50);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF2C3E50).withAlpha(90),
            width: 1.2,
          ),
        ),
        child: Icon(icon, color: foreground, size: 22),
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
              : Icon(icon!, size: 24, color: const Color(0xFF2C3E50)),
        ),
      ),
    );
  }
}

class AddedTileSelection {
  final String tileTypeName;
  final String tileSizeGroup;
  final String tileSizeName;
  double quantity;
  final TextEditingController qtyController;

  AddedTileSelection({
    required this.tileTypeName,
    required this.tileSizeGroup,
    required this.tileSizeName,
    this.quantity = 0.0,
  }) : qtyController = TextEditingController(text: quantity.toString());

  String get key =>
      '${tileTypeName.trim()}|${tileSizeGroup.trim()}|${tileSizeName.trim()}';
}

class AddedPlumbingSelection {
  final String categoryTitle;
  final String kind;
  final String materialName;
  final String? size;
  final String? length;
  final String? coverSize;
  final String unit;
  double quantity;
  final TextEditingController qtyController;

  AddedPlumbingSelection({
    required this.categoryTitle,
    required this.kind,
    required this.materialName,
    this.size,
    this.length,
    this.coverSize,
    this.unit = 'Qty.',
    this.quantity = 0.0,
  }) : qtyController = TextEditingController(text: quantity.toString());

  String get key =>
      '${categoryTitle.trim()}|${kind.trim()}|${materialName.trim()}|${(size ?? '').trim()}|${(length ?? '').trim()}|${(coverSize ?? '').trim()}';

  String get displayLabel {
    final parts = <String>[];

    final kindLabel = kind.trim();
    final s = (size ?? '').trim();
    final l = (length ?? '').trim();
    final c = (coverSize ?? '').trim();

    if (kindLabel.isNotEmpty) parts.add(kindLabel);
    if (s.isNotEmpty) parts.add(s);
    if (l.isNotEmpty) parts.add(l);
    if (c.isNotEmpty) parts.add(c);

    return parts.isEmpty
        ? materialName.trim()
        : '${materialName.trim()} • ${parts.join(' • ')}';
  }
}
