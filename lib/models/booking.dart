// lib/models/booking.dart
import 'package:carrentalapp/models/car.dart';

class Booking {
  final String id;
  final String carId;
  final DateTime bookingDate;
  final DateTime rentStartDate;
  final DateTime endDate;
  final Car carDetails; // Non-nullable field
  final double totalCost; // Total cost of the booking
  final int rentalDays; // Number of days rented
  final double dailyRate; // Rate applied per day

  Booking({
    required this.id,
    required this.carId,
    required this.bookingDate,
    required this.rentStartDate,
    required this.endDate,
    required this.carDetails,
    required this.totalCost,
    required this.rentalDays,
    required this.dailyRate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'carId': carId,
      'bookingDate': bookingDate.toIso8601String(),
      'rentStartDate': rentStartDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'carDetails': carDetails.toMap(),
      'totalCost': totalCost,
      'rentalDays': rentalDays,
      'dailyRate': dailyRate,
    };
  }

  factory Booking.fromMap(Map<String, dynamic> map) {
    return Booking(
      id: map['id'] as String,
      carId: map['carId'] as String,
      bookingDate: DateTime.parse(map['bookingDate'] as String),
      rentStartDate: DateTime.parse(map['rentStartDate'] as String),
      endDate: DateTime.parse(map['endDate'] as String),
      carDetails: Car.fromMap(map['carDetails'] as Map<String, dynamic>),
      totalCost: map['totalCost'] != null ? (map['totalCost'] as num).toDouble() : 0.0,
      rentalDays: map['rentalDays'] != null ? map['rentalDays'] as int : 1,
      dailyRate: map['dailyRate'] != null ? (map['dailyRate'] as num).toDouble() : 0.0,
    );
  }
}
