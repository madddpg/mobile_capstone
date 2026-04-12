import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:iconstruct/core/state/active_project_state.dart';
import 'package:iconstruct/features/auth/presentation/screens/material_estimator.dart';
import 'package:iconstruct/features/auth/presentation/screens/home_screen.dart';

/// Clean handle for the bottom navigation's hammer tap.
/// Determines if an active project exists. If it does, launches estimator.
/// If it doesn't, triggers the modal directing them to project selection.
void handleHammerTap(BuildContext context) {
  final activeProject = ActiveProjectState.instance.activeProject;

  if (activeProject != null) {
    // Open material estimator instantly prepopulating with the active project
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MaterialEstimatorScreen(
          projectName: activeProject.projectName,
          existingProject: activeProject,
        ),
      ),
    );
  } else {
    // Show Modal Dialog recommending the user selects a project
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2C3E50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'No Selected Project',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'You currently don’t have a selected project to estimate. Please select one from our available projects.',
          style: GoogleFonts.poppins(color: const Color(0xFFEDE4D4)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEDE4D4),
              foregroundColor: const Color(0xFF2C3E50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              Navigator.pop(context); // Dismiss dialog
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen()),
              );
            },
            child: Text(
              'Go to Projects',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
