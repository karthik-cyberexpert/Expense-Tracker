import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final securityServiceProvider = Provider((ref) => SecurityService());

class SecurityService {
  static const String _useLockKey = 'use_lock';
  static const String _lockTypeKey = 'lock_type'; // 'pin', 'password', 'pattern'
  static const String _lockValueKey = 'lock_value';
  static const String _useBiometricKey = 'use_biometric';
  static const String _intruderSelfieKey = 'intruder_selfie';
  static const String _intruderAttemptsThresholdKey = 'intruder_attempts_threshold';
  static const String _wrongAttemptsKey = 'wrong_attempts';
  static const String _lastWrongAttemptTimeKey = 'last_wrong_attempt_time';
  static const String _securityQuestionKey = 'security_question';
  static const String _securityAnswerKey = 'security_answer';

  Future<bool> hasLockSet() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lockValueKey) != null;
  }

  Future<void> setLock(String type, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lockTypeKey, type);
    await prefs.setString(_lockValueKey, value);
    await prefs.setBool(_useLockKey, true);
  }

  Future<bool> verifyPassword(String value) async {
    final prefs = await SharedPreferences.getInstance();
    final savedValue = prefs.getString(_lockValueKey);
    return savedValue == value;
  }

  Future<void> deleteLock() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lockTypeKey);
    await prefs.remove(_lockValueKey);
    await prefs.remove(_useLockKey);
    await prefs.remove(_useBiometricKey);
  }

  Future<String?> getLockType() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lockTypeKey);
  }

  Future<String?> getLockValue() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lockValueKey);
  }

  Future<void> setBiometric(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_useBiometricKey, value);
  }

  Future<bool> useBiometric() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_useBiometricKey) ?? false;
  }

  Future<void> setIntruderSelfie(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_intruderSelfieKey, value);
  }

  Future<bool> useIntruderSelfie() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_intruderSelfieKey) ?? false;
  }

  Future<void> setIntruderAttemptsThreshold(int threshold) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_intruderAttemptsThresholdKey, threshold);
  }

  Future<int> getIntruderAttemptsThreshold() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_intruderAttemptsThresholdKey) ?? 3;
  }

  Future<int> getWrongAttempts() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_wrongAttemptsKey) ?? 0;
  }

  Future<void> incrementWrongAttempts() async {
    final prefs = await SharedPreferences.getInstance();
    final current = await getWrongAttempts();
    await prefs.setInt(_wrongAttemptsKey, current + 1);
    await prefs.setInt(_lastWrongAttemptTimeKey, DateTime.now().millisecondsSinceEpoch);
  }

  Future<void> resetWrongAttempts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_wrongAttemptsKey, 0);
    await prefs.remove(_lastWrongAttemptTimeKey);
  }

  Future<int> getLockTimeRemaining() async {
    final prefs = await SharedPreferences.getInstance();
    final attempts = await getWrongAttempts();
    if (attempts < 3) return 0;

    final lastTime = prefs.getInt(_lastWrongAttemptTimeKey) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    
    int waitSeconds = 0;
    if (attempts >= 5) {
      waitSeconds = 60;
    } else if (attempts >= 3) {
      waitSeconds = 30;
    }

    final diffSeconds = (now - lastTime) ~/ 1000;
    final remaining = waitSeconds - diffSeconds;
    return remaining > 0 ? remaining : 0;
  }

  // --- Security Questions ---
  Future<String?> getSecurityQuestion() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_securityQuestionKey);
  }

  Future<void> setSecurityQuestion(String question, String answer) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_securityQuestionKey, question);
    await prefs.setString(_securityAnswerKey, answer.toLowerCase().trim());
  }

  Future<bool> verifySecurityAnswer(String answer) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_securityAnswerKey);
    return saved == answer.toLowerCase().trim();
  }

  Future<String?> getSecurityAnswer() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_securityAnswerKey);
  }
}
