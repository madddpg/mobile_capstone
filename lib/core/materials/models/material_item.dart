class MaterialItem {
  final String? id;
  final String name;
  final String category;
  final String description;
  final String? kind;
  final List<String>? sizes;
  final List<String>? lengths;
  final List<String>? coverSizes;
  final String? type;
  final bool isRecommended;
  final String? imageUrl;

  const MaterialItem({
    this.id,
    required this.name,
    required this.category,
    required this.description,
    this.kind,
    this.sizes,
    this.lengths,
    this.coverSizes,
    this.type,
    this.isRecommended = false,
    this.imageUrl,
  });

  MaterialItem copyWith({
    String? id,
    String? name,
    String? category,
    String? description,
    String? kind,
    List<String>? sizes,
    List<String>? lengths,
    List<String>? coverSizes,
    String? type,
    bool? isRecommended,
    String? imageUrl,
  }) {
    return MaterialItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      description: description ?? this.description,
      kind: kind ?? this.kind,
      sizes: sizes ?? this.sizes,
      lengths: lengths ?? this.lengths,
      coverSizes: coverSizes ?? this.coverSizes,
      type: type ?? this.type,
      isRecommended: isRecommended ?? this.isRecommended,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  static List<String>? _asStringList(dynamic value) {
    if (value == null) return null;
    if (value is! List) return null;
    final list = value
        .map((e) => (e ?? '').toString().trim())
        .where((e) => e.isNotEmpty)
        .toList(growable: false);
    return list.isEmpty ? null : list;
  }

  factory MaterialItem.fromJson(Map<String, dynamic> json) {
    final rawType = (json['type'] ?? json['placement']);
    final rawKind = (json['kind'] ?? json['Kind']);

    return MaterialItem(
      id: (json['id'] ?? '').toString().trim().isEmpty
          ? null
          : (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      category: (json['category'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      kind: (rawKind ?? '').toString().trim().isEmpty
          ? null
          : (rawKind ?? '').toString(),
      sizes: _asStringList(json['sizes']),
      lengths: _asStringList(json['lengths']),
      coverSizes: _asStringList(json['coverSizes'] ?? json['cover_sizes']),
      type: (rawType ?? '').toString().trim().isEmpty
          ? null
          : (rawType ?? '').toString(),
      isRecommended: false,
      imageUrl: (json['image_url'] ?? json['imageUrl'])?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'description': description,
      'kind': kind,
      'sizes': sizes,
      'lengths': lengths,
      'coverSizes': coverSizes,
      'type': type,
      'placement': type,
      'is_recommended': isRecommended,
      'image_url': imageUrl,
    };
  }
}
