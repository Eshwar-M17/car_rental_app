import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/services.dart' show rootBundle;

class EnvConfig {
  // API Keys
  static String get googleMapsApiKey => dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';
  static String get firebaseApiKey => dotenv.env['FIREBASE_API_KEY'] ?? '';

  // Firebase Configuration
  static String get firebaseProjectId =>
      dotenv.env['FIREBASE_PROJECT_ID'] ?? '';
  static String get firebaseMessagingSenderId =>
      dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ?? '';
  static String get firebaseAppId => dotenv.env['FIREBASE_APP_ID'] ?? '';

  // Other Sensitive Data
  static String get stripePublishableKey =>
      dotenv.env['STRIPE_PUBLISHABLE_KEY'] ?? '';
  static String get stripeSecretKey => dotenv.env['STRIPE_SECRET_KEY'] ?? '';

  // Environment
  static String get environment => dotenv.env['ENVIRONMENT'] ?? 'development';

  static Future<void> load() async {
    try {
      // Load the .env file from assets
      await dotenv.load(fileName: '.env');
    } catch (e) {
      print('Error loading .env file: $e');
      // Fallback to loading from root directory
      try {
        await dotenv.load();
      } catch (e) {
        print('Error loading .env file from root: $e');
        throw Exception('Failed to load environment variables');
      }
    }
  }
}
