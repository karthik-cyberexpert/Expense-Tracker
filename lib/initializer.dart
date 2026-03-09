import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/security/lock_screen.dart';
import 'services/security_service.dart';
import 'screens/main_navigation.dart';

class Initializer extends ConsumerWidget {
  const Initializer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    debugPrint("--- INITIALIZER BUILDING ---");
    return FutureBuilder<bool>(
      future: ref.read(securityServiceProvider).hasLockSet().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          debugPrint("STUCK: hasLockSet timed out!");
          return false; // Fail safe to onboarding if stuck
        },
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          debugPrint("Initializer: Waiting for security status...");
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        
        if (snapshot.hasError) {
          debugPrint("Initializer Error: ${snapshot.error}");
          // Onboarding for safety
          return _buildOnboarding(context);
        }

        final hasLock = snapshot.data ?? false;
        debugPrint("Initializer: hasLock = $hasLock");
        
        if (hasLock) {
          return LockScreen(
            onSuccess: () => Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const MainNavigation()),
            ),
          );
        } else {
          return _buildOnboarding(context);
        }
      },
    );
  }

  Widget _buildOnboarding(BuildContext context) {
    return LockScreen(
      isOnboarding: true,
      onSuccess: () => Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainNavigation()),
      ),
    );
  }
}
