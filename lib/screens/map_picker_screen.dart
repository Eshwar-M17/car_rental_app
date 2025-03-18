import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:carrentalapp/screens/car_rental_detail_screen.dart'; // For the PickedLocation class

class MapPickerScreen extends StatefulWidget {
  final String? title;

  const MapPickerScreen({Key? key, this.title}) : super(key: key);

  @override
  _MapPickerScreenState createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  GoogleMapController? _mapController;
  // Default location set to Bangalore, India.
  LatLng _pickedLocation = const LatLng(12.971599, 77.594566);

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  void _onMapTap(LatLng position) {
    setState(() {
      _pickedLocation = position;
    });
  }

  void _onMarkerDragEnd(LatLng position) {
    setState(() {
      _pickedLocation = position;
    });
  }

  Future<String> _getAddressFromLatLng(LatLng position) async {
    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        final Placemark place = placemarks[0];
        // Construct the address string. Adjust this as needed.
        return "${place.street}, ${place.locality}, ${place.country}";
      } else {
        return "No address available";
      }
    } catch (e) {
      debugPrint("Error in reverse geocoding: $e");
      return "Error retrieving address";
    }
  }

  Future<void> _confirmLocation() async {
    // Use reverse geocoding to fetch a human-readable address.
    final address = await _getAddressFromLatLng(_pickedLocation);
    final pickedLocation = PickedLocation(
      address: address,
      latitude: _pickedLocation.latitude,
      longitude: _pickedLocation.longitude,
    );
    Navigator.pop(context, pickedLocation);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title ?? 'Pick Location'),
        backgroundColor: Colors.blue.shade900,
      ),
      body: GoogleMap(
        onMapCreated: _onMapCreated,
        onTap: _onMapTap,
        initialCameraPosition: CameraPosition(
          target: _pickedLocation,
          zoom: 14,
        ),
        markers: {
          Marker(
            markerId: const MarkerId("picked_location"),
            position: _pickedLocation,
            draggable: true,
            onDragEnd: _onMarkerDragEnd,
          )
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _confirmLocation,
        label: const Text("Confirm Location"),
        icon: const Icon(Icons.check),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
