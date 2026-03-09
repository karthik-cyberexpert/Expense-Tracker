import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/data_providers.dart';
import '../models/account.dart';

class ChooseAccountScreen extends ConsumerWidget {
  const ChooseAccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(accountListProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.close, color: Colors.black), onPressed: () => Navigator.of(context).pop()),
        title: Text('Choose Account', style: GoogleFonts.inter(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
        centerTitle: true,
      ),
      body: accountsAsync.when(
        data: (list) => SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(padding: const EdgeInsets.fromLTRB(24, 20, 24, 12), child: Text('ACCOUNTS', style: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.bold, fontSize: 12))),
              ...list.map((acc) => _buildAccountTile(context, acc)),
              const SizedBox(height: 40),
              Center(
                child: TextButton(
                  onPressed: () {
                    // Close ChooseAccountScreen
                    Navigator.of(context).pop();
                    // Close AddTransactionScreen
                    Navigator.of(context).pop();
                    // Switch to Banking tab (Index 3)
                    ref.read(transactionFilterProvider.notifier).setTabIndex(3);
                  }, 
                  child: Text('Add new account', style: GoogleFonts.inter(color: Colors.black, fontWeight: FontWeight.bold))
                )
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, __) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildAccountTile(BuildContext context, Account account) {
    return InkWell(
      onTap: () => Navigator.of(context).pop(account),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(color: Color(account.colorValue), borderRadius: BorderRadius.circular(12)),
              alignment: Alignment.center,
              child: Text(account.name[0], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(account.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              Text(account.owner, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
            ])),
            Text('₹${account.balance.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
