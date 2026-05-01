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

  /// Fetches items for the given project. Grouped into categories.
  Future<List<MaterialCategory>> fetchMaterialsForProject(
    String projectQuery,
  ) async {
    final projectDocId = _projectDocIdFromQuery(projectQuery);

    print('Debugging FirestoreMaterialsService:');
    print(' - Selected project name: $projectQuery');
    print(' - Normalized projectId: $projectDocId');

    QuerySnapshot<Map<String, dynamic>> snap;
    try {
      snap = await _firestore
          .collection('products')
          .where('inStock', isEqualTo: true)
          .where(
            Filter.or(
              Filter('projectId', isEqualTo: projectDocId),
              Filter('projectName', isEqualTo: projectQuery),
            ),
          )
          .get();
    } on FirebaseException catch (e) {
      final message = (e.message == null || e.message!.trim().isEmpty)
          ? e.code
          : e.message!.trim();
      throw Exception('Failed to load products from Firestore. $message');
    }

    print(' - Number of products fetched: ${snap.docs.length}');

    if (snap.docs.isEmpty) return const <MaterialCategory>[];

    final productItems = snap.docs
        .map((doc) => MaterialItem.fromJson(doc.data(), doc.id))
        .toList();

    for (final item in productItems) {
      print(
        ' - Fetched product: ${item.name} | Category: ${item.category} | Price: ${item.price}',
      );
    }

    // Sort products by name
    productItems.sort(
      (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );

    final categoryMap = <String, List<MaterialItem>>{};
    for (final item in productItems) {
      final title = item.category.isNotEmpty ? item.category : 'Others';
      categoryMap.putIfAbsent(title, () => []).add(item);
    }

    final categories = <MaterialCategory>[];
    for (final entry in categoryMap.entries) {
      categories.add(MaterialCategory(title: entry.key, items: entry.value));
    }

    categories.sort((a, b) {
      return a.title.toLowerCase().compareTo(b.title.toLowerCase());
    });

    return categories;
  }
}
