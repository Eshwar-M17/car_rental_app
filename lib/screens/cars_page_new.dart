import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carrentalapp/widgets/Available_Rental_Car_Card.dart';
import 'package:carrentalapp/providers/available_rental_cars_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:carrentalapp/models/car.dart';
import 'package:carrentalapp/core/widgets/common_widgets.dart';
import 'package:carrentalapp/core/theme/app_theme.dart';

class CarsPageNew extends ConsumerStatefulWidget {
  const CarsPageNew({Key? key}) : super(key: key);

  @override
  _CarsPageNewState createState() => _CarsPageNewState();
}

class _CarsPageNewState extends ConsumerState<CarsPageNew> {
  final TextEditingController searchController = TextEditingController();
  List<Car> filteredCars = [];
  List<Car> allCars = [];
  bool isLoading = true;
  bool isFiltered = false; // Track if filters are applied

  // Filter selection variables
  String? selectedCarName;
  int? selectedSeater;
  String? selectedFuelType;

  @override
  void initState() {
    super.initState();
    print('CarsPageNew: initState called');
    // Load data immediately instead of using microtask
    _loadData();
  }

  void _loadData() {
    print('CarsPageNew: _loadData called');
    setState(() {
      isLoading = true;
      print('CarsPageNew: isLoading set to true');
    });

    try {
      // Read the data directly without refreshing the provider
      print('CarsPageNew: Reading data from provider');
      final cars = ref.read(availableRentalCarsProvider);
      print('CarsPageNew: _loadData called, cars count: ${cars.length}');

      // Always update the state with the data we have
      setState(() {
        print('CarsPageNew: Setting state with cars data');
        allCars = List.from(cars); // Create a copy
        print('CarsPageNew: allCars length: ${allCars.length}');

        // Always show all cars initially
        isFiltered = false;
        filteredCars = List.from(cars); // Create a copy
        print('CarsPageNew: filteredCars length: ${filteredCars.length}');

        isLoading = false;
        print('CarsPageNew: isLoading set to false');
      });
    } catch (e) {
      print('CarsPageNew: Error loading cars: $e');
      setState(() {
        isLoading = false;
        print('CarsPageNew: isLoading set to false due to error');
      });
    }
  }

  void _applyFilters() {
    setState(() {
      isFiltered = true; // Mark that filters are applied

      // Start with all cars
      filteredCars = List.from(allCars);

      // Apply filters only if they are selected
      if (selectedCarName != null && selectedCarName!.isNotEmpty) {
        filteredCars =
            filteredCars.where((car) => car.name == selectedCarName).toList();
      }

      if (selectedSeater != null) {
        filteredCars =
            filteredCars.where((car) => car.seater == selectedSeater).toList();
      }

      if (selectedFuelType != null && selectedFuelType!.isNotEmpty) {
        filteredCars = filteredCars
            .where((car) => car.fuelType == selectedFuelType)
            .toList();
      }

      print(
          'Filters applied: Car=${selectedCarName}, Seater=${selectedSeater}, Fuel=${selectedFuelType}');
      print('Filtered cars count: ${filteredCars.length}');
    });
  }

  void _resetFilters() {
    setState(() {
      isFiltered = false; // Mark that filters are not applied
      selectedCarName = null;
      selectedSeater = null;
      selectedFuelType = null;
      searchController.clear(); // Clear search text
      filteredCars = List.from(allCars); // Reset to all cars
      print('Filters reset, showing all ${filteredCars.length} cars');
    });
  }

