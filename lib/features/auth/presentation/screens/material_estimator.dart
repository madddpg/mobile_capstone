import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:iconstruct/features/auth/presentation/screens/cost_estimation.dart'
    show AddedTileSelection, AddedPlumbingSelection;
import 'package:iconstruct/features/auth/presentation/screens/saved_projects.dart';
import 'package:iconstruct/features/auth/presentation/screens/main_home_screen.dart';
import 'package:iconstruct/features/auth/presentation/screens/profile_screen.dart';
import 'package:iconstruct/core/utils/hammer_nav.dart';
import 'package:iconstruct/core/widgets/user_avatar.dart';
import 'package:iconstruct/features/bidding/screens/posted_project_details_screen.dart';

class MaterialEstimatorScreen extends StatefulWidget {
  final String projectName;
  final List<AddedTileSelection> tiles;
  final List<AddedPlumbingSelection> plumbingMaterials;
  final ProjectModel? existingProject;
  final List<String>? aiGeneratedMaterials;
  final double? aiProjectArea;
  final String? aiBudget;
  final String? customProjectName;
  final String? projectNotes;

  const MaterialEstimatorScreen({
    super.key,
    required this.projectName,
    this.tiles = const [],
    this.plumbingMaterials = const [],
    this.existingProject,
    this.aiGeneratedMaterials,
    this.aiProjectArea,
    this.aiBudget,
    this.customProjectName,
    this.projectNotes,
  });

  @override
  State<MaterialEstimatorScreen> createState() =>
      _MaterialEstimatorScreenState();
}

class _MaterialEstimatorScreenState extends State<MaterialEstimatorScreen> {
  String? _selectedBudget;
  double _projectArea = 0.0;
  String _projectName = '';
  late String _projectType;
  final PageController _materialsPageController = PageController();

  late final TextEditingController _projectNameController;
  late final TextEditingController _projectTypeController;
  late final TextEditingController _projectAreaController;
  late final TextEditingController _remarksController;

  int _currentMaterialPage = 0;

  List<AddedTileSelection> _localTiles = [];
  List<AddedPlumbingSelection> _localPlumbing = [];
  List<String> _localMaterials = [];

  int get _materialCount =>
      _localTiles.length + _localPlumbing.length + _localMaterials.length;

  @override
  void initState() {
    super.initState();
    _localTiles = List.from(widget.tiles);
    _localPlumbing = List.from(widget.plumbingMaterials);

    if (widget.aiGeneratedMaterials != null) {
      _localMaterials.addAll(widget.aiGeneratedMaterials!);
    }

    if (widget.aiProjectArea != null && widget.aiProjectArea! > 0) {
      _projectArea = widget.aiProjectArea!;
    }

    if (widget.aiBudget != null) {
      final budgetLower = widget.aiBudget!.toLowerCase();
      if (budgetLower.contains('low')) {
        _selectedBudget = 'Low Budget';
      } else if (budgetLower.contains('high')) {
        _selectedBudget = 'High Budget';
      } else {
        _selectedBudget = 'Mid Budget';
      }
    }

    if (widget.existingProject != null) {
      _projectName = widget.existingProject!.projectName;
      _projectType = widget.existingProject!.projectType;
      _projectArea = widget.existingProject!.projectArea;

      final costLvl = widget.existingProject!.costLevel.toLowerCase();
      if (costLvl.contains('low')) {
        _selectedBudget = 'Low Budget';
      } else if (costLvl.contains('high')) {
        _selectedBudget = 'High Budget';
      } else {
        _selectedBudget = 'Mid Budget';
      }

      _localMaterials = List<String>.from(
        (widget.existingProject!.materials as List<dynamic>)
            .map((m) => m is Map ? (m['name'] ?? '').toString() : m.toString())
            .where((s) => s.isNotEmpty),
      );
    } else {
      _projectType = widget.projectName;
      if (widget.customProjectName != null &&
          widget.customProjectName!.trim().isNotEmpty) {
        _projectName = widget.customProjectName!.trim();
      }
    }

    _projectNameController = TextEditingController(text: _projectName);
    _projectTypeController = TextEditingController(text: _projectType);
    _projectAreaController = TextEditingController(
      text: _projectArea > 0 ? _projectArea.toString() : '',
    );
    _remarksController = TextEditingController(
      text: widget.projectNotes?.trim() ?? '',
    );
  }

