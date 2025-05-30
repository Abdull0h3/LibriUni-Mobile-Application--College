import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'constants/app_colors.dart';

// Import routes (to be created)
import 'routes/app_router.dart';

// Import providers (to be created) hh
import 'providers/auth_provider.dart';
import 'providers/book_provider.dart';
import 'providers/room_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/user_provider.dart';
// import 'providers/borrow_provider.dart';
import 'providers/room_booking_provider.dart';
import 'providers/ai_chat_provider.dart';

// Import services
import 'services/book_service.dart';
import 'services/room_booking_service.dart';
import 'services/analytics_service.dart';
import 'utils/seed.dart'; //for exporting test data

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
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => BookProvider()),
        ChangeNotifierProvider(create: (_) => RoomProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        // ChangeNotifierProvider(create: (_) => BorrowProvider()),
        ChangeNotifierProvider(create: (_) => RoomBookingProvider()),
        ChangeNotifierProvider(create: (_) => AIChatProvider()),
      ],
      child: MaterialApp(
        home: Builder(
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
    return MaterialApp.router(
      title: 'LibriUni',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.light(
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          error: AppColors.error,
          background: AppColors.background,
          surface: AppColors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        cardTheme: CardTheme(
          color: AppColors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
          headlineMedium: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
          titleLarge: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
          bodyLarge: TextStyle(color: AppColors.textPrimary),
          bodyMedium: TextStyle(color: AppColors.textSecondary),
        ),
      ),
      routerConfig: _router,
    );
  }
}
