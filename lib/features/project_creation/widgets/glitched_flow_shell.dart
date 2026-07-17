import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:iconstruct/core/utils/hammer_nav.dart';
import 'package:iconstruct/core/widgets/user_avatar.dart';
import 'package:iconstruct/features/auth/presentation/screens/main_home_screen.dart';
import 'package:iconstruct/features/auth/presentation/screens/profile_screen.dart';
import 'package:iconstruct/features/auth/presentation/screens/saved_projects.dart';

/// Shared “glitched” layout used by Cost Estimation–style planning screens:
/// cream top blob, navy floating card, and cream bottom pill nav.
class GlitchedFlowShell extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String instruction;
  final Widget body;
  final Widget? trailingAction;
  final bool showBackOnCard;

  const GlitchedFlowShell({
    super.key,
    required this.title,
    this.subtitle,
    required this.instruction,
    required this.body,
    this.trailingAction,
    this.showBackOnCard = true,
  });

  static const Color cream = Color(0xFFEDE4D4);
  static const Color darkBlue = Color(0xFF2C3E50);
  static const Color navyCard = Color(0xFF1E3042);
  static const Color midBlue = Color(0xFF648DB6);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0.0, 0.56, 1.0],
            colors: [Color(0xFFE0D7C9), Color(0xFF2C3E50), Color(0xFF648DB6)],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              const Positioned(
                left: 0,
                top: -200,
                width: 393,
                height: 585,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: cream,
                    borderRadius: BorderRadius.all(Radius.circular(50)),
                  ),
                ),
              ),
              _buildHeader(context),
              _buildContentCard(context),
              _buildBottomNav(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        height: 96,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: const BoxDecoration(color: cream),
        child: Row(
          children: [
            if (showBackOnCard)
              Material(
                color: darkBlue,
                shape: const CircleBorder(),
                elevation: 2,
                shadowColor: Colors.black26,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => Navigator.pop(context),
                  child: const SizedBox(
                    width: 40,
                    height: 40,
                    child: Icon(
                      Icons.arrow_back_rounded,
                      color: cream,
                      size: 22,
                    ),
                  ),
                ),
              )
            else
              UserAvatar(
                size: 36,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProfileScreen(),
                    ),
                  );
                },
              ),
            const Spacer(),
            if (showBackOnCard)
              UserAvatar(
                size: 36,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProfileScreen(),
                    ),
                  );
                },
              )
            else
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.centerRight,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(width: 18, height: 2.4, color: darkBlue),
                    const SizedBox(height: 4),
                    Container(width: 14, height: 2.4, color: darkBlue),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentCard(BuildContext context) {
    return Positioned(
      top: 110,
      left: 16,
      right: 0,
      bottom: 80,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 28, 20, 24),
        decoration: const BoxDecoration(
          color: navyCard,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(60),
            topRight: Radius.circular(60),
            bottomLeft: Radius.circular(60),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black38,
              blurRadius: 18,
              offset: Offset(-4, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                height: 1.15,
              ),
            ),
            if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                subtitle!,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: cream.withValues(alpha: 0.85),
                ),
              ),
            ],
            const SizedBox(height: 12),
            const Divider(color: cream, thickness: 1),
            const SizedBox(height: 12),
            Text(
              instruction,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: const Color(0xFFE0D7C9),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            const Divider(color: cream, thickness: 1),
            const SizedBox(height: 14),
            Expanded(child: body),
            if (trailingAction != null) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: trailingAction!,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        height: 72,
        margin: const EdgeInsets.only(bottom: 24),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: cream,
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
            _NavIcon(
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
            const SizedBox(width: 10),
            _NavIcon(
              imagePath: 'assets/images/hammer.png',
              onTap: () => handleHammerTap(context),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: darkBlue,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calculate_rounded,
                    color: cream,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Estimate',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: cream,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            _NavIcon(
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
    );
  }
}

class GlitchedPillButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final double width;

  const GlitchedPillButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.width = 150,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 40,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: GlitchedFlowShell.cream,
          foregroundColor: GlitchedFlowShell.navyCard,
          disabledBackgroundColor:
              GlitchedFlowShell.cream.withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 6,
          shadowColor: Colors.black.withAlpha(100),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  final IconData? icon;
  final String? imagePath;
  final VoidCallback onTap;

  const _NavIcon({
    this.icon,
    this.imagePath,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: SizedBox(
        width: 40,
        height: 40,
        child: Center(
          child: imagePath != null
              ? Image.asset(
                  imagePath!,
                  width: 22,
                  height: 22,
                  color: GlitchedFlowShell.darkBlue,
                )
              : Icon(icon, color: GlitchedFlowShell.darkBlue, size: 24),
        ),
      ),
    );
  }
}
