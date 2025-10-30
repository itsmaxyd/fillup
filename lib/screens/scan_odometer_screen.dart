import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../providers/vehicle_provider.dart';
import '../providers/fuel_entry_provider.dart';
import '../services/fuel_price_service.dart';
import '../models/fuel_entry.dart';

class ScanOdometerScreen extends StatefulWidget {
  const ScanOdometerScreen({super.key});

  @override
  State<ScanOdometerScreen> createState() => _ScanOdometerScreenState();
}

class _ScanOdometerScreenState extends State<ScanOdometerScreen> {
  final ImagePicker _picker = ImagePicker();
  final ApiService _apiService = ApiService.instance;
  
  File? _imageFile;
  String? _extractedReading;
  bool _isProcessing = false;
  bool _canEdit = false;
  
  final _odometerController = TextEditingController();
  final _rupeesController = TextEditingController();
  final _litersController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  double? _currentFuelPrice;
  String _inputMode = 'rupees';

  @override
  void initState() {
    super.initState();
    _fetchCurrentFuelPrice();
  }

  @override
  void dispose() {
    _odometerController.dispose();
    _rupeesController.dispose();
    _litersController.dispose();
    super.dispose();
  }

  Future<void> _fetchCurrentFuelPrice() async {
    final vehicleProvider = context.read<VehicleProvider>();
    if (vehicleProvider.selectedVehicle == null) return;

    try {
      final price = await FuelPriceService.instance.getPrice(
        vehicleProvider.selectedVehicle!.city,
        vehicleProvider.selectedVehicle!.fuelType,
      );
      
      if (mounted) {
        setState(() => _currentFuelPrice = price);
      }
    } catch (e) {
      debugPrint('Error fetching fuel price: $e');
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _imageFile = File(image.path);
          _extractedReading = null;
          _canEdit = false;
        });
        await _processImage();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  Future<void> _processImage() async {
    if (_imageFile == null) return;

    setState(() => _isProcessing = true);

    try {
      final reading = await _apiService.extractOdometerReading(_imageFile!);
      
      if (mounted) {
        if (reading != null && reading.isNotEmpty) {
          setState(() {
            _extractedReading = reading;
            _odometerController.text = reading;
            _canEdit = true;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Odometer reading extracted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not extract odometer reading. Please try again or enter manually.'),
              duration: Duration(seconds: 4),
            ),
          );
          setState(() => _canEdit = true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            duration: const Duration(seconds: 4),
          ),
        );
        setState(() => _canEdit = true);
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _calculateFromRupees() {
    if (_currentFuelPrice != null && _rupeesController.text.isNotEmpty) {
      final rupees = double.tryParse(_rupeesController.text);
      if (rupees != null && _currentFuelPrice! > 0) {
        final liters = rupees / _currentFuelPrice!;
        _litersController.text = liters.toStringAsFixed(2);
      }
    }
  }

  void _calculateFromLiters() {
    if (_currentFuelPrice != null && _litersController.text.isNotEmpty) {
      final liters = double.tryParse(_litersController.text);
      if (liters != null) {
        final rupees = liters * _currentFuelPrice!;
        _rupeesController.text = rupees.toStringAsFixed(0);
      }
    }
  }

  Future<void> _submitEntry() async {
    final vehicleProvider = context.read<VehicleProvider>();
    if (vehicleProvider.selectedVehicle == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No vehicle selected')),
      );
      return;
    }

    if (_odometerController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter odometer reading')),
      );
      return;
    }

    if (_rupeesController.text.isEmpty && _litersController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter fuel amount or quantity')),
      );
      return;
    }

    try {
      final entryProvider = context.read<FuelEntryProvider>();
      
      final odometer = double.parse(_odometerController.text);
      final rupees = _rupeesController.text.isNotEmpty 
          ? double.parse(_rupeesController.text) 
          : null;
      final liters = _litersController.text.isNotEmpty 
          ? double.parse(_litersController.text) 
          : null;

      final entry = FuelEntry(
        vehicleId: vehicleProvider.selectedVehicle!.id!,
        date: _selectedDate,
        odometerReading: odometer,
        fuelLiters: liters,
        fuelRupees: rupees,
        pricePerLiter: _currentFuelPrice,
      );

      final result = await entryProvider.addEntry(entry);

      if (result != null && mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fuel entry added successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Odometer'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image Picker Section
            if (_imageFile == null)
              Column(
                children: [
                  const SizedBox(height: 40),
                  Icon(
                    Icons.camera_alt_outlined,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Take a photo of your odometer',
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Make sure the reading is clear and visible',
                    style: TextStyle(color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _pickImage(ImageSource.camera),
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('Camera'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _pickImage(ImageSource.gallery),
                          icon: const Icon(Icons.photo_library),
                          label: const Text('Gallery'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              )
            else
              Column(
                children: [
                  // Image Preview
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      _imageFile!,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  
                  const SizedBox(height: 16),

                  // Processing Indicator or Result
                  if (_isProcessing)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Row(
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(width: 16),
                            Text('Extracting odometer reading...'),
                          ],
                        ),
                      ),
                    )
                  else if (_extractedReading != null)
                    Card(
                      color: Colors.green[50],
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green[700]),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Extracted Reading',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '$_extractedReading km',
                                    style: const TextStyle(fontSize: 18),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Retake Button
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _imageFile = null;
                        _extractedReading = null;
                        _odometerController.clear();
                        _canEdit = false;
                      });
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retake Photo'),
                  ),

                  const SizedBox(height: 24),

                  // Odometer Reading (Editable)
                  TextFormField(
                    controller: _odometerController,
                    decoration: const InputDecoration(
                      labelText: 'Odometer Reading (km)',
                      hintText: 'Verify or edit the reading',
                      prefixIcon: Icon(Icons.speed),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    enabled: _canEdit,
                  ),

                  const SizedBox(height: 16),

                  // Current Fuel Price
                  if (_currentFuelPrice != null)
                    Card(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            const Icon(Icons.local_gas_station),
                            const SizedBox(width: 8),
                            Text(
                              'Current Price: ₹${_currentFuelPrice!.toStringAsFixed(2)}/L',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Input Mode Toggle
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'rupees',
                        label: Text('Amount (₹)'),
                        icon: Icon(Icons.currency_rupee),
                      ),
                      ButtonSegment(
                        value: 'liters',
                        label: Text('Quantity (L)'),
                        icon: Icon(Icons.water_drop),
                      ),
                    ],
                    selected: {_inputMode},
                    onSelectionChanged: (Set<String> newSelection) {
                      setState(() => _inputMode = newSelection.first);
                    },
                  ),

                  const SizedBox(height: 16),

                  // Fuel Amount/Quantity Input
                  if (_inputMode == 'rupees')
                    TextFormField(
                      controller: _rupeesController,
                      decoration: const InputDecoration(
                        labelText: 'Fuel Amount (₹)',
                        hintText: 'e.g., 500',
                        prefixIcon: Icon(Icons.currency_rupee),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      onChanged: (_) => _calculateFromRupees(),
                    )
                  else
                    TextFormField(
                      controller: _litersController,
                      decoration: const InputDecoration(
                        labelText: 'Fuel Quantity (Liters)',
                        hintText: 'e.g., 5.5',
                        prefixIcon: Icon(Icons.water_drop),
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      onChanged: (_) => _calculateFromLiters(),
                    ),

                  const SizedBox(height: 32),

                  // Submit Button
                  ElevatedButton(
                    onPressed: _canEdit ? _submitEntry : null,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Save Entry'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

