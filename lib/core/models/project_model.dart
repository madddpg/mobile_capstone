import 'package:cloud_firestore/cloud_firestore.dart';

/// Saved material-estimate document for the planning / canvassing cycle.
class ProjectModel {
  final String id;
  final String projectName;
  final String projectType;
  final int materialCount;
  final double projectArea;
  final String costLevel; // Low, Medium, High
  final List<dynamic> materials;
  final String status; // Draft, Ready, Posted
  final DateTime lastUpdated;
  final String? postId;

  ProjectModel({
    required this.id,
    required this.projectName,
    required this.projectType,
    required this.materialCount,
    required this.projectArea,
    required this.costLevel,
    required this.materials,
    required this.status,
    required this.lastUpdated,
    this.postId,
  });

  factory ProjectModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ProjectModel.fromMap(doc.id, data);
  }

  /// Shared parser for Firestore docs and unit tests.
  factory ProjectModel.fromMap(String id, Map<String, dynamic> data) {
    final rawPostId = data['postId']?.toString();
    return ProjectModel(
      id: id,
      projectName: (data['projectName'] ?? 'Unknown Project').toString(),
      projectType: (data['projectType'] ?? '').toString(),
      materialCount: _asInt(data['materialsCount']),
      projectArea: _asDouble(data['totalAreaSqm']),
      costLevel: (data['costLevel'] ?? 'Unknown').toString(),
      // Materials may be stored as a list of strings (legacy) or
      // as a list of structured maps containing name/quantity/unit, etc.
      materials: List<dynamic>.from(
        data['materials'] ?? data['selectedMaterials'] ?? const [],
      ),
      status: (data['status'] ?? 'Draft').toString(),
      lastUpdated: _asDateTime(data['updatedAt']) ?? DateTime.now(),
      postId: (rawPostId == null || rawPostId.isEmpty) ? null : rawPostId,
    );
  }

  static double _asDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  static int _asInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  static DateTime? _asDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
