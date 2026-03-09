import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/main_navigation.dart';
import 'services/database_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'initializer.dart';
import 'services/upi_monitor_service.dart';
import 'services/notification_service.dart';
import 'screens/add_transaction_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:workmanager/workmanager.dart';
import 'services/user_service.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    // This is run in a separate background isolate
    final userService = UserService();
    final lastActive = await userService.getLastActive();
    
    if (lastActive != null) {
      final diff = DateTime.now().difference(lastActive).inDays;
      if (diff >= 3) {
        // Trigger notification
        await NotificationService.showHeartTouchingNotification();
      }
    }
    return Future.value(true);
  });
}

Future<void> main() async {
  debugPrint("--- APP STARTING ---");
  WidgetsFlutterBinding.ensureInitialized();
  
  // We initialize the database first because it's required for the rest of the app
  try {
    debugPrint("Initializing Database...");
    final dbService = DatabaseService();
    await dbService.init().timeout(const Duration(seconds: 10));
    debugPrint("Database Initialized.");
  } catch (e) {
    debugPrint("CRITICAL: Database Initialization Error: $e");
  }

  // Run app as soon as basic DB is ready
  runApp(
    const ProviderScope(
      child: BudgetApp(),
    ),
  );

  // Initialize other services in background or after runApp
  _initServicesInBackground();
}

Future<void> _initServicesInBackground() async {
  try {
    debugPrint("Background: Initializing Firebase...");
    await Firebase.initializeApp();
    debugPrint("Background: Firebase Initialized.");
  } catch (e) {
    debugPrint("Background: Firebase Initialization Error: $e");
  }

  try {
    debugPrint("Background: Initializing Notifications...");
    await NotificationService.initialize();
    debugPrint("Background: Notifications Initialized.");
  } catch (e) {
    debugPrint("Background: Notification Initialization Error: $e");
  }

  try {
    debugPrint("Background: Initializing Workmanager...");
    await Workmanager().initialize(callbackDispatcher);
    await Workmanager().registerPeriodicTask(
      "inactive_notification_task",
      "checkInactiveStatus",
      frequency: const Duration(days: 1),
      initialDelay: const Duration(minutes: 15),
    );
    debugPrint("Background: Workmanager Initialized.");
  } catch (e) {
    debugPrint("Background: Workmanager Initialization Error: $e");
  }
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class BudgetApp extends ConsumerStatefulWidget {
  const BudgetApp({super.key});

  @override
  ConsumerState<BudgetApp> createState() => _BudgetAppState();
}

class _BudgetAppState extends ConsumerState<BudgetApp> {
  @override
  void initState() {
    super.initState();
    _initUpiMonitor();
  }

  void _initUpiMonitor() {
    final monitor = ref.read(upiMonitorProvider);
    monitor.setDeepLinkHandler((route, source) {
      if (route == '/add_transaction') {
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            fullscreenDialog: true,
            builder: (context) => AddTransactionScreen(initialTitle: '$source Payment'),
          ),
        );
      }
    });
    
    // Check for pending data on launch
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final data = await monitor.getPendingData();
      if (data['route'] == '/add_transaction') {
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            fullscreenDialog: true,
            builder: (context) => AddTransactionScreen(initialTitle: '${data['source']} Payment'),
          ),
        );
      }
    });

    // Automatically try to start monitoring if permission exists
    _startMonitoring();
  }

  void _startMonitoring() async {
    final monitor = ref.read(upiMonitorProvider);
    if (await monitor.checkPermission()) {
      await monitor.startMonitoring();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Expense Tacker',
      theme: ThemeData(
        useMaterial3: true,
        textTheme: GoogleFonts.interTextTheme(),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          surface: const Color(0xFFF8F9FE),
        ),
      ),
      home: const Initializer(),
      routes: {
        '/home': (context) => const MainNavigation(),
      },
    );
  }
}
