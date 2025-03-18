// lib/screens/car_rental_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:carrentalapp/models/car.dart'; // Contains the Car model.
import 'package:carrentalapp/models/booking.dart'; // Contains the Booking model.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:carrentalapp/screens/map_picker_screen.dart'; // MapPickerScreen for location picking.
import 'package:carrentalapp/notification.dart';
import 'package:carrentalapp/providers/rented_cars_provider.dart'; // Import the provider
import 'package:carrentalapp/core/theme/app_theme.dart'; // Import app theme

class CarRentalDetailScreen extends ConsumerStatefulWidget {
  final Car car;

  const CarRentalDetailScreen({Key? key, required this.car}) : super(key: key);

  @override
  ConsumerState createState() => _CarRentalDetailScreenState();
}

class _CarRentalDetailScreenState extends ConsumerState<CarRentalDetailScreen> {
  DateTime? _rentalStartDate;
  DateTime? _rentalEndDate;
  final DateFormat _dateFormat = DateFormat('MMM dd, yyyy');
  double? _totalCost;
  int? _rentalDays;
  double? _dailyRate;
  bool _isLoading = false;

  // Instead of text controllers, we use our custom location picker widget.
  PickedLocation? _pickupLocation;
  PickedLocation? _dropoffLocation;

  Future<void> _selectRentalStartDate(BuildContext context) async {
    final DateTime now = DateTime.now();
    final DateTime initialDate = _rentalStartDate ?? now;
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _rentalStartDate) {
      setState(() {
        _rentalStartDate = picked;
        if (_rentalEndDate != null && _rentalEndDate!.isBefore(picked)) {
          _rentalEndDate = null;
        }
        _calculateTotalCost();
      });
    }
  }

  Future<void> _selectRentalEndDate(BuildContext context) async {
    if (_rentalStartDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select a rental start date first.')),
      );
      return;
    }
    final DateTime initialDate =
        _rentalEndDate ?? _rentalStartDate!.add(const Duration(days: 1));
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: _rentalStartDate!,
      lastDate: _rentalStartDate!.add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _rentalEndDate) {
      setState(() {
        _rentalEndDate = picked;
        _calculateTotalCost();
      });
    }
  }

  void _calculateTotalCost() {
    if (_rentalStartDate != null && _rentalEndDate != null) {
      // Calculate days between the dates (inclusive of start and end date)
      _rentalDays = _rentalEndDate!.difference(_rentalStartDate!).inDays + 1;

      // Use the Car model's calculation method
      _totalCost = widget.car.calculateRentalCost(_rentalDays!);

      // Calculate the effective daily rate
      _dailyRate = _totalCost! / _rentalDays!;
    }
  }

  Future<void> _confirmRental() async {
    if (_rentalStartDate == null ||
        _rentalEndDate == null ||
        _pickupLocation == null ||
        _dropoffLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Create a new Booking instance using user-provided dates and include nested car details.
      final newBooking = Booking(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        carId: widget.car.id,
        bookingDate: DateTime.now(),
        rentStartDate: _rentalStartDate!,
        endDate: _rentalEndDate!,
        carDetails: widget.car,
        totalCost: _totalCost!,
        rentalDays: _rentalDays!,
        dailyRate: _dailyRate!,
      );

      // Create a map with the additional location data
      final Map<String, dynamic> extraData = {
        'pickupLocation': _pickupLocation!.address,
        'pickupLatitude': _pickupLocation!.latitude,
        'pickupLongitude': _pickupLocation!.longitude,
        'dropoffLocation': _dropoffLocation!.address,
        'dropoffLatitude': _dropoffLocation!.latitude,
        'dropoffLongitude': _dropoffLocation!.longitude,
      };

      // Use the provider to add the booking instead of directly writing to Firestore
      await ref
          .read(rentedCarsProvider.notifier)
          .addBooking(newBooking, extraData);

      // Show confirmation notification
      await showRentalConfirmationNotification(newBooking);

      if (!mounted) return;

      // Show success message and navigate back.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking confirmed!')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar with Car Image
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Car Image
                  Image.asset(
                    widget.car.imageUrl,
                    fit: BoxFit.cover,
                  ),
                  // Gradient overlay for better text visibility
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                        stops: [0.7, 1.0],
                      ),
                    ),
                  ),
                  // Car name and price at the bottom
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.car.name,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          widget.car.carModel,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.success,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '\$${widget.car.pricePerDay.toStringAsFixed(0)}/day',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            leading: IconButton(
              icon: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.arrow_back, color: AppColors.textPrimary),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    shape: BoxShape.circle,
                  ),
                  child:
                      Icon(Icons.favorite_border, color: AppColors.textPrimary),
                ),
                onPressed: () {},
              ),
              SizedBox(width: 8),
            ],
          ),

          // Car Details and Booking Form
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Car Specifications
                  Text(
                    'Car Specifications',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildSpecItem(
                        icon: Icons.event_seat,
                        value: '${widget.car.seater}',
                        label: 'Seats',
                      ),
                      _buildSpecItem(
                        icon: Icons.local_gas_station,
                        value: widget.car.fuelType,
                        label: 'Fuel',
                      ),
                      _buildSpecItem(
                        icon: Icons.settings,
                        value: 'Auto',
                        label: 'Transmission',
                      ),
                      _buildSpecItem(
                        icon: Icons.speed,
                        value: 'GPS',
                        label: 'Navigation',
                      ),
                    ],
                  ),

                  SizedBox(height: 24),
                  Divider(),
                  SizedBox(height: 24),

                  // Booking Form
                  Text(
                    'Rental Details',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),

                  // Date Selection
                  Row(
                    children: [
                      Expanded(
                        child: _buildDateSelector(
                          label: 'Start Date',
                          value: _rentalStartDate != null
                              ? _dateFormat.format(_rentalStartDate!)
                              : 'Select Date',
                          icon: Icons.calendar_today,
                          onTap: () => _selectRentalStartDate(context),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: _buildDateSelector(
                          label: 'End Date',
                          value: _rentalEndDate != null
                              ? _dateFormat.format(_rentalEndDate!)
                              : 'Select Date',
                          icon: Icons.calendar_today,
                          onTap: () => _selectRentalEndDate(context),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 24),

                  // Location Selection
                  _buildLocationSelector(
                    label: 'Pickup Location',
                    value: _pickupLocation?.address ?? 'Select Location',
                    icon: Icons.location_on,
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MapPickerScreen(
                            title: 'Select Pickup Location',
                          ),
                        ),
                      );
                      if (result != null && result is PickedLocation) {
                        setState(() {
                          _pickupLocation = result;
                        });
                      }
                    },
                  ),

                  SizedBox(height: 16),

                  _buildLocationSelector(
                    label: 'Dropoff Location',
                    value: _dropoffLocation?.address ?? 'Select Location',
                    icon: Icons.location_on,
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MapPickerScreen(
                            title: 'Select Dropoff Location',
                          ),
                        ),
                      );
                      if (result != null && result is PickedLocation) {
                        setState(() {
                          _dropoffLocation = result;
                        });
                      }
                    },
                  ),

                  SizedBox(height: 32),

                  // Total Cost
                  if (_totalCost != null)
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Total Cost',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: AppColors.primary,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                '\$${_totalCost!.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                              if (_dailyRate != null)
                                Text(
                                  '\$${_dailyRate!.toStringAsFixed(2)}/day',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppColors.primary,
                                  ),
                                ),
                            ],
                          ),
                          Text(
                            _rentalDays != null ? '$_rentalDays days' : '',
                            style: TextStyle(
                              fontSize: 16,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),

                  SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, -5),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _isLoading ? null : _confirmRental,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: _isLoading
              ? SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  'Confirm Rental',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildSpecItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: AppColors.primary,
            size: 24,
          ),
        ),
        SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildDateSelector({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.divider),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(icon, color: AppColors.primary),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    value,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationSelector({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.divider),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(icon, color: AppColors.primary),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    value,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class PickedLocation {
  final String address;
  final double latitude;
  final double longitude;

  PickedLocation({
    required this.address,
    required this.latitude,
    required this.longitude,
  });
}
