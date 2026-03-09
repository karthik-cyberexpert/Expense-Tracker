import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/account.dart';
import '../../providers/data_providers.dart';

class AddBankDetailsScreen extends ConsumerStatefulWidget {
  final String bankName;
  const AddBankDetailsScreen({super.key, required this.bankName});

  @override
  ConsumerState<AddBankDetailsScreen> createState() => _AddBankDetailsScreenState();
}

class _AddBankDetailsScreenState extends ConsumerState<AddBankDetailsScreen> {
  final _ifscController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _holderNameController = TextEditingController();
  bool _agreed = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Account Details', style: GoogleFonts.inter(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.bankName,
              style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF6366F1)),
            ),
            const SizedBox(height: 32),
            _buildTextField('IFSC Code', _ifscController, hint: 'e.g. SBIN0012345'),
            const SizedBox(height: 16),
            _buildTextField('Bank Account Number', _accountNumberController, hint: 'e.g. 123456789012', isNumber: true),
            const SizedBox(height: 16),
            _buildTextField('Account Holder Name', _holderNameController, hint: 'As per bank records'),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F1F1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Checkbox(
                    value: _agreed,
                    onChanged: (v) => setState(() => _agreed = v ?? false),
                    activeColor: const Color(0xFF6366F1),
                  ),
                  Expanded(
                    child: Text(
                      'I agree to store these details for expense tracking purposes.',
                      style: GoogleFonts.inter(fontSize: 12, color: Colors.black54),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _agreed ? _onCreate : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E1E1E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  disabledBackgroundColor: Colors.grey[300],
                ),
                child: const Text('Create Account', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {String? hint, bool isNumber = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: const Color(0xFFF1F1F1),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  void _onCreate() async {
    if (_ifscController.text.isEmpty || _accountNumberController.text.isEmpty || _holderNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all details')));
      return;
    }

    final account = Account()
      ..name = widget.bankName.split(' ')[0] // e.g. "SBI" from "State Bank of India"
      ..displayName = widget.bankName
      ..type = AccountType.bank
      ..balance = 0.0
      ..owner = 'User'
      ..colorValue = const Color(0xFF6366F1).value
      ..ifscCode = _ifscController.text
      ..accountNumber = _accountNumberController.text
      ..accountHolderName = _holderNameController.text;

    await ref.read(databaseProvider).addAccount(account);
    if (mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }
}
