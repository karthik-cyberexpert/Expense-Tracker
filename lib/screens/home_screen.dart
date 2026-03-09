import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/data_providers.dart';
import '../models/transaction.dart';
import '../models/account.dart';
import '../utils/icon_helper.dart';
import 'banking_screen.dart';
import 'banking/account_overview_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String _selectedTab = 'All';

  @override
  Widget build(BuildContext context) {
    final summary = ref.watch(balanceSummaryProvider);
    final transactionsAsync = ref.watch(transactionListProvider);
    final accountsAsync = ref.watch(accountListProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(context, summary['total'] ?? 0, accountsAsync),
            const SizedBox(height: 24),
            transactionsAsync.when(
              data: (list) => _buildReportSection(context, summary['spent'] ?? 0, summary['income'] ?? 0, list),
              loading: () => _buildReportSection(context, 0, 0, []),
              error: (_, __) => _buildReportSection(context, 0, 0, []),
            ),
            const SizedBox(height: 24),
            _buildTransactionSection(context, transactionsAsync),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, double total, AsyncValue<List<Account>> accounts) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2D1B69), Color(0xFF4A148C), Color(0xFF6A1B9A)],
        ),
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Total savings', style: GoogleFonts.inter(color: Colors.white70, fontSize: 14)),
              const SizedBox(width: 8),
              const Icon(Icons.visibility_outlined, color: Colors.white70, size: 16),
            ],
          ),
          const SizedBox(height: 8),
          Text('₹${total.toStringAsFixed(2)}', style: GoogleFonts.inter(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
            child: Text(
              'Manage your finances seamlessly with Expense Tracker.',
              style: GoogleFonts.inter(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 44,
            child: accounts.when(
              data: (list) => ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: list.length + 1,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, i) {
                  if (i == list.length) {
                    return GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const BankingScreen())),
                      child: Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.add, color: Colors.white),
                      ),
                    );
                  }
                  final account = list[i];
                  return GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => AccountOverviewScreen(account: account))),
                    child: _buildBrandLogo(account.name, Color(account.colorValue)),
                  );
                },
              ),
              loading: () => const Center(child: CircularProgressIndicator(color: Colors.white)),
              error: (_, __) => const SizedBox(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrandLogo(String text, Color bgColor) {
    return Container(
      width: 44, height: 44,
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
      alignment: Alignment.center,
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildReportSection(BuildContext context, double spent, double income, List<Transaction> transactions) {
    final now = DateTime.now();
    final last7Days = List.generate(7, (i) => DateUtils.dateOnly(now.subtract(Duration(days: 6 - i))));
    
    final incomeSpots = last7Days.asMap().entries.map((e) {
      final day = e.value;
      final dailyIncome = transactions
          .where((t) => DateUtils.isSameDay(t.date, day) && t.amount > 0)
          .fold(0.0, (sum, t) => sum + t.amount);
      return FlSpot(e.key.toDouble(), dailyIncome);
    }).toList();

    final spentSpots = last7Days.asMap().entries.map((e) {
      final day = e.value;
      final dailySpent = transactions
          .where((t) => DateUtils.isSameDay(t.date, day) && t.amount < 0)
          .fold(0.0, (sum, t) => sum + t.amount.abs());
      return FlSpot(e.key.toDouble(), dailySpent);
    }).toList();

    List<LineChartBarData> barData = [];
    if (_selectedTab == 'All' || _selectedTab == 'Income') {
      barData.add(LineChartBarData(
        spots: incomeSpots.isEmpty ? [const FlSpot(0, 0), const FlSpot(6, 0)] : incomeSpots,
        isCurved: true, color: Colors.green, barWidth: 3, dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(show: true, color: Colors.green.withOpacity(0.1)),
      ));
    }
    if (_selectedTab == 'All' || _selectedTab == 'Spent') {
      barData.add(LineChartBarData(
        spots: spentSpots.isEmpty ? [const FlSpot(0, 0), const FlSpot(6, 0)] : spentSpots,
        isCurved: true, color: Colors.red, barWidth: 3, dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(show: true, color: Colors.red.withOpacity(0.1)),
      ));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Report this week', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
                GestureDetector(
                  onTap: () => ref.read(transactionFilterProvider.notifier).setTabIndex(1),
                  child: Text('See details', style: GoogleFonts.inter(color: Colors.blueAccent, fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _buildReportTab('All'),
                _buildReportTab('Spent'),
                _buildReportTab('Income'),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 120,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: barData,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportTab(String title) {
    final isSelected = _selectedTab == title;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = title),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(color: isSelected ? const Color(0xFFF1F1F1) : Colors.transparent, borderRadius: BorderRadius.circular(12)),
          child: Center(
            child: Text(title, style: GoogleFonts.inter(color: isSelected ? Colors.black : Colors.grey, fontSize: 13, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionSection(BuildContext context, AsyncValue<List<Transaction>> transactions) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Recent transaction', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),
          transactions.when(
            data: (list) => Column(
              children: [
                ...list.take(5).map((t) => _buildTransactionItem(
                      t.title,
                      t.categoryName,
                      '${t.date.day.toString().padLeft(2, '0')}/${t.date.month.toString().padLeft(2, '0')}/${t.date.year}',
                      '${t.amount > 0 ? "+" : "-"}₹${t.amount.abs().toStringAsFixed(2)}',
                      t.accountName,
                      IconHelper.getIcon(t.category.value?.iconCode ?? Icons.circle.codePoint),
                      t.amount > 0 ? Colors.green : Colors.red,
                    )),
                if (list.isEmpty) const Center(child: Text('No transactions yet')),
              ],
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, __) => Center(child: Text('Error: $e')),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => ref.read(transactionFilterProvider.notifier).setTabIndex(1),
              style: TextButton.styleFrom(backgroundColor: const Color(0xFFF1F1F1), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              child: Text('See all transaction', style: GoogleFonts.inter(color: Colors.black, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(String title, String category, String date, String amount, String account, IconData icon, Color color) {
    final isIncome = amount.startsWith('+');
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 20)),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14)),
            Text('$category • $date', style: GoogleFonts.inter(color: Colors.grey, fontSize: 12)),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(amount, style: GoogleFonts.inter(color: isIncome ? Colors.green : Colors.red, fontWeight: FontWeight.bold, fontSize: 14)),
            Text(account, style: GoogleFonts.inter(color: Colors.grey, fontSize: 11)),
          ]),
        ],
      ),
    );
  }
}
