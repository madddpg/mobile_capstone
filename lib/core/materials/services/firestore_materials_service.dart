import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/material_category.dart';
import '../models/material_item.dart';

class FirestoreMaterialsService {
  final FirebaseFirestore _firestore;

  FirestoreMaterialsService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  String _normalizeProjectQuery(String value) {
    return value.replaceAll(RegExp(r'\s+'), ' ').trim().toLowerCase();
  }

  String _projectDocIdFromQuery(String projectQuery) {
    final normalized = _normalizeProjectQuery(projectQuery);

    // Explicit mapping required by spec.
    if (normalized == 'bathroom renovation' || normalized == 'bathroom') {
      return 'bathroom_renovation';
    }

    // Generic fallback (e.g. "Kitchen Renovation" -> "kitchen_renovation").
    final underscored = normalized.replaceAll(' ', '_');
    return underscored.replaceAll(RegExp(r'[^a-z0-9_]'), '');
  }

  String _asString(dynamic value) => (value ?? '').toString();

  List<String>? _asStringList(dynamic value) {
    if (value == null) return null;
    if (value is! List) return null;
    final list = value
        .map((e) => _asString(e).trim())
        .where((e) => e.isNotEmpty)
        .toList(growable: false);
    return list.isEmpty ? null : list;
  }

  String _humanizeDocId(String value) {
    final cleaned = value
        .replaceAll('_', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (cleaned.isEmpty) return value;

    final words = cleaned.split(' ');
    final buffer = StringBuffer();
    for (var i = 0; i < words.length; i++) {
      final w = words[i];
      if (w.isEmpty) continue;
      final lower = w.toLowerCase();
      final cased = lower[0].toUpperCase() + lower.substring(1);
      if (buffer.isNotEmpty) buffer.write(' ');
      buffer.write(cased);
    }
    return buffer.toString();
  }

  /// Fetches categories and items for the given project.
  ///
  /// Firestore structure expected:
  /// materials/{projectDocId}/categories/{categoryDoc}
  /// - title: string (optional)
  /// - items: array of maps
  Future<List<MaterialCategory>> fetchMaterialsForProject(
    String projectQuery,
  ) async {
    final projectDocId = _projectDocIdFromQuery(projectQuery);

    QuerySnapshot<Map<String, dynamic>> snap;
    try {
      snap = await _firestore
          .collection('materials')
          .doc(projectDocId)
          .collection('categories')
          .get();
    } on FirebaseException catch (e) {
      final message = (e.message == null || e.message!.trim().isEmpty)
          ? e.code
          : e.message!.trim();
      throw Exception(
        'Failed to load materials from Firestore (materials/$projectDocId/categories). $message',
      );
    }

    if (snap.docs.isEmpty) return const <MaterialCategory>[];

    final categories = <({int order, MaterialCategory category})>[];

    for (final doc in snap.docs) {
      final data = doc.data();

      final titleFromData = data['title'] ?? data['name'];
      final title = (titleFromData == null)
          ? _humanizeDocId(doc.id)
          : _asString(titleFromData).trim();
      if (title.isEmpty) continue;

      final order = int.tryParse(_asString(data['order'])) ?? 0;

      final rawItems = data['items'];
      final items = <MaterialItem>[];

      if (rawItems is List) {
        for (final raw in rawItems) {
          if (raw is! Map) continue;
          final map = Map<String, dynamic>.from(raw);

          final name = _asString(map['name']).trim();
          if (name.isEmpty) continue;

          final description = _asString(map['description']).trim();
          final type = _asString(map['type'] ?? map['placement']).trim();
          final kind = _asString(map['kind']).trim();

          final sizes = _asStringList(map['sizes']);
          final lengths = _asStringList(map['lengths']);
          final coverSizes = _asStringList(
            map['coverSizes'] ?? map['cover_sizes'],
          );

          final imageUrl = _asString(
            map['imageUrl'] ?? map['image_url'],
          ).trim();

          items.add(
            MaterialItem(
              name: name,
              category: title,
              description: description,
              kind: kind.isEmpty ? null : kind,
              sizes: sizes,
              lengths: lengths,
              coverSizes: coverSizes,
              type: type.isEmpty ? null : type,
              imageUrl: imageUrl.isEmpty ? null : imageUrl,
            ),
          );
        }
      }

      categories.add((
        order: order,
        category: MaterialCategory(title: title, items: items),
      ));
    }

    categories.sort((a, b) {
      if (a.order != b.order) return a.order.compareTo(b.order);
      return a.category.title.toLowerCase().compareTo(
        b.category.title.toLowerCase(),
      );
    });

    return categories.map((e) => e.category).toList(growable: false);
  }
}