  void _filterCars() {
    // Create local variables to track changes in the modal
    String? tempCarName = selectedCarName;
    int? tempSeater = selectedSeater;
    String? tempFuelType = selectedFuelType;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allow the sheet to be larger
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(builder: (context, setModalState) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Filter Options',
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 16),

                // Only show dropdown if there are cars to filter
                if (allCars.isNotEmpty) ...[
                  // Car Name Dropdown
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Car Name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    value: tempCarName,
                    hint: Text('Select Car'),
                    items: [
                      // Add a "All" option
                      DropdownMenuItem<String>(
                        value: null,
                        child: Text('All Cars'),
                      ),
                      // Add car name options
                      ...allCars.map((car) => car.name).toSet().map((name) {
                        return DropdownMenuItem<String>(
                          value: name,
                          child: Text(name),
                        );
                      }).toList(),
                    ],
                    onChanged: (value) {
                      setModalState(() {
                        tempCarName = value;
                        print('Selected car name: $tempCarName');
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Seater Dropdown
                  DropdownButtonFormField<int>(
                    decoration: InputDecoration(
                      labelText: 'Seater',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    value: tempSeater,
                    hint: Text('Select Seater'),
                    items: [
                      // Add a "All" option
                      DropdownMenuItem<int>(
                        value: null,
                        child: Text('All Seaters'),
                      ),
                      // Add seater options
                      ...allCars.map((car) => car.seater).toSet().map((seater) {
                        return DropdownMenuItem<int>(
                          value: seater,
                          child: Text('$seater Seater'),
                        );
                      }).toList(),
                    ],
                    onChanged: (value) {
                      setModalState(() {
                        tempSeater = value;
                        print('Selected seater: $tempSeater');
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Fuel Type Dropdown
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Fuel Type',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    value: tempFuelType,
                    hint: Text('Select Fuel Type'),
                    items: [
                      // Add a "All" option
                      DropdownMenuItem<String>(
                        value: null,
                        child: Text('All Fuel Types'),
                      ),
                      // Add fuel type options
                      ...allCars
                          .map((car) => car.fuelType)
                          .toSet()
                          .map((fuelType) {
                        return DropdownMenuItem<String>(
                          value: fuelType,
                          child: Text(fuelType),
                        );
                      }).toList(),
                    ],
                    onChanged: (value) {
                      setModalState(() {
                        tempFuelType = value;
                        print('Selected fuel type: $tempFuelType');
                      });
                    },
                  ),
                ] else ...[
                  // Show message if no cars available
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text('No cars available to filter'),
                  ),
                ],

                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    OutlinedButton(
                      onPressed: () {
                        setModalState(() {
                          tempCarName = null;
                          tempSeater = null;
                          tempFuelType = null;
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        padding:
                            EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: Text('Reset'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        // Apply the temporary filter values to the actual filters
                        selectedCarName = tempCarName;
                        selectedSeater = tempSeater;
                        selectedFuelType = tempFuelType;

                        // Check if any filters are actually applied
                        bool hasFilters = selectedCarName != null ||
                            selectedSeater != null ||
                            selectedFuelType != null;

                        if (hasFilters) {
                          // Apply the filters only if at least one filter is selected
                          _applyFilters();
                        } else {
                          // If no filters selected, reset to show all cars
                          _resetFilters();
                        }

                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        padding:
                            EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: Text('Apply Filters'),
                    ),
                  ],
                ),
              ],
            ),
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    print(
        'CarsPageNew: build method called, isLoading: $isLoading, isFiltered: $isFiltered');
    final user = FirebaseAuth.instance.currentUser;
    final userName = user?.displayName ?? 'User';

    // Watch the provider to rebuild when data changes
    final cars = ref.watch(availableRentalCarsProvider);
    print('CarsPageNew: build method, cars from provider: ${cars.length}');
    print(
        'CarsPageNew: allCars length: ${allCars.length}, filteredCars length: ${filteredCars.length}');

    // If we have cars from the provider but our local lists are empty, update them
    if (cars.isNotEmpty &&
        (allCars.isEmpty || filteredCars.isEmpty) &&
        !isLoading) {
      print(
          'CarsPageNew: Provider has cars but local lists are empty, updating');
      // Use Future.microtask to avoid setState during build
      Future.microtask(() {
        if (mounted) {
          setState(() {
            allCars = List.from(cars);
            if (!isFiltered) {
              filteredCars = List.from(cars);
            }
            print(
                'CarsPageNew: Updated local lists from provider, allCars: ${allCars.length}, filteredCars: ${filteredCars.length}');
          });
        }
      });
    }

    return Scaffold(
      appBar: LocationAppBar(
        location: 'Ahmedabad, INDIA',
        onLocationTap: () {
          // Handle location tap
        },
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          print('CarsPageNew: RefreshIndicator triggered');
          // Force a refresh of the provider
          ref.refresh(availableRentalCarsProvider);
          // Then load the data
          _loadData();
          return Future.value();
        },
        child: SingleChildScrollView(
          physics:
              AlwaysScrollableScrollPhysics(), // Enable scrolling even when content is small
          child: Padding(
            padding: AppUI.padding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                UserGreeting(
                  userName: userName,
                  subtitle: "Let's find your favourite car here",
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: searchController,
                          onChanged: (value) {
                            setState(() {
                              if (value.isEmpty) {
                                // If search is cleared, reset filters
                                isFiltered = false;
                                filteredCars = allCars;
                              } else {
                                // If searching, mark as filtered
                                isFiltered = true;
                                filteredCars = allCars.where((car) {
                                  return car.name
                                      .toLowerCase()
                                      .contains(value.toLowerCase());
                                }).toList();
                              }
                            });
                          },
                          decoration: InputDecoration(
                            hintText: 'Search for cars',
                            hintStyle:
                                TextStyle(color: AppColors.textSecondary),
                            prefixIcon:
                                Icon(Icons.search, color: AppColors.primary),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 16, horizontal: 16),
                          ),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        margin: const EdgeInsets.all(4),
                        child: IconButton(
                          icon: Icon(Icons.filter_list, color: Colors.white),
                          onPressed: _filterCars,
                          tooltip: 'Filter cars',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isFiltered ? 'Filtered Cars' : 'All Cars',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    if (isFiltered)
                      ElevatedButton.icon(
                        onPressed: _resetFilters,
                        icon: Icon(Icons.clear, size: 18),
                        label: Text('Clear Filters'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade50,
                          foregroundColor: Colors.red,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),

                // Loading indicator
                if (isLoading)
                  LoadingIndicator(message: 'Loading cars...')

                // Show all cars by default, or filtered cars if filters are applied
                else if ((isFiltered && filteredCars.isNotEmpty) ||
                    (!isFiltered && allCars.isNotEmpty))
                  ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount:
                        isFiltered ? filteredCars.length : allCars.length,
                    itemBuilder: (context, index) {
                      final car =
                          isFiltered ? filteredCars[index] : allCars[index];
                      return AvailableRentalCarCard(car: car);
                    },
                  )

                // No cars found message
                else
                  EmptyState(
                    message: isFiltered
                        ? 'No cars match your filters'
                        : 'No cars available',
                    icon: Icons.car_rental,
                    actionLabel: 'Refresh',
                    onAction: _loadData,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
