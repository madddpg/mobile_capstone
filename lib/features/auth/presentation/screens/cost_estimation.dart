import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:iconstruct/core/materials/material_recommendation_controller.dart';
import 'package:iconstruct/core/materials/models/material_category.dart';
import 'package:iconstruct/core/materials/models/material_item.dart';
import 'package:iconstruct/core/materials/services/firestore_materials_service.dart';
import 'package:iconstruct/features/auth/presentation/screens/material_estimator.dart';
import 'package:iconstruct/features/auth/presentation/screens/saved_projects.dart';
import 'package:iconstruct/features/auth/presentation/screens/main_home_screen.dart';

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

  const CostEstimationScreen({super.key, required this.projectName});

  @override
  State<CostEstimationScreen> createState() => _CostEstimationScreenState();
}

class _CostEstimationScreenState extends State<CostEstimationScreen> {
  late final MaterialRecommendationController _materials;
  final ScrollController _materialsScrollController = ScrollController();
  final PageController _categoryPageController = PageController();

  // Title of the category currently used for tile-size selection.
  // This used to be hard-coded to "Floor Surface" but Firestore categories can
  // have different titles (e.g. "Tiles").
  String? _tileCategoryTitleForTileSize;

  final List<AddedTileSelection> _addedTiles = <AddedTileSelection>[];
  final List<AddedPlumbingSelection> _addedPlumbingMaterials =
      <AddedPlumbingSelection>[];

  final Map<String, String> _selectedPlumbingMaterialKeyByKind = {};
  final Map<String, String> _selectedPlumbingSizeByKind = {};
  final Map<String, String> _selectedPlumbingLengthByKind = {};
  final Map<String, String> _selectedCoverSizeByKind = {};

  String? _selectedTileSizeGroup;

  static const String _tileSizeGroupSmall = 'Small Tiles';
  static const String _tileSizeGroupMedium = 'Medium Tiles';
  static const String _tileSizeGroupLarge = 'Large Tiles';

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
    // The UI sometimes inserts newlines into the project name for display.
    // The backend expects either a stable slug (e.g. "bathroom") or a
    // normalized name ("bathroom renovation"), so collapse whitespace.
    final projectQuery = widget.projectName
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    await _materials.loadForProject(projectQuery);

