import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'add_bank_details_screen.dart';

class BankSelectionScreen extends StatefulWidget {
  const BankSelectionScreen({super.key});

  @override
  State<BankSelectionScreen> createState() => _BankSelectionScreenState();
}

class _BankSelectionScreenState extends State<BankSelectionScreen> {
  final List<String> _allBanks = [
    'Axis Bank',
    'Bank of Baroda',
    'Bank of India',
    'Bank of Maharashtra',
    'Canara Bank',
    'Central Bank of India',
    'City Union Bank',
    'CSB Bank',
    'DBS Bank India',
    'DCB Bank',
    'Dhanlaxmi Bank',
    'Federal Bank',
    'HDFC Bank',
    'ICICI Bank',
    'IDBI Bank',
    'IDFC First Bank',
    'Indian Bank',
    'Indian Overseas Bank',
    'IndusInd Bank',
    'Jammu & Kashmir Bank',
    'Karnataka Bank',
    'Karur Vysya Bank',
    'Kotak Mahindra Bank',
    'Nainital Bank',
    'Punjab & Sind Bank',
    'Punjab National Bank',
    'RBL Bank',
    'South Indian Bank',
    'State Bank of India',
    'Tamilnad Mercantile Bank',
    'UCO Bank',
    'Union Bank of India',
    'YES Bank',
  ];

  List<String> _filteredBanks = [];
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<String> _alphabets = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.split('');

  @override
  void initState() {
    super.initState();
    _filteredBanks = _allBanks;
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    setState(() {
      _filteredBanks = _allBanks
          .where((bank) => bank.toLowerCase().contains(_searchController.text.toLowerCase()))
          .toList();
    });
  }

  void _scrollToAlphabet(String letter) {
    final index = _filteredBanks.indexWhere((bank) => bank.startsWith(letter));
    if (index != -1) {
      _scrollController.animateTo(
        index * 72.0, // ListTile height approx
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

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
        title: Text('Search Bank', style: GoogleFonts.inter(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: Row(
        children: [
          // Alphabet Index
          Container(
            width: 32,
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: ListView.builder(
              itemCount: _alphabets.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () => _scrollToAlphabet(_alphabets[index]),
                  child: Container(
                    height: 20,
                    alignment: Alignment.center,
                    child: Text(
                      _alphabets[index],
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                  ),
                );
              },
            ),
          ),
          // Main Content
          Expanded(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search for your bank',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: const Color(0xFFF1F1F1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: _filteredBanks.length,
                    itemBuilder: (context, index) {
                      final bank = _filteredBanks[index];
                      return ListTile(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddBankDetailsScreen(bankName: bank),
                            ),
                          );
                        },
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFFF1F1F1),
                          child: Text(bank[0], style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                        ),
                        title: Text(bank, style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
