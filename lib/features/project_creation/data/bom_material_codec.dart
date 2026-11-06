/// Round-trip helpers for BOM rows stored on `saved_projects` / `projectPosts`.
///
/// Rows may be legacy plain strings or structured maps. Edit → save must not
/// drop quantity/unit/size/category (or optional kind/length/coverSize).
class BomMaterialCodec {
  const BomMaterialCodec._();

  /// Normalize a stored materials list into structured maps that keep quantities.
  static List<Map<String, dynamic>> normalize(List<dynamic> materials) {
    final out = <Map<String, dynamic>>[];
    for (final raw in materials) {
      final row = normalizeEntry(raw);
      if (row != null) out.add(row);
    }
    return out;
  }

  /// Normalize one stored materials entry, or `null` when it has no usable name.
  static Map<String, dynamic>? normalizeEntry(dynamic raw) {
    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);
      final name = (map['name'] ?? '').toString().trim();
      if (name.isEmpty) return null;
      return _structuredRow(name: name, source: map);
    }
    final name = raw.toString().trim();
    if (name.isEmpty) return null;
    return _structuredRow(name: name, source: const {});
  }

  /// Serialize estimator UI buckets back to Firestore material maps.
  static List<Map<String, dynamic>> serialize({
    required List<String> looseNames,
    required List<Map<String, dynamic>> tileRows,
    required List<Map<String, dynamic>> plumbingRows,
  }) {
    return [
      ...looseNames
          .map((name) => name.trim())
          .where((name) => name.isNotEmpty)
          .map(
            (name) => _structuredRow(name: name, source: const {}),
          ),
      ...tileRows,
      ...plumbingRows,
    ];
  }

  static Map<String, dynamic> tileRow({
    required String tileTypeName,
    required String tileSizeGroup,
    required String tileSizeName,
    required double quantity,
  }) {
    return {
      'name': tileTypeName.trim(),
      'quantity': quantity,
      'unit': 'Qty.',
      'size': tileSizeName.trim().isEmpty ? null : tileSizeName.trim(),
      'category': 'Tiles',
      'kind': tileSizeGroup.trim(),
    };
  }

  static Map<String, dynamic> plumbingRow({
    required String categoryTitle,
    required String kind,
    required String materialName,
    required String unit,
    required double quantity,
    String? size,
    String? length,
    String? coverSize,
  }) {
    final category = categoryTitle.trim().isEmpty ? 'Material' : categoryTitle.trim();
    return {
      'name': materialName.trim(),
      'quantity': quantity,
      'unit': unit.trim().isEmpty ? 'Qty.' : unit.trim(),
      'size': _cleaned(size),
      'category': category,
      'kind': kind.trim(),
      if (_cleaned(length) != null) 'length': _cleaned(length),
      if (_cleaned(coverSize) != null) 'coverSize': _cleaned(coverSize),
    };
  }

  static bool isTilesCategory(String category) =>
      category.trim().toLowerCase() == 'tiles';

  static double asQuantity(dynamic raw) {
    if (raw is num) return raw.toDouble();
    return double.tryParse('${raw ?? ''}') ?? 0;
  }

  static Map<String, dynamic> _structuredRow({
    required String name,
    required Map<String, dynamic> source,
  }) {
    final category = (source['category'] ?? 'Material').toString().trim();
    final unit = (source['unit'] ?? '').toString().trim();
    final kind = (source['kind'] ?? '').toString().trim();
    return {
      'name': name,
      'quantity': asQuantity(source['quantity']),
      'unit': unit,
      'size': _cleaned(source['size']),
      'category': category.isEmpty ? 'Material' : category,
      'kind': kind,
      if (_cleaned(source['length']) != null) 'length': _cleaned(source['length']),
      if (_cleaned(source['coverSize']) != null)
        'coverSize': _cleaned(source['coverSize']),
    };
  }

  static String? _cleaned(dynamic value) {
    final text = value?.toString().trim() ?? '';
    if (text.isEmpty || text == 'null') return null;
    return text;
  }
}
