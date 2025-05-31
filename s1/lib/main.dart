import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'constants/app_colors.dart';

// Import routes (to be created)
import 'routes/app_router.dart';

// Import providers
import 'providers/auth_provider.dart';
import 'providers/book_provider.dart';
import 'providers/room_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/user_provider.dart';
// import 'providers/borrow_provider.dart';
import 'providers/room_booking_provider.dart';
import 'providers/theme_provider.dart'; // <-- Added for dark mode

// Import services
import 'services/book_service.dart';
import 'services/room_booking_service.dart';
import 'services/analytics_service.dart';
import 'utils/seed.dart'; //for exporting test data

import 'constants/app_theme.dart'
    hide
        RoomBookingProvider; // <-- If you have AppTheme.light and AppTheme.dark

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, // generated options
  );

  // ---- Optional: Seed Data ----

  bool seedData = false; // Set to true once to seed, then false.
  if (seedData) {
    print("Seeding data...");
    await FirestoreSeeder.seedLibriUniData();
    print("Data seeding complete.");
  }
  // ---- End Optional: Seed Data ----

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ThemeProvider(),
        ), // <-- Added for dark mode
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => BookProvider()),
        ChangeNotifierProvider(create: (_) => RoomProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        // ChangeNotifierProvider(create: (_) => BorrowProvider()),
        ChangeNotifierProvider(create: (_) => RoomBookingProvider()),
      ],
      child: Builder(
        builder: (context) {
          try {
            return LibriUniApp();
          } catch (e) {
            return MaterialApp(
              home: Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text('Error: $e'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          // Restart the app
                          main();
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
        },
      ),
    );
  }
}

class LibriUniApp extends StatelessWidget {
  LibriUniApp({super.key});

  // Get the router instance from app_router.dart
  final _router = AppRouter.router;

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return MaterialApp.router(
          title: 'LibriUni',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light, // <-- Use your light theme
          darkTheme: AppTheme.dark, // <-- Use your dark theme
          themeMode:
              themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          routerConfig: _router,
        );
      },
    );
  }
}
