import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/data_providers.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../models/account.dart';
import '../utils/icon_helper.dart';
import 'choose_account_screen.dart';
import '../services/notification_service.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  final String? initialTitle;
  const AddTransactionScreen({super.key, this.initialTitle});

  @override
  ConsumerState<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  String _amount = "0";
  Category? _selectedCategory;
  Account? _selectedAccount;
  String _type = 'Spent'; // Spent or Income
  late final TextEditingController _titleController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle);
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _onSave() async {
    if (_amount == "0" || _selectedCategory == null || _selectedAccount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    final amountVal = double.parse(_amount);
    final finalAmount = _type == 'Spent' ? -amountVal : amountVal;

    final transaction = Transaction()
      ..title = _titleController.text.isEmpty ? _selectedCategory!.name : _titleController.text
      ..amount = finalAmount
      ..date = DateTime.now()
      ..categoryName = _selectedCategory!.name
      ..accountName = _selectedAccount!.name;
    
    transaction.category.value = _selectedCategory;
    transaction.account.value = _selectedAccount;

    await ref.read(databaseProvider).addTransaction(transaction);
    
    // Trigger notification
    NotificationService.showTransactionNotification(
      title: transaction.title,
      amount: amountVal,
      isIncome: _type == 'Income',
    );
    
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoryListProvider);
    final accountsAsync = ref.watch(accountListProvider);
    
    // Set defaults if not set
    if (_selectedAccount == null && accountsAsync.hasValue && accountsAsync.value!.isNotEmpty) {
      _selectedAccount = accountsAsync.value!.first;
    }

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        toolbarHeight: 56,
        leading: IconButton(icon: const Icon(Icons.close, color: Colors.black, size: 24), onPressed: () => Navigator.of(context).pop()),
        title: Text('Add transaction', style: GoogleFonts.inter(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
        actions: [IconButton(icon: const Icon(Icons.help_outline, color: Colors.black, size: 24), onPressed: _showHelpDialog)],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            children: [
              _buildTypeTabs(),
              const SizedBox(height: 12),
              
              // TITLE SECTION
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('TITLE', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF6366F1), letterSpacing: 1.0)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FE),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFF1F1F1)),
                      ),
                      child: TextField(
                        controller: _titleController,
                        style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
                        decoration: const InputDecoration(
                          hintText: 'What did you spend on?',
                          hintStyle: TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.normal),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              
              // CATEGORY GRID
              Expanded(
                child: categoriesAsync.when(
                  data: (list) {
                    final targetIndex = _type == 'Income' ? 1 : 0;
                    final sortedList = list.where((c) => c.typeIndex == targetIndex).toList();
                    sortedList.sort((a, b) {
                      if (a.name == 'Others') return 1;
                      if (b.name == 'Others') return -1;
                      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
                    });

                    if (sortedList.isEmpty) return _buildEmptyCategories(ref);
                    return _buildCategoryGrid(sortedList);
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (_, __) => const Center(child: Text('Error loading categories')),
                ),
              ),

              // BOTTOM ACTIONS
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -4))],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildAccountSelector(),
                    const SizedBox(height: 12),
                    _buildAmountInput(),
                    const SizedBox(height: 8),
                    _buildNumericKeypad(),
                    const SizedBox(height: 12),
                    _buildSaveButton(),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyCategories(WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Setting up categories...', style: TextStyle(fontSize: 14, color: Colors.grey)),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () async {
              await ref.read(databaseProvider).forceReseed();
              setState(() {});
            },
            child: const Text('Reset Categories', style: TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24), padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: const Color(0xFFF1F1F1), borderRadius: BorderRadius.circular(16)),
      child: Row(children: [
        _buildTypeTab('Spent'), _buildTypeTab('Income'),
      ]),
    );
  }

  Widget _buildTypeTab(String title) {
    final isSelected = _type == title;
    return Expanded(child: GestureDetector(
      onTap: () => setState(() {
        _type = title;
        _selectedCategory = null; // reset category on type change
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(color: isSelected ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(12), boxShadow: isSelected ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)] : null),
        child: Center(child: Text(title, style: GoogleFonts.inter(color: isSelected ? Colors.black : Colors.grey, fontSize: 13, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500))),
      ),
    ));
  }

  Widget _buildCategoryGrid(List<Category> cats) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20), 
      child: GridView.builder(
        shrinkWrap: true, 
        physics: const BouncingScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 6,
          mainAxisSpacing: 10,
          crossAxisSpacing: 8,
          childAspectRatio: 0.7
        ),
        itemCount: cats.length,
        itemBuilder: (context, i) {
          final category = cats[i];
          final isSelected = _selectedCategory?.id == category.id;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = category), 
            child: Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(8), 
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF6366F1).withOpacity(0.12) : const Color(0xFFF8F9FE), 
                    borderRadius: BorderRadius.circular(14), 
                    border: Border.all(color: isSelected ? const Color(0xFF6366F1) : const Color(0xFFF1F1F1), width: 1.5)
                  ), 
                  child: Icon(
                    IconHelper.getIcon(category.iconCode), 
                    color: isSelected ? const Color(0xFF6366F1) : Colors.black87, 
                    size: 22
                  )
                ),
                const SizedBox(height: 4), 
                Text(
                  category.name, 
                  style: GoogleFonts.inter(fontSize: 10, color: isSelected ? const Color(0xFF6366F1) : Colors.black87, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500), 
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ]
            )
          );
        },
      )
    );
  }

  Widget _buildAccountSelector() {
    return GestureDetector(
      onTap: () async {
        final result = await Navigator.of(context).push<Account>(MaterialPageRoute(builder: (_) => const ChooseAccountScreen()));
        if (result != null) {
          setState(() => _selectedAccount = result);
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FE), 
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF1F1F1)),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Select Account', style: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 14)),
          Row(children: [
            if (_selectedAccount != null) ...[
              Container(
                width: 28, height: 28, 
                decoration: BoxDecoration(color: Color(_selectedAccount!.colorValue), borderRadius: BorderRadius.circular(8)), 
                alignment: Alignment.center, 
                child: Text(_selectedAccount!.name[0], style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))
              ),
              const SizedBox(width: 10),
              Text(_selectedAccount!.name, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14)),
            ],
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
          ]),
        ]),
      ),
    );
  }

  Widget _buildAmountInput() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24), 
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FE), 
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('₹', style: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black)),
            const SizedBox(width: 12),
            Text(_amount, style: GoogleFonts.inter(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.black)),
          ],
        ),
      ),
    );
  }

  Widget _buildNumericKeypad() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32), 
      child: Column(
        children: [
          Row(children: [_buildKey('1'), _buildKey('2'), _buildKey('3')]),
          const SizedBox(height: 8),
          Row(children: [_buildKey('4'), _buildKey('5'), _buildKey('6')]),
          const SizedBox(height: 8),
          Row(children: [_buildKey('7'), _buildKey('8'), _buildKey('9')]),
          const SizedBox(height: 8),
          Row(children: [_buildKey('.'), _buildKey('0'), _buildKeyIcon(Icons.backspace_outlined, isBack: true)]),
        ],
      ),
    );
  }

  Widget _buildKey(String val) => Expanded(
    child: InkWell(
      onTap: () => setState(() => _amount = _amount == "0" ? val : _amount + val), 
      borderRadius: BorderRadius.circular(12),
      child: Container(height: 48, alignment: Alignment.center, child: Text(val, style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w600)))
    )
  );
  Widget _buildKeyIcon(IconData icon, {bool isBack = false}) => Expanded(
    child: InkWell(
      onTap: () { if (isBack) setState(() { _amount = _amount.length > 1 ? _amount.substring(0, _amount.length - 1) : "0"; }); }, 
      borderRadius: BorderRadius.circular(12),
      child: Container(height: 48, alignment: Alignment.center, child: Icon(icon, size: 24, color: Colors.black87))
    )
  );

  Widget _buildSaveButton() {
    return Container(
      width: double.infinity, 
      margin: const EdgeInsets.symmetric(horizontal: 24), 
      height: 56, 
      child: ElevatedButton(
        onPressed: _onSave, 
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1E1E1E), 
          foregroundColor: Colors.white, 
          elevation: 2,
          shadowColor: Colors.black54,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
        ),
        child: Text('Save Transaction', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 0.5)),
      )
    );
  }
  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('How to use Add Transaction', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('1. Choose between Spent (Expense) or Income using the top tabs.'),
              SizedBox(height: 12),
              Text('2. Enter a Title for your transaction (e.g. "Lunch" or "Grocery").'),
              SizedBox(height: 12),
              Text('3. Select a Category from the grid below the title.'),
              SizedBox(height: 12),
              Text('4. Choose the Account (Bank/UPI/Cash) that you used.'),
              SizedBox(height: 12),
              Text('5. Use the Keypad to enter the exact Amount in ₹.'),
              SizedBox(height: 12),
              Text('6. Click "Save" to record your transaction instantly.'),
              SizedBox(height: 20),
              Text('Tip: Auto-Detection features can help record payments even faster when you pay using UPI apps!', style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.indigo)),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Got it!')),
        ],
      ),
    );
  }
}
