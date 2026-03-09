import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/security_service.dart';

class SecurityQuestionDialog extends ConsumerStatefulWidget {
  const SecurityQuestionDialog({super.key});

  static Future<void> show(BuildContext context) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const SecurityQuestionDialog(),
    );
  }

  @override
  ConsumerState<SecurityQuestionDialog> createState() => _SecurityQuestionDialogState();
}

class _SecurityQuestionDialogState extends ConsumerState<SecurityQuestionDialog> {
  final _questions = [
    'What was the name of your first pet?',
    'What is your mother\'s maiden name?',
    'What city were you born in?',
    'What was the name of your first school?',
    'What is your favorite movie?',
    'What was your first car?',
  ];
  
  String? _selectedQuestion;
  final _answerController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedQuestion = _questions[0];
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Security Question', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Please set a security question to recover your password if forgotten.'),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: _selectedQuestion,
              items: _questions.map((q) => DropdownMenuItem(value: q, child: Text(q, style: const TextStyle(fontSize: 12)))).toList(),
              onChanged: (v) => setState(() => _selectedQuestion = v),
              decoration: const InputDecoration(labelText: 'Select Question'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _answerController,
              decoration: const InputDecoration(labelText: 'Secret Answer'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () async {
            if (_answerController.text.isNotEmpty && _selectedQuestion != null) {
              await ref.read(securityServiceProvider).setSecurityQuestion(_selectedQuestion!, _answerController.text);
              if (mounted) Navigator.pop(context);
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
