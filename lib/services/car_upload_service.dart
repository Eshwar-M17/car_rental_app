// lib/services/car_upload_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:carrentalapp/models/car.dart';

class CarUploadService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// List of Rental Cars provided by admin.
  List<Car> get rentalCars => [
        Car(
          id: 'rental1',
          name: 'BMW X5',
          carModel: 'X5 M',
          seater: 7,
          imageUrl: 'assets/images/BMW_X5.jpeg',
          fuelType: 'Diesel',
          pricePerHour: 30.0,
          pricePerDay: 200.0,
          pricePerKm: 2.0,
          availableLocation: 'Downtown, City A', // new field
        ),
        Car(
          id: 'rental2',
          name: 'Mercedes-Benz GLC',
          carModel: 'GLC 300',
          seater: 5,
          imageUrl: 'assets/images/Mercedes_Benz_GLC.jpeg',
          fuelType: 'Petrol',
          pricePerHour: 25.0,
          pricePerDay: 180.0,
          pricePerKm: 1.8,
          availableLocation: 'Airport, City B',
        ),
        Car(
          id: 'rental3',
          name: 'Toyota Camry',
          carModel: 'Camry Hybrid',
          seater: 5,
          imageUrl: 'assets/images/Toyota_Camry.jpeg',
          fuelType: 'Hybrid',
          pricePerHour: 20.0,
          pricePerDay: 150.0,
          pricePerKm: 1.5,
          availableLocation: 'Suburb, City C',
        ),
        Car(
          id: 'rental4',
          name: 'Tesla Model 3',
          carModel: 'Model 3 Long Range',
          seater: 5,
          imageUrl: 'assets/images/Tesla_Model_3.jpeg',
          fuelType: 'Electric',
          pricePerHour: 40.0,
          pricePerDay: 250.0,
          pricePerKm: 2.5,
          availableLocation: 'Downtown, City D',
        ),
      ];

  /// Uploads a list of rental cars to the "rentalCars" collection in Firestore.
  Future<void> uploadRentalCars() async {
    WriteBatch batch = _firestore.batch();
    CollectionReference rentalCarsCollection = _firestore.collection('rentalCars');
    for (Car car in rentalCars) {
      // Use the car's id as the document ID.
      DocumentReference docRef = rentalCarsCollection.doc(car.id);
      batch.set(docRef, car.toMap());
    }
    try {
      await batch.commit();
      print('Rental cars uploaded successfully!');
    } catch (e) {
      print('Error uploading rental cars: $e');
    }
  }
}
