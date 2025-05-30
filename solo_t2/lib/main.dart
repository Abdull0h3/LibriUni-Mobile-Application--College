// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; 
import 'routes/app_router.dart';
import 'constants/app_colors.dart';
import 'firebase_options.dart'; // FlutterFire CLI
import 'utils/seed_data.dart'; //for exporting test data




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

  runApp(const LibriUniApp());
}

class LibriUniApp extends StatelessWidget {
  const LibriUniApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LibriUni Staff',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: AppColors.primaryColor,
        scaffoldBackgroundColor: AppColors.backgroundColor,
        fontFamily: 'YourCustomFont', // 
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.primaryColor,
          foregroundColor: AppColors.textColorLight,
          iconTheme: IconThemeData(color: AppColors.textColorLight),
          titleTextStyle: TextStyle(
            color: AppColors.textColorLight,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: AppColors.textColorDark),
          bodyMedium: TextStyle(color: AppColors.textColorDark),
          titleMedium: TextStyle(color: AppColors.textColorDark, fontWeight: FontWeight.bold),
        ),
        cardTheme: CardTheme(
          color: AppColors.cardBackgroundColor,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: AppColors.primaryColor,
          secondary: AppColors.secondaryColor,
          background: AppColors.backgroundColor,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.secondaryColor,
            foregroundColor: AppColors.textColorDark, // Text color for ElevatedButton
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ),
      initialRoute: AppRoutes.dashboard,
      onGenerateRoute: AppRouter.generateRoute,
    );
  }
}