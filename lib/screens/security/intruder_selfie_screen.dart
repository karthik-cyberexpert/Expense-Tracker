import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' show join;
import 'package:permission_handler/permission_handler.dart';
import '../../services/security_service.dart';
import '../../utils/permission_helper.dart';

class IntruderSelfieScreen extends ConsumerStatefulWidget {
  const IntruderSelfieScreen({super.key});

  @override
  ConsumerState<IntruderSelfieScreen> createState() => _IntruderSelfieScreenState();
}

class _IntruderSelfieScreenState extends ConsumerState<IntruderSelfieScreen> {
  bool _isEnabled = false;
  int _threshold = 3;
  List<File> _selfies = [];

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadSelfies();
  }

  Future<void> _loadSettings() async {
    final security = ref.read(securityServiceProvider);
    final enabled = await security.useIntruderSelfie();
    final threshold = await security.getIntruderAttemptsThreshold();
    setState(() {
      _isEnabled = enabled;
      _threshold = threshold;
    });
  }

  Future<void> _loadSelfies() async {
    final directory = await getApplicationDocumentsDirectory();
    final intruderDir = Directory(join(directory.path, 'intruders'));
    if (await intruderDir.exists()) {
      final files = intruderDir.listSync()
          .where((item) => item is File && (item.path.endsWith('.jpg') || item.path.endsWith('.png')))
          .cast<File>()
          .toList();
      files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
      setState(() {
        _selfies = files;
      });
    }
  }

  Future<void> _toggleIntruderSelfie(bool value) async {
    if (value) {
      final granted = await PermissionHelper.checkAndRequest(
        context, 
        Permission.camera, 
        message: 'Camera access is required for the Intruder Selfie feature.'
      );
      if (!granted) return;
    }
    await ref.read(securityServiceProvider).setIntruderSelfie(value);
    setState(() {
      _isEnabled = value;
    });
  }

  Future<void> _deleteSelfie(File file) async {
    await file.delete();
    _loadSelfies();
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
        title: Text('Intruder Selfie', style: GoogleFonts.inter(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSettingsCard(),
            const SizedBox(height: 32),
            Text(
              'CAPTURED SELFIES',
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2),
            ),
            const SizedBox(height: 16),
            _buildSelfieGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsCard() {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Column(
        children: [
          SwitchListTile(
            activeColor: const Color(0xFF6366F1),
            secondary: const Icon(Icons.camera_alt_outlined),
            title: const Text('Enable Intruder Selfie'),
            subtitle: const Text('Take a photo on failed attempt'),
            value: _isEnabled,
            onChanged: _toggleIntruderSelfie,
          ),
          if (_isEnabled) ...[
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.warning_amber_outlined),
              title: const Text('Wrong attempts threshold'),
              subtitle: Text('Capture after $_threshold failed attempts'),
              trailing: DropdownButton<int>(
                value: _threshold,
                items: [1, 2, 3, 5].map((t) => DropdownMenuItem(value: t, child: Text(t.toString()))).toList(),
                onChanged: (v) async {
                  if (v != null) {
                    await ref.read(securityServiceProvider).setIntruderAttemptsThreshold(v);
                    setState(() => _threshold = v);
                  }
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSelfieGrid() {
    if (_selfies.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            children: [
              Icon(Icons.photo_library_outlined, size: 64, color: Colors.grey[300]),
              const SizedBox(height: 16),
              Text('No intruders captured yet', style: GoogleFonts.inter(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemCount: _selfies.length,
      itemBuilder: (context, index) {
        final file = _selfies[index];
        return GestureDetector(
          onTap: () => _viewSelfie(file),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              image: DecorationImage(image: FileImage(file), fit: BoxFit.cover),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 8, right: 8,
                  child: GestureDetector(
                    onTap: () => _deleteSelfie(file),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                      child: const Icon(Icons.delete_outline, color: Colors.white, size: 18),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0, left: 0, right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter, end: Alignment.topCenter,
                        colors: [Colors.black54, Colors.transparent],
                      ),
                      borderRadius: BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)),
                    ),
                    child: Text(
                      file.lastModifiedSync().toString().split('.')[0],
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _viewSelfie(File file) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              child: Image.file(file),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   Text(file.lastModifiedSync().toString().split('.')[0]),
                   IconButton(
                     onPressed: () {
                       _deleteSelfie(file);
                       Navigator.pop(context);
                     },
                     icon: const Icon(Icons.delete_outline, color: Colors.red),
                   ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
