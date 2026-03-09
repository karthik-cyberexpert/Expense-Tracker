import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/account.dart';
import '../../providers/data_providers.dart';

class AddUPIDetailsScreen extends ConsumerStatefulWidget {
  final String appName;
  final Color appColor;
  const AddUPIDetailsScreen({super.key, required this.appName, required this.appColor});

  @override
  ConsumerState<AddUPIDetailsScreen> createState() => _AddUPIDetailsScreenState();
}

class _AddUPIDetailsScreenState extends ConsumerState<AddUPIDetailsScreen> {
  final _upiIdController = TextEditingController();
  final _holderNameController = TextEditingController();

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
        title: Text('UPI Details', style: GoogleFonts.inter(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: widget.appColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(Icons.qr_code_scanner, color: widget.appColor, size: 32),
                ),
                const SizedBox(width: 16),
                Text(
                  widget.appName,
                  style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 48),
            _buildTextField('UPI ID', _upiIdController, hint: 'username@bank'),
            const SizedBox(height: 24),
            _buildTextField('Account Holder Name', _holderNameController, hint: 'As per bank records'),
            const SizedBox(height: 64),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _onCreate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E1E1E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Add UPI Profile', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {String? hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
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
    if (_upiIdController.text.isEmpty || _holderNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all details')));
      return;
    }

    final account = Account()
      ..name = widget.appName
      ..displayName = '${widget.appName} UPI'
      ..type = AccountType.upi
      ..balance = 0.0
      ..owner = 'User'
      ..colorValue = widget.appColor.value
      ..upiId = _upiIdController.text
      ..accountHolderName = _holderNameController.text;

    await ref.read(databaseProvider).addAccount(account);
    if (mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }
}
