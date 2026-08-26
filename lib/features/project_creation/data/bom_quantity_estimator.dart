import 'package:iconstruct/features/project_creation/data/ph_renovation_rates.dart';
import 'package:iconstruct/features/project_creation/data/renovation_scope.dart';
import 'package:iconstruct/features/project_creation/data/renovation_templates.dart';

/// Scales template BOM quantities from a project area (sqm) using Philippine DPWH/NSCP standards.
class BomQuantityEstimator {
  BomQuantityEstimator._();

  static List<RenovationTemplateItem> scaleTemplate({
    required RenovationTemplate template,
    required double areaSqm,
    RenovationScope scope = RenovationScope.fullRenovation,
  }) {
    final area = areaSqm <= 0 ? 1.0 : areaSqm;
    final items = <RenovationTemplateItem>[];

    for (final item in template.items) {
      // Filter structural items if Full Renovation scope
      if (!scope.includesStructural && _isStructuralOnlyItem(item)) {
        continue;
      }

      final scaledQty = estimateQuantity(item: item, areaSqm: area);
      items.add(
        ensureSwappable(
          item.copyWith(
            defaultQuantity: scaledQty,
          ),
        ),
      );
    }

    // Add Master Foreman Auxiliary Consumables if not present (skip for AI consultation templates)
    if (template.id != 'ai_consultation_bom' && !template.id.contains('consultation')) {
      _addForemanAuxiliaries(items, area, scope);
    }

    return items;
  }

  static bool _isStructuralOnlyItem(RenovationTemplateItem item) {
    final name = item.name.toLowerCase();
    final cat = item.category.toLowerCase();
    return name.contains('gravel') ||
        name.contains('chb') ||
        name.contains('rebar') ||
        name.contains('roofing sheet') ||
        name.contains('purlin') ||
        name.contains('plywood') ||
        name.contains('coco lumber') ||
        name.contains('wire nail') ||
        cat.contains('structural') ||
        cat.contains('roofing framing');
  }

  /// Appends Master Foreman auxiliary items (Spacers, Teflon Tape, Silicone, Sandpaper, Roller Sets)
  static void _addForemanAuxiliaries(
    List<RenovationTemplateItem> items,
    double areaSqm,
    RenovationScope scope,
  ) {
    final names = items.map((i) => i.name.toLowerCase()).toSet();
    final aux = PhRenovationRates.calculateForemanAuxiliaries(
      areaSqm: areaSqm,
      isExtension: scope.includesStructural,
    );

    if (!names.any((n) => n.contains('spacer'))) {
      items.add(
        const RenovationTemplateItem(
          name: 'Tile Cross Spacers (2mm/3mm)',
          category: 'Installation & Auxiliaries',
          unit: 'packs',
          defaultQuantity: 1,
          qtyPerSqm: 0.10,
          notes: 'Foreman essential — keeps tile joint lines uniform',
        ),
      );
    }

    if (!names.any((n) => n.contains('teflon'))) {
      items.add(
        const RenovationTemplateItem(
          name: 'Teflon Threadseal Tape (3/4")',
          category: 'Plumbing Supplies',
          unit: 'rolls',
          defaultQuantity: 2,
          notes: 'Foreman essential — prevents faucet & valve thread leaks',
        ),
      );
    }

    if (!names.any((n) => n.contains('silicone'))) {
      items.add(
        const RenovationTemplateItem(
          name: 'Sanitary Silicone Sealant (300ml)',
          category: 'Plumbing Supplies',
          unit: 'tubes',
          defaultQuantity: 1,
          notes: 'Foreman essential — seals sink rim & toilet base',
        ),
      );
    }

    if (!names.any((n) => n.contains('sandpaper'))) {
      items.add(
        const RenovationTemplateItem(
          name: 'Assorted Sandpaper (Grit 100/180)',
          category: 'Painting Supplies',
          unit: 'sheets',
          defaultQuantity: 4,
          notes: 'Foreman essential — for smoothing skim coat & putty',
        ),
      );
    }

    if (!names.any((n) => n.contains('roller'))) {
      items.add(
        const RenovationTemplateItem(
          name: 'Paint Roller Set (7") with Tray',
          category: 'Painting Supplies',
          unit: 'set',
          defaultQuantity: 1,
          notes: 'Foreman essential — for latex wall painting',
        ),
      );
    }

    if (scope.includesStructural) {
      if (!names.any((n) => n.contains('plywood'))) {
        items.add(
          RenovationTemplateItem(
            name: 'Marine Plywood 1/2" (4\'x8\')',
            category: 'Formwork & Structural',
            unit: 'sheets',
            defaultQuantity: aux['marinePlywoodSheets'] as double? ?? 2.0,
            notes: 'Foreman essential — slab & column concrete formwork',
          ),
        );
      }
      if (!names.any((n) => n.contains('coco lumber'))) {
        items.add(
          RenovationTemplateItem(
            name: 'Coco Lumber (2"x2" & 2"x3")',
            category: 'Formwork & Structural',
            unit: 'bd.ft',
            defaultQuantity: aux['cocoLumberBdFt'] as double? ?? 30.0,
            notes: 'Foreman essential — form joists & vertical shoring',
          ),
        );
      }
      if (!names.any((n) => n.contains('nail'))) {
        items.add(
          RenovationTemplateItem(
            name: 'Common Wire Nails (CWN Assorted)',
            category: 'Formwork & Structural',
            unit: 'kg',
            defaultQuantity: aux['cwnNailsKg'] as double? ?? 2.0,
            notes: 'Foreman essential — formwork assembly nails',
          ),
        );
      }
    }
  }

