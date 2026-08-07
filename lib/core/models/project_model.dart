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
    return ProjectModel(
      id: doc.id,
      projectName: data['projectName'] ?? 'Unknown Project',
      projectType: data['projectType'] ?? '',
      materialCount: data['materialsCount'] ?? 0,
      projectArea: (data['totalAreaSqm'] ?? 0.0).toDouble(),
      costLevel: data['costLevel'] ?? 'Unknown',
      // Materials may be stored as a list of strings (legacy) or
      // as a list of structured maps containing name/quantity/unit, etc.
      materials: List<dynamic>.from(
        data['materials'] ?? data['selectedMaterials'] ?? [],
      ),
      status: data['status'] ?? 'Draft',
      lastUpdated:
          (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      postId: data['postId'],
    );
  }
}