  @override
  void dispose() {
    _projectNameController.dispose();
    _projectTypeController.dispose();
    _projectAreaController.dispose();
    _remarksController.dispose();
    _materialsPageController.dispose();
    super.dispose();
  }

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
                    color: Color(0xFFEDE4D4),
                    borderRadius: BorderRadius.all(Radius.circular(50)),
                  ),
                ),
              ),
              _buildTopBar(context),
              Positioned.fill(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 110, 0, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildContentCard(context),
                      const SizedBox(height: 20),
                      _buildFinalizeCard(context),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
              _buildBottomNav(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        height: 96,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: const BoxDecoration(color: Color(0xFFEDE4D4)),
        child: Row(
          children: [
            Material(
              color: const Color(0xFF2C3E50),
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
                    color: Color(0xFFEDE4D4),
                    size: 22,
                  ),
                ),
              ),
            ),
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
      ),
    );
  }

  Widget _buildContentCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 28, 20, 24),
      decoration: const BoxDecoration(
        color: Color(0xFF1E3042),
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
            'Review Bill of\nMaterials',
            style: GoogleFonts.poppins(
              fontSize: 26,
              height: 1.15,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Finalize your material plan before requesting supplier quotations.',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: const Color(0xFFE0D7C9),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          const Divider(color: Color(0xFFEDE4D4), thickness: 1),
          const SizedBox(height: 14),
          _buildProcedureSteps(),
          const SizedBox(height: 18),
          const Divider(color: Color(0xFFEDE4D4), thickness: 1),
          const SizedBox(height: 16),
          Text(
            'Estimate Details',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 14),
          _buildInputLabel('Estimate Name:'),
          _buildTextField(
            'e.g., Modern Kitchen Materials',
            controller: _projectNameController,
            onChanged: (val) {
              setState(() {
                _projectName = val;
              });
            },
          ),
          const SizedBox(height: 14),
          _buildInputLabel('Renovation Type:'),
          _buildTextField(
            'e.g., Kitchen Renovation',
            controller: _projectTypeController,
            onChanged: (val) {
              setState(() {
                _projectType = val;
              });
            },
          ),
          const SizedBox(height: 14),
          _buildInputLabel('Project Area (sqm) — optional:'),
          _buildTextField(
            '0.00',
            controller: _projectAreaController,
            onChanged: (val) {
              setState(() {
                _projectArea = double.tryParse(val) ?? 0.0;
              });
            },
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 14),
          _buildInputLabel('Budget Preference — optional:'),
          _buildDropdownField(),
          const SizedBox(height: 14),
          _buildInputLabel('Remarks for suppliers — optional:'),
          _buildTextField(
            'Brand preferences, delivery notes, or scope remarks',
            controller: _remarksController,
            maxLines: 3,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Text(
                'Bill of Materials',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              Text(
                '$_materialCount items',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF8FB2D4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Confirm materials and quantities. Prices come from supplier quotations.',
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: const Color(0xFFE0D7C9),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          if (_materialCount == 0)
            Text(
              'No materials in this plan yet. Go back and load a template or AI BOM.',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: const Color(0xFFE0D7C9),
              ),
            )
          else
            _buildSelectedMaterialsSlider(),
        ],
      ),
    );
  }

  Widget _buildProcedureSteps() {
    const steps = [
      ('1', 'Review details'),
      ('2', 'Confirm BOM'),
      ('3', 'Save or request quotes'),
    ];

    return Row(
      children: [
        for (var i = 0; i < steps.length; i++) ...[
          if (i > 0)
            Expanded(
              child: Container(
                height: 1.5,
                margin: const EdgeInsets.symmetric(horizontal: 6),
                color: const Color(0xFFEDE4D4).withValues(alpha: 0.35),
              ),
            ),
          Column(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFEDE4D4).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFEDE4D4)),
                ),
                child: Text(
                  steps[i].$1,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFEDE4D4),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: 72,
                child: Text(
                  steps[i].$2,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: const Color(0xFFE0D7C9),
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildFinalizeCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 28, 20, 24),
      decoration: const BoxDecoration(
        color: Color(0xFF1E3042),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(60),
          bottomLeft: Radius.circular(60),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Finalize &\nCanvass',
            style: GoogleFonts.poppins(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 12),
          const Divider(color: Color(0xFFEDE4D4), thickness: 1),
          const SizedBox(height: 14),
          _buildSummaryRow('Materials in BOM:', '$_materialCount items'),
          const SizedBox(height: 8),
          _buildSummaryRow(
            'Renovation type:',
            _projectTypeController.text.trim().isEmpty
                ? '—'
                : _projectTypeController.text.trim(),
          ),
          const SizedBox(height: 8),
          _buildSummaryRow(
            'Area:',
            _projectArea > 0
                ? '${_projectArea.toStringAsFixed(2)} sq.m'
                : 'Not set',
          ),
          const SizedBox(height: 8),
          _buildSummaryRow(
            'Budget preference:',
            _selectedBudget ?? 'Not set',
          ),
          const SizedBox(height: 14),
          const Divider(color: Color(0xFFEDE4D4), thickness: 1),
          const SizedBox(height: 14),
          Text(
            'Pricing comes from hardware shop quotations after you request bids. This screen finalizes your material list only.',
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: const Color(0xFFE0D7C9),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _materialCount == 0 ? null : _postProjectForBidding,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEDE4D4),
                foregroundColor: const Color(0xFF2C3E50),
                disabledBackgroundColor:
                    const Color(0xFFEDE4D4).withValues(alpha: 0.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                'Request Supplier Quotations',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _materialCount == 0 ? null : _saveProject,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFEDE4D4),
                side: const BorderSide(color: Color(0xFFEDE4D4)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(
                'Save Draft',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedMaterialsSlider() {
    final List<Widget> allMaterials = [
      for (final material in _localMaterials)
        _buildStringMaterialCard(material),
      for (final tile in _localTiles) _buildTileCard(tile),
      for (final plumbing in _localPlumbing) _buildPlumbingCard(plumbing),
    ];

    final int itemsPerPage = 4;
    final int pageCount = (allMaterials.length / itemsPerPage).ceil();

    return Column(
      children: [
        SizedBox(
          height:
              480, // Adjust height to fit up to 4 items per page comfortably
          child: PageView.builder(
            controller: _materialsPageController,
            onPageChanged: (index) {
              setState(() {
                _currentMaterialPage = index;
              });
            },
            itemCount: pageCount,
            itemBuilder: (context, pageIndex) {
              final startIndex = pageIndex * itemsPerPage;
              final endIndex = (startIndex + itemsPerPage < allMaterials.length)
                  ? startIndex + itemsPerPage
                  : allMaterials.length;
              final items = allMaterials.sublist(startIndex, endIndex);

              return Column(
                children: items
                    .map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: item,
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ),
        if (pageCount > 1) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              pageCount,
              (index) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentMaterialPage == index
                      ? const Color(0xFFEDE4D4)
                      : const Color(0xFFEDE4D4).withAlpha(100),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 5,
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: const Color(0xFFE0D7C9),
            ),
          ),
        ),
        Expanded(
          flex: 6,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _saveProject() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to save projects')),
        );
      }
      return;
    }

    if (_projectName.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter an Estimate Name')),
        );
      }
      return;
    }

    try {
      final materialsList = [
        ..._localMaterials.map(
          (name) => {
            'name': name,
            'quantity': 0,
            'unit': '',
            'size': null,
            'category': 'Material',
          },
        ),
        ..._localTiles.map(
          (t) => {
            'name': t.tileTypeName,
            'quantity': t.quantity,
            'unit': 'Qty.',
            'size': t.tileSizeName,
            'category': 'Tiles',
          },
        ),
        ..._localPlumbing.map(
          (p) => {
            'name': p.materialName,
            'quantity': p.quantity,
            'unit': p.unit,
            'size': p.size,
            'category': p.categoryTitle,
          },
        ),
      ];

      // Convert selectedBudget strings to expected costLevel logic
      String costLevel = 'medium';
      if (_selectedBudget != null) {
        if (_selectedBudget!.toLowerCase().contains('low')) {
          costLevel = 'low';
        } else if (_selectedBudget!.toLowerCase().contains('high')) {
          costLevel = 'high';
        }
      }

      final Map<String, dynamic> projectData = {
        'projectName': _projectName,
        'projectType': _projectType,
        'costLevel': costLevel,
        'materials': materialsList,
        'materialsCount': materialsList.length,
        'totalAreaSqm': _projectArea,
        'status': widget.existingProject?.status ?? 'draft',
        'updatedAt': FieldValue.serverTimestamp(),
        if (_remarksController.text.trim().isNotEmpty)
          'projectNotes': _remarksController.text.trim(),
      };

      if (widget.existingProject != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('saved_projects')
            .doc(widget.existingProject!.id)
            .update(projectData);
      } else {
        projectData['createdAt'] = FieldValue.serverTimestamp();
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('saved_projects')
            .add(projectData);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Draft saved. You can request quotations anytime.'),
          ),
        );
        // By using `push` instead of `pushReplacement`, the current screen
        // stays in the navigation stack, preserving values. When the user taps
        // "Back" on SavedProjectsScreen, they will perfectly return here.
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SavedProjectsScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving project: $e')));
      }
    }
  }

  Future<void> _postProjectForBidding() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to post projects')),
        );
      }
      return;
    }

    if (_projectName.trim().isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter an Estimate Name')),
        );
      }
      return;
    }

    final materialsList = [
      ..._localMaterials.map(
        (name) => {
          'name': name,
          'quantity': 0,
          'unit': '',
          'size': null,
          'category': 'Material',
        },
      ),
      ..._localTiles.map(
        (t) => {
          'name': t.tileTypeName,
          'quantity': t.quantity,
          'unit': 'Qty.',
          'size': t.tileSizeName,
          'category': 'Tiles',
        },
      ),
      ..._localPlumbing.map(
        (p) => {
          'name': p.materialName,
          'quantity': p.quantity,
          'unit': p.unit,
          'size': p.size,
          'category': p.categoryTitle,
        },
      ),
    ];

    if (materialsList.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cannot post a project without materials'),
          ),
        );
      }
      return;
    }

    try {
      String costLevel = 'medium';
      if (_selectedBudget != null) {
        if (_selectedBudget!.toLowerCase().contains('low')) {
          costLevel = 'low';
        } else if (_selectedBudget!.toLowerCase().contains('high')) {
          costLevel = 'high';
        }
      }

      final firestore = FirebaseFirestore.instance;
      final batch = firestore.batch();

      final String uid = user.uid;
      DocumentReference savedProjectRef;
      if (widget.existingProject != null) {
        savedProjectRef = firestore
            .collection('users')
            .doc(uid)
            .collection('saved_projects')
            .doc(widget.existingProject!.id);
      } else {
        savedProjectRef = firestore
            .collection('users')
            .doc(uid)
            .collection('saved_projects')
            .doc();
      }

      final DocumentReference newPostRef = firestore
          .collection('projectPosts')
          .doc();

      final Map<String, dynamic> projectPostData = {
        'postId': newPostRef.id,
        'userId': uid,
        'projectId': savedProjectRef.id,
        'projectName': _projectName,
        'projectType': _projectType,
        'materials': materialsList,
        'materialsCount': materialsList.length,
        'totalAreaSqm': _projectArea,
        'budget': costLevel,
        'status': 'open',
        'quotationCount': 0,
        'postedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        if (_remarksController.text.trim().isNotEmpty)
          'remarks': _remarksController.text.trim(),
      };

      final Map<String, dynamic> savedProjectData = {
        'projectName': _projectName,
        'projectType': _projectType,
        'costLevel': costLevel,
        'materials': materialsList,
        'materialsCount': materialsList.length,
        'totalAreaSqm': _projectArea,
        'status': 'posted',
        'postId': newPostRef.id,
        'postedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        if (_remarksController.text.trim().isNotEmpty)
          'projectNotes': _remarksController.text.trim(),
      };

      if (widget.existingProject == null) {
        savedProjectData['createdAt'] = FieldValue.serverTimestamp();
        batch.set(savedProjectRef, savedProjectData);
      } else {
        batch.update(savedProjectRef, savedProjectData);
      }

      // Add to public projectPosts collection
      batch.set(newPostRef, projectPostData);

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'BOM sent to hardware shops. Waiting for supplier quotations.',
            ),
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                PostedProjectDetailsScreen(postId: newPostRef.id),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error posting project: $e')));
      }
    }
  }

  Widget _buildInputLabel(String label, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 13,
          color: const Color(0xFFE0D7C9),
        ),
      ),
    );
  }

  Widget _buildTextField(
    String hintText, {
    TextEditingController? controller,
    ValueChanged<String>? onChanged,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Container(
      constraints: BoxConstraints(minHeight: maxLines > 1 ? 88 : 48),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDE4D4), width: 1),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: maxLines > 1 ? 12 : 0,
          ),
          border: InputBorder.none,
          hintText: hintText,
          hintStyle: GoogleFonts.poppins(
            color: const Color(0xFFEDE4D4).withAlpha(153),
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownField() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDE4D4), width: 1),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedBudget,
          isExpanded: true,
          dropdownColor: const Color(0xFF2C3E50),
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Colors.white,
          ),
          hint: Text(
            'Select budget range',
            style: GoogleFonts.poppins(
              color: const Color(0xFFEDE4D4).withAlpha(153),
              fontSize: 14,
            ),
          ),
          items: ['Low Budget', 'Mid Budget', 'High Budget'].map((
            String value,
          ) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(
                value,
                style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
              ),
            );
          }).toList(),
          onChanged: (newValue) {
            setState(() {
              _selectedBudget = newValue;
            });
          },
        ),
      ),
    );
  }

  Widget _buildStringMaterialCard(String material) {
    return SelectedMaterialCard(
      name: material,
      category: 'Material',
      quantity: 0,
      projectArea: _projectArea,
      onRemove: () {
        setState(() {
          _localMaterials.remove(material);
        });
      },
    );
  }

  Widget _buildTileCard(AddedTileSelection tile) {
    return SelectedMaterialCard(
      name: tile.tileTypeName,
      category: 'Tiles',
      kind: tile.tileSizeGroup,
      size: tile.tileSizeName,
      quantity: tile.quantity,
      projectArea: _projectArea,
      onRemove: () {
        setState(() {
          _localTiles.remove(tile);
        });
      },
    );
  }

  Widget _buildPlumbingCard(AddedPlumbingSelection plumbing) {
    return SelectedMaterialCard(
      name: plumbing.materialName,
      category: plumbing.categoryTitle,
      kind: plumbing.kind,
      size: plumbing.size,
      length: plumbing.length,
      quantity: plumbing.quantity,
      projectArea: _projectArea,
      onRemove: () {
        setState(() {
          _localPlumbing.remove(plumbing);
        });
      },
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
          color: const Color(0xFFEDE4D4),
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
            const SizedBox(width: 10),
            _BottomIconButton(
              imagePath: 'assets/images/hammer.png',
              onTap: () => handleHammerTap(context),
            ),
            const SizedBox(width: 10),
            const _BottomNavItem(
              icon: Icons.fact_check_rounded,
              label: 'Finalize',
              isActive: true,
            ),
            const SizedBox(width: 10),
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
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;

  const _BottomNavItem({
    required this.icon,
    required this.label,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF2C3E50) : Colors.transparent,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 22,
            color: isActive ? const Color(0xFFEDE4D4) : const Color(0xFF2C3E50),
          ),
          if (isActive) ...[
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFFEDE4D4),
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
                  color: const Color(0xFF2C3E50),
                )
              : Icon(icon, size: 24, color: const Color(0xFF2C3E50)),
        ),
      ),
    );
  }
}

