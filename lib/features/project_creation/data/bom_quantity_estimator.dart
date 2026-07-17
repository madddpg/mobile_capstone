import 'package:iconstruct/features/project_creation/data/renovation_templates.dart';

/// Scales template BOM quantities from a project area (sqm).
class BomQuantityEstimator {
  BomQuantityEstimator._();

  /// Waste factor for surface materials (tiles, paint coverage buffer).
  static const double surfaceWasteFactor = 1.1;

  static List<RenovationTemplateItem> scaleTemplate({
    required RenovationTemplate template,
    required double areaSqm,
  }) {
    final area = areaSqm <= 0 ? 1.0 : areaSqm;

    return template.items.map((item) {
      final scaledQty = estimateQuantity(item: item, areaSqm: area);
      return ensureSwappable(
        RenovationTemplateItem(
          name: item.name,
          category: item.category,
          unit: item.unit,
          defaultQuantity: scaledQty,
          size: item.size,
          notes: item.notes,
          qtyPerSqm: item.qtyPerSqm,
          isSwappable: item.isSwappable,
          alternatives: item.alternatives,
        ),
      );
    }).toList();
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

  static List<MaterialAlternative> defaultAlternativesFor(
    RenovationTemplateItem item,
  ) {
    final name = item.name.toLowerCase();
    final cat = item.category.toLowerCase();

    if (name.contains('wall tile') ||
        name.contains('backsplash') ||
        cat.contains('wall surface')) {
      return const [
        MaterialAlternative(name: 'Subway Wall Tiles', size: '75x300'),
        MaterialAlternative(name: 'Ceramic Wall Tiles', size: '300x600'),
        MaterialAlternative(name: 'Large-format Wall Tiles', size: '600x1200'),
      ];
    }
    if (name.contains('tile') ||
        name.contains('vinyl') ||
        name.contains('flooring') ||
        cat.contains('floor')) {
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
    if (name.contains('counter') || cat.contains('counter')) {
      return const [
        MaterialAlternative(name: 'Laminate Countertop'),
        MaterialAlternative(name: 'Granite Countertop'),
        MaterialAlternative(name: 'Quartz Countertop'),
      ];
    }
    if (name.contains('cabinet') || cat.contains('cabin')) {
      return const [
        MaterialAlternative(name: 'Base Cabinets'),
        MaterialAlternative(name: 'Wall Cabinets'),
        MaterialAlternative(name: 'Modular Cabinet Set'),
      ];
    }
    if (name.contains('sink') || name.contains('lavatory')) {
      return const [
        MaterialAlternative(name: 'Stainless Steel Sink'),
        MaterialAlternative(name: 'Ceramic Sink'),
        MaterialAlternative(name: 'Undermount Sink'),
      ];
    }
    if (name.contains('faucet') || name.contains('tap')) {
      return const [
        MaterialAlternative(name: 'Single-lever Faucet'),
        MaterialAlternative(name: 'Two-handle Faucet'),
        MaterialAlternative(name: 'Pull-down Faucet'),
      ];
    }
    if (name.contains('toilet')) {
      return const [
        MaterialAlternative(name: 'One-piece Toilet'),
        MaterialAlternative(name: 'Two-piece Toilet'),
        MaterialAlternative(name: 'Wall-hung Toilet'),
      ];
    }
    if (name.contains('shower')) {
      return const [
        MaterialAlternative(name: 'Rain Shower Set'),
        MaterialAlternative(name: 'Handheld Shower Set'),
        MaterialAlternative(name: 'Thermostatic Shower Valve'),
      ];
    }
    if (name.contains('waterproof') || cat.contains('waterproof')) {
      return const [
        MaterialAlternative(name: 'Liquid Waterproofing'),
        MaterialAlternative(name: 'Waterproofing Membrane'),
        MaterialAlternative(name: 'Cementitious Waterproofing'),
      ];
    }
    if (name.contains('adhesive') || name.contains('grout')) {
      return const [
        MaterialAlternative(name: 'Standard Tile Adhesive'),
        MaterialAlternative(name: 'Flexible Tile Adhesive'),
        MaterialAlternative(name: 'Epoxy Grout'),
      ];
    }
    if (name.contains('primer')) {
      return const [
        MaterialAlternative(name: 'Acrylic Primer'),
        MaterialAlternative(name: 'Sealer Primer'),
        MaterialAlternative(name: 'Stain-blocking Primer'),
      ];
    }
    return const [];
  }

  /// Builds a reviewable essential BOM from AI consultation selections.
  static RenovationTemplate buildConsultationTemplate({
    required String projectType,
    required String style,
    required double areaSqm,
    required List<String> materialNames,
  }) {
    final names = <String>[];
    for (final raw in materialNames) {
      for (final name in expandVagueMaterialName(raw.trim())) {
        if (name.isNotEmpty && !names.contains(name)) names.add(name);
      }
    }

    if (names.isEmpty) {
      names.addAll(_defaultBasicsForType(projectType));
    }

    final items = names.map((name) {
      final lower = name.toLowerCase();
      final isSurface = lower.contains('tile') ||
          lower.contains('paint') ||
          lower.contains('floor') ||
          lower.contains('vinyl') ||
          lower.contains('waterproof') ||
          lower.contains('membrane');
      final unit = lower.contains('paint') || lower.contains('primer')
          ? 'gal'
          : (lower.contains('adhesive') ||
                  lower.contains('grout') ||
                  lower.contains('cement') ||
                  lower.contains('mortar'))
              ? 'bags'
              : (lower.contains('waterproof') && lower.contains('liquid'))
                  ? 'L'
                  : isSurface
                      ? 'sqm'
                      : 'pcs';
      final qtyPerSqm = isSurface
          ? (lower.contains('wall')
              ? 2.0
              : lower.contains('paint') || lower.contains('primer')
                  ? 0.1
                  : lower.contains('waterproof')
                      ? 0.8
                      : 1.0)
          : (lower.contains('adhesive')
              ? 0.25
              : lower.contains('grout')
                  ? 0.12
                  : null);

      return ensureSwappable(
        RenovationTemplateItem(
          name: name,
          category: _guessCategory(name),
          unit: unit,
          defaultQuantity: 1,
          qtyPerSqm: qtyPerSqm,
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

  /// Turns vague labels into concrete basic materials builders recognize.
  static List<String> expandVagueMaterialName(String raw) {
    if (raw.isEmpty) return const [];
    final lower = raw.toLowerCase();

    final looksVague = lower.startsWith('essential materials') ||
        lower.contains('matching install') ||
        lower.contains('finishing / protective') ||
        lower.contains('based on your note') ||
        lower.contains('or underlayment') ||
        (lower.contains('matching') && lower.contains('"'));

    if (!looksVague &&
        raw.length <= 48 &&
        !raw.contains(' / ') &&
        !raw.contains('(')) {
      return [raw];
    }

    if (lower.contains('floor') || lower.contains('tile')) {
      return const ['Ceramic floor tiles', 'Tile adhesive', 'Tile grout'];
    }
    if (lower.contains('wall') ||
        lower.contains('paint') ||
        lower.contains('finish')) {
      return const ['Interior wall paint', 'Wall primer', 'Paint roller set'];
    }
    if (lower.contains('install') ||
        lower.contains('protective') ||
        lower.contains('finishing')) {
      return const ['Silicone sealant', 'Tile adhesive', 'Tile grout'];
    }
    if (lower.contains('counter')) {
      return const ['Laminate countertop'];
    }
    if (lower.contains('cabinet')) {
      return const ['Base kitchen cabinets'];
    }

    final cleaned = raw
        .split(RegExp(r'[—\-–]'))
        .first
        .split('(')
        .first
        .split('/')
        .first
        .trim();
    if (cleaned.isNotEmpty && cleaned.length <= 40) return [cleaned];
    return _defaultBasicsForType('');
  }

  static List<String> _defaultBasicsForType(String projectType) {
    final key = projectType.toLowerCase().replaceAll('\n', ' ');
    if (key.contains('bathroom')) {
      return const [
        'Non-slip ceramic floor tiles',
        'Ceramic wall tiles',
        'Waterproofing membrane',
        'Toilet bowl set',
        'Lavatory sink',
        'Shower faucet set',
        'Tile adhesive',
        'Tile grout',
      ];
    }
    if (key.contains('kitchen')) {
      return const [
        'Ceramic floor tiles',
        'Ceramic backsplash tiles',
        'Laminate countertop',
        'Kitchen sink',
        'Kitchen faucet',
        'Tile adhesive',
        'Tile grout',
      ];
    }
    if (key.contains('floor')) {
      return const [
        'Ceramic floor tiles',
        'Tile adhesive',
        'Tile grout',
        'Skirting boards',
      ];
    }
    return const [
      'Ceramic floor tiles',
      'Tile adhesive',
      'Tile grout',
      'Interior wall paint',
      'Silicone sealant',
    ];
  }

  static String _guessCategory(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('tile') ||
        lower.contains('floor') ||
        lower.contains('vinyl')) {
      return 'Floor Surface';
    }
    if (lower.contains('paint') ||
        lower.contains('primer') ||
        lower.contains('wall')) {
      return 'Wall Finishing';
    }
    if (lower.contains('sink') ||
        lower.contains('faucet') ||
        lower.contains('toilet') ||
        lower.contains('shower')) {
      return 'Fixtures';
    }
    if (lower.contains('waterproof') ||
        lower.contains('adhesive') ||
        lower.contains('grout') ||
        lower.contains('sealant') ||
        lower.contains('cement')) {
      return 'Installation';
    }
    return 'General';
  }

  static double estimateQuantity({
    required RenovationTemplateItem item,
    required double areaSqm,
  }) {
    final area = areaSqm <= 0 ? 1.0 : areaSqm;

    // Fixed-count essentials (sinks, toilets, valves, etc.)
    if (item.qtyPerSqm == null || item.qtyPerSqm! <= 0) {
      return item.defaultQuantity <= 0 ? 1 : item.defaultQuantity;
    }

    final raw = item.qtyPerSqm! * area;
    final withWaste = _needsWasteBuffer(item) ? raw * surfaceWasteFactor : raw;
    final rounded = withWaste < 1 ? 1.0 : withWaste.roundToDouble();
    return rounded;
  }

  static bool _needsWasteBuffer(RenovationTemplateItem item) {
    final unit = item.unit.toLowerCase();
    final cat = item.category.toLowerCase();
    final name = item.name.toLowerCase();
    return unit.contains('sqm') ||
        cat.contains('floor') ||
        cat.contains('wall') ||
        cat.contains('paint') ||
        name.contains('tile') ||
        name.contains('paint');
  }
}
