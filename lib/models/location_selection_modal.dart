import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:carrentalapp/widgets/location_picker_widget.dart';

class LocationSelectionModal extends StatefulWidget {
  const LocationSelectionModal({Key? key}) : super(key: key);

  @override
  _LocationSelectionModalState createState() => _LocationSelectionModalState();
}

class _LocationSelectionModalState extends State<LocationSelectionModal> {
  LatLng? _selectedLocation;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Location')),
      body: Column(
        children: [
          LocationPickerWidget(
            onLocationSelected: (latLng) {
              setState(() {
                _selectedLocation = latLng;
              });
            },
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              child: const Text('Confirm Location'),
              onPressed: () {
                if (_selectedLocation != null) {
                  Navigator.pop(context, _selectedLocation);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select a location')),
                  );
                }
              },
            ),
          )
        ],
      ),
    );
  }
}
