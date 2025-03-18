class Car {
  final String id; // Unique identifier for the car.
  final String name;
  final String carModel;
  final int seater;
  final String imageUrl;
  final String fuelType;
  final double pricePerHour; // Admin-set
  final double pricePerDay; // Admin-set
  final double pricePerKm; // Admin-set
  final String availableLocation; // Where the car is available

  Car({
    required this.id,
    required this.name,
    required this.carModel,
    required this.seater,
    required this.imageUrl,
    required this.fuelType,
    required this.pricePerHour,
    required this.pricePerDay,
    required this.pricePerKm,
    required this.availableLocation,
  });

  // Calculate rental cost based on duration in days
  double calculateRentalCost(int days) {
    // Minimum 1 day rental
    days = days < 1 ? 1 : days;

    // Apply discount for longer rentals
    double dailyRate = pricePerDay;
    if (days > 7) {
      // 10% discount for rentals longer than a week
      dailyRate = pricePerDay * 0.9;
    } else if (days > 30) {
      // 20% discount for rentals longer than a month
      dailyRate = pricePerDay * 0.8;
    }

    return dailyRate * days;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'carModel': carModel,
      'seater': seater,
      'imageUrl': imageUrl,
      'fuelType': fuelType,
      'pricePerHour': pricePerHour,
      'pricePerDay': pricePerDay,
      'pricePerKm': pricePerKm,
      'availableLocation': availableLocation,
    };
  }

  factory Car.fromMap(Map<String, dynamic> map) {
    return Car(
      id: map['id'] as String,
      name: map['name'] as String,
      carModel: map['carModel'] as String,
      seater: map['seater'] as int,
      imageUrl: map['imageUrl'] as String,
      fuelType: map['fuelType'] as String,
      pricePerHour: (map['pricePerHour'] as num).toDouble(),
      pricePerDay: (map['pricePerDay'] as num).toDouble(),
      pricePerKm: (map['pricePerKm'] as num).toDouble(),
      availableLocation: map['availableLocation'] as String,
    );
  }
}
