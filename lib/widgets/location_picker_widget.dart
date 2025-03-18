import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationPickerWidget extends StatefulWidget {
  final Function(LatLng) onLocationSelected;
  const LocationPickerWidget({Key? key, required this.onLocationSelected})
      : super(key: key);

  @override
  State<LocationPickerWidget> createState() => _LocationPickerWidgetState();
}

class _LocationPickerWidgetState extends State<LocationPickerWidget> {
  final Completer<GoogleMapController> _controller = Completer();
  LatLng? _selectedLocation;

  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(12.971599, 77.594566), // Starting at Bangalore, India
    zoom: 10,
  );

  void _handleTap(LatLng position) {
    setState(() {
      _selectedLocation = position;
    });
    widget.onLocationSelected(position);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 300, // Fixed height for the map
      child: GoogleMap(
        initialCameraPosition: _initialPosition,
        mapType: MapType.hybrid,
        onMapCreated: (controller) {
          _controller.complete(controller);
        },
        onTap: _handleTap,
        markers: _selectedLocation != null
            ? {
                Marker(
                  markerId: const MarkerId('selected'),
                  position: _selectedLocation!,
                  draggable: true,
                  onDragEnd: (LatLng newPosition) {
                    setState(() {
                      _selectedLocation = newPosition;
                    });
                    widget.onLocationSelected(newPosition);
                  },
                )
              }
            : {},
      ),
    );
  }
}
