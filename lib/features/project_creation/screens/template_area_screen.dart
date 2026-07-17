import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:iconstruct/features/auth/presentation/screens/cost_estimation.dart';
import 'package:iconstruct/features/project_creation/data/bom_quantity_estimator.dart';
import 'package:iconstruct/features/project_creation/data/renovation_templates.dart';
import 'package:iconstruct/features/project_creation/widgets/glitched_flow_shell.dart';

/// After a template reference is chosen, collect project area so quantities
/// can be auto-estimated before opening the BOM review.
class TemplateAreaScreen extends StatefulWidget {
  final RenovationTemplate template;
  final String projectName;
  final String? customProjectName;
  final String? projectNotes;

  const TemplateAreaScreen({
    super.key,
    required this.template,
    required this.projectName,
    this.customProjectName,
    this.projectNotes,
  });

  @override
  State<TemplateAreaScreen> createState() => _TemplateAreaScreenState();
}

class _TemplateAreaScreenState extends State<TemplateAreaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _areaController = TextEditingController();

  @override
  void dispose() {
    _areaController.dispose();
    super.dispose();
  }

  void _continue() {
    if (!_formKey.currentState!.validate()) return;
    final area = double.parse(_areaController.text.trim());

    final scaledItems = BomQuantityEstimator.scaleTemplate(
      template: widget.template,
      areaSqm: area,
    );
    final scaledTemplate = widget.template.copyWithItems(scaledItems);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CostEstimationScreen(
          projectName: widget.projectName,
          customProjectName: widget.customProjectName,
          projectNotes: widget.projectNotes,
          template: scaledTemplate,
          projectAreaSqm: area,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GlitchedFlowShell(
      title: 'Project\nArea',
      subtitle: widget.template.name,
      instruction:
          'Enter the total area (sqm). Essential materials will auto-estimate quantities from this size.\nTemplates are a reference only.',
      trailingAction: GlitchedPillButton(
        label: 'Estimate Qty',
        width: 140,
        onPressed: _continue,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.only(right: 4, bottom: 8),
          children: [
            Text(
              'Total area (square meters) *',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: GlitchedFlowShell.cream,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _areaController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: GoogleFonts.poppins(
                color: GlitchedFlowShell.darkBlue,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                hintText: 'e.g. 18',
                hintStyle: GoogleFonts.poppins(
                  color: GlitchedFlowShell.darkBlue.withValues(alpha: 0.4),
                ),
                suffixText: 'sqm',
                filled: true,
                fillColor: GlitchedFlowShell.cream,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              validator: (value) {
                final parsed = double.tryParse(value?.trim() ?? '');
                if (parsed == null || parsed <= 0) {
                  return 'Enter a valid area greater than 0';
                }
                return null;
              },
            ),
            const SizedBox(height: 18),
            Text(
              '${widget.template.items.length} essential materials will scale from your area.',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: const Color(0xFFE0D7C9),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
