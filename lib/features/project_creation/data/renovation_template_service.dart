import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:iconstruct/features/project_creation/data/renovation_templates.dart';

class RenovationTemplateService {
  final FirebaseFirestore _firestore;

  RenovationTemplateService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Loads up to 3 active templates for a renovation type.
  /// Falls back to the built-in catalog when Firestore is empty/unavailable.
  Future<List<RenovationTemplate>> fetchTemplatesForType(
    String renovationType,
  ) async {
    final normalized = RenovationTemplatesCatalog.normalizeType(renovationType);
    final local = RenovationTemplatesCatalog.forType(normalized);

    try {
      final snap = await _firestore
          .collection('renovation_templates')
          .where('renovationType', isEqualTo: normalized)
          .where('isActive', isEqualTo: true)
          .get();

      if (snap.docs.isEmpty) return local;

      final remote = snap.docs
          .map((doc) => RenovationTemplate.fromMap(doc.id, doc.data()))
          .where((t) => t.items.isNotEmpty)
          .map(_enrichWithLocalVisual)
          .toList()
        ..sort((a, b) => a.order.compareTo(b.order));

      if (remote.isEmpty) return local;
      return remote.take(3).toList();
    } catch (_) {
      return local;
    }
  }

  RenovationTemplate _enrichWithLocalVisual(RenovationTemplate template) {
    if ((template.imageAsset != null && template.imageAsset!.isNotEmpty) ||
        (template.imageUrl != null && template.imageUrl!.isNotEmpty)) {
      return template;
    }

    RenovationTemplate? localMatch;
    for (final t in RenovationTemplatesCatalog.allTemplates) {
      if (t.id == template.id) {
        localMatch = t;
        break;
      }
    }

    if (localMatch == null) return template;

    return RenovationTemplate(
      id: template.id,
      renovationType: template.renovationType,
      style: template.style,
      name: template.name,
      description: template.description,
      items: template.items,
      order: template.order,
      imageAsset: localMatch.imageAsset,
      imageUrl: template.imageUrl ?? localMatch.imageUrl,
    );
  }
}