    if (!mounted) return;
    if (_isBathroomRenovationProject(projectQuery)) {
      _primeTileSizeUi();
    }
  }

  bool _isBathroomRenovationProject(String projectQuery) {
    final key = projectQuery.trim().toLowerCase();
    return key.contains('bathroom') && key.contains('renovation');
  }

  void _primeTileSizeUi() {
    if (_materials.categories.isEmpty) return;

    String? tileCategoryTitle = _tileCategoryTitleForTileSize;
    tileCategoryTitle ??= _findTileCategoryTitle();

    final nextGroup = _selectedTileSizeGroup ?? _tileSizeGroupSmall;
    final shouldUpdateState =
        (tileCategoryTitle != _tileCategoryTitleForTileSize) ||
        (nextGroup != _selectedTileSizeGroup);

    if (shouldUpdateState) {
      setState(() {
        _tileCategoryTitleForTileSize = tileCategoryTitle;
        _selectedTileSizeGroup = nextGroup;
      });
    }

    // Default to the first size option so the dropdown has a value.
    if (_materials.getSelectedForCategory('Tile Size') == null) {
      final options = _tileSizeOptionsForGroup(nextGroup);
      if (options.isNotEmpty) {
        _materials.selectItem(options.first);
      }
    }
  }

  String? _findTileCategoryTitle() {
    for (final cat in _materials.categories) {
      final titleKey = cat.title.trim().toLowerCase();
      if (titleKey.contains('tile')) return cat.title;

      final hasTileItem = cat.items.any((item) {
        final typeKey = (item.type ?? '').trim().toLowerCase();
        final nameKey = item.name.trim().toLowerCase();
        return typeKey == 'floor' && nameKey.contains('tile');
      });
      if (hasTileItem) return cat.title;
    }
    return null;
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
              _buildBackgroundPanel(context),
              _buildHeader(context),
              _buildContentCard(context),
              _buildFloatingFilter(context),
              _buildBottomNav(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackgroundPanel(BuildContext context) {
    // Beige background panel from the design: W=393, H=585, x=0, y=-178.
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
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF2C3E50),
              ),
              child: const Icon(Icons.person, color: Colors.white, size: 20),
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

  IconData getCategoryIcon(String categoryTitle) {
    final t = categoryTitle.trim().toLowerCase();

    if (t.startsWith('floor surface')) return Icons.grid_view;
    if (t.startsWith('floor installation')) return Icons.construction;

    if (t.startsWith('wall surface')) return Icons.view_agenda;
    if (t.startsWith('wall finishing')) return Icons.brush;

    // Sensible fallbacks for other project-defined categories.
    if (t.contains('installation')) return Icons.construction;
    if (t.contains('finishing')) return Icons.brush;
    if (t.contains('surface')) return Icons.grid_view;
    return Icons.category;
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
              'Based on your selections, iConstruct \nprovides the following recommendations.',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Color(0xFFE0D7C9),
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

  // Sidebar with filter options.
  Widget _buildFloatingFilter(BuildContext context) {
    return Positioned(
      top: 360,
      left: 10,
      child: FloatingFilterRail(
        selectedFilter: _materials.selectedFilter,
        onChanged: _onFilterSelected,
      ),
    );
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
              ? 'Could not load materials.\n${_materials.errorMessage}'
              : 'No materials available for this project yet.',
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: const Color(0xFFE0D7C9),
            height: 1.4,
          ),
        ),
      );
    }

    final list = _materials.filteredCategories;

    final slides = _slideshowCategories(list);
    if (slides.isEmpty) {
      return Align(
        alignment: Alignment.topLeft,
        child: Text(
          'No materials match this filter.',
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
              final isPlumbingCategory = category.title
                  .trim()
                  .toLowerCase()
                  .contains('plumb');

              final selectedName = !isPlumbingCategory
                  ? _materials.getSelectedForCategory(category.title)?.name
                  : null;

              final items = _materials.getItemsByCategory(category.title);

              return SingleChildScrollView(
                controller: _materialsScrollController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!isPlumbingCategory)
                      _FilterSection(
                        title: category.title,
                        leadingIcon: getCategoryIcon(category.title),
                        items: items,
                        selectedName: selectedName,
                        onSelect: (item) =>
                            _onMaterialSelected(category.title, item),
                      )
                    else ...[
                      Row(
                        children: [
                          Icon(
                            getCategoryIcon(category.title),
                            size: 16,
                            color: const Color(0xFFEDE4D4),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              category.title,
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
                      for (final entry in _groupItemsByKind(items).entries)
                        Builder(
                          builder: (context) {
                            final kindKey = entry.key;
                            final mapKey = '${category.title.trim()}|$kindKey';
                            final selectedPlumbing = _materials
                                .getSelectedForCategory(mapKey);
                            final selectedMaterialName = selectedPlumbing?.name;

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _FilterSection(
                                  title: entry.key,
                                  items: entry.value,
                                  selectedName: selectedMaterialName,
                                  onSelect: (item) => _onMaterialSelected(
                                    category.title,
                                    item,
                                    kindKey: kindKey,
                                  ),
                                ),
                                if (selectedPlumbing != null) ...[
                                  const SizedBox(height: 10),
                                  if (selectedPlumbing.sizes != null &&
                                      selectedPlumbing.sizes!.isNotEmpty) ...[
                                    _DropdownSection(
                                      title: 'Select size:',
                                      value: _effectivePlumbingOption(
                                        _selectedPlumbingSizeByKind[mapKey],
                                        selectedPlumbing.sizes!,
                                      ),
                                      onTap: () => _showPlumbingSizePicker(
                                        selectedPlumbing.sizes!,
                                        mapKey,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                  ],
                                  if (selectedPlumbing.lengths != null &&
                                      selectedPlumbing.lengths!.isNotEmpty) ...[
                                    _DropdownSection(
                                      title: 'Select length:',
                                      value: _effectivePlumbingOption(
                                        _selectedPlumbingLengthByKind[mapKey],
                                        selectedPlumbing.lengths!,
                                      ),
                                      onTap: () => _showPlumbingLengthPicker(
                                        selectedPlumbing.lengths!,
                                        mapKey,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                  ],
                                  if (selectedPlumbing.coverSizes != null &&
                                      selectedPlumbing
                                          .coverSizes!
                                          .isNotEmpty) ...[
                                    _DropdownSection(
                                      title: 'Select cover size:',
                                      value: _effectivePlumbingOption(
                                        _selectedCoverSizeByKind[mapKey],
                                        selectedPlumbing.coverSizes!,
                                      ),
                                      onTap: () => _showCoverSizePicker(
                                        selectedPlumbing.coverSizes!,
                                        mapKey,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                  ],
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: SizedBox(
                                      width: 110,
                                      height: 36,
                                      child: ElevatedButton(
                                        onPressed:
                                            _canAddSelectedPlumbing(mapKey)
                                            ? () => _addSelectedPlumbingToList(
                                                mapKey,
                                                category.title,
                                              )
                                            : null,
                                        style: ElevatedButton.styleFrom(
                                          padding: EdgeInsets.zero,
                                          elevation: 4,
                                          shadowColor: Colors.black54,
                                          backgroundColor: const Color(
                                            0xFFEDE4D4,
                                          ),
                                          foregroundColor: const Color(
                                            0xFF1E3042,
                                          ),
                                          disabledBackgroundColor: const Color(
                                            0xFFEDE4D4,
                                          ).withAlpha(40),
                                          disabledForegroundColor: const Color(
                                            0xFF1E3042,
                                          ).withAlpha(120),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              18,
                                            ),
                                            side: BorderSide(
                                              color: const Color(
                                                0xFF1E3042,
                                              ).withAlpha(90),
                                              width: 1.2,
                                            ),
                                          ),
                                        ),
                                        child: Text(
                                          'Add',
                                          style: GoogleFonts.poppins(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 14),
                              ],
                            );
                          },
                        ),
                      if (_addedPlumbingMaterials.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        const Divider(color: Color(0xFFEDE4D4), thickness: 1),
                        const SizedBox(height: 12),
                        Text(
                          'Added Plumbing:',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFEDE4D4),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Column(
                          children: [
                            for (final entry in _addedPlumbingMaterials)
                              _AddedMaterialItem(
                                title: entry.materialName.trim(),
                                subtitle: entry.displayLabel
                                    .replaceFirst(entry.materialName.trim(), '')
                                    .replaceFirst(' • ', '')
                                    .trim(),
                                unit: 'Qty.',
                                qtyController: entry.qtyController,
                                onChanged: (val) {
                                  entry.quantity = double.tryParse(val) ?? 0.0;
                                },
                              ),
                          ],
                        ),
                      ],
                    ],
                    if (_tileCategoryTitleForTileSize != null &&
                        category.title == _tileCategoryTitleForTileSize) ...[
                      const SizedBox(height: 12),
                      _FilterSection(
                        title: 'Tile Size',
                        leadingIcon: Icons.straighten,
                        items: const [
                          MaterialItem(
                            name: _tileSizeGroupSmall,
                            category: 'Tile Size Group',
                            description: '',
                          ),
                          MaterialItem(
                            name: _tileSizeGroupMedium,
                            category: 'Tile Size Group',
                            description: '',
                          ),
                          MaterialItem(
                            name: _tileSizeGroupLarge,
                            category: 'Tile Size Group',
                            description: '',
                          ),
                        ],
                        selectedName: _selectedTileSizeGroup,
                        onSelect: _onTileSizeGroupSelected,
                      ),
                      const SizedBox(height: 12),
                      _DropdownSection(
                        title: 'Select size:',
                        value: _selectedTileSizeValue(),
                        onTap: _showTileSizePicker,
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: SizedBox(
                          width: 110,
                          height: 36,
                          child: ElevatedButton(
                            onPressed: _canAddSelectedTile()
                                ? _addSelectedTileToList
                                : null,
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.zero,
                              elevation: 4,
                              shadowColor: Colors.black54,
                              backgroundColor: const Color(0xFFEDE4D4),
                              foregroundColor: const Color(0xFF1E3042),
                              disabledBackgroundColor: const Color(
                                0xFFEDE4D4,
                              ).withAlpha(40),
                              disabledForegroundColor: const Color(
                                0xFF1E3042,
                              ).withAlpha(120),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                                side: BorderSide(
                                  color: const Color(0xFF1E3042).withAlpha(90),
                                  width: 1.2,
                                ),
                              ),
                            ),
                            child: Text(
                              'Add',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],

                    if (_addedTiles.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Divider(color: Color(0xFFEDE4D4), thickness: 1),
                      const SizedBox(height: 12),
                      Text(
                        'Added Tiles:',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFEDE4D4),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Column(
                        children: [
                          for (final tile in _addedTiles)
                            _AddedMaterialItem(
                              title: tile.tileTypeName,
                              subtitle:
                                  '${tile.tileSizeGroup} • ${tile.tileSizeName}',
                              unit: 'Qty.',
                              qtyController: tile.qtyController,
                              onChanged: (val) {
                                tile.quantity = double.tryParse(val) ?? 0.0;
                              },
                            ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 20),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 28),
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
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MaterialEstimatorScreen(
                      projectName: widget.projectName,
                      tiles: _addedTiles,
                      plumbingMaterials: _addedPlumbingMaterials,
                    ),
                  ),
                );
              },
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

  List<MaterialCategory> _slideshowCategories(List<MaterialCategory> input) {
    final projectQuery = widget.projectName
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (!_isBathroomRenovationProject(projectQuery)) return input;

    final tiles = <MaterialCategory>[];
    final plumbing = <MaterialCategory>[];
    final rest = <MaterialCategory>[];

    for (final cat in input) {
      final key = cat.title.trim().toLowerCase();
      if (key.contains('tile')) {
        tiles.add(cat);
      } else if (key.contains('plumb')) {
        plumbing.add(cat);
      } else {
        rest.add(cat);
      }
    }

    return <MaterialCategory>[...tiles, ...plumbing, ...rest];
  }

  Map<String, List<MaterialItem>> _groupItemsByKind(List<MaterialItem> items) {
    final grouped = <String, List<MaterialItem>>{};

    for (final item in items) {
      final rawKind = (item.kind ?? '').trim();
      final key = rawKind.isEmpty ? 'Others' : rawKind;
      grouped.putIfAbsent(key, () => <MaterialItem>[]).add(item);
    }

    return grouped;
  }

  String _selectedTileSizeValue() {
    final group = _selectedTileSizeGroup;
    if (group == null) return '';

    final options = _tileSizeOptionsForGroup(group);
    if (options.isEmpty) return '';

    final selected = _materials.getSelectedForCategory('Tile Size');
    if (selected == null) return options.first.name;

    final isInGroup = options.any((e) => e.name == selected.name);
    return isInGroup ? selected.name : options.first.name;
  }

  List<MaterialItem> _tileSizeOptionsForGroup(String group) {
    if (group == _tileSizeGroupSmall) {
      return const [
        MaterialItem(
          name: '25 × 25 mm',
          category: 'Tile Size',
          description: '1” × 1”',
        ),
        MaterialItem(
          name: '50 × 50 mm',
          category: 'Tile Size',
          description: '2” × 2”',
        ),
        MaterialItem(
          name: '100 × 100 mm',
          category: 'Tile Size',
          description: '4” × 4”',
        ),
      ];
    }

    if (group == _tileSizeGroupMedium) {
      return const [
        MaterialItem(
          name: '200 × 200 mm',
          category: 'Tile Size',
          description: '8” × 8”',
        ),
        MaterialItem(
          name: '300 × 300 mm',
          category: 'Tile Size',
          description: '12” × 12”',
        ),
        MaterialItem(
          name: '300 × 600 mm',
          category: 'Tile Size',
          description: '12” × 24”',
        ),
      ];
    }

    if (group == _tileSizeGroupLarge) {
      return const [
        MaterialItem(
          name: '600 × 600 mm',
          category: 'Tile Size',
          description: '24” × 24”',
        ),
        MaterialItem(
          name: '600 × 1200 mm',
          category: 'Tile Size',
          description: '24” × 48”',
        ),
        MaterialItem(
          name: '800 × 800 mm',
          category: 'Tile Size',
          description: '',
        ),
        MaterialItem(
          name: '1200 × 1200 mm',
          category: 'Tile Size',
          description: '',
        ),
      ];
    }

    return const <MaterialItem>[];
  }

  String _tileSizeGroupDescription(String group) {
    if (group == _tileSizeGroupSmall) {
      return 'Small Tile Sizes\n\n'
          'Used for decorative areas, mosaics, and detailed designs.\n\n'
          'Sizes:\n'
          '• 25 × 25 mm (1” × 1”)\n'
          '• 50 × 50 mm (2” × 2”)\n'
          '• 100 × 100 mm (4” × 4”)\n\n'
          'Common for: shower floors (better grip), accent walls, mosaic designs.';
    }

    if (group == _tileSizeGroupMedium) {
      return 'Medium Tile Sizes\n\n'
          'Most commonly used tiles in bathrooms.\n\n'
          'Sizes:\n'
          '• 200 × 200 mm (8” × 8”)\n'
          '• 300 × 300 mm (12” × 12”)\n'
          '• 300 × 600 mm (12” × 24”)\n\n'
          'Common for: bathroom walls, main floors, shower walls.\n'
          'Easy to install and balances aesthetics with practicality.';
    }

    return 'Large Tile Sizes\n\n'
        'Used for a modern, spacious, and seamless look.\n\n'
        'Sizes:\n'
        '• 600 × 600 mm (24” × 24”)\n'
        '• 600 × 1200 mm (24” × 48”)\n'
        '• 800 × 800 mm\n'
        '• 1200 × 1200 mm\n\n'
        'Common for: large bathroom floors, minimal grout lines (cleaner look).\n'
        'Best for bigger bathrooms.';
  }

  void _onTileSizeGroupSelected(MaterialItem item) {
    final group = item.name;
    if (group != _tileSizeGroupSmall &&
        group != _tileSizeGroupMedium &&
        group != _tileSizeGroupLarge) {
      return;
    }

    setState(() {
      _selectedTileSizeGroup = group;

      final options = _tileSizeOptionsForGroup(group);
      if (options.isNotEmpty) {
        _materials.selectItem(options.first);
      }
    });

    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFFEDE4D4),
          title: Text(
            '$group Sizes',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF2C3E50),
            ),
          ),
          content: Text(
            _tileSizeGroupDescription(group),
            style: GoogleFonts.poppins(
              fontSize: 13,
              height: 1.4,
              color: const Color(0xFF2C3E50),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Close',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF2C3E50),
                ),
              ),
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        );
      },
    );
  }

  void _onMaterialSelected(
    String categoryTitle,
    MaterialItem item, {
    String? kindKey,
  }) {
    final effectiveCategoryKey = kindKey != null
        ? '${categoryTitle.trim()}|$kindKey'
        : categoryTitle;

    _selectMaterial(
      item,
      categoryKey: effectiveCategoryKey,
      showDescriptionModal: true,
    );

    final titleKey = categoryTitle.trim().toLowerCase();
    if (titleKey.contains('plumb')) {
      _primePlumbingOptionUi(effectiveCategoryKey, item);
    }

    final type = (item.type ?? '').trim().toLowerCase();
    final itemCategoryKey = item.category.trim().toLowerCase();
    final nameKey = item.name.trim().toLowerCase();

    // Heuristic: show tile size selection for floor tile categories.
    if (type == 'floor' &&
        (itemCategoryKey.contains('tile') || nameKey.contains('tile'))) {
      setState(() {
        _tileCategoryTitleForTileSize = categoryTitle;
        _selectedTileSizeGroup ??= _tileSizeGroupSmall;
      });

      _primeTileSizeUi();
    }
  }

  bool _canAddSelectedTile() {
    final categoryTitle = _tileCategoryTitleForTileSize;
    if (categoryTitle == null) return false;

    final tileType = _materials.getSelectedForCategory(categoryTitle);
    final group = _selectedTileSizeGroup;
    if (tileType == null) return false;
    if (group == null) return false;
    final sizeName = _selectedTileSizeValue().trim();
    if (sizeName.isEmpty) return false;
    return true;
  }

  void _addSelectedTileToList() {
    final categoryTitle = _tileCategoryTitleForTileSize;
    if (categoryTitle == null) return;

    final tileType = _materials.getSelectedForCategory(categoryTitle);
    final group = _selectedTileSizeGroup;
    if (tileType == null || group == null) return;

    final sizeOptions = _tileSizeOptionsForGroup(group);
    if (sizeOptions.isEmpty) return;

    final selectedSize = _materials.getSelectedForCategory('Tile Size');
    final size =
        (selectedSize != null &&
            sizeOptions.any((e) => e.name == selectedSize.name))
        ? selectedSize
        : sizeOptions.first;

    final selection = AddedTileSelection(
      tileTypeName: tileType.name,
      tileSizeGroup: group,
      tileSizeName: size.name,
    );

    setState(() {
      final alreadyAdded = _addedTiles.any((e) => e.key == selection.key);
      if (!alreadyAdded) {
        _addedTiles.add(selection);
      }
    });
  }

  bool _canAddSelectedPlumbing(String mapKey) {
    final selected = _materials.getSelectedForCategory(mapKey);
    if (selected == null) return false;
    if (selected.name.trim().isEmpty) return false;

    final sizes = selected.sizes;
    final lengths = selected.lengths;
    final coverSizes = selected.coverSizes;

    if (sizes != null && sizes.isEmpty) return false;
    if (lengths != null && lengths.isEmpty) return false;
    if (coverSizes != null && coverSizes.isEmpty) return false;

    return true;
  }

  void _addSelectedPlumbingToList(String mapKey, String categoryTitle) {
    final selected = _materials.getSelectedForCategory(mapKey);
    if (selected == null) return;

    final size = _selectedPlumbingSizeByKind[mapKey];
    final length = _selectedPlumbingLengthByKind[mapKey];
    final coverSize = _selectedCoverSizeByKind[mapKey];

    final effectiveSize = (selected.sizes != null && selected.sizes!.isNotEmpty)
        ? _effectivePlumbingOption(size, selected.sizes!)
        : null;
    final effectiveLength =
        (selected.lengths != null && selected.lengths!.isNotEmpty)
        ? _effectivePlumbingOption(length, selected.lengths!)
        : null;
    final effectiveCoverSize =
        (selected.coverSizes != null && selected.coverSizes!.isNotEmpty)
        ? _effectivePlumbingOption(coverSize, selected.coverSizes!)
        : null;

    final selection = AddedPlumbingSelection(
      categoryTitle: categoryTitle,
      kind: (selected.kind ?? '').trim(),
      materialName: selected.name,
      size: effectiveSize,
      length: effectiveLength,
      coverSize: effectiveCoverSize,
    );

    setState(() {
      final alreadyAdded = _addedPlumbingMaterials.any(
        (e) => e.key == selection.key,
      );
      if (!alreadyAdded) {
        _addedPlumbingMaterials.add(selection);
      }
    });
  }

  String _effectivePlumbingOption(String? current, List<String> options) {
    if (options.isEmpty) return '';
    final v = (current ?? '').trim();
    if (v.isNotEmpty && options.contains(v)) return v;
    return options.first;
  }

  void _primePlumbingOptionUi(String mapKey, MaterialItem item) {
    final itemKey = '${mapKey.trim()}|${item.name.trim()}';
    final isNewItem = itemKey != _selectedPlumbingMaterialKeyByKind[mapKey];

    final sizes = item.sizes ?? const <String>[];
    final lengths = item.lengths ?? const <String>[];
    final coverSizes = item.coverSizes ?? const <String>[];

    setState(() {
      _selectedPlumbingMaterialKeyByKind[mapKey] = itemKey;

      if (sizes.isEmpty) {
        _selectedPlumbingSizeByKind.remove(mapKey);
      } else if (isNewItem ||
          !_isOptionValid(_selectedPlumbingSizeByKind[mapKey], sizes)) {
        _selectedPlumbingSizeByKind[mapKey] = sizes.first;
      }

      if (lengths.isEmpty) {
        _selectedPlumbingLengthByKind.remove(mapKey);
      } else if (isNewItem ||
          !_isOptionValid(_selectedPlumbingLengthByKind[mapKey], lengths)) {
        _selectedPlumbingLengthByKind[mapKey] = lengths.first;
      }

      if (coverSizes.isEmpty) {
        _selectedCoverSizeByKind.remove(mapKey);
      } else if (isNewItem ||
          !_isOptionValid(_selectedCoverSizeByKind[mapKey], coverSizes)) {
        _selectedCoverSizeByKind[mapKey] = coverSizes.first;
      }
    });
  }

  bool _isOptionValid(String? current, List<String> options) {
    final v = (current ?? '').trim();
    return v.isNotEmpty && options.contains(v);
  }

  void _selectMaterial(
    MaterialItem item, {
    String? categoryKey,
    required bool showDescriptionModal,
  }) {
    setState(() {
      if (categoryKey == null || categoryKey.trim().isEmpty) {
        _materials.selectItem(item);
      } else {
        _materials.selectItemForCategory(categoryKey, item);
      }
    });

    if (!showDescriptionModal) return;
    _showMaterialDescription(item);
  }

  void _showMaterialDescription(MaterialItem item) {
    final description = item.description.trim();
    final imageUrl = (item.imageUrl ?? '').trim();
    if (description.isEmpty && imageUrl.isEmpty) return;

    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFFEDE4D4),
          title: Text(
            item.name,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF2C3E50),
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (imageUrl.isNotEmpty) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(
                            child: SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Color(0xFF2C3E50),
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: const Color(0xFF2C3E50).withAlpha(15),
                            alignment: Alignment.center,
                            child: Text(
                              'Could not load image.',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: const Color(0xFF2C3E50),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                if (description.isNotEmpty)
                  Text(
                    description,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      height: 1.4,
                      color: const Color(0xFF2C3E50),
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Close',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF2C3E50),
                ),
              ),
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        );
      },
    );
  }

  void _showTileSizePicker() {
    final group = _selectedTileSizeGroup;
    if (group == null) return;

    final options = _tileSizeOptionsForGroup(group);
    if (options.isEmpty) return;

    showDialog<void>(
      context: context,
      builder: (context) {
        return SimpleDialog(
          backgroundColor: const Color(0xFFEDE4D4),
          title: Text(
            'Select size',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF2C3E50),
            ),
          ),
          children: [
            for (final item in options)
              SimpleDialogOption(
                onPressed: () {
                  Navigator.of(context).pop();
                  _selectMaterial(item, showDescriptionModal: false);
                },
                child: Text(
                  item.description.trim().isNotEmpty
                      ? '${item.name} (${item.description})'
                      : item.name,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: const Color(0xFF2C3E50),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  void _showPlumbingSizePicker(List<String> options, String mapKey) {
    if (options.isEmpty) return;

    showDialog<void>(
      context: context,
      builder: (context) {
        return SimpleDialog(
          backgroundColor: const Color(0xFFEDE4D4),
          title: Text(
            'Select size',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF2C3E50),
            ),
          ),
          children: [
            for (final size in options)
              SimpleDialogOption(
                onPressed: () {
                  Navigator.of(context).pop();
                  setState(() {
                    _selectedPlumbingSizeByKind[mapKey] = size;
                  });
                },
                child: Text(
                  size,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: const Color(0xFF2C3E50),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  void _showPlumbingLengthPicker(List<String> options, String mapKey) {
    if (options.isEmpty) return;

    showDialog<void>(
      context: context,
      builder: (context) {
        return SimpleDialog(
          backgroundColor: const Color(0xFFEDE4D4),
          title: Text(
            'Select length',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF2C3E50),
            ),
          ),
          children: [
            for (final length in options)
              SimpleDialogOption(
                onPressed: () {
                  Navigator.of(context).pop();
                  setState(() {
                    _selectedPlumbingLengthByKind[mapKey] = length;
                  });
                },
                child: Text(
                  length,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: const Color(0xFF2C3E50),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  void _showCoverSizePicker(List<String> options, String mapKey) {
    if (options.isEmpty) return;

    showDialog<void>(
      context: context,
      builder: (context) {
        return SimpleDialog(
          backgroundColor: const Color(0xFFEDE4D4),
          title: Text(
            'Select cover size',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF2C3E50),
            ),
          ),
          children: [
            for (final size in options)
              SimpleDialogOption(
                onPressed: () {
                  Navigator.of(context).pop();
                  setState(() {
                    _selectedCoverSizeByKind[mapKey] = size;
                  });
                },
                child: Text(
                  size,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: const Color(0xFF2C3E50),
                  ),
                ),
              ),
          ],
        );
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
            GestureDetector(
              onTap: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MainHomeScreen(),
                  ),
                  (route) => false,
                );
              },
              child: const _BottomNavItem(
                icon: Icons.home_rounded,
                label: 'Home',
                isActive: true,
              ),
            ),
            const SizedBox(width: 10),
            _BottomIconButton(
              imagePath: 'assets/images/hammer.png',
              onTap: () {},
            ),
            const SizedBox(width: 10),
            _BottomIconButton(
              icon: Icons.calculate_rounded,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MaterialEstimatorScreen(
                      projectName: widget.projectName,
                      tiles: _addedTiles,
                      plumbingMaterials: _addedPlumbingMaterials,
                    ),
                  ),
                );
              },
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
    final isTileSection = title.trim().toLowerCase().contains('tile');
    final headerGap = isTileSection ? 6.0 : 10.0;

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
        SizedBox(height: headerGap),
        Column(
          children: [
            for (int i = 0; i < items.length; i++) ...[
              _MaterialCardOption(
                item: items[i],
                isSelected: items[i].name == selectedName,
                onTap: () => onSelect(items[i]),
                showDescriptionLine:
                    items[i].category == 'Tile Size' &&
                    items[i].description.trim().isNotEmpty,
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
  final bool showDescriptionLine;

  const _MaterialCardOption({
    required this.item,
    required this.isSelected,
    required this.onTap,
    required this.showDescriptionLine,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = (item.imageUrl ?? '').trim();
    final title = item.name.trim();
    final subtitle = showDescriptionLine ? item.description.trim() : '';
    final showImage = !item.category.contains('Tile Size');

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
            if (showImage) ...[
              _MaterialThumb(imageUrl: imageUrl),
              const SizedBox(width: 12),
            ],
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
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFEDE4D4),
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
          ],
        ),
      ),
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

  const _AddedMaterialItem({
    required this.title,
    required this.subtitle,
    required this.qtyController,
    required this.unit,
    required this.onChanged,
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
          // Quantity Input
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
                      hintText: 'Enter quantity (optional)',
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
                Container(
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

class _DropdownSection extends StatelessWidget {
  final String title;
  final String value;
  final VoidCallback onTap;

  const _DropdownSection({
    required this.title,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFFEDE4D4),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: 134,
          height: 36,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1E3042),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFEDE4D4), width: 3),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    value,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: const Color(0xFFEDE4D4).withAlpha(191),
                    ),
                  ),
                  const Icon(
                    Icons.keyboard_arrow_down,
                    color: Color(0xFFEDE4D4),
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
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
  }) : qtyController = TextEditingController();

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
  double quantity;
  final TextEditingController qtyController;

  AddedPlumbingSelection({
    required this.categoryTitle,
    required this.kind,
    required this.materialName,
    this.size,
    this.length,
    this.coverSize,
    this.quantity = 0.0,
  }) : qtyController = TextEditingController();

  String get key =>
      '${categoryTitle.trim()}|${kind.trim()}|${materialName.trim()}|${(size ?? '').trim()}|${(length ?? '').trim()}|${(coverSize ?? '').trim()}';

  String get displayLabel {
    final kindLabel = kind.trim().isEmpty ? 'Others' : kind.trim();
    final parts = <String>[materialName.trim(), kindLabel];
    final s = (size ?? '').trim();
    final l = (length ?? '').trim();
    final c = (coverSize ?? '').trim();
    if (s.isNotEmpty) parts.add(s);
    if (l.isNotEmpty) parts.add(l);
    if (c.isNotEmpty) parts.add(c);
    return parts.join(' • ');
  }
}
