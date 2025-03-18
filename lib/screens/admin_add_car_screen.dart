import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:carrentalapp/models/car.dart';
import 'package:carrentalapp/core/theme/app_theme.dart';

class AdminAddCarScreen extends StatefulWidget {
  final Car? carToEdit;

  const AdminAddCarScreen({Key? key, this.carToEdit}) : super(key: key);

  @override
  _AdminAddCarScreenState createState() => _AdminAddCarScreenState();
}

class _AdminAddCarScreenState extends State<AdminAddCarScreen> {
  final _formKey = GlobalKey<FormState>();

  // Form controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _modelController = TextEditingController();
  final TextEditingController _seaterController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();
  final TextEditingController _fuelTypeController = TextEditingController();
  final TextEditingController _pricePerDayController = TextEditingController();
  final TextEditingController _pricePerHourController = TextEditingController();
  final TextEditingController _pricePerKmController = TextEditingController();
  final TextEditingController _availableLocationController =
      TextEditingController();

  bool _isLoading = false;
  bool _isEditing = false;
  String? _carId;

  // Dropdown options
  final List<String> _fuelTypes = ['Petrol', 'Diesel', 'Electric', 'Hybrid'];
  final List<int> _seaterOptions = [2, 4, 5, 6, 7, 8];

  @override
  void initState() {
    super.initState();
    // If we're editing an existing car, populate the form fields
    if (widget.carToEdit != null) {
      _isEditing = true;
      _carId = widget.carToEdit!.id;
      _nameController.text = widget.carToEdit!.name;
      _modelController.text = widget.carToEdit!.carModel;
      _seaterController.text = widget.carToEdit!.seater.toString();
      _imageUrlController.text = widget.carToEdit!.imageUrl;
      _fuelTypeController.text = widget.carToEdit!.fuelType;
      _pricePerDayController.text = widget.carToEdit!.pricePerDay.toString();
      _pricePerHourController.text = widget.carToEdit!.pricePerHour.toString();
      _pricePerKmController.text = widget.carToEdit!.pricePerKm.toString();
      _availableLocationController.text = widget.carToEdit!.availableLocation;
    } else {
      // Set default values for new cars
      _seaterController.text = '4';
      _fuelTypeController.text = 'Petrol';
      _pricePerDayController.text = '0.0';
      _pricePerHourController.text = '0.0';
      _pricePerKmController.text = '0.0';
    }
  }

  Future<void> _saveCarData() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final String id = _isEditing
            ? _carId!
            : DateTime.now().millisecondsSinceEpoch.toString();
        final car = {
          'id': id,
          'name': _nameController.text.trim(),
          'carModel': _modelController.text.trim(),
          'seater': int.parse(_seaterController.text.trim()),
          'imageUrl': _imageUrlController.text.trim(),
          'fuelType': _fuelTypeController.text.trim(),
          'pricePerDay': double.parse(_pricePerDayController.text.trim()),
          'pricePerHour': double.parse(_pricePerHourController.text.trim()),
          'pricePerKm': double.parse(_pricePerKmController.text.trim()),
          'availableLocation': _availableLocationController.text.trim(),
        };

