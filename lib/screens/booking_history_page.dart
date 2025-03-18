// lib/screens/bookings_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/rented_cars_provider.dart';
import 'package:carrentalapp/widgets/rented_car_card.dart';
import 'package:carrentalapp/models/booking.dart';
import 'package:carrentalapp/core/widgets/common_widgets.dart';
import 'package:carrentalapp/core/theme/app_theme.dart';

class BookingsPage extends ConsumerStatefulWidget {
  const BookingsPage({Key? key}) : super(key: key);

  @override
  _BookingsPageState createState() => _BookingsPageState();
}

class _BookingsPageState extends ConsumerState<BookingsPage> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _refreshBookings();
  }

  Future<void> _refreshBookings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Refresh bookings from Firestore
      await ref.read(rentedCarsProvider.notifier).loadBookingsFromFirestore();
    } catch (e) {
      print("Error refreshing bookings: $e");
      // Show error message if needed
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookings = ref.watch(rentedCarsProvider);

    return Scaffold(
      appBar: CommonAppBar(
        title: 'Your Rental History',
        showBackButton: false,
        centerTitle: false,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshBookings,
        child: Container(
          color: AppColors.background,
          child: _isLoading
              ? LoadingIndicator(message: 'Loading your bookings...')
              : bookings.isEmpty
                  ? EmptyState(
                      message: 'No rental history found',
                      icon: Icons.car_rental,
                      actionLabel: 'Rent a Car',
                      onAction: () {
                        // Navigate to cars page or handle as needed
                      },
                    )
                  : ListView.builder(
                      padding: AppUI.padding,
                      itemCount: bookings.length,
                      itemBuilder: (context, index) {
                        final booking = bookings[index];
                        // Pass both the booking and the nested Car object.
                        return RentedCarCard(
                            booking: booking, car: booking.carDetails);
                      },
                    ),
        ),
      ),
    );
  }
}
