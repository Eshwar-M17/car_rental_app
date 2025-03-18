import 'package:carrentalapp/services/dummy_booking_service.dart';
import 'package:flutter/material.dart';

/// This is a utility class that can be used to add dummy bookings to the database.
/// It can be called from a button in the admin panel or during development.
class AddDummyBookings {
  static Future<void> run(BuildContext? context) async {
    final DummyBookingService service = DummyBookingService();

    try {
      await service.createDummyCompletedBookings();

      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully added dummy bookings!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error adding dummy bookings: $e');

      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding dummy bookings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