        await FirebaseFirestore.instance
            .collection('rentalCars')
            .doc(id)
            .set(car);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing
                ? 'Car updated successfully'
                : 'Car added successfully'),
            backgroundColor: AppColors.success,
          ),
        );

        if (!_isEditing) {
          _formKey.currentState!.reset();
          // Reset to default values
          _seaterController.text = '4';
          _fuelTypeController.text = 'Petrol';
          _pricePerDayController.text = '0.0';
          _pricePerHourController.text = '0.0';
          _pricePerKmController.text = '0.0';
        } else {
          Navigator.pop(context); // Go back to the cars list after editing
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving car: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Builds a styled text field with a uniform look
  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    String? hintText,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffixIcon,
    String? Function(String?)? validator,
    bool readOnly = false,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        readOnly: readOnly,
        onTap: onTap,
        style: const TextStyle(fontSize: 16),
        decoration: InputDecoration(
          labelText: labelText,
          hintText: hintText,
          labelStyle: TextStyle(color: AppColors.primary),
          hintStyle: const TextStyle(color: Colors.grey),
          suffixIcon: suffixIcon,
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.error, width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.error, width: 2),
          ),
        ),
        validator: validator ??
            (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter $labelText';
              }
              return null;
            },
      ),
    );
  }

  // Build a dropdown field for selection
  Widget _buildDropdownField({
    required TextEditingController controller,
    required String labelText,
    required List<String> items,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: items.contains(controller.text) ? controller.text : items.first,
        decoration: InputDecoration(
          labelText: labelText,
          labelStyle: TextStyle(color: AppColors.primary),
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.primary, width: 2),
          ),
        ),
        items: items.map((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
        onChanged: (newValue) {
          if (newValue != null) {
            controller.text = newValue;
          }
        },
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please select $labelText';
          }
          return null;
        },
      ),
    );
  }

  // Build a number dropdown field
  Widget _buildNumberDropdownField({
    required TextEditingController controller,
    required String labelText,
    required List<int> items,
  }) {
    // Convert the controller text to int for comparison
    int? currentValue;
    try {
      currentValue = int.parse(controller.text);
    } catch (e) {
      currentValue = items.first;
    }

    // Ensure the current value is in the list
    if (!items.contains(currentValue)) {
      currentValue = items.first;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<int>(
        value: currentValue,
        decoration: InputDecoration(
          labelText: labelText,
          labelStyle: TextStyle(color: AppColors.primary),
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.primary, width: 2),
          ),
        ),
        items: items.map((int value) {
          return DropdownMenuItem<int>(
            value: value,
            child: Text('$value Seats'),
          );
        }).toList(),
        onChanged: (newValue) {
          if (newValue != null) {
            controller.text = newValue.toString();
          }
        },
        validator: (value) {
          if (value == null) {
            return 'Please select $labelText';
          }
          return null;
        },
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _modelController.dispose();
    _seaterController.dispose();
    _imageUrlController.dispose();
    _fuelTypeController.dispose();
    _pricePerDayController.dispose();
    _pricePerHourController.dispose();
    _pricePerKmController.dispose();
    _availableLocationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          _isEditing ? 'Edit Car' : 'Add New Car',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Form header
                    Card(
                      elevation: 0,
                      color: AppColors.primary.withOpacity(0.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                _isEditing ? Icons.edit : Icons.add_circle,
                                color: AppColors.primary,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _isEditing
                                        ? 'Edit Car Details'
                                        : 'Add New Car',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _isEditing
                                        ? 'Update car information in your fleet'
                                        : 'Enter car details to add to the fleet',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Basic Information Section
                    _buildSectionHeader(
                      title: 'Basic Information',
                      icon: Icons.directions_car,
                    ),
                    const SizedBox(height: 16),

                    _buildTextField(
                      controller: _nameController,
                      labelText: 'Car Name',
                      hintText: 'e.g., Toyota Camry',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter car name';
                        }
                        return null;
                      },
                    ),

                    _buildTextField(
                      controller: _modelController,
                      labelText: 'Car Model',
                      hintText: 'e.g., 2023 SE',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter car model';
                        }
                        return null;
                      },
                    ),

                    _buildNumberDropdownField(
                      controller: _seaterController,
                      labelText: 'Seating Capacity',
                      items: _seaterOptions,
                    ),

                    _buildDropdownField(
                      controller: _fuelTypeController,
                      labelText: 'Fuel Type',
                      items: _fuelTypes,
                    ),

                    _buildTextField(
                      controller: _imageUrlController,
                      labelText: 'Image URL',
                      hintText: 'Enter image URL or path',
                      suffixIcon: Icon(Icons.image, color: AppColors.primary),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter image URL';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 24),

                    // Pricing Section
                    _buildSectionHeader(
                      title: 'Pricing Information',
                      icon: Icons.attach_money,
                    ),
                    const SizedBox(height: 16),

                    _buildTextField(
                      controller: _pricePerDayController,
                      labelText: 'Price Per Day (\$)',
                      hintText: 'e.g., 50.00',
                      keyboardType: TextInputType.number,
                      suffixIcon: const Icon(Icons.calendar_today,
                          color: AppColors.primary),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter price per day';
                        }
                        try {
                          double price = double.parse(value);
                          if (price < 0) {
                            return 'Price cannot be negative';
                          }
                        } catch (e) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),

                    _buildTextField(
                      controller: _pricePerHourController,
                      labelText: 'Price Per Hour (\$)',
                      hintText: 'e.g., 10.00',
                      keyboardType: TextInputType.number,
                      suffixIcon: const Icon(Icons.access_time,
                          color: AppColors.primary),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter price per hour';
                        }
                        try {
                          double price = double.parse(value);
                          if (price < 0) {
                            return 'Price cannot be negative';
                          }
                        } catch (e) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),

                    _buildTextField(
                      controller: _pricePerKmController,
                      labelText: 'Price Per Km (\$)',
                      hintText: 'e.g., 0.50',
                      keyboardType: TextInputType.number,
                      suffixIcon:
                          const Icon(Icons.speed, color: AppColors.primary),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter price per km';
                        }
                        try {
                          double price = double.parse(value);
                          if (price < 0) {
                            return 'Price cannot be negative';
                          }
                        } catch (e) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 24),

                    // Location Section
                    _buildSectionHeader(
                      title: 'Location Information',
                      icon: Icons.location_on,
                    ),
                    const SizedBox(height: 16),

                    _buildTextField(
                      controller: _availableLocationController,
                      labelText: 'Available Location',
                      hintText: 'e.g., Downtown Branch',
                      suffixIcon: const Icon(Icons.location_on,
                          color: AppColors.primary),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter available location';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 32),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        onPressed: _saveCarData,
                        icon: Icon(_isEditing ? Icons.update : Icons.add),
                        label: Text(
                          _isEditing ? 'Update Car' : 'Add Car',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    if (_isEditing)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.textSecondary,
                              side: BorderSide(color: Colors.grey[300]!),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.cancel),
                            label: const Text(
                              'Cancel',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionHeader({required String title, required IconData icon}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
