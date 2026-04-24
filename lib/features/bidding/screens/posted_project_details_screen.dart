import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconstruct/features/auth/presentation/screens/saved_projects.dart';
import 'package:iconstruct/features/auth/presentation/screens/main_home_screen.dart';
import 'package:iconstruct/features/auth/presentation/screens/cost_estimation.dart';
import 'quotations_screen.dart';

class PostedProjectDetailsScreen extends StatelessWidget {
  final String postId;

  const PostedProjectDetailsScreen({super.key, required this.postId});

  // Official Theme Colors
  static const Color creamBg = Color(0xFFEDE4D4);
  static const Color navyCard = Color(0xFF2C3E50);
  static const Color textLight = Color(0xFFE0D7C9);
  static const Color blueGradientTop = Color(0xFF2C3E50);
  static const Color blueGradientBottom = Color(0xFF648DB6);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: blueGradientBottom,
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('projectPosts')
            .doc(postId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [blueGradientTop, blueGradientBottom],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: const Center(
                child: CircularProgressIndicator(color: creamBg),
              ),
            );
          }

          if (!snapshot.data!.exists) {
            return const Center(child: Text("Project not found."));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final String projectName = data['projectName'] ?? 'Untitled Project';
          final String projectType = data['projectType'] ?? 'N/A';
          final num totalArea = data['totalAreaSqm'] ?? 0;
          final String budget = data['budget'] ?? 'N/A';
          final int quoteCount = data['quotationCount'] ?? 0;

          return Stack(
            children: [
              // --- BACKGROUND GRADIENT ---
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [blueGradientTop, blueGradientBottom],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),

              // --- TOP CREAM SHAPE (With curved left side matching your design) ---
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: MediaQuery.of(context).size.height * 0.45,
                child: Container(
                  decoration: const BoxDecoration(
                    color: creamBg,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(60),
                    ),
                  ),
                ),
              ),

              // --- CONTENT LAYER ---
              SafeArea(
                child: Stack(
                  children: [
                    // --- BACK BUTTON ---
                    Positioned(
                      top: 10,
                      left: 20,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: const BoxDecoration(
                            color: navyCard,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),

                    // --- MAIN FLOATING CARD PANEL ---
                    Positioned(
                      top: 90,
                      right: 0,
                      left:
                          60, // Keep space on left so it looks connected to right side
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(28, 36, 24, 30),
                        decoration: const BoxDecoration(
                          color: navyCard,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(55),
                            bottomLeft: Radius.circular(55),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 15,
                              offset: Offset(-5, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              projectName,
                              style: GoogleFonts.poppins(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Divider(color: Colors.white30, thickness: 1),
                            const SizedBox(height: 20),

                            Text(
                              "Project Details",
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                color: creamBg,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const SizedBox(height: 8),

                            _buildDetailText("Project Type: $projectType"),
                            const SizedBox(height: 4),
                            _buildDetailText(
                              "Project Area: ${totalArea.toStringAsFixed(2)}",
                            ),
                            const SizedBox(height: 4),
                            _buildDetailText("Budget: $budget"),
                            const SizedBox(height: 28),

                            const Divider(color: Colors.white30, thickness: 1),
                            const SizedBox(height: 20),

                            // Quotations Row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Quotations Received",
                                  style: GoogleFonts.poppins(
                                    color: textLight,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                Text(
                                  quoteCount == 0
                                      ? "0 bids"
                                      : (quoteCount == 1
                                            ? "1 bids"
                                            : "$quoteCount bids"), // Match Mockup exactly ("1 bids")
                                  style: GoogleFonts.poppins(
                                    color: creamBg,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 36),

                            // Bottom Right Button
                            Align(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: creamBg,
                                  foregroundColor: navyCard,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 10,
                                  ),
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          QuotationsScreen(postId: postId),
                                    ),
                                  );
                                },
                                child: Text(
                                  "View Quotations",
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // --- BOTTOM NAVIGATION BAR ---
              _buildBottomNav(context),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDetailText(String text) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        color: textLight,
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: SafeArea(
        child: Container(
          height: 72,
          margin: const EdgeInsets.only(bottom: 24),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          decoration: BoxDecoration(
            color: creamBg,
            borderRadius: BorderRadius.circular(40),
            boxShadow: const [
              BoxShadow(
                color: Colors.black54,
                blurRadius: 16,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _BottomIconButton(
                icon: Icons.home_rounded,
                onTap: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MainHomeScreen(),
                    ),
                    (route) => false,
                  );
                },
              ),
              const SizedBox(width: 8),

              // Active "Bidding" state (hammer icon)
              const _BottomNavItem(
                imagePath: 'assets/images/hammer.png',
                label: 'Bidding',
                isActive: true,
              ),

              const SizedBox(width: 8),
              _BottomIconButton(
                icon: Icons.calculate_rounded,
                onTap: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const CostEstimationScreen(projectName: ''),
                    ),
                    (route) => false,
                  );
                },
              ),
              const SizedBox(width: 8),
              _BottomIconButton(
                icon: Icons.folder_rounded,
                onTap: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SavedProjectsScreen(),
                    ),
                    (route) => false,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  final IconData? icon;
  final String? imagePath;
  final String label;
  final bool isActive;

  const _BottomNavItem({
    this.icon,
    this.imagePath,
    required this.label,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: isActive
            ? PostedProjectDetailsScreen.navyCard
            : Colors.transparent,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (imagePath != null)
            Image.asset(
              imagePath!,
              width: 22,
              height: 22,
              color: isActive
                  ? PostedProjectDetailsScreen.creamBg
                  : PostedProjectDetailsScreen.navyCard,
            )
          else if (icon != null)
            Icon(
              icon,
              size: 22,
              color: isActive
                  ? PostedProjectDetailsScreen.creamBg
                  : PostedProjectDetailsScreen.navyCard,
            ),
          if (isActive) ...[
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: PostedProjectDetailsScreen.creamBg,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BottomIconButton extends StatelessWidget {
  final IconData? icon;
  final String? imagePath;
  final VoidCallback? onTap;

  const _BottomIconButton({this.icon, this.imagePath, this.onTap})
    : assert(icon != null || imagePath != null);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        color: Colors.transparent,
        child: Center(
          child: imagePath != null
              ? Image.asset(
                  imagePath!,
                  width: 24,
                  height: 24,
                  fit: BoxFit.contain,
                  color: PostedProjectDetailsScreen.navyCard,
                )
              : Icon(
                  icon,
                  size: 24,
                  color: PostedProjectDetailsScreen.navyCard,
                ),
        ),
      ),
    );
  }
}
