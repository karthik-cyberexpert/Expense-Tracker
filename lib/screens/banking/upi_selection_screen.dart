import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'add_upi_details_screen.dart';

class UPISelectionScreen extends StatefulWidget {
  const UPISelectionScreen({super.key});

  @override
  State<UPISelectionScreen> createState() => _UPISelectionScreenState();
}

class _UPISelectionScreenState extends State<UPISelectionScreen> {
  final List<Map<String, dynamic>> _upiApps = [
    {'name': 'PhonePe', 'icon': Icons.account_balance_wallet, 'color': const Color(0xFF5F259F)},
    {'name': 'Google Pay', 'icon': Icons.payment, 'color': const Color(0xFF4285F4)},
    {'name': 'Paytm', 'icon': Icons.account_balance, 'color': const Color(0xFF00B9F1)},
    {'name': 'Amazon Pay', 'icon': Icons.shopping_bag, 'color': const Color(0xFFFF9900)},
    {'name': 'WhatsApp Pay', 'icon': Icons.message, 'color': const Color(0xFF25D366)},
    {'name': 'BHIM UPI', 'icon': Icons.qr_code, 'color': const Color(0xFFE31E24)},
    {'name': 'MobiKwik', 'icon': Icons.wallet, 'color': const Color(0xFF003780)},
  ];

  List<Map<String, dynamic>> _filteredApps = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredApps = _upiApps;
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    setState(() {
      _filteredApps = _upiApps
          .where((app) => app['name'].toLowerCase().contains(_searchController.text.toLowerCase()))
          .toList();
    });
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
        title: Text('Select UPI App', style: GoogleFonts.inter(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search UPI App',
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
              itemCount: _filteredApps.length,
              itemBuilder: (context, index) {
                final app = _filteredApps[index];
                return ListTile(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddUPIDetailsScreen(appName: app['name'], appColor: app['color']),
                      ),
                    );
                  },
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: app['color'].withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(app['icon'], color: app['color']),
                  ),
                  title: Text(app['name'], style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
