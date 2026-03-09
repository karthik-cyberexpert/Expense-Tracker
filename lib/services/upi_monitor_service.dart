import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

final upiMonitorProvider = Provider((ref) => UpiMonitorService());

class UpiMonitorService {
  static const _channel = MethodChannel('com.expensetracker.expense_tracker/upi_monitor');
  
  Function(String route, String source)? _onDeepLink;
  bool _isActive = false;

  bool get isActive => _isActive;


  UpiMonitorService() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onDeepLink') {
        final Map? data = call.arguments;
        if (data != null && _onDeepLink != null) {
          _onDeepLink!(data['route'], data['source']);
        }
      }
    });
  }

  void setDeepLinkHandler(Function(String route, String source) handler) {
    _onDeepLink = handler;
  }

  Future<bool> startMonitoring() async {
    try {
      final hasPermission = await checkPermission(ignoreActive: true);
      if (!hasPermission) return false;
      final result = await _channel.invokeMethod<bool>('startService') ?? false;
      _isActive = result;
      return result;
    } catch (e) {
      return false;
    }
  }

  Future<void> stopMonitoring() async {
    try {
      await _channel.invokeMethod('stopService');
      _isActive = false;
    } catch (e) {}
  }

  Future<bool> isServiceRunning() async {
    try {
      return await _channel.invokeMethod<bool>('isServiceRunning') ?? false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> checkPermission({bool ignoreActive = false}) async {
    try {
      final usageGranted = await _channel.invokeMethod<bool>('checkUsagePermission') ?? false;
      final notificationGranted = await Permission.notification.isGranted;
      return usageGranted && notificationGranted;
    } catch (e) {
      return false;
    }
  }




  Future<void> requestPermission() async {
    try {
      await Permission.notification.request();
      await _channel.invokeMethod('requestUsagePermission');
    } catch (e) {}
  }

  Future<Map<String, String>> getPendingData() async {
    try {
      final Map? data = await _channel.invokeMethod('getPendingNotificationData');
      if (data != null) {
        return Map<String, String>.from(data);
      }
    } catch (e) {}
    return {};
  }
}
