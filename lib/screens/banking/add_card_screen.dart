import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/account.dart';
import '../../providers/data_providers.dart';
import '../../utils/card_formatters.dart';

class AddCardScreen extends ConsumerStatefulWidget {
  const AddCardScreen({super.key});

  @override
  ConsumerState<AddCardScreen> createState() => _AddCardScreenState();
}

class _AddCardScreenState extends ConsumerState<AddCardScreen> {
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _holderNameController = TextEditingController();
  
  bool _isCredit = false; // false = Debit, true = Credit
  String _cardType = 'Visa'; // Visa, Mastercard, RuPay
  
  final List<String> _cardTypes = ['Visa', 'Mastercard', 'RuPay', 'Amex'];

  @override
  void initState() {
    super.initState();
    _cardNumberController.addListener(() => setState(() {}));
    _expiryController.addListener(() => setState(() {}));
    _holderNameController.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Add Card', style: GoogleFonts.inter(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Card Visualization
            _buildVisualCard(),
            const SizedBox(height: 32),
            
            // Toggle Switch for Debit/Credit
            _buildTypeToggle(),
            const SizedBox(height: 32),
            
            // Form Fields
            _buildTextField('Card Number', _cardNumberController, hint: 'XXXX XXXX XXXX XXXX', isNumber: true, formatters: [CardNumberFormatter()]),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: _buildTextField('Valid Through', _expiryController, hint: 'MM/YY', formatters: [CardExpiryFormatter()])),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Card Type', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.withOpacity(0.2)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _cardType,
                            isExpanded: true,
                            items: _cardTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                            onChanged: (v) => setState(() => _cardType = v!),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildTextField('Card Holder Name', _holderNameController, hint: 'Name as on card'),
            
            const SizedBox(height: 48),
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
                child: const Text('Add Card', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisualCard() {
    return Container(
      width: double.infinity,
      height: 210,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isCredit 
              ? [const Color(0xFF2D2D2D), const Color(0xFF4A4A4A)] // Dark for Credit
              : [const Color(0xFF6366F1), const Color(0xFF4F46E5)], // Purple for Debit
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (_isCredit ? Colors.black : const Color(0xFF6366F1)).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _isCredit ? 'PREMIUM CREDIT' : 'DEBIT CARD',
                style: GoogleFonts.inter(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const Icon(Icons.contactless, color: Colors.white70, size: 24),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            _cardNumberController.text.isEmpty ? 'XXXX XXXX XXXX XXXX' : _cardNumberController.text,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CARD HOLDER',
                    style: GoogleFonts.inter(color: Colors.white70, fontSize: 10),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _holderNameController.text.isEmpty ? 'HOLDER NAME' : _holderNameController.text.toUpperCase(),
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'VALID THRU',
                    style: GoogleFonts.inter(color: Colors.white70, fontSize: 10),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _expiryController.text.isEmpty ? 'MM/YY' : _expiryController.text,
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              _buildProviderLogo(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProviderLogo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        _cardType.toUpperCase(),
        style: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic),
      ),
    );
  }

  Widget _buildTypeToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          _buildToggleButton('Debit', !_isCredit),
          _buildToggleButton('Credit', _isCredit),
        ],
      ),
    );
  }

  Widget _buildToggleButton(String label, bool isSelected) {
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _isCredit = label == 'Credit'),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF1E1E1E) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.inter(
                color: isSelected ? Colors.white : Colors.black54,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {String? hint, bool isNumber = false, List<TextInputFormatter>? formatters}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          inputFormatters: formatters,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF6366F1)),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  void _onCreate() async {
    if (_cardNumberController.text.isEmpty || _expiryController.text.isEmpty || _holderNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all details')));
      return;
    }

    final account = Account()
      ..name = _cardType
      ..displayName = '${_isCredit ? 'Credit' : 'Debit'} Card (${_cardNumberController.text.substring(_cardNumberController.text.length - 4)})'
      ..type = AccountType.card
      ..balance = 0.0
      ..owner = 'User'
      ..colorValue = (_isCredit ? Colors.black.value : const Color(0xFF6366F1).value)
      ..cardNumber = _cardNumberController.text
      ..expiryDate = _expiryController.text
      ..cardType = _cardType
      ..isCredit = _isCredit
      ..accountHolderName = _holderNameController.text;

    await ref.read(databaseProvider).addAccount(account);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }
}