  /// Calculates material quantity according to Philippine DPWH/NSCP mathematical formulas.
  static double estimateQuantity({
    required RenovationTemplateItem item,
    required double areaSqm,
  }) {
    final area = areaSqm <= 0 ? 1.0 : areaSqm;
    final name = item.name.toLowerCase();
    final cat = item.category.toLowerCase();
    final sizeKey = item.size ?? '';

    // 1. Wall Tiles (Wall Area = 2.2x floor area)
    if (name.contains('wall tile') || cat.contains('wall surface')) {
      final wallArea = area * 2.2;
      return PhRenovationRates.calculateWallTilePieces(wallArea, sizeKey);
    }

    // 2. Floor Tiles
    if (name.contains('floor tile') || name.contains('tile') || cat.contains('floor surface') || cat.contains('flooring')) {
      if (!name.contains('adhesive') && !name.contains('grout')) {
        return PhRenovationRates.calculateFloorTilePieces(area, sizeKey);
      }
    }

    // 3. Tile Adhesive
    if (name.contains('adhesive')) {
      return PhRenovationRates.calculateTileAdhesiveBags(area);
    }

    // 4. Tile Grout
    if (name.contains('grout')) {
      return PhRenovationRates.calculateTileGroutPacks(area, sizeKey);
    }

    // 5. Paint / Primer / Skim Coat
    if (name.contains('paint') || name.contains('primer') || name.contains('skim')) {
      final p = PhRenovationRates.calculatePaintWorks(area);
      if (name.contains('primer')) return p.primerGal;
      if (name.contains('skim')) return p.skimCoatBags;
      return p.totalGal;
    }

    // 6. Portland Cement (Screed bedding vs Slab)
    if (name.contains('cement')) {
      if (cat.contains('structural') || cat.contains('concrete')) {
        return PhRenovationRates.calculateStructuralConcreteSlab(area, sizeKey.isEmpty ? '100mm' : sizeKey).cementBags;
      }
      return PhRenovationRates.calculateTileBeddingMortar(area).cementBags;
    }

    // 7. Washed Sand
    if (name.contains('sand')) {
      return PhRenovationRates.calculateTileBeddingMortar(area).sandCum;
    }

    // 8. CHB Masonry (Extension)
    if (name.contains('chb')) {
      final wallArea = area * 2.2;
      return PhRenovationRates.calculateChbPieces(wallArea);
    }

    // 9. Rebar (Extension)
    if (name.contains('rebar')) {
      final wallArea = area * 2.2;
      return PhRenovationRates.calculateChbRebar(wallArea, sizeKey.isEmpty ? '10mm' : sizeKey).commercialBars.toDouble();
    }

    // Fixed-count items or items with direct qtyPerSqm
    if (item.qtyPerSqm == null || item.qtyPerSqm! <= 0) {
      return item.defaultQuantity <= 0 ? 1 : item.defaultQuantity;
    }

    final raw = item.qtyPerSqm! * area;
    final withWaste = raw * 1.08;
    return withWaste < 1 ? 1.0 : withWaste.ceilToDouble();
  }

