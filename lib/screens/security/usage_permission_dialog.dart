import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:app_settings/app_settings.dart';
import '../../services/upi_monitor_service.dart';

class UsagePermissionDialog extends ConsumerStatefulWidget {
  const UsagePermissionDialog({super.key});

  static Future<bool> show(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const UsagePermissionDialog(),
    ) ?? false;
  }

  @override
  ConsumerState<UsagePermissionDialog> createState() => _UsagePermissionDialogState();
}

class _UsagePermissionDialogState extends ConsumerState<UsagePermissionDialog> {
  bool _restrictedAllowed = false;
  bool _usageAllowed = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final hasUsage = await ref.read(upiMonitorProvider).checkPermission();
    // Note: There's no direct API to check if "Restricted Settings" was clicked in settings,
    // but on Android 13/14, "Restricted Settings" is what prevents setting Usage Access.
    // If Usage Access is finally granted, it means restricted was bypassed.
    setState(() {
      _usageAllowed = hasUsage;
      _restrictedAllowed = hasUsage; // If usage is on, restricted must have been bypassed
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Permissions Required', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'To auto-detect payments, we need two steps on your device:',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 24),
          _buildRow(
            'Step 1: Allow Restricted Settings',
            'Go to App Settings > Three dots (⋮) > Allow restricted settings.',
            _restrictedAllowed,
            () async {
              await AppSettings.openAppSettings(type: AppSettingsType.settings);
              // When user returns, they might have enabled it.
            },
          ),
          const SizedBox(height: 20),
          _buildRow(
            'Step 2: Grant Usage Access',
            'Allow this app to detect when you exit a payment application.',
            _usageAllowed,
            () async {
              await ref.read(upiMonitorProvider).requestPermission();
              await _checkPermissions();
            },
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, _usageAllowed), child: const Text('Back')),
        if (_usageAllowed)
           ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1), foregroundColor: Colors.white),
            child: const Text('All Set!'),
          ),
      ],
    );
  }

  Widget _buildRow(String title, String subtitle, bool isAllowed, VoidCallback onAllow) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(isAllowed ? Icons.check_circle : Icons.circle_outlined, color: isAllowed ? Colors.green : Colors.grey),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              const SizedBox(height: 8),
              if (!isAllowed)
                OutlinedButton(
                  onPressed: onAllow,
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0)),
                  child: const Text('Allow', style: TextStyle(fontSize: 12)),
                )
              else
                const Text('Allowed', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }
}
