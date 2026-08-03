import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:iconstruct/core/utils/hammer_nav.dart';
import 'package:iconstruct/core/widgets/iconstruct_panel.dart';
import 'package:iconstruct/core/widgets/user_avatar.dart';
import 'package:iconstruct/features/auth/presentation/screens/home_screen.dart';
import 'package:iconstruct/features/auth/presentation/screens/main_home_screen.dart';
import 'package:iconstruct/features/auth/presentation/screens/profile_screen.dart';
import 'package:iconstruct/features/auth/presentation/screens/saved_projects.dart';

/// How the navy offset panel is laid out inside [OffsetPanelShell].
enum OffsetPanelExtent {
  /// Floating card with clearance above the pill nav (default planning steps).
  pinnedWithNav,

  /// Panel stretches toward the bottom (AI chat, saved projects).
  fillBottom,

  /// Scrollable column of offset cards.
  scrollBody,
}

/// Which pill-nav label is active.
enum OffsetNavTab { estimate, finalize, files, bidding }

/// Shared shell for the offset-panel look used by posted-project details:
/// cream top curve, navy card shifted right / flush left-rounded, pill nav.
class OffsetPanelShell extends StatelessWidget {
  final Widget header;
  final Widget body;
  final Widget? overlay;
  final OffsetPanelExtent extent;
  final bool wrapPanel;
  final EdgeInsetsGeometry? contentPadding;
  final BorderRadius? borderRadius;
  final Color? panelColor;
  final OffsetNavTab? activeNav;
  final GlobalKey<ScaffoldState>? scaffoldKey;
  final Widget? endDrawer;
  final bool safeAreaBottom;

  const OffsetPanelShell({
    super.key,
    required this.header,
    required this.body,
    this.overlay,
    this.extent = OffsetPanelExtent.pinnedWithNav,
    this.wrapPanel = true,
    this.contentPadding,
    this.borderRadius,
    this.panelColor,
    this.activeNav,
    this.scaffoldKey,
    this.endDrawer,
    this.safeAreaBottom = true,
  });

  @override
  Widget build(BuildContext context) {
    final showNav = activeNav != null;
    final bottomClearance = showNav && extent == OffsetPanelExtent.pinnedWithNav
        ? IConstructPanel.bottomInsetOf(context)
        : 0.0;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: IConstructPanel.cream,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: IConstructPanel.midBlue,
        endDrawer: endDrawer,
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                IConstructPanel.darkBlue,
                Color(0xFF4F6B8A),
                IConstructPanel.midBlue,
              ],
            ),
          ),
          child: OffsetSafeArea(
            bottom: safeAreaBottom,
            child: Stack(
              children: [
                const CreamBackdrop(),
                CreamHeaderBand(child: header),
                if (extent == OffsetPanelExtent.scrollBody)
                  _buildScrollBody(context, showNav: showNav)
                else
                  _buildOffsetPanel(context, bottom: bottomClearance),
                if (overlay != null) overlay!,
                if (showNav) OffsetPillNav(activeTab: activeNav!),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOffsetPanel(BuildContext context, {required double bottom}) {
    final radius = borderRadius ??
        (extent == OffsetPanelExtent.fillBottom
            ? IConstructPanel.offsetTallRadiusOf(context)
            : IConstructPanel.offsetRadiusOf(context));
    final padding =
        contentPadding ?? IConstructPanel.contentPaddingOf(context);

    Widget child = body;
    if (wrapPanel) {
      child = Container(
        padding: padding,
        decoration: BoxDecoration(
          color: panelColor ?? IConstructPanel.darkBlue,
          borderRadius: radius,
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 15,
              offset: Offset(-5, 10),
            ),
          ],
        ),
        child: body,
      );
    }

    return Positioned(
      top: IConstructPanel.panelTopOf(context),
      left: IConstructPanel.leftInsetOf(context),
      right: 0,
      bottom: bottom,
      child: child,
    );
  }

  Widget _buildScrollBody(BuildContext context, {required bool showNav}) {
    return Positioned.fill(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          IConstructPanel.leftInsetOf(context),
          IConstructPanel.panelTopOf(context),
          0,
          showNav ? 120 : 24,
        ),
        child: body,
      ),
    );
  }
}

/// Cream floating pill navigation from the offset-panel reference.
class OffsetPillNav extends StatelessWidget {
  final OffsetNavTab activeTab;

  const OffsetPillNav({super.key, required this.activeTab});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: SafeArea(
        top: false,
        child: Container(
          height: 72,
          margin: const EdgeInsets.only(bottom: 24, left: 20, right: 20),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          decoration: BoxDecoration(
            color: IConstructPanel.cream,
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
              if (activeTab == OffsetNavTab.bidding)
                const _ActiveNavChip(
                  icon: Icons.gavel_rounded,
                  imagePath: 'assets/images/hammer.png',
                  label: 'Bidding',
                )
              else
                _NavIcon(
                  imagePath: 'assets/images/hammer.png',
                  onTap: () => handleHammerTap(context),
                ),
              const SizedBox(width: 10),
              if (activeTab == OffsetNavTab.files ||
                  activeTab == OffsetNavTab.bidding)
                _NavIcon(
                  icon: Icons.calculate_rounded,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HomeScreen(),
                      ),
                    );
                  },
                )
              else
                _ActiveNavChip(
                  icon: activeTab == OffsetNavTab.finalize
                      ? Icons.fact_check_rounded
                      : Icons.calculate_rounded,
                  label: activeTab == OffsetNavTab.finalize
                      ? 'Finalize'
                      : 'Estimate',
                ),
              const SizedBox(width: 10),
              if (activeTab == OffsetNavTab.files)
                const _ActiveNavChip(
                  icon: Icons.folder_rounded,
                  label: 'Files',
                )
              else
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
      ),
    );
  }
}

/// Common header rows for offset screens.
class OffsetPanelHeaders {
  const OffsetPanelHeaders._();

  static Widget backAndAvatar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _BackButton(onTap: () => Navigator.pop(context)),
          const Spacer(),
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
        ],
      ),
    );
  }

  static Widget avatarAndMenu(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
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
          SizedBox(
            width: 28,
            height: 28,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  width: 18,
                  height: 2.4,
                  color: IConstructPanel.darkBlue,
                ),
                const SizedBox(height: 4),
                Container(
                  width: 14,
                  height: 2.4,
                  color: IConstructPanel.darkBlue,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget backOnly(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Align(
        alignment: Alignment.centerLeft,
        child: _BackButton(onTap: () => Navigator.pop(context)),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  final VoidCallback onTap;

  const _BackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: IConstructPanel.darkBlue,
      shape: const CircleBorder(),
      elevation: 2,
      shadowColor: Colors.black26,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const SizedBox(
          width: 44,
          height: 44,
          child: Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }
}

class _ActiveNavChip extends StatelessWidget {
  final IconData? icon;
  final String? imagePath;
  final String label;

  const _ActiveNavChip({
    this.icon,
    this.imagePath,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: IConstructPanel.darkBlue,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          if (imagePath != null)
            Image.asset(
              imagePath!,
              width: 18,
              height: 18,
              color: IConstructPanel.cream,
            )
          else
            Icon(icon, color: IConstructPanel.cream, size: 18),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: IConstructPanel.cream,
            ),
          ),
        ],
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
                  color: IConstructPanel.darkBlue,
                )
              : Icon(icon, color: IConstructPanel.darkBlue, size: 24),
        ),
      ),
    );
  }
}
