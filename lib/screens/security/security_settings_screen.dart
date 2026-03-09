import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:local_auth/local_auth.dart';
import '../../services/security_service.dart';
import 'lock_screen.dart';
import 'intruder_selfie_screen.dart';
import '../../services/upi_monitor_service.dart';
import 'usage_permission_dialog.dart';

class SecuritySettingsScreen extends ConsumerStatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  ConsumerState<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends ConsumerState<SecuritySettingsScreen> {
  bool _useBiometric = false;
  bool _useIntruderSelfie = false;
  String? _lockType;
  bool _hasLock = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() async {
    final security = ref.read(securityServiceProvider);
    final hasLock = await security.hasLockSet();
    final type = await security.getLockType();
    final bio = await security.useBiometric();
    final intruder = await security.useIntruderSelfie();

    setState(() {
      _hasLock = hasLock;
      _lockType = type;
      _useBiometric = bio;
      _useIntruderSelfie = intruder;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Security', style: GoogleFonts.inter(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('APP LOCK'),
            _buildLockManagement(),
            const SizedBox(height: 32),
            _buildSectionTitle('BIOMETRICS & PROTECTION'),
            _buildBiometricToggle(),
            _buildIntruderSettingsTile(),
            const SizedBox(height: 16),
            _buildUpiMonitorToggle(),
          ],
        ),
      ),
    );
  }

  Widget _buildUpiMonitorToggle() {
    return FutureBuilder<bool>(
      future: ref.read(upiMonitorProvider).checkPermission(),
      builder: (context, snapshot) {
        final hasPermission = snapshot.data ?? false;
        return Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
          child: Column(
            children: [
              SwitchListTile(
                activeColor: const Color(0xFF6366F1),
                secondary: const Icon(Icons.bolt, color: Colors.amber),
                title: const Text('Auto-Detect Payments'),
                subtitle: const Text('Notify when you exit a UPI app'),
                value: hasPermission,
                onChanged: (v) async {
                  if (v) {
                    final success = await UsagePermissionDialog.show(context);
                    if (success) {
                      await ref.read(upiMonitorProvider).startMonitoring();
                    }
                  } else {
                    await ref.read(upiMonitorProvider).requestPermission();
                    await ref.read(upiMonitorProvider).stopMonitoring();
                  }
                  setState(() {});
                },
              ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(72, 0, 24, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Requires Usage Access. If the setting is grayed out, use the 3-dot menu in App Info.',
                        style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'If you can already turn it ON, the 3-dot menu will not appear.',
                        style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF6366F1), fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 12),
      child: Text(
        title,
        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2),
      ),
    );
  }

  Widget _buildLockManagement() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          if (!_hasLock)
            ListTile(
              onTap: () => _setupLock(isChanging: false),
              leading: const Icon(Icons.lock_outline, color: Color(0xFF6366F1)),
              title: const Text('Setup App Lock'),
              trailing: const Icon(Icons.chevron_right),
            )
          else ...[
            ListTile(
              onTap: () => _changeLock(),
              leading: const Icon(Icons.lock_open, color: Colors.green),
              title: const Text('Change Lock'),
              subtitle: Text('Current type: ${_lockType?.toUpperCase() ?? "N/A"}'),
              trailing: const Icon(Icons.chevron_right),
            ),
            const Divider(height: 1),
            ListTile(
              onTap: _deleteLock,
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Delete Lock', style: TextStyle(color: Colors.red)),
              trailing: const Icon(Icons.chevron_right),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildIntruderSettingsTile() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: ListTile(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const IntruderSelfieScreen())),
        leading: const Icon(Icons.camera_alt_outlined, color: Colors.orange),
        title: const Text('Intruder Selfie'),
        subtitle: Text(_useIntruderSelfie ? 'Enabled' : 'Disabled'),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }

  Widget _buildBiometricToggle() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: SwitchListTile(
        activeColor: const Color(0xFF6366F1),
        secondary: const Icon(Icons.fingerprint),
        title: const Text('Biometric Unlock'),
        subtitle: const Text('Use fingerprint or face to unlock'),
        value: _useBiometric,
        onChanged: (v) async {
          if (v) {
            final auth = LocalAuthentication();
            final canBio = await auth.canCheckBiometrics;
            if (canBio) {
              final didAuth = await auth.authenticate(localizedReason: 'Verify to enable biometric unlock');
              if (didAuth) {
                await ref.read(securityServiceProvider).setBiometric(true);
                setState(() => _useBiometric = true);
              }
            } else {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Biometrics not available')));
            }
          } else {
            await ref.read(securityServiceProvider).setBiometric(false);
            setState(() => _useBiometric = false);
          }
        },
      ),
    );
  }

  void _setupLock({required bool isChanging, String? type}) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => LockScreen(
        isOnboarding: !isChanging,
        lockType: type ?? 'pin',
        onSuccess: () {
          Navigator.pop(context);
          _loadSettings();
        },
      )),
    );
  }

  void _changeLock() async {
    // 1. Verify current lock
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => LockScreen(
        isOnboarding: false,
        onSuccess: () async {
          Navigator.pop(context); // back from verifying screen
          // 2. Show options for new lock type
          _showLockTypeSelector();
        },
      )),
    );
  }

  void _showLockTypeSelector() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('CHOOSE NEW LOCK TYPE', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
            const SizedBox(height: 24),
            _lockTypeOption(Icons.dialpad, 'PIN', 'Secure 4-digit numeric code', 'pin'),
            _lockTypeOption(Icons.password, 'Password', 'Alphanumeric strong password', 'password'),
            _lockTypeOption(Icons.gesture, 'Pattern', 'Connect dots to unlock', 'pattern'),
          ],
        ),
      ),
    );
  }

  Widget _lockTypeOption(IconData icon, String title, String subtitle, String type) {
    return ListTile(
      onTap: () {
        Navigator.pop(context); // close bottom sheet
        _setupLock(isChanging: true, type: type);
      },
      leading: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: const Color(0xFF6366F1).withOpacity(0.1), shape: BoxShape.circle),
        child: Icon(icon, color: const Color(0xFF6366F1)),
      ),
      title: Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
      trailing: const Icon(Icons.chevron_right, size: 20),
    );
  }

  void _deleteLock() {
    // Requires previous verification
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => LockScreen(
        onSuccess: () async {
          await ref.read(securityServiceProvider).deleteLock();
          Navigator.pop(context); // back from screen
          _loadSettings();
        },
      )),
    );
  }
}
