// lib/providers/rented_cars_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:carrentalapp/models/booking.dart';

class RentedCarsNotifier extends StateNotifier<List<Booking>> {
  RentedCarsNotifier() : super([]) {
    loadBookingsFromFirestore();
  }

  // Loads booking history for the current user from Firestore.
  Future<void> loadBookingsFromFirestore() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        print("Loading bookings for user: ${user.uid}");
        // Query the main bookings collection where userId matches the current user
        final querySnapshot = await FirebaseFirestore.instance
            .collection('bookings')
            .where('userId', isEqualTo: user.uid)
            .get();

        print("Found ${querySnapshot.docs.length} bookings in Firestore");

        if (querySnapshot.docs.isEmpty) {
          state = [];
          print("No bookings found for user: ${user.uid}");
          return;
        }

        final List<Booking> bookings = [];

        for (var doc in querySnapshot.docs) {
          try {
            print("Processing booking document: ${doc.id}");
            final data = doc.data();
            print("Document data: $data");

            // Ensure carDetails is present
            if (data['carDetails'] == null) {
              print("Warning: carDetails is missing in booking ${doc.id}");
              continue;
            }

            final booking = Booking.fromMap(data);
            bookings.add(booking);
            print("Successfully parsed booking: ${booking.id}");
          } catch (e) {
            print("Error parsing booking document ${doc.id}: $e");
          }
        }

        state = bookings;
        print("Total bookings loaded: ${state.length}");
      } else {
        print("No user logged in. Skipping loading bookings.");
      }
    } catch (e, stacktrace) {
      print("Error loading bookings from Firestore: $e");
      print(stacktrace);
    }
  }

  // Adds a new booking to local state and writes it to Firestore.
  // The extraData map includes fields like pickup and drop-off location details.
  Future<void> addBooking(
      Booking booking, Map<String, dynamic> extraData) async {
    try {
      print("Adding new booking: ${booking.id}");

      // Write the booking data to Firestore in the main bookings collection.
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final bookingData = booking.toMap();
        print("Booking data: $bookingData");

        // Merge extra data (e.g., pickup location)
        bookingData.addAll(extraData);
        bookingData['userId'] = user.uid;

        print("Saving booking to Firestore with ID: ${booking.id}");
        await FirebaseFirestore.instance
            .collection('bookings')
            .doc(booking.id)
            .set(bookingData);

        print("Booking saved to Firestore for user: ${user.uid}");

        // Update local state after successful Firestore write
        state = [...state, booking];
        print("Local state updated. Total bookings: ${state.length}");
      } else {
        print("Error: No user logged in. Cannot save booking.");
      }
    } catch (e, stacktrace) {
      print("Error adding booking: $e");
      print(stacktrace);
      // Re-throw the error so the UI can handle it
      rethrow;
    }
  }
}

final rentedCarsProvider =
    StateNotifierProvider<RentedCarsNotifier, List<Booking>>((ref) {
  return RentedCarsNotifier();
});
