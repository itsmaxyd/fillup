import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/vehicle.dart';
import '../providers/vehicle_provider.dart';
import '../services/fuel_price_service.dart';
import '../utils/security_utils.dart';
import 'home_screen.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _mileageController = TextEditingController();
  
  String? _selectedFuelType = 'Petrol';
  String? _selectedCity = 'Delhi';
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _mileageController.dispose();
    super.dispose();
  }

  Future<void> _submitSetup() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final vehicleProvider = context.read<VehicleProvider>();
      
      // Sanitize inputs
      final sanitizedName = SecurityUtils.sanitizeInput(_nameController.text.trim());
      
      final vehicle = Vehicle(
        name: sanitizedName,
        fuelType: _selectedFuelType!,
        city: _selectedCity!,
        initialMileage: double.parse(_mileageController.text),
      );

      final newVehicle = await vehicleProvider.addVehicle(vehicle);

      if (newVehicle != null && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to create vehicle')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString().replaceAll(RegExp(r'[^\w\s-]'), '')}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cities = FuelPriceService.getMajorCities();
    final fuelTypes = FuelPriceService.getFuelTypes();

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                
                // App Logo/Icon
                Icon(
                  Icons.local_gas_station,
                  size: 80,
                  color: Theme.of(context).primaryColor,
                ),
                
                const SizedBox(height: 16),
                
                // Welcome Text
                Text(
                  'Welcome to Fillup',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 8),
                
                Text(
                  'Let\'s set up your first vehicle',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 40),
                
                // Vehicle Name
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Vehicle Name',
                    hintText: 'e.g., My Honda City',
                    prefixIcon: Icon(Icons.directions_car),
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a vehicle name';
                    }
                    if (!SecurityUtils.isValidVehicleName(value)) {
                      return 'Please enter a valid vehicle name (letters, numbers, and basic punctuation only)';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Fuel Type Dropdown
                DropdownButtonFormField<String>(
                  value: _selectedFuelType,
                  decoration: const InputDecoration(
                    labelText: 'Fuel Type',
                    prefixIcon: Icon(Icons.local_gas_station),
                    border: OutlineInputBorder(),
                  ),
                  items: fuelTypes.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedFuelType = value);
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a fuel type';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                // City Dropdown
                DropdownButtonFormField<String>(
                  value: _selectedCity,
                  decoration: const InputDecoration(
                    labelText: 'City',
                    prefixIcon: Icon(Icons.location_city),
                    border: OutlineInputBorder(),
                  ),
                  items: cities.map((city) {
                    return DropdownMenuItem(
                      value: city,
                      child: Text(city),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedCity = value);
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a city';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Initial Mileage
                TextFormField(
                  controller: _mileageController,
                  decoration: const InputDecoration(
                    labelText: 'Current Odometer Reading (km)',
                    hintText: 'e.g., 25000',
                    prefixIcon: Icon(Icons.speed),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter current odometer reading';
                    }
                    if (!SecurityUtils.isValidNumericInput(value, max: 500000)) {
                      return 'Please enter a valid number (max 500,000 km)';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 32),
                
                // Submit Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _submitSetup,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          'Get Started',
                          style: TextStyle(fontSize: 16),
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
