import 'package:flutter/material.dart';

import 'package:iconstruct/core/navigation/planning_nav.dart';
import 'package:iconstruct/core/services/unread_notifications.dart';
import 'package:iconstruct/features/auth/presentation/screens/saved_projects.dart';
import 'package:iconstruct/features/auth/presentation/screens/profile_screen.dart';
import 'package:iconstruct/features/auth/presentation/screens/top_shops_screen.dart';
import 'package:iconstruct/features/auth/presentation/screens/home_screen.dart';
import 'package:iconstruct/features/auth/presentation/models/ranked_shop.dart';
import 'package:iconstruct/features/auth/presentation/services/shop_ranking_service.dart';
import 'package:iconstruct/core/widgets/offset_pill_nav.dart';
import 'package:iconstruct/core/widgets/user_avatar.dart';
import 'package:iconstruct/features/notifications/screens/notifications_screen.dart';
import 'package:iconstruct/features/project_creation/screens/project_tracking_screen.dart';

class MainHomeScreen extends StatelessWidget {
  const MainHomeScreen({super.key});

  static const Color _cream = Color(0xFFEBE0CC);
  static const Color _darkBlue = Color(0xFF2C3E50);
  static const Color _midBlue = Color(0xFF648DB6);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cream,
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [_darkBlue, _midBlue],
                  stops: [0.3, 1.0],
                ),
              ),
            ),
          ),

          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
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

          Positioned.fill(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 120),
              child: Column(
                children: [
                  SafeArea(
                    bottom: false,
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
                              UserAvatar(
                                size: 38,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const ProfileScreen(),
                                    ),
                                  );
                                },
                              ),
                              UnreadNotificationsBadge(
                                child: _TopIconButton(
                                  icon: Icons.notifications_none_rounded,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const NotificationsScreen(),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 10,
                          ),
                          child: SizedBox(
                            width: double.infinity,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: const [
                                Text(
                                  'Welcome to iConstruct!',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 27,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF2C3E50),
                                    letterSpacing: -0.5,
                                    height: 1.2,
                                  ),
                                ),
                                SizedBox(height: 6),
                                Text(
                                  'Where builders connect to smarter solutions.',
                                  textAlign: TextAlign.center,
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
                        ),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),

                  _MainCard(
                    backgroundColor: _darkBlue,
                    cream: _cream,
                    onSeeLocations: () {},
                    onContinueLastEstimate: () {
                      PlanningNav.continueLastEstimate(context);
                    },
                    onStartNewRenovation: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HomeScreen(),
                        ),
                      );
                    },
                    onSavedProjects: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SavedProjectsScreen(
                            focus: SavedProjectsFocus.all,
                          ),
                        ),
                      );
                    },
                    onPostProject: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SavedProjectsScreen(
                            focus: SavedProjectsFocus.readyToPost,
                          ),
                        ),
                      );
                    },
                    onViewQuotations: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProjectTrackingScreen(),
                        ),
                      );
                    },
                    onTopShops: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TopShopsScreen(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 28),
                  const _TopShopsSection(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),

          const OffsetPillNav(activeTab: OffsetNavTab.home),
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
  final VoidCallback onContinueLastEstimate;
  final VoidCallback onStartNewRenovation;
  final VoidCallback onSavedProjects;
  final VoidCallback onPostProject;
  final VoidCallback onViewQuotations;
  final VoidCallback onTopShops;

  const _MainCard({
    required this.backgroundColor,
    required this.cream,
    required this.onSeeLocations,
    required this.onContinueLastEstimate,
    required this.onStartNewRenovation,
    required this.onSavedProjects,
    required this.onPostProject,
    required this.onViewQuotations,
    required this.onTopShops,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 330,
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
      padding: const EdgeInsets.fromLTRB(18, 28, 18, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ActionTile(
            icon: Icons.play_circle_outline_rounded,
            title: 'Continue Last Estimate',
            subtitle:
                'Resume your most recent unfinished material plan or open its quotations.',
            onTap: onContinueLastEstimate,
          ),
          const SizedBox(height: 12),
          _ActionTile(
            icon: Icons.home_repair_service_outlined,
            title: 'Start New Estimate',
            subtitle:
                'Name an estimate, plan materials with AI or a template, then get ready to canvass shops.',
            onTap: onStartNewRenovation,
          ),
          const SizedBox(height: 12),
          _ActionTile(
            icon: Icons.folder_open_outlined,
            title: 'My Projects',
            subtitle:
                'Browse and edit all your saved material estimates, downloads, and drafts.',
            onTap: onSavedProjects,
          ),
          const SizedBox(height: 12),
          _ActionTile(
            icon: Icons.campaign_outlined,
            title: 'Post for Bidding',
            subtitle:
                'Choose an estimate that is ready and request private quotations from hardware shops.',
            onTap: onPostProject,
          ),
          const SizedBox(height: 12),
          _ActionTile(
            icon: Icons.timeline_outlined,
            title: 'Canvass Tracking',
            subtitle:
                'Follow each estimate from planning through bids received to supplier selected.',
            onTap: onViewQuotations,
          ),
        ],
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
    const cream = Color(0xFFEBE0CC);

    return Semantics(
      button: true,
      label: title,
      hint: 'Opens $title',
      child: Material(
        color: cream.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          splashColor: cream.withValues(alpha: 0.22),
          highlightColor: cream.withValues(alpha: 0.12),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: cream.withValues(alpha: 0.32)),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 14, 8, 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: cream.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: cream, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                            color: cream,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12.5,
                            height: 1.4,
                            fontWeight: FontWeight.w400,
                            color: cream.withValues(alpha: 0.78),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: cream.withValues(alpha: 0.9),
                    size: 28,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TopShopsSection extends StatefulWidget {
  const _TopShopsSection();

  @override
  State<_TopShopsSection> createState() => _TopShopsSectionState();
}

class _TopShopsSectionState extends State<_TopShopsSection> {
  final ShopRankingService _rankingService = ShopRankingService();
  late Future<List<RankedShop>> _shopsFuture;

  @override
  void initState() {
    super.initState();
    _shopsFuture = _rankingService.fetchRankedShops();
  }

  @override
  Widget build(BuildContext context) {
    const darkBlue = Color(0xFF2C3E50);
    const cream = Color(0xFFEBE0CC);

    return Container(
      width: 330,
      decoration: BoxDecoration(
        color: darkBlue,
        borderRadius: BorderRadius.circular(50),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.emoji_events_rounded, color: cream, size: 28),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Top Hardware Shops',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                    color: cream,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TopShopsScreen(),
                    ),
                  );
                },
                style: TextButton.styleFrom(
                  foregroundColor: cream,
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(55, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'View All',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          FutureBuilder<List<RankedShop>>(
            future: _shopsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 30),
                  child: Center(child: CircularProgressIndicator(color: cream)),
                );
              }

              if (snapshot.hasError) {
                return Text(
                  'Error loading shops.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: cream.withValues(alpha: 0.8),
                  ),
                );
              }

              final shops = snapshot.data ?? [];

              final displayShops = shops
                  .where((shop) => shop.quotationCount > 0)
                  .take(5)
                  .toList();

              if (displayShops.isEmpty) {
                return Text(
                  'No submitted quotations yet.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: cream.withValues(alpha: 0.8),
                  ),
                );
              }

              return Column(
                children: displayShops.asMap().entries.map((entry) {
                  final index = entry.key;
                  final shop = entry.value;
                  final isTop3 = index < 3;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isTop3 ? darkBlue : Colors.grey.shade200,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.bold,
                              color: isTop3 ? Colors.white : darkBlue,
                            ),
                          ),
                        ),

                        const SizedBox(width: 14),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                shop.shopName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: darkBlue,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${shop.address}, ${shop.barangay}, ${shop.city}',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 11,
                                  color: darkBlue.withValues(alpha: 0.7),
                                ),
                              ),
                              if (shop.subscriptionPlan != null &&
                                  shop.subscriptionPlan!.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Plan: ${shop.subscriptionPlan}',
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.orange,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),

                        const SizedBox(width: 10),

                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${shop.quotationCount}',
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: darkBlue,
                              ),
                            ),
                            Text(
                              shop.quotationCount == 1 ? 'quote' : 'quotes',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 10,
                                color: darkBlue.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

