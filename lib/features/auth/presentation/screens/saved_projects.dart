import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:iconstruct/features/auth/presentation/screens/main_home_screen.dart';
import 'package:iconstruct/features/auth/presentation/screens/material_estimator.dart';
import 'package:iconstruct/core/state/active_project_state.dart';
import 'package:iconstruct/core/utils/hammer_nav.dart';
import 'package:iconstruct/features/bidding/screens/project_bids_screen.dart';

// --- Data Model ---
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
          // 1. Full dark blue background ONLY
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFE0D7C9), // cream top
                  Color(0xFF2C3E50), // dark blue mid
                  Color(0xFF648DB6), // light blue bottom
                ],
                stops: [0.28, 0.55, 1.0],
              ),
            ),
          ),

          Positioned(
            left: 0,
            top: -200,
            width: 393,
            height: 585,
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFE0D7C9), // YOUR cream
                borderRadius: BorderRadius.all(Radius.circular(50)),
              ),
            ),
          ),

          // 2. Main Dark Blue Panel (Offset from left)
          Positioned(
            top: 110,
            bottom: 0,
            left: 70,
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
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseAuth.instance.currentUser == null
                          ? const Stream.empty()
                          : FirebaseFirestore.instance
                                .collection('users')
                                .doc(FirebaseAuth.instance.currentUser!.uid)
                                .collection('saved_projects')
                                .orderBy('updatedAt', descending: true)
                                .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(color: creamBg),
                          );
                        }

                        if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              'Error loading projects.',
                              style: TextStyle(color: creamBg.withAlpha(150)),
                            ),
                          );
                        }

                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return Center(
                            child: Text(
                              'No saved projects yet.',
                              style: TextStyle(
                                color: creamBg.withAlpha(150),
                                fontSize: 16,
                              ),
                            ),
                          );
                        }

                        final projects = snapshot.data!.docs
                            .map((doc) => ProjectModel.fromDocument(doc))
                            .toList();

                        return AnimatedBuilder(
                          animation: ActiveProjectState.instance,
                          builder: (context, child) {
                            return ListView.builder(
                              padding: const EdgeInsets.only(
                                left: 24,
                                right: 24,
                                top: 8,
                                bottom: 120, // Extra space for bottom nav
                              ),
                              itemCount: projects.length,
                              itemBuilder: (context, index) {
                                final project = projects[index];
                                return ProjectCard(
                                  project: project,
                                  isActive:
                                      project.id ==
                                      ActiveProjectState
                                          .instance
                                          .activeProject
                                          ?.id,
                                );
                              },
                            );
                          },
                        );
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
                      onTap: () => handleHammerTap(context),
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
  final bool isActive;

  const ProjectCard({super.key, required this.project, this.isActive = false});

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

  void _handlePostProject(BuildContext context) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    if (project.status.toLowerCase() == 'posted' || project.postId != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This project is already posted for bidding.'),
        ),
      );
      return;
    }

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final batch = FirebaseFirestore.instance.batch();
      final newPostRef = FirebaseFirestore.instance
          .collection('projectPosts')
          .doc();
      final savedProjectRef = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('saved_projects')
          .doc(project.id);

      final Map<String, dynamic> projectPostData = {
        'postId': newPostRef.id,
        'userId': uid,
        'projectId': project.id,
        'projectName': project.projectName,
        'projectType': project.projectType,
        'materials': project
            .materials, // assuming it's exactly the correct property string map
        'materialsCount': project.materialCount,
        'totalAreaSqm': project.projectArea,
        'budget': project.costLevel,
        'status': 'open',
        'quotationCount': 0,
        'postedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      batch.set(newPostRef, projectPostData);

      batch.update(savedProjectRef, {
        'status': 'posted',
        'postId': newPostRef.id,
        'postedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      if (context.mounted) {
        Navigator.pop(context); // Remove loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Project successfully posted for bidding!'),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Remove loading
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error posting project: $e')));
      }
    }
  }

  void _handleDeleteProject(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: const Color(0xFFEDE4D4), // Matching cream UI
          title: const Text(
            'Delete local project?',
            style: TextStyle(
              color: Color(0xFF2A3E4E),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            project.status.toLowerCase() == 'posted'
                ? 'This project is already posted for bidding. Deleting this will only remove your saved local copy, not the active bidding board post. Proceed?'
                : 'Are you sure you want to permanently delete this saved project?',
            style: const TextStyle(color: Color(0xFF5A6E7E)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Color(0xFF5A6E7E)),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade400,
              ),
              onPressed: () async {
                Navigator.pop(context); // Close dialog
                try {
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(uid)
                      .collection('saved_projects')
                      .doc(project.id)
                      .delete();

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Project deleted successfully.'),
                      ),
                    );

                    // Clear the active state if the deleted project was the currently active project
                    if (isActive) {
                      ActiveProjectState.instance.setActiveProject(null);
                    }
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error deleting project: $e')),
                    );
                  }
                }
              },
              child: const Text(
                'Delete',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color cardBg = Color(0xFFEDE4D4); // Match cream background precisely
    const Color textDark = Color(0xFF2A3E4E);
    const Color textMuted = Color(0xFF5A6E7E);

    // Prepare material preview string (support structured items)
    final previewMaterials = project.materials
        .take(3)
        .map((m) => m is Map ? (m['name'] ?? '').toString() : m.toString())
        .where((s) => s.isNotEmpty)
        .join(', ');
    final remainingCount = project.materials.length > 3
        ? project.materials.length - 3
        : 0;
    final materialsText = remainingCount > 0
        ? '$previewMaterials +$remainingCount more'
        : previewMaterials;

    return GestureDetector(
      onTap: () {
        if (project.postId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('This project is not posted yet.')),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProjectBidsScreen(
                postId: project.postId!,
                projectName: project.projectName,
              ),
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(28),
          border: isActive
              ? Border.all(color: const Color(0xFF648DB6), width: 3)
              : null,
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
                    icon: const Icon(
                      Icons.more_vert,
                      color: textDark,
                      size: 22,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
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
                    onSelected: (value) {
                      if (value == 'edit') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MaterialEstimatorScreen(
                              projectName: project.projectName,
                              existingProject: project,
                            ),
                          ),
                        );
                      } else if (value == 'post') {
                        _handlePostProject(context);
                      } else if (value == 'delete') {
                        _handleDeleteProject(context);
                      }
                    },
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

            if (project.postId != null &&
                project.status.toLowerCase() == 'posted')
              StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('projectPosts')
                    .doc(project.postId)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || !snapshot.data!.exists) {
                    return const SizedBox.shrink();
                  }

                  final data = snapshot.data!.data() as Map<String, dynamic>;
                  final int count = data['quotationCount'] ?? 0;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: count > 0
                          ? Colors.green.shade100
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.local_offer_outlined,
                          size: 16,
                          color: count > 0
                              ? Colors.green.shade700
                              : Colors.grey.shade700,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$count bid${count == 1 ? '' : 's'}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: count > 0
                                ? Colors.green.shade700
                                : Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

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
      ),
    );
  }
}
