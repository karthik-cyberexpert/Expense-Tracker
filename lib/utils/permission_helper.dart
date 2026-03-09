import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';

class PermissionHelper {
  /// Checks and requests the specified permission.
  /// Returns true if granted, false otherwise.
  static Future<bool> checkAndRequest(BuildContext context, Permission permission, {String? message}) async {
    final status = await permission.status;
    
    if (status.isGranted) {
      return true;
    }
    
    // If denied or permanently denied, try to request
    final result = await permission.request();
    
    if (result.isGranted) {
      return true;
    }
    
    if (result.isPermanentlyDenied) {
      if (context.mounted) {
        _showPermanentDeniedDialog(context, message ?? 'This feature requires ${permission.toString().split('.')[1]} permission.');
      }
      return false;
    }
    
    return false;
  }

  static void _showPermanentDeniedDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permission Required'),
        content: Text(message + '\n\nPlease enable it in system settings.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              openAppSettings();
              Navigator.pop(context);
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }
}
