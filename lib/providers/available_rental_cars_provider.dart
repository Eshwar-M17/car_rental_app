// lib/providers/available_rental_cars_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carrentalapp/models/car.dart'; // Now contains the Car model.
import 'package:cloud_firestore/cloud_firestore.dart';

class AvailableRentalCarsNotifier extends StateNotifier<List<Car>> {
  AvailableRentalCarsNotifier() : super([]) {
    print('AvailableRentalCarsNotifier initialized');
    loadAvailableRentalCars();
  }

  Future<void> loadAvailableRentalCars() async {
    try {
      print('Loading available rental cars...');

      // Always load sample data first to ensure we have something to display
      final sampleCars = _getSampleCars();
      print('Sample cars loaded: ${sampleCars.length}');
      state = sampleCars;
      print('State updated with sample cars: ${state.length}');

      // Then try to get data from Firestore
      print('Attempting to query Firestore...');
      final QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection('rentalCars').get();

      print(
          'Firestore query completed. Documents count: ${snapshot.docs.length}');

      // Only proceed if we got documents from Firestore
      if (snapshot.docs.isNotEmpty) {
        try {
          // Map each document to a Car object.
          final cars = snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            // Optionally store the document ID in the model if required.
            data['id'] = doc.id;
            return Car.fromMap(data);
          }).toList();

          print('Cars mapped from Firestore: ${cars.length}');

          // Update state with Firestore data if we have any
          if (cars.isNotEmpty) {
            print('Using cars from Firestore');
            state = cars;
            print('State updated with Firestore cars: ${state.length}');
          }
        } catch (e) {
          print('Error mapping Firestore documents to Car objects: $e');
          // We already loaded sample data, so no need to do it again
        }
      } else {
        print('No cars found in Firestore, using sample data');
        // We already loaded sample data, so no need to do it again
      }
    } catch (e) {
      print('Error loading rental cars: $e');
      // Load sample data in case of error
      if (state.isEmpty) {
        print('State is empty, loading sample data due to error');
        final sampleCars = _getSampleCars();
        print('Sample cars count: ${sampleCars.length}');
        state = sampleCars;
        print('State updated with sample cars: ${state.length}');
      }
    }
  }

  // Sample car data for testing
  List<Car> _getSampleCars() {
    print('Creating sample car data');
    return [
      Car(
        id: '1',
        name: 'Toyota Camry',
        carModel: 'Sedan',
        seater: 5,
        imageUrl: 'assets/images/Toyota_Camry.jpeg',
        fuelType: 'Petrol',
        pricePerHour: 15.0,
        pricePerDay: 100.0,
        pricePerKm: 0.5,
        availableLocation: 'Ahmedabad, India',
      ),
      Car(
        id: '2',
        name: 'BMW X5',
        carModel: 'SUV',
        seater: 7,
        imageUrl: 'assets/images/BMW_X5.jpeg',
        fuelType: 'Diesel',
        pricePerHour: 25.0,
        pricePerDay: 180.0,
        pricePerKm: 0.8,
        availableLocation: 'Ahmedabad, India',
      ),
      Car(
        id: '3',
        name: 'Tesla Model 3',
        carModel: 'Electric Sedan',
        seater: 5,
        imageUrl: 'assets/images/Tesla_Model_3.jpeg',
        fuelType: 'Electric',
        pricePerHour: 20.0,
        pricePerDay: 150.0,
        pricePerKm: 0.6,
        availableLocation: 'Ahmedabad, India',
      ),
      Car(
        id: '4',
        name: 'Mercedes Benz GLC',
        carModel: 'SUV',
        seater: 5,
        imageUrl: 'assets/images/Mercedes_Benz_GLC.jpeg',
        fuelType: 'Diesel',
        pricePerHour: 22.0,
        pricePerDay: 160.0,
        pricePerKm: 0.7,
        availableLocation: 'Ahmedabad, India',
      ),
      Car(
        id: '5',
        name: 'Audi A8',
        carModel: 'Luxury Sedan',
        seater: 5,
        imageUrl: 'assets/images/Audi_A8.jpeg',
        fuelType: 'Petrol',
        pricePerHour: 30.0,
        pricePerDay: 200.0,
        pricePerKm: 0.9,
        availableLocation: 'Ahmedabad, India',
      ),
    ];
  }
}

final availableRentalCarsProvider =
    StateNotifierProvider<AvailableRentalCarsNotifier, List<Car>>((ref) {
  print('Creating availableRentalCarsProvider');
  return AvailableRentalCarsNotifier();
});
