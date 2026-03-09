import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final userServicePrivider = Provider((ref) => UserService());
final installDateProvider = FutureProvider((ref) => ref.watch(userServicePrivider).getInstallDate());

class UserService {
  static const String _nameKey = 'user_name';
  static const String _emailKey = 'user_email';
  static const String _profileImageKey = 'user_profile_image';
  static const String _installDateKey = 'install_date';
  static const String _lastActiveKey = 'last_active_date';

  Future<String> getName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_nameKey) ?? 'User Name';
  }

  Future<String> getEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_emailKey) ?? 'user@example.com';
  }

  Future<String?> getProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_profileImageKey);
  }

  Future<void> updateProfile(String name, String email, String? imagePath) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_nameKey, name);
    await prefs.setString(_emailKey, email);
    if (imagePath != null) {
      await prefs.setString(_profileImageKey, imagePath);
    }
  }

  Future<DateTime> getInstallDate() async {
    final prefs = await SharedPreferences.getInstance();
    final ts = prefs.getInt(_installDateKey);
    if (ts == null) {
      final now = DateTime.now();
      await prefs.setInt(_installDateKey, now.millisecondsSinceEpoch);
      return now;
    }
    return DateTime.fromMillisecondsSinceEpoch(ts);
  }

  Future<void> setInstallDateIfNotSet() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(_installDateKey)) {
      await prefs.setInt(_installDateKey, DateTime.now().millisecondsSinceEpoch);
    }
  }

  Future<void> touchLastActive() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastActiveKey, DateTime.now().millisecondsSinceEpoch);
  }

  Future<DateTime?> getLastActive() async {
    final prefs = await SharedPreferences.getInstance();
    final ts = prefs.getInt(_lastActiveKey);
    return ts != null ? DateTime.fromMillisecondsSinceEpoch(ts) : null;
  }
}
