import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../providers/data_providers.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../utils/icon_helper.dart';
import '../services/user_service.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedCategory;
  String? _selectedType;
  String? _selectedMonthYear; // format "MM/yyyy"
  String? _selectedYear;

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(filteredTransactionsProvider);
    final categoriesAsync = ref.watch(categoryListProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text('History', style: GoogleFonts.inter(color: Colors.black, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.black),
            onPressed: () => _showFilterSheet(context, categoriesAsync),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_hasActiveFilters()) _buildActiveFilters(),
          Expanded(
            child: transactionsAsync.when(
              data: (list) => list.isEmpty 
                ? const Center(child: Text('No transactions found'))
                : ListView.builder(
                    padding: const EdgeInsets.all(24),
                    itemCount: list.length,
                    itemBuilder: (context, i) => _buildTransactionItem(list[i]),
                  ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, __) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }

  bool _hasActiveFilters() {
    return _startDate != null || _selectedCategory != null || _selectedType != null || _selectedMonthYear != null;
  }

  void _showFilterSheet(BuildContext context, AsyncValue<List<dynamic>> categories) async {
    final installDate = await ref.read(userServicePrivider).getInstallDate();
    
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Filters', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              
              Text('Type', style: GoogleFonts.inter(fontSize: 14, color: Colors.grey)),
              const SizedBox(height: 8),
              _buildChoiceList(['All', 'Spent', 'Income'], _selectedType ?? 'All', (val) {
                setState(() => _selectedType = val == 'All' ? null : val);
                ref.read(transactionFilterProvider.notifier).setType(_selectedType);
              }),

              const SizedBox(height: 24),
              Text('Category', style: GoogleFonts.inter(fontSize: 14, color: Colors.grey)),
              const SizedBox(height: 8),
              categories.when(
                data: (list) {
                  // Filter list based on _selectedType if it's not null or 'All'
                  final filteredList = list.where((c) {
                    if (_selectedType == null || _selectedType == 'All') return true;
                    final targetIndex = _selectedType == 'Income' ? 1 : 0;
                    return c.typeIndex == targetIndex;
                  }).map((c) => c.name).toSet().toList(); // toSet() to ensure unique names

                  return _buildChoiceList(['All', ...filteredList], _selectedCategory ?? 'All', (val) {
                    setState(() => _selectedCategory = val == 'All' ? null : val);
                    ref.read(transactionFilterProvider.notifier).setCategory(_selectedCategory);
                  });
                },
                loading: () => const SizedBox(),
                error: (_, __) => const SizedBox(),
              ),

              const SizedBox(height: 24),
              Text('Year', style: GoogleFonts.inter(fontSize: 14, color: Colors.grey)),
              const SizedBox(height: 8),
              _buildYearPicker(installDate),

              const SizedBox(height: 24),
              Text('Month', style: GoogleFonts.inter(fontSize: 14, color: Colors.grey)),
              const SizedBox(height: 8),
              _buildMonthYearPicker(installDate),

              const SizedBox(height: 24),
              Text('Custom Date Range', style: GoogleFonts.inter(fontSize: 14, color: Colors.grey)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        final date = await showDatePicker(context: context, initialDate: _startDate ?? DateTime.now(), firstDate: installDate, lastDate: DateTime.now());
                        if (date != null) {
                          setState(() {
                            _startDate = date;
                            _selectedMonthYear = null;
                          });
                          ref.read(transactionFilterProvider.notifier).setDateRange(_startDate, _endDate);
                        }
                      },
                      child: Text(_startDate == null ? 'From' : DateFormat('dd/MM/yyyy').format(_startDate!)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        final date = await showDatePicker(context: context, initialDate: _endDate ?? DateTime.now(), firstDate: _startDate ?? installDate, lastDate: DateTime.now());
                        if (date != null) {
                          setState(() {
                            _endDate = date;
                            _selectedMonthYear = null;
                          });
                          ref.read(transactionFilterProvider.notifier).setDateRange(_startDate, _endDate);
                        }
                      },
                      child: Text(_endDate == null ? 'To' : DateFormat('dd/MM/yyyy').format(_endDate!)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChoiceList(List<String> items, String current, Function(String) onSelected) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) => ChoiceChip(
          label: Text(items[i], style: TextStyle(fontSize: 12, color: current == items[i] ? Colors.white : Colors.black87)),
          selected: current == items[i],
          selectedColor: const Color(0xFF6366F1),
          onSelected: (s) {
            onSelected(items[i]);
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  Widget _buildMonthYearPicker(DateTime installDate) {
    final now = DateTime.now();
    List<String> options = [];
    DateTime temp = DateTime(installDate.year, installDate.month);
    while (temp.isBefore(now) || (temp.year == now.year && temp.month == now.month)) {
      options.add(DateFormat('MMM yyyy').format(temp));
      temp = DateTime(temp.year, temp.month + 1);
    }
    options = options.reversed.toList();

    return _buildChoiceList(['All', ...options], _selectedMonthYear == null ? 'All' : DateFormat('MMM yyyy').format(DateFormat('MM/yyyy').parse(_selectedMonthYear!)), (val) {
      if (val == 'All') {
        setState(() => _selectedMonthYear = null);
        ref.read(transactionFilterProvider.notifier).setDateRange(null, null);
      } else {
        final parsed = DateFormat('MMM yyyy').parse(val);
        setState(() {
          _selectedMonthYear = DateFormat('MM/yyyy').format(parsed);
          _selectedYear = null;
          _startDate = DateTime(parsed.year, parsed.month, 1);
          _endDate = DateTime(parsed.year, parsed.month + 1, 0);
        });
        ref.read(transactionFilterProvider.notifier).setDateRange(_startDate, _endDate);
      }
    });
  }

  Widget _buildYearPicker(DateTime installDate) {
    final now = DateTime.now();
    List<String> years = [];
    for (int y = installDate.year; y <= now.year; y++) {
      years.add(y.toString());
    }
    years = years.reversed.toList();

    return _buildChoiceList(['All', ...years], _selectedYear ?? 'All', (val) {
      if (val == 'All') {
        setState(() => _selectedYear = null);
        ref.read(transactionFilterProvider.notifier).setDateRange(null, null);
      } else {
        final year = int.parse(val);
        setState(() {
          _selectedYear = val;
          _selectedMonthYear = null;
          _startDate = DateTime(year, 1, 1);
          _endDate = DateTime(year, 12, 31);
        });
        ref.read(transactionFilterProvider.notifier).setDateRange(_startDate, _endDate);
      }
    });
  }

  Widget _buildActiveFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      color: Colors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            const Icon(Icons.filter_alt_outlined, size: 16, color: Colors.grey),
            const SizedBox(width: 12),
            if (_selectedType != null)
              _filterChip(_selectedType!, () {
                setState(() => _selectedType = null);
                ref.read(transactionFilterProvider.notifier).setType(null);
              }),
            if (_selectedCategory != null)
              _filterChip(_selectedCategory!, () {
                setState(() => _selectedCategory = null);
                ref.read(transactionFilterProvider.notifier).setCategory(null);
              }),
            if (_selectedMonthYear != null)
              _filterChip(DateFormat('MMM yyyy').format(DateFormat('MM/yyyy').parse(_selectedMonthYear!)), () {
                setState(() {
                  _selectedMonthYear = null;
                  _startDate = null;
                  _endDate = null;
                });
                ref.read(transactionFilterProvider.notifier).setDateRange(null, null);
              })
            else if (_selectedYear != null)
              _filterChip(_selectedYear!, () {
                setState(() {
                  _selectedYear = null;
                  _startDate = null;
                  _endDate = null;
                });
                ref.read(transactionFilterProvider.notifier).setDateRange(null, null);
              })
            else if (_startDate != null)
              _filterChip('${DateFormat('dd/MM/yyyy').format(_startDate!)} - ${_endDate != null ? DateFormat('dd/MM/yyyy').format(_endDate!) : 'now'}', () {
                setState(() {
                  _startDate = null;
                  _endDate = null;
                });
                ref.read(transactionFilterProvider.notifier).setDateRange(null, null);
              }),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String label, VoidCallback onDeleted) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: Chip(
        label: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF6366F1))),
        deleteIcon: const Icon(Icons.close, size: 14, color: Color(0xFF6366F1)),
        onDeleted: onDeleted,
        backgroundColor: const Color(0xFF6366F1).withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide.none),
      ),
    );
  }

  Widget _buildTransactionItem(Transaction t) {
    final isIncome = t.amount > 0;
    final color = isIncome ? Colors.green : Colors.red;
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(16)),
            child: Icon(IconHelper.getIcon(t.category.value?.iconCode ?? Icons.circle.codePoint), color: color, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.title, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
                const SizedBox(height: 2),
                Text('${t.categoryName} • ${DateFormat('dd/MM/yyyy').format(t.date)}', style: GoogleFonts.inter(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${isIncome ? "+" : "-"}₹${t.amount.abs().toStringAsFixed(2)}', style: GoogleFonts.inter(color: color, fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 2),
              Text(t.accountName, style: GoogleFonts.inter(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }
}
