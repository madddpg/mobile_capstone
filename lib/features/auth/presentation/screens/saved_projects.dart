import 'package:flutter/material.dart';

import 'package:iconstruct/features/auth/presentation/screens/main_home_screen.dart';
import 'package:iconstruct/features/auth/presentation/screens/cost_estimation.dart';
import 'package:iconstruct/features/auth/presentation/screens/material_estimator.dart';

// --- Data Model ---
class ProjectModel {
  final String id;
  final String projectName;
  final String projectType;
  final int materialCount;
  final double projectArea;
  final String costLevel; // Low, Medium, High
  final List<String> materials;
  final String status; // Draft, Ready, Posted
  final DateTime lastUpdated;

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
  });
}

// --- Dummy Data ---
final List<ProjectModel> dummyProjects = [
  ProjectModel(
    id: '1',
    projectName: 'Window Installation',
    projectType: 'Bathroom Renovation • Structural',
    materialCount: 12,
    projectArea: 24.50,
    costLevel: 'Medium',
    materials: ['Tiles', 'PVC Pipe', 'Faucet', 'Cement', 'Sealant', 'Grout'],
    status: 'Draft',
    lastUpdated: DateTime.now().subtract(const Duration(hours: 2)),
  ),
  ProjectModel(
    id: '2',
    projectName: 'Kitchen Remodel',
    projectType: 'Interior • Custom Woodwork',
    materialCount: 45,
    projectArea: 120.0,
    costLevel: 'High',
    materials: ['Cabinetry', 'Marble Countertop', 'Sink', 'Screws', 'Paint'],
    status: 'Ready',
    lastUpdated: DateTime.now().subtract(const Duration(days: 1)),
  ),
  ProjectModel(
    id: '3',
    projectName: 'Patio Extension',
    projectType: 'Exterior • Landscaping',
    materialCount: 8,
    projectArea: 40.0,
    costLevel: 'Low',
    materials: ['Pavers', 'Sand', 'Gravel', 'Edging'],
    status: 'Posted',
    lastUpdated: DateTime.now().subtract(const Duration(days: 3)),
  ),
];

// --- Screen ---
class SavedProjectsScreen extends StatelessWidget {
  const SavedProjectsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color creamBg = Color(0xFFEDE4D4);
    const Color darkBlue = Color(0xFF2C3E50);
    const Color lightBlue = Color(0xFF648DB6);

    return Scaffold(
      body: Stack(
        children: [
          // 1. Background Layer (Cream fading to Light Blue)
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [creamBg, lightBlue],
                stops: [0.5, 1.0],
              ),
            ),
          ),

          // 2. Main Dark Blue Panel (Offset from left)
          Positioned(
            top: 140,
            bottom: 0,
            left: 55, // Indented from left to match prototype
            right: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: darkBlue,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(50)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 20,
                    offset: Offset(-5, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),

                  // Title Area
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      'Saved Projects',
                      style: TextStyle(
                        fontFamily: 'Inter', // Or custom app font
                        color: creamBg,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Divider
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Container(
                      height: 1,
                      color: creamBg.withValues(alpha: 0.4),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Project List
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.only(
                        left: 24,
                        right: 24,
                        top: 8,
                        bottom: 120, // Extra space for bottom nav
                      ),
                      itemCount: dummyProjects.length,
                      itemBuilder: (context, index) {
                        return ProjectCard(project: dummyProjects[index]);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. Fake Top Left SafeArea / Back Button Layer over the dark blue to ensure no overlapping issues
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 140,
            child: SafeArea(
              child: Stack(
                children: [
                  Positioned(
                    top: 10,
                    left: 20,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          color: darkBlue,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new,
                          color: creamBg,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 4. Floating Bottom Navigation (Visual Mock)
          Positioned(
            bottom: 30,
            left: 30,
            right: 30,
            child: Container(
              height: 72,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: creamBg,
                borderRadius: BorderRadius.circular(40),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 15,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildNavIcon(context, Icons.home_rounded, () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MainHomeScreen(),
                      ),
                      (route) => false,
                    );
                  }),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CostEstimationScreen(
                              projectName: 'Your Project Name',
                            ),
                          ),
                          (route) => false,
                        );
                      },
                      child: Image.asset(
                        'assets/images/hammer.png',
                        width: 24,
                        height: 24,
                        color: const Color(0xFF2C3E50),
                      ),
                    ),
                  ),
                  _buildNavIcon(context, Icons.calculate_rounded, () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MaterialEstimatorScreen(
                          projectName:
                              'Your Project Name', // Adjust later if needed
                        ),
                      ),
                      (route) => false,
                    );
                  }),
                  // Active "Files" Tab
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: darkBlue,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.folder_rounded, color: creamBg, size: 22),
                        SizedBox(width: 8),
                        Text(
                          'Files',
                          style: TextStyle(
                            color: creamBg,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavIcon(
    BuildContext context,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: GestureDetector(
        onTap: onTap,
        child: Icon(icon, color: const Color(0xFF2C3E50), size: 28),
      ),
    );
  }
}

