import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:carrentalapp/models/car.dart';
import 'package:carrentalapp/services/car_upload_service.dart';
import 'dart:math';

class DummyBookingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Random _random = Random();
  final CarUploadService _carUploadService = CarUploadService();

  // User IDs for which to create dummy bookings
  final List<String> _userIds = [
    "gTsdX9sqCVX5hpHwQlnmNbP7z613",
    "EBmeOGYT5KgH9NZtrVnJaf3xLEX2",
    "zuGsaFToo6SFH29yZVa75DBwAAv2",
  ];

  // Pickup and dropoff locations
  final List<Map<String, dynamic>> _locations = [
    {
      'address': '123 Main St, Downtown',
      'latitude': 37.7749,
      'longitude': -122.4194,
    },
    {
      'address': '456 Park Ave, Uptown',
      'latitude': 37.7833,
      'longitude': -122.4167,
    },
    {
      'address': '789 Broadway, Midtown',
      'latitude': 37.7915,
      'longitude': -122.4123,
    },
    {
      'address': '321 Market St, Financial District',
      'latitude': 37.7935,
      'longitude': -122.3964,
    },
    {
      'address': '654 Ocean Ave, Beach Area',
      'latitude': 37.7249,
      'longitude': -122.4782,
    },
  ];

  /// Creates dummy completed bookings for the specified users
  Future<void> createDummyCompletedBookings() async {
    // Get the list of cars
    final List<Car> cars = _carUploadService.rentalCars;

    // Create a batch for efficient writes
    WriteBatch batch = _firestore.batch();

    // For each user, create 3-5 completed bookings
    for (String userId in _userIds) {
      final int bookingsCount = _random.nextInt(3) + 3; // 3-5 bookings per user

      print('Creating $bookingsCount bookings for user $userId');

      for (int i = 0; i < bookingsCount; i++) {
        // Select a random car
        final Car car = cars[_random.nextInt(cars.length)];

        // Generate random dates in the past (1-180 days ago)
        final DateTime now = DateTime.now();
        final int daysAgo = _random.nextInt(180) + 1;
        final DateTime endDate = now.subtract(Duration(days: daysAgo));

        // Rental duration between 1-14 days
        final int rentalDays = _random.nextInt(14) + 1;
        final DateTime startDate =
            endDate.subtract(Duration(days: rentalDays - 1));
        final DateTime bookingDate =
            startDate.subtract(Duration(days: _random.nextInt(7) + 1));

        // Calculate cost using the car's pricing
        final double dailyRate =
            car.calculateRentalCost(rentalDays) / rentalDays;
        final double totalCost = car.calculateRentalCost(rentalDays);

        // Generate a unique booking ID
        final String bookingId =
            '${userId}_${DateTime.now().millisecondsSinceEpoch}_$i';

        // Select random pickup and dropoff locations
        final pickupLocation = _locations[_random.nextInt(_locations.length)];
        final dropoffLocation = _locations[_random.nextInt(_locations.length)];

        // Create the booking data
        final Map<String, dynamic> bookingData = {
          'id': bookingId,
          'carId': car.id,
          'bookingDate': bookingDate.toIso8601String(),
          'rentStartDate': startDate.toIso8601String(),
          'endDate': endDate.toIso8601String(),
          'carDetails': car.toMap(),
          'totalCost': totalCost,
          'rentalDays': rentalDays,
          'dailyRate': dailyRate,
          'userId': userId,
          'pickupLocation': pickupLocation['address'],
          'pickupLatitude': pickupLocation['latitude'],
          'pickupLongitude': pickupLocation['longitude'],
          'dropoffLocation': dropoffLocation['address'],
          'dropoffLatitude': dropoffLocation['latitude'],
          'dropoffLongitude': dropoffLocation['longitude'],
        };

        // Add to batch
        batch.set(
            _firestore.collection('bookings').doc(bookingId), bookingData);
      }
    }

    // Commit the batch
    try {
      await batch.commit();
      print('Successfully created dummy completed bookings for all users!');
    } catch (e) {
      print('Error creating dummy bookings: $e');
    }
  }
}
