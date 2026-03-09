import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/account.dart';

class BankCardWidget extends StatelessWidget {
  final Account account;
  final VoidCallback? onTap;

  const BankCardWidget({super.key, required this.account, this.onTap});

  @override
  Widget build(BuildContext context) {
    final bool isCredit = account.isCredit ?? false;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 180,
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isCredit 
                ? [const Color(0xFF2D2D2D), const Color(0xFF4A4A4A)]
                : [const Color(0xFF6366F1), const Color(0xFF4F46E5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: (isCredit ? Colors.black : const Color(0xFF6366F1)).withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 5),
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
                  isCredit ? 'CREDIT' : 'DEBIT',
                  style: GoogleFonts.inter(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  account.cardType?.toUpperCase() ?? 'VISA',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              _formatCardNumber(account.cardNumber ?? 'XXXX XXXX XXXX XXXX'),
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
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
                      '₹${account.balance.toStringAsFixed(2)}',
                      style: GoogleFonts.inter(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'CURRENT BALANCE',
                      style: GoogleFonts.inter(color: Colors.white70, fontSize: 8),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      account.accountHolderName?.toUpperCase() ?? 'USER',
                      style: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'VALID THRU: ${account.expiryDate ?? 'MM/YY'}',
                      style: GoogleFonts.inter(color: Colors.white70, fontSize: 8),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatCardNumber(String number) {
    if (number.length < 12) return number;
    return '**** **** **** ${number.substring(number.length - 4)}';
  }
}