// --- Reusable Card ---
class ProjectCard extends StatelessWidget {
  final ProjectModel project;

  const ProjectCard({super.key, required this.project});

  String _formatTimeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 60) return 'Updated ${diff.inMinutes} mins ago';
    if (diff.inHours < 24) return 'Updated ${diff.inHours} hours ago';
    return 'Updated ${diff.inDays} days ago';
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'ready':
        return Colors.blue.shade100;
      case 'posted':
        return Colors.green.shade100;
      case 'draft':
      default:
        return Colors.grey.shade300;
    }
  }

  Color _getStatusTextColor(String status) {
    switch (status.toLowerCase()) {
      case 'ready':
        return Colors.blue.shade900;
      case 'posted':
        return Colors.green.shade900;
      case 'draft':
      default:
        return Colors.grey.shade800;
    }
  }

  String _getCostEmoji(String costLevel) {
    switch (costLevel.toLowerCase()) {
      case 'high':
        return '🔴';
      case 'low':
        return '🟢';
      case 'medium':
      default:
        return '🟡';
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color cardBg = Color(0xFFEDE4D4); // Match cream background precisely
    const Color textDark = Color(0xFF2A3E4E);
    const Color textMuted = Color(0xFF5A6E7E);

    // Prepare material preview string
    final previewMaterials = project.materials.take(3).join(', ');
    final remainingCount = project.materials.length - 3;
    final materialsText = remainingCount > 0
        ? '$previewMaterials +$remainingCount more'
        : previewMaterials;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Top Row: Small Title Label & Action Menu
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Project Name',
                style: TextStyle(
                  color: textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
              // Three-dot Quick Actions Menu
              SizedBox(
                height: 24,
                width: 24,
                child: PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.more_vert, color: textDark, size: 22),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  onSelected: (value) {
                    // Quick Action Handler
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 20),
                          SizedBox(width: 10),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'post',
                      child: Row(
                        children: [
                          Icon(Icons.upload_outlined, size: 20),
                          SizedBox(width: 10),
                          Text('Post'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                            size: 20,
                          ),
                          SizedBox(width: 10),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // 2. Project Title & Status Badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  project.projectName,
                  style: const TextStyle(
                    color: textDark,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor(project.status),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  project.status.toUpperCase(),
                  style: TextStyle(
                    color: _getStatusTextColor(project.status),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // 3. Project Type / Category
          Text(
            project.projectType,
            style: const TextStyle(
              color: textMuted,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 16),

          // 4. Key Project Summary
          Text(
            '${project.materialCount} Materials • ${project.projectArea.toStringAsFixed(2)} sq.m • ${_getCostEmoji(project.costLevel)} ${project.costLevel} Cost',
            style: const TextStyle(
              color: textDark,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),

          // 5. Material Preview (Inline stylized text)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.6),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.inventory_2_outlined,
                  size: 16,
                  color: textMuted,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    materialsText,
                    style: const TextStyle(
                      color: textMuted,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 6. Last Updated
          Row(
            children: [
              const Icon(Icons.access_time, size: 14, color: Colors.grey),
              const SizedBox(width: 6),
              Text(
                _formatTimeAgo(project.lastUpdated),
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