class SelectedMaterialCard extends StatelessWidget {
  final String name;
  final String category;
  final String? kind;
  final String? size;
  final String? length;
  final double quantity;
  final double projectArea;
  final VoidCallback? onRemove;

  const SelectedMaterialCard({
    super.key,
    required this.name,
    required this.category,
    this.kind,
    this.size,
    this.length,
    required this.quantity,
    this.projectArea = 0.0,
    this.onRemove,
  });

  double autoComputeQuantity() {
    if (projectArea <= 0) return 0;

    final cat = category.toLowerCase();
    if (cat == 'tiles' || cat == 'flooring' || cat == 'floor surface') {
      double tileWidth = 0.6;
      double tileHeight = 0.6;
      if (size != null && size!.trim().isNotEmpty) {
        final match = RegExp(r'(\d+)\s*[×xX]\s*(\d+)').firstMatch(size!);
        if (match != null) {
          tileWidth = (double.tryParse(match.group(1)!) ?? 600) / 1000;
          tileHeight = (double.tryParse(match.group(2)!) ?? 600) / 1000;
        }
      }
      double tileArea = tileWidth * tileHeight;
      if (tileArea == 0) return 0;
      double tilesNeeded = projectArea / tileArea;
      return (tilesNeeded * 1.10).ceilToDouble(); // 10% allowance
    } else if (cat.contains('plumb') ||
        cat.contains('pipes') ||
        cat.contains('wiring')) {
      return projectArea * 1.5;
    } else if (cat.contains('fixtures')) {
      return 1;
    }
    return 0;
  }

