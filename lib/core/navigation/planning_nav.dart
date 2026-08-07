import 'package:flutter/material.dart';

import 'package:iconstruct/core/models/project_model.dart';
import 'package:iconstruct/features/auth/presentation/screens/material_estimator.dart';
import 'package:iconstruct/features/auth/presentation/screens/saved_projects.dart';

/// Cross-screen navigation for the planning / finalize flow.
///
/// Lives outside feature screens so `saved_projects` and `material_estimator`
/// do not import each other (avoids circular library dependencies).
class PlanningNav {
  const PlanningNav._();

  static Future<void> openSavedProjects(BuildContext context) {
    return Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SavedProjectsScreen()),
    );
  }

  static Future<void> openMaterialEstimator(
    BuildContext context, {
    required String projectName,
    ProjectModel? existingProject,
  }) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MaterialEstimatorScreen(
          projectName: projectName,
          existingProject: existingProject,
        ),
      ),
    );
  }
}
