import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:iconstruct/features/auth/presentation/screens/login_screen.dart';
import 'package:iconstruct/features/auth/presentation/screens/edit_profile_screen.dart';
import 'package:iconstruct/core/materials/services/favorites_service.dart';
import 'package:iconstruct/core/materials/models/favorite_model.dart';
import 'package:iconstruct/features/auth/presentation/screens/home_screen.dart';
import 'package:iconstruct/features/auth/presentation/screens/cost_estimation.dart';

import 'package:iconstruct/core/state/active_project_state.dart';
import 'package:iconstruct/core/materials/models/material_item.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    const creamBg = Color(0xFFEDE4D4);
    const darkBlue = Color(0xFF2C3E50);

    return Scaffold(
      backgroundColor: creamBg,
      body: user == null
          ? const Center(child: Text('User not logged in.'))
          : StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: darkBlue),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading profile data.',
                      style: GoogleFonts.poppins(color: darkBlue),
                    ),
                  );
                }

                final userData =
                    snapshot.data?.data() as Map<String, dynamic>? ?? {};

                final firstName = userData['firstName'] ?? 'User';
                final lastName = userData['lastName'] ?? '';
                final fullName = '$firstName $lastName'.trim();
                final email = userData['email'] ?? user.email ?? '';
                final profileImg = userData['profileImage'] as String?;

                return Stack(
                  children: [
                    // 1. Top Dark Blue Header Banner
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: 280,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: darkBlue,
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(50),
                            bottomRight: Radius.circular(50),
                          ),
                        ),
                      ),
                    ),

                    // 2. Safe Area Content
                    Positioned.fill(
                      child: SafeArea(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Header area with Back button and Title
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 10,
                              ),
                              child: Row(
                                children: [
                                  GestureDetector(
                                    onTap: () => Navigator.pop(context),
                                    child: Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: creamBg.withAlpha(50),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.arrow_back_ios_new,
                                        color: creamBg,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Text(
                                    'Profile',
                                    style: GoogleFonts.poppins(
                                      color: creamBg,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Profile Avatar
                            Center(
                              child: Stack(
                                alignment: Alignment.bottomRight,
                                children: [
                                  Container(
                                    width: 110,
                                    height: 110,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: creamBg,
                                        width: 4,
                                      ),
                                      image:
                                          profileImg != null &&
                                              profileImg.isNotEmpty
                                          ? DecorationImage(
                                              image: NetworkImage(profileImg),
                                              fit: BoxFit.cover,
                                            )
                                          : null,
                                      color: creamBg,
                                    ),
                                    child:
                                        profileImg == null || profileImg.isEmpty
                                        ? const Icon(
                                            Icons.person_rounded,
                                            size: 60,
                                            color: darkBlue,
                                          )
                                        : null,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Name and Email
                            Center(
                              child: Text(
                                fullName.isEmpty
                                    ? 'iConstruct Builder'
                                    : fullName,
                                style: GoogleFonts.poppins(
                                  color: creamBg,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Center(
                              child: Text(
                                email,
                                style: GoogleFonts.poppins(
                                  color: creamBg.withAlpha(200),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                            const SizedBox(height: 40),

                            // Scrollable Cards
                            Expanded(
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Edit Profile Button
                                    SizedBox(
                                      width: double.infinity,
                                      height: 54,
                                      child: ElevatedButton(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  EditProfileScreen(
                                                    firstName: firstName,
                                                    lastName: lastName,
                                                    profileImg: profileImg,
                                                  ),
                                            ),
                                          );
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: darkBlue,
                                          foregroundColor: creamBg,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                          ),
                                          elevation: 8,
                                          shadowColor: Colors.black.withAlpha(
                                            100,
                                          ),
                                        ),
                                        child: Text(
                                          'Edit Profile',
                                          style: GoogleFonts.poppins(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 32),

                                    _buildSectionTitle('Personal Information'),
                                    const SizedBox(height: 12),
                                    _buildInfoCard(
                                      children: [
                                        _buildInfoRow(
                                          Icons.badge_outlined,
                                          'First Name',
                                          firstName,
                                        ),
                                        const Divider(height: 1),
                                        _buildInfoRow(
                                          Icons.badge_outlined,
                                          'Last Name',
                                          lastName,
                                        ),
                                        const Divider(height: 1),
                                        _buildInfoRow(
                                          Icons.email_outlined,
                                          'Email',
                                          email,
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 32),

                                    _buildSectionTitle('Favorite Materials'),
                                    const SizedBox(height: 12),
                                    _buildFavoriteMaterialsSection(
                                      darkBlue,
                                      creamBg,
                                    ),

                                    const SizedBox(height: 32),

                                    _buildSectionTitle('Account'),
                                    const SizedBox(height: 12),
                                    _buildInfoCard(
                                      children: [
                                        _buildActionTile(
                                          icon: Icons.lock_outline_rounded,
                                          title: 'Change Password',
                                          onTap: () {
                                            // To implement later
                                          },
                                        ),
                                        const Divider(height: 1),
                                        _buildActionTile(
                                          icon: Icons.description_outlined,
                                          title: 'Terms & Conditions',
                                          onTap: () {
                                            // To implement later
                                          },
                                        ),
                                        const Divider(height: 1),
                                        _buildActionTile(
                                          icon: Icons.logout_rounded,
                                          title: 'Logout',
                                          isDestructive: true,
                                          onTap: () => _logout(context),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 40),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF5A6E7E),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildInfoCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF648DB6), size: 22),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: const Color(0xFF5A6E7E),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value.isEmpty ? '-' : value,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    color: const Color(0xFF2C3E50),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final color = isDestructive ? Colors.red.shade400 : const Color(0xFF2C3E50);
    final iconColor = isDestructive
        ? Colors.red.shade400
        : const Color(0xFF648DB6);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24), // Matching parent radius roughly
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.grey.shade400,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFavoriteMaterialsSection(Color darkBlue, Color creamBg) {
    return StreamBuilder<List<FavoriteModel>>(
      stream: FavoritesService().streamFavorites(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final favorites = snapshot.data ?? [];

        if (favorites.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(20),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(
                  Icons.favorite_border_rounded,
                  size: 40,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  "You don’t have favorite materials yet",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: darkBlue,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Start saving materials to quickly reuse them in your projects",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey.shade500,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: darkBlue,
                    foregroundColor: creamBg,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const HomeScreen()),
                    );
                  },
                  child: Text(
                    'Browse Materials',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return SizedBox(
          height: 140, // Height of the horizontal list
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: favorites.length,
            // Adjust margin for overscroll alignment
            clipBehavior: Clip.none,
            itemBuilder: (context, index) {
              final item = favorites[index];
              return GestureDetector(
                onTap: () => _showFavoriteDetailsBottomSheet(
                  context,
                  item,
                  darkBlue,
                  creamBg,
                ),
                child: Container(
                  width: 120,
                  margin: EdgeInsets.only(
                    right: index == favorites.length - 1 ? 0 : 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: creamBg.withAlpha(80), width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(10),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        flex: 3,
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                          child: Container(
                            color: creamBg.withAlpha(50),
                            child: item.imageUrl.isNotEmpty
                                ? Image.network(
                                    item.imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            _fallbackImagePlaceholder(),
                                  )
                                : _fallbackImagePlaceholder(),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                item.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: darkBlue,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                item.category,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _fallbackImagePlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [Icon(Icons.image, size: 24, color: Colors.grey.shade400)],
    );
  }

  void _showFavoriteDetailsBottomSheet(
    BuildContext context,
    FavoriteModel item,
    Color darkBlue,
    Color creamBg,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bContext) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.fromLTRB(
            24,
            16,
            24,
            MediaQuery.of(bContext).padding.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 80,
                      height: 80,
                      color: creamBg.withAlpha(50),
                      child: item.imageUrl.isNotEmpty
                          ? Image.network(
                              item.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _fallbackImagePlaceholder(),
                            )
                          : _fallbackImagePlaceholder(),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: darkBlue,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.category,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: darkBlue,
                    foregroundColor: creamBg,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(bContext); // Close bottom sheet
                    final activeProject =
                        ActiveProjectState.instance.activeProject;

                    if (activeProject != null) {
                      final materialItem = MaterialItem(
                        name: item.name,
                        category: item.category,
                        description: '',
                        type: '',
                        kind: item.projectType,
                        imageUrl: item.imageUrl,
                      );

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CostEstimationScreen(
                            projectName: activeProject.projectName,
                            preselectedMaterial: materialItem,
                          ),
                        ),
                      );
                    } else {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor: darkBlue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          title: Text(
                            'No Selected Project',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          content: Text(
                            'You currently don’t have a selected project to estimate. Please select one from our available projects.',
                            style: GoogleFonts.poppins(color: creamBg),
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
                                backgroundColor: creamBg,
                                foregroundColor: darkBlue,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () {
                                Navigator.pop(context);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const HomeScreen(),
                                  ),
                                );
                              },
                              child: Text(
                                'Go to Projects',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                  },
                  child: Text(
                    'Use in Selected Project',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