  /// Recalculates quantity live when user picks a different size in the BOM review.
  static ({double newQty, String formulaString}) recalculateForSize({
    required RenovationTemplateItem item,
    required String newSize,
    required double areaSqm,
  }) {
    final area = areaSqm <= 0 ? 1.0 : areaSqm;
    final name = item.name.toLowerCase();
    final cat = item.category.toLowerCase();

    // Wall Tiles
    if (name.contains('wall tile') || cat.contains('wall surface')) {
      final wallArea = area * 2.2;
      final pcs = PhRenovationRates.calculateWallTilePieces(wallArea, newSize);
      final formula = PhRenovationRates.wallTileFormulaString(wallArea, newSize, pcs);
      return (newQty: pcs, formulaString: formula);
    }

    // Floor Tiles
    if (name.contains('floor tile') || name.contains('tile') || cat.contains('floor surface')) {
      final pcs = PhRenovationRates.calculateFloorTilePieces(area, newSize);
      final formula = PhRenovationRates.floorTileFormulaString(area, newSize, pcs);
      return (newQty: pcs, formulaString: formula);
    }

    // Tile Grout
    if (name.contains('grout')) {
      final packs = PhRenovationRates.calculateTileGroutPacks(area, newSize);
      final formula = PhRenovationRates.tileGroutFormulaString(area, newSize, packs);
      return (newQty: packs, formulaString: formula);
    }

    // CHB Masonry
    if (name.contains('chb')) {
      final wallArea = area * 2.2;
      final pcs = PhRenovationRates.calculateChbPieces(wallArea);
      final formula = PhRenovationRates.chbFormulaString(wallArea, pcs);
      return (newQty: pcs, formulaString: formula);
    }

    // Rebar
    if (name.contains('rebar')) {
      final wallArea = area * 2.2;
      final calc = PhRenovationRates.calculateChbRebar(wallArea, newSize);
      final formula = PhRenovationRates.rebarFormulaString(wallArea, newSize, calc.commercialBars);
      return (newQty: calc.commercialBars.toDouble(), formulaString: formula);
    }

    // Concrete Slab
    if (name.contains('cement') && (cat.contains('structural') || cat.contains('concrete'))) {
      final calc = PhRenovationRates.calculateStructuralConcreteSlab(area, newSize);
      final formula = PhRenovationRates.structuralCementFormulaString(area, newSize, calc.cementBags);
      return (newQty: calc.cementBags, formulaString: formula);
    }

    final stdQty = estimateQuantity(item: item.copyWith(size: newSize), areaSqm: area);
    return (newQty: stdQty, formulaString: 'Calculated using DPWH standard equations.');
  }

  /// Returns formula transparency string for displaying on material cards
  static String getFormulaString({
    required RenovationTemplateItem item,
    required double areaSqm,
    required double currentQty,
  }) {
    final area = areaSqm <= 0 ? 1.0 : areaSqm;
    final name = item.name.toLowerCase();
    final sizeKey = item.size ?? '';

    if (name.contains('wall tile')) {
      return PhRenovationRates.wallTileFormulaString(area * 2.2, sizeKey, currentQty);
    }
    if (name.contains('floor tile') || name.contains('tile')) {
      return PhRenovationRates.floorTileFormulaString(area, sizeKey, currentQty);
    }
    if (name.contains('adhesive')) {
      return PhRenovationRates.tileAdhesiveFormulaString(area, currentQty);
    }
    if (name.contains('grout')) {
      return PhRenovationRates.tileGroutFormulaString(area, sizeKey, currentQty);
    }
    if (name.contains('paint')) {
      return PhRenovationRates.paintFormulaString(area, currentQty);
    }
    if (name.contains('skim')) {
      return PhRenovationRates.skimCoatFormulaString(area, currentQty);
    }
    if (name.contains('cement')) {
      return PhRenovationRates.beddingCementFormulaString(area, currentQty);
    }
    if (name.contains('sand')) {
      return PhRenovationRates.beddingSandFormulaString(area, currentQty);
    }
    if (name.contains('chb')) {
      return PhRenovationRates.chbFormulaString(area * 2.2, currentQty);
    }
    if (name.contains('rebar')) {
      return PhRenovationRates.rebarFormulaString(area * 2.2, sizeKey, currentQty.toInt());
    }

    return '${area.toStringAsFixed(1)} sq.m × standard rate = ${currentQty.toInt()} ${item.unit}\n(Standard: DPWH / Max Fajardo Estimates)';
  }

  /// Ensures every essential material can be drag/tap-swapped to an alternative.
  static RenovationTemplateItem ensureSwappable(RenovationTemplateItem item) {
    if (item.alternatives.isNotEmpty) {
      return item.copyWith(isSwappable: true);
    }
    final alts = defaultAlternativesFor(item);
    if (alts.isEmpty) {
      return item.copyWith(isSwappable: true, alternatives: [
        MaterialAlternative(name: item.name, size: item.size),
        MaterialAlternative(name: 'Premium ${item.name}'),
        MaterialAlternative(name: 'Economy ${item.name}'),
      ]);
    }
    return item.copyWith(isSwappable: true, alternatives: alts);
  }

