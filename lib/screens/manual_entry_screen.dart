import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/fuel_entry.dart';
import '../providers/vehicle_provider.dart';
import '../providers/fuel_entry_provider.dart';
import '../services/fuel_price_service.dart';

class ManualEntryScreen extends StatefulWidget {
  const ManualEntryScreen({super.key});

  @override
  State<ManualEntryScreen> createState() => _ManualEntryScreenState();
}

class _ManualEntryScreenState extends State<ManualEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _odometerController = TextEditingController();
  final _rupeesController = TextEditingController();
  final _litersController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;
  bool _isFetchingPrice = false;
  double? _currentFuelPrice;
  String _inputMode = 'rupees'; // 'rupees' or 'liters'

  @override
  void initState() {
    super.initState();
    _fetchCurrentFuelPrice();
    _loadLastOdometerReading();
  }

  @override
  void dispose() {
    _odometerController.dispose();
    _rupeesController.dispose();
    _litersController.dispose();
    super.dispose();
  }

  Future<void> _loadLastOdometerReading() async {
    final vehicleProvider = context.read<VehicleProvider>();
    final entryProvider = context.read<FuelEntryProvider>();
    
    if (vehicleProvider.selectedVehicle != null) {
      final lastEntry = await entryProvider.getLastEntry(
        vehicleProvider.selectedVehicle!.id!,
      );
      
      if (lastEntry != null && mounted) {
        // Pre-fill with last odometer + 100 as suggestion
        _odometerController.text = (lastEntry.odometerReading + 100).toStringAsFixed(0);
      } else if (vehicleProvider.selectedVehicle != null && mounted) {
        // Use initial mileage if no entries
        _odometerController.text = vehicleProvider.selectedVehicle!.initialMileage.toStringAsFixed(0);
      }
    }
  }

  Future<void> _fetchCurrentFuelPrice() async {
    final vehicleProvider = context.read<VehicleProvider>();
    if (vehicleProvider.selectedVehicle == null) return;

    setState(() => _isFetchingPrice = true);

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
    } finally {
      if (mounted) {
        setState(() => _isFetchingPrice = false);
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

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _submitEntry() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final vehicleProvider = context.read<VehicleProvider>();
    if (vehicleProvider.selectedVehicle == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No vehicle selected')),
      );
      return;
    }

    setState(() => _isLoading = true);

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
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to add fuel entry')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
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
    final dateFormat = DateFormat('dd MMM yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manual Entry'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Date Selector
              Card(
                child: ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: const Text('Date'),
                  subtitle: Text(dateFormat.format(_selectedDate)),
                  trailing: const Icon(Icons.edit),
                  onTap: _selectDate,
                ),
              ),

              const SizedBox(height: 16),

              // Current Fuel Price Display
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
                        const Spacer(),
                        if (_isFetchingPrice)
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        else
                          IconButton(
                            icon: const Icon(Icons.refresh, size: 20),
                            onPressed: _fetchCurrentFuelPrice,
                          ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 16),

              // Odometer Reading
              TextFormField(
                controller: _odometerController,
                decoration: const InputDecoration(
                  labelText: 'Odometer Reading (km)',
                  hintText: 'e.g., 25100',
                  prefixIcon: Icon(Icons.speed),
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter odometer reading';
                  }
                  final odometer = double.tryParse(value);
                  if (odometer == null || odometer < 0) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
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

              // Rupees Input
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
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter fuel amount';
                    }
                    final amount = double.tryParse(value);
                    if (amount == null || amount <= 0) {
                      return 'Please enter a valid amount';
                    }
                    return null;
                  },
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
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter fuel quantity';
                    }
                    final liters = double.tryParse(value);
                    if (liters == null || liters <= 0) {
                      return 'Please enter a valid quantity';
                    }
                    return null;
                  },
                ),

              const SizedBox(height: 16),

              // Calculated Values Display
              if (_rupeesController.text.isNotEmpty || _litersController.text.isNotEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Summary',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const Divider(),
                        if (_rupeesController.text.isNotEmpty)
                          _SummaryRow(
                            label: 'Amount',
                            value: '₹${_rupeesController.text}',
                          ),
                        if (_litersController.text.isNotEmpty)
                          _SummaryRow(
                            label: 'Quantity',
                            value: '${_litersController.text} L',
                          ),
                        if (_currentFuelPrice != null)
                          _SummaryRow(
                            label: 'Price/Liter',
                            value: '₹${_currentFuelPrice!.toStringAsFixed(2)}',
                          ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 32),

              // Submit Button
              ElevatedButton(
                onPressed: _isLoading ? null : _submitEntry,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save Entry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey[600]),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

