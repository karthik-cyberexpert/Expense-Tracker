import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/account.dart';
import '../../providers/data_providers.dart';
import '../../widgets/bank_card.dart';

class AccountOverviewScreen extends ConsumerWidget {
  final Account account;
  const AccountOverviewScreen({super.key, required this.account});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(account.displayName, style: GoogleFonts.inter(color: Colors.black, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () => _showDeleteConfirmation(context, ref),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildDetailsSection(),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Recent Transactions', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold)),
                  TextButton(onPressed: () {}, child: const Text('See All')),
                ],
              ),
            ),
            _buildTransactionsList(ref),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    if (account.type == AccountType.card) {
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: BankCardWidget(account: account),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Color(account.colorValue).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              account.type == AccountType.bank ? Icons.account_balance : Icons.qr_code_scanner,
              color: Color(account.colorValue),
              size: 48,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '₹${account.balance.toStringAsFixed(2)}',
            style: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.bold),
          ),
          Text(
            'Current Balance',
            style: GoogleFonts.inter(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ACCOUNT DETAILS', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 16),
          if (account.type == AccountType.bank) ...[
            _buildDetailRow('Account Holder', account.accountHolderName ?? 'N/A'),
            _buildDetailRow('Account Number', account.accountNumber ?? 'N/A'),
            _buildDetailRow('IFSC Code', account.ifscCode ?? 'N/A'),
          ] else if (account.type == AccountType.upi) ...[
            _buildDetailRow('Account Holder', account.accountHolderName ?? 'N/A'),
            _buildDetailRow('UPI ID', account.upiId ?? 'N/A'),
          ] else if (account.type == AccountType.card) ...[
            _buildDetailRow('Card Holder', account.accountHolderName ?? 'N/A'),
            _buildDetailRow('Card Number', '**** **** **** ${account.cardNumber?.substring((account.cardNumber?.length ?? 4) - 4) ?? "XXXX"}'),
            _buildDetailRow('Expiry Date', account.expiryDate ?? 'MM/YY'),
            _buildDetailRow('Card Type', account.cardType ?? 'N/A'),
            _buildDetailRow('Type', account.isCredit == true ? 'Credit' : 'Debit'),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(color: Colors.grey[600], fontSize: 14)),
          Text(value, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildTransactionsList(WidgetRef ref) {
    final transactionsAsync = ref.watch(transactionListProvider);
    return transactionsAsync.when(
      data: (list) {
        final filtered = list.where((t) => t.accountName == account.name).take(5).toList();
        if (filtered.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(32.0),
            child: Text('No recent transactions'),
          );
        }
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: filtered.length,
          itemBuilder: (context, i) {
            final t = filtered[i];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: (t.amount < 0 ? Colors.red : Colors.green).withOpacity(0.1),
                child: Icon(t.amount < 0 ? Icons.arrow_downward : Icons.arrow_upward, 
                  color: t.amount < 0 ? Colors.red : Colors.green, size: 16),
              ),
              title: Text(t.title, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              subtitle: Text(t.date.toString().split(' ')[0], style: const TextStyle(fontSize: 12)),
              trailing: Text(
                '${t.amount < 0 ? "-" : "+"}₹${t.amount.abs().toStringAsFixed(2)}',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  color: t.amount < 0 ? Colors.red : Colors.green,
                ),
              ),
            );
          },
        );
      },
      loading: () => const CircularProgressIndicator(),
      error: (_, __) => const Text('Error loading transactions'),
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove ${account.name}?'),
        content: const Text('Are you sure you want to remove this account?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              await ref.read(databaseProvider).removeAccount(account.id);
              if (context.mounted) {
                Navigator.pop(context); // close dialog
                Navigator.pop(context); // go back from overview
              }
            },
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