  static List<MaterialAlternative> defaultAlternativesFor(RenovationTemplateItem item) {
    final name = item.name.toLowerCase();
    final cat = item.category.toLowerCase();

    if (name.contains('wall tile') || name.contains('backsplash') || cat.contains('wall surface')) {
      return const [
        MaterialAlternative(name: 'Subway Wall Tiles', size: '75x300'),
        MaterialAlternative(name: 'Ceramic Wall Tiles', size: '300x600'),
        MaterialAlternative(name: 'Large-format Wall Tiles', size: '600x1200'),
      ];
    }
    if (name.contains('tile') || name.contains('vinyl') || name.contains('flooring') || cat.contains('floor')) {
      return const [
        MaterialAlternative(name: 'Ceramic Floor Tiles', size: '600x600'),
        MaterialAlternative(name: 'Porcelain Floor Tiles', size: '600x600'),
        MaterialAlternative(name: 'Vinyl Flooring Planks'),
        MaterialAlternative(name: 'Non-Slip Floor Tiles', size: '300x300'),
      ];
    }
    if (name.contains('paint') || cat.contains('paint')) {
      return const [
        MaterialAlternative(name: 'Matte Interior Paint'),
        MaterialAlternative(name: 'Semi-Gloss Interior Paint'),
        MaterialAlternative(name: 'Eggshell Interior Paint'),
      ];
    }
    return const [];
  }

  static RenovationTemplate buildConsultationTemplate({
    required String projectType,
    required String style,
    required double areaSqm,
    required List<String> materialNames,
  }) {
    final names = <String>[];
    final seen = <String>{};
    for (final raw in materialNames) {
      for (final name in expandVagueMaterialName(raw.trim())) {
        if (name.isEmpty) continue;
        if (seen.add(name.toLowerCase())) names.add(name);
      }
    }

    if (names.isEmpty) {
      names.addAll(_defaultBasicsForType(projectType));
    }

    final items = names.map((raw) {
      final detail = _splitNameAndDetail(raw);
      final name = detail.name;
      final lower = name.toLowerCase();
      final isSurface = lower.contains('tile') || lower.contains('paint') || lower.contains('floor') || lower.contains('vinyl') || lower.contains('waterproof');
      final unit = lower.contains('paint') || lower.contains('primer') ? 'gal' : (lower.contains('adhesive') || lower.contains('grout') || lower.contains('cement')) ? 'bags' : isSurface ? 'pcs' : 'pcs';

      return ensureSwappable(
        RenovationTemplateItem(
          name: name,
          category: _guessCategory(name),
          unit: unit,
          defaultQuantity: 1,
          qtyPerSqm: 1.0,
          size: detail.size,
          notes: detail.notes,
        ),
      );
    }).toList();

    final scaled = scaleTemplate(
      template: RenovationTemplate(
        id: 'ai_consultation_bom',
        renovationType: projectType,
        style: style.isEmpty ? 'custom' : style,
        name: 'AI Essential BOM',
        description: 'Built from materials you confirmed in consultation.',
        items: items,
      ),
      areaSqm: areaSqm,
    );

    return RenovationTemplate(
      id: 'ai_consultation_bom',
      renovationType: projectType,
      style: style.isEmpty ? 'custom' : style,
      name: 'AI Essential BOM',
      description: 'Built from materials you confirmed in consultation.',
      items: scaled,
    );
  }

  static ({String name, String? size, String? notes}) _splitNameAndDetail(String raw) {
    final match = RegExp(r'^(.*?)\s*\(([^)]*)\)\s*$').firstMatch(raw.trim());
    if (match == null) return (name: raw.trim(), size: null, notes: null);
    final name = match.group(1)?.trim() ?? '';
    final detail = match.group(2)?.trim() ?? '';

    final parts = detail.split(',');
    if (parts.length > 1) {
      final size = parts[0].trim();
      final notes = parts.sublist(1).join(',').trim();
      return (
        name: name.isEmpty ? raw.trim() : name,
        size: size.isEmpty ? null : size,
        notes: notes.isEmpty ? null : notes,
      );
    }

    return (name: name.isEmpty ? raw.trim() : name, size: detail.isEmpty ? null : detail, notes: null);
  }

  static List<String> expandVagueMaterialName(String raw) {
    final lower = raw.trim().toLowerCase();
    if (lower == 'flooring' ||
        lower == 'tile' ||
        lower == 'tiles' ||
        lower.contains('essential materials for flooring')) {
      return const ['Ceramic floor tiles', 'Tile adhesive', 'Tile grout'];
    }
    if (lower == 'painting' ||
        lower == 'paint' ||
        lower.contains('essential materials for painting')) {
      return const ['Interior wall paint', 'Wall primer', 'Paint roller set'];
    }
    return [raw];
  }

  static List<String> _defaultBasicsForType(String projectType) {
    return const ['Ceramic floor tiles', 'Tile adhesive', 'Tile grout', 'Interior wall paint'];
  }

  static String _guessCategory(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('tile') || lower.contains('floor')) return 'Floor Surface';
    if (lower.contains('paint') || lower.contains('wall')) return 'Wall Finishing';
    return 'General';
  }
}
