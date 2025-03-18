// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/register_page.dart';
import 'notification.dart'; // Import our notifications file
// import 'services/car_upload_service.dart';
import 'screens/admin_dashboard_screen.dart';
import "package:carrentalapp/screens/admin_home_screen.dart";
import "package:carrentalapp/screens/add_user_page.dart";
import 'core/theme/app_theme.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/config/env_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Load environment variables
  await EnvConfig.load();

  // Initialize the CarUploadService and upload rental cars only.
  // CarUploadService service = CarUploadService();
  // await service.uploadRentalCars(); // Upload rental cars
  // Removed: await service.uploadBookingCars(); // Upload booking cars

  // Initialize notifications using our helper function.
  await initializeNotifications();

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Car Rental App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: '/register',
      routes: {
        '/login': (context) => LoginScreen(),
        '/home': (context) => HomeScreen(),
        '/register': (context) => RegisterPage(),
        '/adminDashboard': (context) => const AdminHomeScreen(),
        '/adminHomeScreen': (context) => const AdminHomeScreen(),
        '/adduser': (context) => const AdminAddUserScreen(),
      },
      builder: (context, child) {
        return ScrollConfiguration(
          behavior: ScrollBehavior().copyWith(
            physics: const BouncingScrollPhysics(),
          ),
          child: child!,
        );
      },
    );
  }
}
