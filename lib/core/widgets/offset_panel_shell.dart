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

/// How the navy panel is laid out inside [OffsetPanelShell].
enum OffsetPanelExtent {
  /// Centered card with clearance above the floating pill nav.
  pinnedWithNav,

  /// Centered card that stretches toward the bottom (AI chat, saved projects).
  fillBottom,

  /// Scrollable column of centered cards.
  scrollBody,
}

/// Which pill-nav label is active on a planning screen.
enum OffsetNavTab { estimate, finalize, files }

/// Home-style shell for planning screens: cream top, centered rounded navy
/// card, optional floating pill nav. Screens only supply header + body.
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
    final bottomClearance = showNav
        ? IConstructPanel.bottomInsetOf(context)
        : (extent == OffsetPanelExtent.fillBottom ? 16.0 : 0.0);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: IConstructPanel.cream,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: IConstructPanel.cream,
        endDrawer: endDrawer,
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: [0.28, 0.55, 1.0],
              colors: [
                IConstructPanel.creamSoft,
                IConstructPanel.darkBlue,
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
                  _buildCenteredPanel(context, bottom: bottomClearance),
                if (overlay != null) overlay!,
                if (showNav) OffsetPillNav(activeTab: activeNav!),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCenteredPanel(BuildContext context, {required double bottom}) {
    final margin = IConstructPanel.horizontalMarginOf(context);
    final radius = borderRadius ?? IConstructPanel.cardRadiusOf(context);
    final padding =
        contentPadding ?? IConstructPanel.contentPaddingOf(context);
    final maxWidth = IConstructPanel.maxPanelWidthOf(context);

    Widget child = body;
    if (wrapPanel) {
      child = Container(
        padding: padding,
        decoration: BoxDecoration(
          color: panelColor ?? IConstructPanel.darkBlue,
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: body,
      );
    }

    return Positioned(
      top: IConstructPanel.panelTopOf(context),
      left: margin,
      right: margin,
      bottom: bottom,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _buildScrollBody(BuildContext context, {required bool showNav}) {
    final margin = IConstructPanel.horizontalMarginOf(context);

    return Positioned.fill(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          margin,
          IConstructPanel.panelTopOf(context),
          margin,
          showNav ? 120 : 24,
        ),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: IConstructPanel.maxPanelWidthOf(context),
            ),
            child: body,
          ),
        ),
      ),
    );
  }
}

/// Shared cream pill navigation used by planning screens.
class OffsetPillNav extends StatelessWidget {
  final OffsetNavTab activeTab;

  const OffsetPillNav({super.key, required this.activeTab});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        height: 64,
        margin: EdgeInsets.only(
          left: 20,
          right: 20,
          bottom: 12 + MediaQuery.paddingOf(context).bottom,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: IConstructPanel.cream,
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
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
            const SizedBox(width: 8),
            _NavIcon(
              imagePath: 'assets/images/hammer.png',
              onTap: () => handleHammerTap(context),
            ),
            const SizedBox(width: 8),
            if (activeTab == OffsetNavTab.files)
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
            const SizedBox(width: 8),
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
    );
  }
}

/// Common header rows for planning screens.
class OffsetPanelHeaders {
  const OffsetPanelHeaders._();

  static Widget backAndAvatar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _BackButton(onTap: () => Navigator.pop(context)),
          const Spacer(),
          UserAvatar(
            size: 34,
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
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          UserAvatar(
            size: 34,
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
      padding: const EdgeInsets.symmetric(horizontal: 16),
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
          width: 40,
          height: 40,
          child: Icon(
            Icons.arrow_back_rounded,
            color: IConstructPanel.cream,
            size: 22,
          ),
        ),
      ),
    );
  }
}

class _ActiveNavChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ActiveNavChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: IConstructPanel.darkBlue,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
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
