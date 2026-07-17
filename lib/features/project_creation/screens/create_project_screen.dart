import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:iconstruct/features/project_creation/screens/ai_consultation_screen.dart';
import 'package:iconstruct/features/project_creation/widgets/glitched_flow_shell.dart';

/// Names the material-planning estimate, then opens AI consultation.
/// Templates are available beside the AI chat as references.
class CreateProjectScreen extends StatefulWidget {
  final String renovationType;

  const CreateProjectScreen({super.key, required this.renovationType});

  @override
  State<CreateProjectScreen> createState() => _CreateProjectScreenState();
}

class _CreateProjectScreenState extends State<CreateProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _continue() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AIConsultationScreen(
          projectName: widget.renovationType,
          customProjectName: _nameController.text.trim(),
          projectNotes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GlitchedFlowShell(
      title: 'Name Your\nEstimate',
      subtitle: widget.renovationType,
      instruction:
          'Next you will describe your material ideas with AI.\nIf you need inspiration, ready-made templates are available beside the chat as references.',
      trailingAction: GlitchedPillButton(
        label: 'Continue to AI',
        width: 150,
        onPressed: _continue,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.only(right: 4, bottom: 8),
          children: [
            Text(
              'Estimate Name *',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: GlitchedFlowShell.cream,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              style: GoogleFonts.poppins(
                color: GlitchedFlowShell.darkBlue,
                fontSize: 14,
              ),
              decoration: _fieldDecoration('e.g. Modern Kitchen Materials'),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Estimate name is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 18),
            Text(
              'Material Notes (Optional)',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: GlitchedFlowShell.cream,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _notesController,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              style: GoogleFonts.poppins(
                color: GlitchedFlowShell.darkBlue,
                fontSize: 14,
              ),
              decoration: _fieldDecoration(
                'Preferred materials, brand notes, or BOM remarks',
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.poppins(
        fontSize: 13,
        color: GlitchedFlowShell.darkBlue.withValues(alpha: 0.45),
      ),
      filled: true,
      fillColor: GlitchedFlowShell.cream,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(
          color: const Color(0xFF648DB6).withValues(alpha: 0.35),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFF648DB6), width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      errorStyle: GoogleFonts.poppins(fontSize: 11),
    );
  }
}
