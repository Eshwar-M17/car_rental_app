// lib/screens/cars_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carrentalapp/widgets/Available_Rental_Car_Card.dart';
import 'package:carrentalapp/providers/available_rental_cars_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:carrentalapp/models/car.dart';

class CarsPage extends ConsumerStatefulWidget {
  const CarsPage({Key? key}) : super(key: key);

  @override
  _CarsPageState createState() => _CarsPageState();
}

class _CarsPageState extends ConsumerState<CarsPage> {
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
    // We'll load data in didChangeDependencies instead
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadData();
  }

  void _loadData() {
    setState(() {
      isLoading = true;
    });

    try {
      // Force a refresh of the provider
      ref.refresh(availableRentalCarsProvider);

      // Now read the data
      final cars = ref.read(availableRentalCarsProvider);
      print('_loadData called, cars count: ${cars.length}');

      if (mounted) {
        setState(() {
          allCars = List.from(cars); // Create a copy

          // Only update filtered cars if filters are applied
          if (isFiltered) {
            _applyFilters(); // Reapply filters to the new data
          } else {
            filteredCars = List.from(cars); // Create a copy
          }

          isLoading = false;
          print('setState in _loadData, filteredCars: ${filteredCars.length}');
        });
      }
    } catch (e) {
      print('Error loading cars: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
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
    final user = FirebaseAuth.instance.currentUser;
    final userName = user?.displayName ?? 'User';

    // Watch the provider to rebuild when data changes
    final cars = ref.watch(availableRentalCarsProvider);
    print('build method, cars from provider: ${cars.length}');

    // Update allCars and filteredCars if they're empty but provider has data
    if ((allCars.isEmpty || filteredCars.isEmpty) &&
        cars.isNotEmpty &&
        !isLoading) {
      print('Updating allCars and filteredCars in build');
      // Use Future.microtask to avoid setState during build
      Future.microtask(() {
        if (mounted) {
          setState(() {
            allCars = List.from(cars);

            // Only update filtered cars if filters are not applied
            if (!isFiltered) {
              filteredCars = List.from(cars);
            } else {
              // If filters are applied, reapply them with the new data
              _applyFilters();
            }
          });
        }
      });
    }

    print('build method, filteredCars: ${filteredCars.length}');

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.menu, color: Colors.black),
          onPressed: () {},
        ),
        title: Row(
          children: [
            Icon(Icons.location_on, color: Colors.black),
            const SizedBox(width: 4),
            Text(
              'Ahmedabad, INDIA',
              style: TextStyle(color: Colors.black),
            ),
            Icon(Icons.keyboard_arrow_down, color: Colors.black),
          ],
        ),
        actions: [
          CircleAvatar(
            backgroundImage: AssetImage('assets/images/avatar2.png'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _loadData();
          return Future.value();
        },
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello $userName 👋',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Let's find your favourite car here",
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
                Row(
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
                          hintText: 'Search',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(Icons.filter_list),
                      onPressed: _filterCars,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isFiltered ? 'Filtered Cars' : 'All Cars',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    if (isFiltered)
                      TextButton(
                        onPressed: _resetFilters,
                        child: Text('Clear Filters'),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                if (isLoading)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
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
                else
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        children: [
                          Icon(
                            Icons.car_rental,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Text(
                            isFiltered
                                ? 'No cars match your filters'
                                : 'No cars available',
                            style: TextStyle(fontSize: 16),
                          ),
                          SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _loadData,
                            icon: Icon(Icons.refresh),
                            label: Text('Refresh'),
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
