import 'package:flutter/material.dart';

import 'package:iconstruct/core/state/active_project_state.dart';
import 'package:iconstruct/features/auth/presentation/screens/home_screen.dart';
import 'package:iconstruct/features/auth/presentation/screens/material_estimator.dart';
import 'package:iconstruct/features/project_creation/data/project_lifecycle.dart';

/// Hammer tab: resume an in-progress estimate, or pick a new project plan.
void handleHammerTap(BuildContext context) {
  final activeProject = ActiveProjectState.instance.activeProject;
  final stillPlanning = activeProject != null &&
      !ProjectLifecycle.isPosted(
        activeProject.status,
        postId: activeProject.postId,
      );

  if (stillPlanning) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MaterialEstimatorScreen(
          projectName: activeProject.projectName,
          existingProject: activeProject,
        ),
      ),
    );
    return;
  }

  Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => const HomeScreen()),
  );
}
