import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Retrieves the current device location after checking permissions.
Future<Position?> getCurrentLocation() async {
  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    // You might want to prompt the user to enable location services.
    return null;
  }

  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      // Handle the case when permissions are denied.
      return null;
    }
  }

  return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high);
}

/// Manages periodic location updates for an active ride.
class RideTracker {
  Timer? _trackingTimer;

  /// Starts tracking the location for a given bookingId.
  /// The location is updated every 5 minutes.
  void startTracking(String bookingId) {
    // Cancel any existing timer.
    _trackingTimer?.cancel();

    // Start periodic updates (adjust the duration as needed).
    _trackingTimer = Timer.periodic(const Duration(minutes: 5), (timer) async {
      final position = await getCurrentLocation();
      if (position != null) {
        // Update the booking document in Firestore with the latest location.
        await FirebaseFirestore.instance.collection('bookings').doc(bookingId).update({
          'currentLocation': {
            'latitude': position.latitude,
            'longitude': position.longitude,
          },
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  /// Stops the location tracking.
  void stopTracking() {
    _trackingTimer?.cancel();
    _trackingTimer = null;
  }
}
