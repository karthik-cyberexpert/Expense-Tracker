import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/data_providers.dart';
import 'home_screen.dart';
import 'add_transaction_screen.dart';
import 'history_screen.dart';
import 'banking_screen.dart';
import 'profile_screen.dart';
import '../services/security_service.dart';
import 'security/security_question_dialog.dart';
import '../services/user_service.dart';

class MainNavigation extends ConsumerStatefulWidget {
  const MainNavigation({super.key});

  @override
  ConsumerState<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends ConsumerState<MainNavigation> {
  @override
  void initState() {
    super.initState();
    _checkSecurityQuestion();
    _updateLastActive();
  }

  void _checkSecurityQuestion() async {
    final security = ref.read(securityServiceProvider);
    final question = await security.getSecurityQuestion();
    if (question == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        SecurityQuestionDialog.show(context);
      });
    }
  }

  void _updateLastActive() {
    ref.read(userServicePrivider).touchLastActive();
    ref.read(userServicePrivider).setInstallDateIfNotSet();
  }

  Future<bool> _onWillPop() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit App'),
        content: const Text('Are you sure want to Exit?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Yes')),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = ref.watch(transactionFilterProvider.select((s) => s['tabIndex'] as int));

    final List<Widget> _screens = [
      const HomeScreen(),
      const HistoryScreen(),
      const SizedBox(), // Placeholder for Add
      const BankingScreen(),
      const ProfileScreen(),
    ];

    void _onItemTapped(int index) {
      if (index == 2) {
        Navigator.of(context).push(
          MaterialPageRoute(
            fullscreenDialog: true,
            builder: (context) => const AddTransactionScreen(),
          ),
        );
        return;
      }
      ref.read(transactionFilterProvider.notifier).setTabIndex(index);
    }

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FE),
        body: IndexedStack(
          index: selectedIndex,
          children: _screens,
        ),
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: Colors.black,
          unselectedItemColor: Colors.grey,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          currentIndex: selectedIndex,
          onTap: _onItemTapped,
          items: [
            const BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
            const BottomNavigationBarItem(icon: Icon(Icons.pie_chart_outline), label: 'History'),
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(color: Color(0xFF1E1E1E), shape: BoxShape.circle),
                child: const Icon(Icons.add, color: Colors.white),
              ),
              label: '',
            ),
            const BottomNavigationBarItem(icon: Icon(Icons.account_balance_outlined), label: 'Banking'),
            const BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}
