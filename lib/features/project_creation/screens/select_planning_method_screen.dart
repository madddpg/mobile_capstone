import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:iconstruct/features/project_creation/screens/ai_consultation_screen.dart';
import 'package:iconstruct/features/project_creation/screens/select_template_screen.dart';
import 'package:iconstruct/features/project_creation/widgets/glitched_flow_shell.dart';

class SelectPlanningMethodScreen extends StatelessWidget {
  /// Renovation category (e.g. Kitchen Renovation).
  final String projectName;

  /// User-entered display name from the estimate naming screen.
  final String? customProjectName;
  final String? projectNotes;

  const SelectPlanningMethodScreen({
    super.key,
    required this.projectName,
    this.customProjectName,
    this.projectNotes,
  });

  @override
  Widget build(BuildContext context) {
    final displayName = customProjectName?.isNotEmpty == true
        ? customProjectName!
        : projectName;

    return GlitchedFlowShell(
      title: 'Choose Planning\nMethod',
      subtitle: displayName,
      instruction:
          'Template = pre-defined materials.\nAI Planner = custom material list.',
      body: ListView(
        padding: const EdgeInsets.only(right: 4, bottom: 8),
        children: [
          _MethodTile(
            title: 'Plan with AI Planner',
            subtitle:
                'Chat with the AI consultant to generate a custom Bill of Materials.',
            icon: Icons.auto_awesome,
            accent: const Color(0xFFC4B5FD),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AIConsultationScreen(
                    projectName: projectName,
                    customProjectName: customProjectName,
                    projectNotes: projectNotes,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 14),
          _MethodTile(
            title: 'Use Renovation Template',
            subtitle:
                'Pick a style template with pre-defined materials, then edit quantities or remove items.',
            icon: Icons.grid_view_rounded,
            accent: const Color(0xFF6EE7B7),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SelectTemplateScreen(
                    projectName: projectName,
                    customProjectName: customProjectName,
                    projectNotes: projectNotes,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _MethodTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;

  const _MethodTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: const Color(0xFF648DB6).withValues(alpha: 0.85),
              width: 1.2,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: accent, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: const Color(0xFFE0D7C9),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