  double getFinalQuantity() {
    if (quantity > 0) {
      return quantity;
    } else {
      return autoComputeQuantity();
    }
  }

  String getUnit(String category) {
    if (category.toLowerCase().contains('plumb')) return 'meters';
    switch (category.toLowerCase()) {
      case 'tiles':
      case 'flooring':
      case 'floor surface':
        return 'pcs';
      case 'plumbing':
      case 'pipes':
      case 'wiring':
        return 'meters';
      case 'fixtures':
        return 'pcs';
      case 'paint':
        return 'liters';
      default:
        return 'pcs';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDE4D4), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              if (onRemove != null)
                GestureDetector(
                  onTap: onRemove,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Icon(
                      Icons.delete_outline_rounded,
                      size: 20,
                      color: Colors.redAccent.withAlpha(200),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            kind != null && kind!.isNotEmpty ? '$category • $kind' : category,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: Color(0xCCE0D7C9),
            ),
          ),
          const SizedBox(height: 12),

          if (size != null && size!.isNotEmpty) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Size: $size',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: Color(0xFFE0D7C9),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
          ],

          if (length != null && length!.isNotEmpty) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Length: $length',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: Color(0xFFE0D7C9),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
          ],

          Builder(
            builder: (context) {
              final finalQty = getFinalQuantity();

              if (finalQty > 0) {
                final qtyStr = finalQty.toStringAsFixed(
                  finalQty.truncateToDouble() == finalQty ? 0 : 2,
                );

                final isEstimated = quantity <= 0 && projectArea > 0;
                final estStr = isEstimated ? ' (estimated)' : '';

                return Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Quantity: $qtyStr',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFEDE4D4),
                        ),
                      ),
                    ),
                    Text(
                      '${getUnit(category)}$estStr',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        color: Color(0xCCEDE4D4),
                      ),
                    ),
                  ],
                );
              } else {
                return Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Quantity: Not set',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFEDE4D4),
                        ),
                      ),
                    ),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
