import 'package:flutter/material.dart';

import 'package:iconstruct/features/auth/presentation/screens/material_estimator.dart';
import 'package:iconstruct/features/auth/presentation/screens/saved_projects.dart';
import 'package:iconstruct/core/utils/hammer_nav.dart';

class MainHomeScreen extends StatefulWidget {
  const MainHomeScreen({super.key});

  @override
  State<MainHomeScreen> createState() => _MainHomeScreenState();
}

class _MainHomeScreenState extends State<MainHomeScreen> {
  int _navIndex = 0;

  Color get _cream => const Color(0xFFEBE0CC);
  Color get _darkBlue => const Color(0xFF2C3E50);
  Color get _midBlue => const Color(0xFF648DB6);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cream,
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [_darkBlue, _midBlue],
                  stops: const [0.3, 1.0],
                ),
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              width: 434,
              height: 380,
              decoration: BoxDecoration(
                color: _cream,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(50),
                  bottomRight: Radius.circular(50),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 15,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _TopIconButton(icon: Icons.account_circle, onTap: () {}),
                      _TopIconButton(icon: Icons.menu_rounded, onTap: () {}),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 10,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Welcome to iConstruct!',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 27,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF2C3E50),
                          letterSpacing: -0.5,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'where builders connect to smarter solutions.',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
          Positioned(
            top: 209,
            left: 47,
            child: _MainCard(
              backgroundColor: _darkBlue,
              cream: _cream,
              onSeeLocations: () {},
              onEstimateMaterials: () {},
              onSavedProjects: () {},
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 24,
            child: _BottomPillNav(
              index: _navIndex,
              onChanged: (i) => setState(() => _navIndex = i),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _TopIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkResponse(
        onTap: onTap,
        radius: 24,
        child: Icon(icon, color: const Color(0xFF2C3E50), size: 34),
      ),
    );
  }
}

class _MainCard extends StatelessWidget {
  final Color backgroundColor;
  final Color cream;
  final VoidCallback onSeeLocations;
  final VoidCallback onEstimateMaterials;
  final VoidCallback onSavedProjects;

  const _MainCard({
    required this.backgroundColor,
    required this.cream,
    required this.onSeeLocations,
    required this.onEstimateMaterials,
    required this.onSavedProjects,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 330,
      height: 643,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(50),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(26, 36, 26, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ActionTile(
            icon: Icons.map_outlined,
            title: 'See Locations',
            subtitle:
                'Find and connect with trusted hardware shops and suppliers near your construction site.',
            onTap: onSeeLocations,
          ),
          const _ThinDivider(),
          _ActionTile(
            icon: Icons.calculate_outlined,
            title: 'Estimate Materials',
            subtitle:
                'Calculate the exact quantity and cost of main materials and accessories needed for your project.',
            onTap: onEstimateMaterials,
          ),
          const _ThinDivider(),
          _ActionTile(
            icon: Icons.folder_open_outlined,
            title: 'Saved Projects',
            subtitle:
                'Access and manage your previous material estimates and project drafts in one secure place.',
            onTap: onSavedProjects,
          ),
          const Spacer(),
          Text(
            'Need Inspiration?',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: cream,
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _ThinDivider extends StatelessWidget {
  const _ThinDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Container(
        height: 1,
        width: double.infinity,
        color: Colors.white.withValues(alpha: 0.25),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFFEBE0CC), size: 32),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFEBE0CC),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              height: 1.45,
              fontWeight: FontWeight.w400,
              color: const Color(0xFFEBE0CC).withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomPillNav extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChanged;

  const _BottomPillNav({required this.index, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const cream = Color(0xFFEBE0CC);

    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: cream,
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 25,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            flex: index == 0 ? 4 : 2,
            child: _NavItem(
              selected: index == 0,
              icon: Icons.home_rounded,
              label: 'Home',
              onTap: () {},
            ),
          ),
          Expanded(
            flex: 2,
            child: _NavIconOnly(
              selected: index == 1,
              imagePath: 'assets/images/hammer.png',
              onTap: () => handleHammerTap(context),
            ),
          ),
          Expanded(
            flex: 2,
            child: _NavIconOnly(
              selected: index == 2,
              icon: Icons.calculate_rounded,
              onTap: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MaterialEstimatorScreen(
                      projectName: 'Your Project Name',
                    ),
                  ),
                  (route) => false,
                );
              },
            ),
          ),
          Expanded(
            flex: 2,
            child: _NavIconOnly(
              selected: index == 3,
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
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _NavItem({
    required this.selected,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const dark = Color(0xFF2C3E50);
    const cream = Color(0xFFEBE0CC);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        height: double.infinity,
        decoration: BoxDecoration(
          color: selected ? dark : Colors.transparent,
          borderRadius: BorderRadius.circular(32),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: selected
                  ? const BoxDecoration(color: cream, shape: BoxShape.circle)
                  : null,
              child: Icon(
                icon,
                size: 20,
                color: selected ? dark : dark.withValues(alpha: 0.7),
              ),
            ),
            if (selected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: cream,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NavIconOnly extends StatelessWidget {
  final bool selected;
  final IconData? icon;
  final String? imagePath;
  final VoidCallback onTap;

  const _NavIconOnly({
    required this.selected,
    this.icon,
    this.imagePath,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const dark = Color(0xFF2C3E50);
    final color = selected ? dark : dark.withValues(alpha: 0.7);
    final opacity = selected ? 1.0 : 0.7;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: Colors.transparent,
        child: Center(
          child: imagePath != null
              ? Opacity(
                  opacity: opacity,
                  child: Image.asset(
                    imagePath!,
                    width: 26,
                    height: 26,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.handyman_rounded,
                        size: 26,
                        color: color,
                      );
                    },
                  ),
                )
              : Icon(icon, size: 26, color: color),
        ),
      ),
    );
  }
}
