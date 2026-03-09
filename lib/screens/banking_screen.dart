import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/data_providers.dart';
import '../models/account.dart';
import 'banking/bank_selection_screen.dart';
import 'banking/upi_selection_screen.dart';
import 'banking/add_card_screen.dart';
import 'banking/account_overview_screen.dart';
import 'banking/add_wallet_screen.dart';
import '../widgets/bank_card.dart';
import 'package:lucide_icons/lucide_icons.dart';

class BankingScreen extends ConsumerStatefulWidget {
  const BankingScreen({super.key});

  @override
  ConsumerState<BankingScreen> createState() => _BankingScreenState();
}

class _BankingScreenState extends ConsumerState<BankingScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(accountListProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text('Banking', style: GoogleFonts.inter(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF6366F1),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF6366F1),
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Banks'),
            Tab(text: 'UPI'),
            Tab(text: 'Cards'),
            Tab(text: 'Wallet'),
          ],
        ),
      ),
      body: accountsAsync.when(
        data: (accounts) => TabBarView(
          controller: _tabController,
          children: [
            _buildBankSection(accounts.where((a) => a.type == AccountType.bank).toList()),
            _buildUPISection(accounts.where((a) => a.type == AccountType.upi).toList()),
            _buildCardSection(accounts.where((a) => a.type == AccountType.card).toList()),
            _buildWalletSection(accounts.where((a) => a.type == AccountType.cash).toList()),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, __) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _onAddPressed,
        backgroundColor: const Color(0xFF1E1E1E),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _onAddPressed() {
    switch (_tabController.index) {
      case 0:
        Navigator.push(context, MaterialPageRoute(builder: (context) => const BankSelectionScreen()));
        break;
      case 1:
        Navigator.push(context, MaterialPageRoute(builder: (context) => const UPISelectionScreen()));
        break;
      case 2:
        Navigator.push(context, MaterialPageRoute(builder: (context) => const AddCardScreen()));
        break;
      case 3:
        Navigator.push(context, MaterialPageRoute(builder: (context) => const AddWalletScreen()));
        break;
    }
  }

  Widget _buildWalletSection(List<Account> accounts) {
    if (accounts.isEmpty) {
      return _buildEmptyState(Icons.account_balance_wallet_outlined, 'Wallets');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: accounts.length,
      itemBuilder: (context, index) {
        final account = accounts[index];
        return _buildAccountTile(account);
      },
    );
  }

  Widget _buildBankSection(List<Account> accounts) {
    if (accounts.isEmpty) {
      return _buildEmptyState(Icons.account_balance_outlined, 'Banks');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: accounts.length,
      itemBuilder: (context, index) {
        final account = accounts[index];
        return _buildAccountTile(account);
      },
    );
  }

  Widget _buildUPISection(List<Account> accounts) {
    if (accounts.isEmpty) {
      return _buildEmptyState(Icons.qr_code_scanner, 'UPI Profiles');
    }

    return GridView.builder(
      padding: const EdgeInsets.all(24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.1,
      ),
      itemCount: accounts.length,
      itemBuilder: (context, index) {
        final account = accounts[index];
        return GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => AccountOverviewScreen(account: account))),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Color(account.colorValue).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.qr_code_scanner, color: Color(account.colorValue), size: 32),
                ),
                const SizedBox(height: 12),
                Text(account.name, style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                Text(account.owner, style: GoogleFonts.inter(fontSize: 10, color: Colors.grey)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCardSection(List<Account> accounts) {
    if (accounts.isEmpty) {
      return _buildEmptyState(Icons.credit_card, 'Cards');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: accounts.length,
      itemBuilder: (context, index) {
        final account = accounts[index];
        return BankCardWidget(
          account: account,
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => AccountOverviewScreen(account: account))),
        );
      },
    );
  }

  Widget _buildEmptyState(IconData icon, String type) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text('No $type found', style: GoogleFonts.inter(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildAccountTile(Account account) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: ListTile(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => AccountOverviewScreen(account: account))),
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 56, height: 56,
          decoration: BoxDecoration(
            color: Color(account.colorValue).withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(_getIconForType(account.type), color: Color(account.colorValue)),
        ),
        title: Text(account.name, style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        subtitle: Text(account.displayName, style: GoogleFonts.inter(color: Colors.grey, fontSize: 12)),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('₹${account.balance.toStringAsFixed(2)}', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
            const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  IconData _getIconForType(AccountType type) {
    switch (type) {
      case AccountType.bank: return Icons.account_balance;
      case AccountType.upi: return Icons.qr_code_scanner;
      case AccountType.card: return Icons.credit_card;
      case AccountType.cash: return Icons.account_balance_wallet;
    }
  }
}
