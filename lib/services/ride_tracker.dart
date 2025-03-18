// lib/services/ride_tracker.dart
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Retrieves the current location after ensuring that location services
/// and permissions are enabled.
Future<Position?> getCurrentLocation() async {
  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) return null;

  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      return null;
    }
  }
  return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
}

/// A RideTracker that updates the booking document with the current location
/// only if the current time is between pickup and drop-off times.
class RideTracker {
  Timer? _trackingTimer;
  final DateTime pickupDateTime;
  final DateTime dropOffDateTime;

  RideTracker({
    required this.pickupDateTime,
    required this.dropOffDateTime,
  });

  void startTracking(String bookingId) {
    // Cancel any previous timer.
    _trackingTimer?.cancel();
    _trackingTimer = Timer.periodic(const Duration(minutes: 5), (timer) async {
      final now = DateTime.now();
      // If the ride hasn't started yet, do nothing.
      if (now.isBefore(pickupDateTime)) return;
      // If the ride has ended, stop tracking.
      if (now.isAfter(dropOffDateTime)) {
        stopTracking();
        return;
      }

      final position = await getCurrentLocation();
      if (position != null) {
        await FirebaseFirestore.instance
            .collection('bookings')
            .doc(bookingId)
            .update({
          'currentLocation': {
            'latitude': position.latitude,
            'longitude': position.longitude,
          },
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  void stopTracking() {
    _trackingTimer?.cancel();
    _trackingTimer = null;
  }
}
