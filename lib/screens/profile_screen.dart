import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/data_providers.dart';
import '../services/user_service.dart';
import 'profile/edit_profile_screen.dart';
import 'profile/notifications_screen.dart';
import 'security/security_settings_screen.dart';
import 'dart:io';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 60),
            _buildProfileHeader(context, ref),
            const SizedBox(height: 40),
            _buildSettingsSection(context, ref),
            const SizedBox(height: 40),
            _buildAppInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, WidgetRef ref) {
    final userProfile = ref.watch(userProfileProvider);
    
    return userProfile.when(
      data: (data) {
        final name = data['name'] ?? 'User Name';
        final email = data['email'] ?? 'user@example.com';
        final imagePath = data['image'];

        return Column(
          children: [
            GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen())),
              child: Container(
                width: 100, height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: imagePath == null ? const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF4F46E5)]) : null,
                  image: imagePath != null ? DecorationImage(image: FileImage(File(imagePath)), fit: BoxFit.cover) : null,
                  boxShadow: [
                    BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10)),
                  ],
                ),
                child: imagePath == null ? const Icon(Icons.person, size: 50, color: Colors.white) : null,
              ),
            ),
            const SizedBox(height: 16),
            Text(name, style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold)),
            Text(email, style: GoogleFonts.inter(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen())),
              icon: const Icon(Icons.edit_outlined, size: 16),
              label: Text('Edit Profile', style: GoogleFonts.inter(fontSize: 12)),
            ),
          ],
        );
      },
      loading: () => const CircularProgressIndicator(),
      error: (_, __) => const Text('Error loading profile'),
    );
  }


  Widget _buildSettingsSection(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSettingsTile(Icons.account_balance_wallet_outlined, 'Accounts Management', () {
            ref.read(transactionFilterProvider.notifier).setTabIndex(3); // Switch to Banking tab
          }),
          _buildDivider(),
          _buildSettingsTile(Icons.notifications_none_outlined, 'Notifications', () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()));
          }),
          _buildDivider(),
          _buildSettingsTile(Icons.security_outlined, 'Security', () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const SecuritySettingsScreen()));
          }),
          _buildDivider(),
          _buildSettingsTile(Icons.file_download_outlined, 'Export Data', () async {
            try {
              final path = await ref.read(databaseProvider).exportDataToJson();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Data exported to: $path')));
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e')));
              }
            }
          }),
          _buildDivider(),
          _buildSettingsTile(Icons.delete_outline, 'Clear Data', () async {
            final size = await ref.read(databaseProvider).getDataSize();
            if (context.mounted) {
              _showClearDataDialog(context, ref, size);
            }
          }, isDestructive: true),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(IconData icon, String title, VoidCallback onTap, {bool isDestructive = false}) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: isDestructive ? Colors.red : Colors.black87),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: isDestructive ? Colors.red : Colors.black87,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Divider(color: Colors.grey.withOpacity(0.1), height: 1),
    );
  }

  Widget _buildAppInfo() {
    return Column(
      children: [
        Text(
          'Budget Tracker v1.0.0',
          style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 4),
        Text(
          'Premium Edition',
          style: GoogleFonts.inter(
            fontSize: 10,
            color: const Color(0xFF6366F1),
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  void _showClearDataDialog(BuildContext context, WidgetRef ref, int sizeInBytes) {
    final sizeStr = sizeInBytes < 1024 
        ? '$sizeInBytes B' 
        : '${(sizeInBytes / 1024).toStringAsFixed(2)} KB';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Current data size: $sizeStr'),
            const SizedBox(height: 12),
            const Text('This will delete all transactions and accounts. This action cannot be undone.'),
            const SizedBox(height: 12),
            const Text('Tip: Save data for future reinstallation by clicking Export first.', style: TextStyle(fontSize: 12, color: Colors.blue)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                final path = await ref.read(databaseProvider).exportDataToJson();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Backup saved to: $path')));
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Backup failed: $e')));
                }
              }
            },
            child: const Text('Backup first'),
          ),
          TextButton(
            onPressed: () async {
              await ref.read(databaseProvider).clearAllData();
              if (context.mounted) Navigator.pop(context);
              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All data cleared')));
            },
            child: const Text('Clear All', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
