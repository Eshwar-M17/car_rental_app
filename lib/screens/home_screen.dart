// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:carrentalapp/screens/booking_history_page.dart';
import 'package:carrentalapp/screens/cars_page_new.dart';
import 'package:carrentalapp/screens/profile_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carrentalapp/core/widgets/common_widgets.dart';
import 'package:carrentalapp/core/theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  // Define pages as getters to ensure they're created when needed
  Widget get _carsPage => const CarsPageNew();
  Widget get _bookingsPage => BookingsPage();
  Widget get _profilePage => ProfilePage();

  @override
  Widget build(BuildContext context) {
    // Use a list of functions to create pages on demand
    final pages = [
      _carsPage,
      _bookingsPage,
      _profilePage,
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}
