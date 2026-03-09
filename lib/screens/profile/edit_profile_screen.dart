import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../providers/data_providers.dart';
import '../../utils/permission_helper.dart';
import '../../services/user_service.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  String? _imagePath;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void _loadProfile() async {
    final user = ref.read(userServicePrivider);
    final name = await user.getName();
    final email = await user.getEmail();
    final img = await user.getProfileImage();
    
    setState(() {
      _nameController.text = name;
      _emailController.text = email;
      _imagePath = img;
    });
  }

  Future<void> _pickImage() async {
    // Check and request permission
    bool canPick = await PermissionHelper.checkAndRequest(
      context, 
      Permission.photos,
      message: 'Access to your photos is required to select a profile picture.'
    );
    
    if (!canPick) {
      // Fallback for older Android
      canPick = await PermissionHelper.checkAndRequest(
        context, 
        Permission.storage,
      );
    }
    
    if (!canPick) return;

    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _imagePath = image.path;
      });
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
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Edit Profile', style: GoogleFonts.inter(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Stack(
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey[100],
                      image: _imagePath != null 
                        ? DecorationImage(image: FileImage(File(_imagePath!)), fit: BoxFit.cover)
                        : null,
                    ),
                    child: _imagePath == null 
                      ? const Icon(Icons.person, size: 60, color: Colors.grey)
                      : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(color: Color(0xFF6366F1), shape: BoxShape.circle),
                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
            _buildTextField('Full Name', _nameController),
            const SizedBox(height: 24),
            _buildTextField('Email Address', _emailController),
            const SizedBox(height: 64),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _onSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E1E1E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey[700])),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF1F1F1),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          ),
        ),
      ],
    );
  }

  void _onSave() async {
    if (_nameController.text.isEmpty) return;
    await ref.read(userProfileProvider.notifier).updateProfileInfo(_nameController.text, _emailController.text, _imagePath);
    if (mounted) Navigator.pop(context);
  }
}
