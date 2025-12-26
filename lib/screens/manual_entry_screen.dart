import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/vehicle_provider.dart';
import '../providers/fuel_entry_provider.dart';
import '../services/fuel_price_service.dart';
import '../models/fuel_entry.dart';

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
  double? _currentFuelPrice;
  String _inputMode = 'rupees';
  bool _isLoading = false;
  bool _isRefreshing = false;

  // Validation errors
  String? _odometerError;
  String? _rupeesError;
  String? _litersError;

  // Quick fill amounts
  final List<double> _quickFillAmounts = [200, 500, 1000, 1500, 2000];
  final List<double> _quickFillLiters = [5, 10, 15, 20, 25];

  @override
  void initState() {
    super.initState();
    _fetchCurrentFuelPrice();
    _odometerController.addListener(_onOdometerChanged);
    _rupeesController.addListener(_validateRupees);
    _litersController.addListener(_validateLiters);
  }

  @override
  void dispose() {
    _odometerController.removeListener(_onOdometerChanged);
    _rupeesController.removeListener(_validateRupees);
    _litersController.removeListener(_validateLiters);
    _odometerController.dispose();
    _rupeesController.dispose();
    _litersController.dispose();
    super.dispose();
  }

  void _onOdometerChanged() {
    final value = _odometerController.text.trim();
    if (value.isEmpty) {
      setState(() => _odometerError = 'Odometer reading is required');
    } else {
      final odometer = double.tryParse(value);
      if (odometer == null) {
        setState(() => _odometerError = 'Please enter a valid number');
      } else if (odometer <= 0) {
        setState(() => _odometerError = 'Must be greater than 0');
      } else if (odometer > 10000000) {
        setState(() => _odometerError = 'Please check the reading');
      } else {
        setState(() => _odometerError = null);
      }
    }
  }

  void _validateRupees() {
    final value = _rupeesController.text.trim();
    if (value.isEmpty) {
      setState(() => _rupeesError = null);
    } else {
      final rupees = double.tryParse(value);
      if (rupees == null) {
        setState(() => _rupeesError = 'Please enter a valid number');
      } else if (rupees <= 0) {
        setState(() => _rupeesError = 'Must be greater than 0');
      } else if (rupees > 100000) {
        setState(() => _rupeesError = 'Amount seems too high');
      } else {
        setState(() => _rupeesError = null);
      }
      if (rupees != null && _inputMode == 'rupees') {
        _litersController.text = '';
      }
    }
  }

  void _validateLiters() {
    final value = _litersController.text.trim();
    if (value.isEmpty) {
      setState(() => _litersError = null);
    } else {
      final liters = double.tryParse(value);
      if (liters == null) {
        setState(() => _litersError = 'Please enter a valid number');
      } else if (liters <= 0) {
        setState(() => _litersError = 'Must be greater than 0');
      } else if (liters > 1000) {
        setState(() => _litersError = 'Quantity seems too high');
      } else {
        setState(() => _litersError = null);
      }
      if (liters != null && _inputMode == 'liters') {
        _rupeesController.text = '';
      }
    }
  }

  Future<void> _fetchCurrentFuelPrice() async {
    final vehicleProvider = context.read<VehicleProvider>();
    if (vehicleProvider.selectedVehicle == null) return;

    try {
      if (mounted) setState(() => _isRefreshing = true);
      final price = await FuelPriceService.instance.getPrice(
        vehicleProvider.selectedVehicle!.city,
        vehicleProvider.selectedVehicle!.fuelType,
      );
      
      if (mounted) {
        setState(() {
          _currentFuelPrice = price;
          _isRefreshing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isRefreshing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not fetch fuel price: $e'), duration: const Duration(seconds: 3)),
        );
      }
    }
  }

  Future<void> _selectDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() => _selectedDate = pickedDate);
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

  void _onRupeesChanged(String value) {
    _validateRupees();
    if (_inputMode == 'rupees') _calculateFromRupees();
  }

  void _onLitersChanged(String value) {
    _validateLiters();
    if (_inputMode == 'liters') _calculateFromLiters();
  }

  void _setQuickAmount(double amount) {
    _rupeesController.text = amount.toString();
    _validateRupees();
    _calculateFromRupees();
  }

  void _setQuickLiters(double liters) {
    _litersController.text = liters.toStringAsFixed(1);
    _validateLiters();
    _calculateFromLiters();
  }

  String? _validateOdometer(String? value) {
    if (value == null || value.trim().isEmpty) return 'Odometer reading is required';
    final odometer = double.tryParse(value);
    if (odometer == null) return 'Please enter a valid number';
    if (odometer <= 0) return 'Must be greater than 0';
    return null;
  }

  String? _validateRupeesField(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final rupees = double.tryParse(value);
    if (rupees == null) return 'Please enter a valid number';
    if (rupees <= 0) return 'Must be greater than 0';
    return null;
  }

  String? _validateLitersField(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final liters = double.tryParse(value);
    if (liters == null) return 'Please enter a valid number';
    if (liters <= 0) return 'Must be greater than 0';
    return null;
  }

  Future<void> _submitEntry() async {
    final vehicleProvider = context.read<VehicleProvider>();
    
    if (vehicleProvider.selectedVehicle == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a vehicle first'), duration: Duration(seconds: 3)),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please check the form for errors')));
      return;
    }

    if (_rupeesController.text.isEmpty && _litersController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter fuel amount or quantity')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final entryProvider = context.read<FuelEntryProvider>();
      final odometer = double.parse(_odometerController.text);
      final rupees = _rupeesController.text.isNotEmpty ? double.parse(_rupeesController.text) : null;
      final liters = _litersController.text.isNotEmpty ? double.parse(_litersController.text) : null;

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
        _odometerController.clear();
        _rupeesController.clear();
        _litersController.clear();
        _selectedDate = DateTime.now();
        
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fuel entry added successfully!'), duration: Duration(seconds: 2)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving entry: $e'), duration: const Duration(seconds: 3)),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final vehicleProvider = context.watch<VehicleProvider>();
    final selectedVehicle = vehicleProvider.selectedVehicle;

    final rupees = double.tryParse(_rupeesController.text);
    final liters = double.tryParse(_litersController.text);
    final displayRupees = rupees ?? (liters != null && _currentFuelPrice != null ? liters * _currentFuelPrice! : 0);
    final displayLiters = liters ?? (rupees != null && _currentFuelPrice != null ? rupees / _currentFuelPrice! : 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Fuel Entry'),
        actions: [
          if (_isRefreshing)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Vehicle Info Card
              if (selectedVehicle != null)
                Card(
                  color: theme.primaryColor.withOpacity(0.08),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        const Icon(Icons.directions_car, color: Colors.blue),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(selectedVehicle.name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                              Text('${selectedVehicle.fuelType} • ${selectedVehicle.city}', style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600])),
                            ],
                          ),
                        ),
                        TextButton(onPressed: () => Navigator.pushNamed(context, '/settings'), child: const Text('Change')),
                      ],
                    ),
                  ),
                )
              else
                Card(
                  color: Colors.orange.withValues(alpha: 0.1),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                        const SizedBox(width: 12),
                        const Expanded(child: Text('Please add a vehicle in Settings first')),
                        ElevatedButton(onPressed: () => Navigator.pushNamed(context, '/settings'), child: const Text('Go to Settings')),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 16),

              // Date Selection
              InkWell(
                onTap: _selectDate,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Date',
                    prefixIcon: const Icon(Icons.calendar_today),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    suffixIcon: const Icon(Icons.arrow_drop_down),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(DateFormat('EEEE, dd MMM yyyy').format(_selectedDate), style: const TextStyle(fontSize: 16)),
                      Text(DateFormat('dd/MM/yy').format(_selectedDate), style: TextStyle(color: Colors.grey[600])),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Odometer Reading
              TextFormField(
                controller: _odometerController,
                decoration: InputDecoration(
                  labelText: 'Odometer Reading',
                  hintText: 'e.g., 12345',
                  prefixIcon: const Icon(Icons.speed),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  errorText: _odometerError,
                  errorMaxLines: 2,
                  filled: _odometerError != null,
                  fillColor: _odometerError != null ? Colors.red.withOpacity(0.05) : null,
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textInputAction: TextInputAction.next,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: _validateOdometer,
              ),

              const SizedBox(height: 16),

              // Current Fuel Price Card
              if (_currentFuelPrice != null)
                Card(
                  color: theme.primaryColor.withOpacity(0.08),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        const Icon(Icons.local_gas_station, color: Colors.green),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Current Fuel Price', style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600])),
                              Text('₹${_currentFuelPrice!.toStringAsFixed(2)}/L', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        _isRefreshing
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                            : IconButton(onPressed: _fetchCurrentFuelPrice, icon: const Icon(Icons.refresh), tooltip: 'Refresh price'),
                      ],
                    ),
                  ),
                )
              else
                Card(
                  color: Colors.grey.withValues(alpha: 0.1),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.grey),
                        const SizedBox(width: 8),
                        const Expanded(child: Text('Fuel price not available')),
                        TextButton.icon(onPressed: _fetchCurrentFuelPrice, icon: const Icon(Icons.refresh, size: 16), label: const Text('Retry')),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 16),

              // Input Mode Toggle
              Container(
                decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(8)),
                child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'rupees', label: Center(child: Text('Amount (₹)')), icon: Icon(Icons.currency_rupee)),
                    ButtonSegment(value: 'liters', label: Center(child: Text('Quantity (L)')), icon: Icon(Icons.water_drop)),
                  ],
                  selected: {_inputMode},
                  onSelectionChanged: (Set<String> newSelection) {
                    setState(() {
                      _inputMode = newSelection.first;
                      _rupeesError = null;
                      _litersError = null;
                    });
                  },
                ),
              ),

              const SizedBox(height: 16),

              // Fuel Input
              if (_inputMode == 'rupees')
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _rupeesController,
                      decoration: InputDecoration(
                        labelText: 'Fuel Amount',
                        hintText: 'Enter amount in rupees',
                        prefixIcon: const Icon(Icons.currency_rupee),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        errorText: _rupeesError,
                        errorMaxLines: 2,
                        filled: _rupeesError != null,
                        fillColor: _rupeesError != null ? Colors.red.withOpacity(0.05) : null,
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      textInputAction: TextInputAction.done,
                      onChanged: _onRupeesChanged,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      validator: _validateRupeesField,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: _quickFillAmounts.map((amount) {
                        return FilterChip(
                          label: Text('₹$amount'),
                          onSelected: (_) => _setQuickAmount(amount),
                          selectedColor: theme.primaryColor.withOpacity(0.2),
                        );
                      }).toList(),
                    ),
                  ],
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _litersController,
                      decoration: InputDecoration(
                        labelText: 'Fuel Quantity',
                        hintText: 'Enter quantity in liters',
                        prefixIcon: const Icon(Icons.water_drop),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        errorText: _litersError,
                        errorMaxLines: 2,
                        filled: _litersError != null,
                        fillColor: _litersError != null ? Colors.red.withOpacity(0.05) : null,
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      textInputAction: TextInputAction.done,
                      onChanged: _onLitersChanged,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      validator: _validateLitersField,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: _quickFillLiters.map((liters) {
                        return FilterChip(
                          label: Text('${liters.toStringAsFixed(1)} L'),
                          onSelected: (_) => _setQuickLiters(liters),
                          selectedColor: theme.primaryColor.withOpacity(0.2),
                        );
                      }).toList(),
                    ),
                  ],
                ),

              const SizedBox(height: 24),

              // Summary Card
              if (rupees != null || liters != null)
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.receipt_long, size: 20),
                            const SizedBox(width: 8),
                            Text('Entry Summary', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const Divider(height: 16),
                        _SummaryRow(label: 'Amount', value: '₹${displayRupees.toStringAsFixed(2)}', isBold: true),
                        const SizedBox(height: 8),
                        _SummaryRow(label: 'Quantity', value: '${displayLiters.toStringAsFixed(2)} L', isBold: true),
                        if (_currentFuelPrice != null) ...[
                          const SizedBox(height: 8),
                          _SummaryRow(label: 'Price/Liter', value: '₹${_currentFuelPrice!.toStringAsFixed(2)}'),
                          const SizedBox(height: 8),
                          _SummaryRow(label: 'Efficiency', value: '${(displayLiters > 0 ? displayRupees / displayLiters : 0).toStringAsFixed(2)} ₹/L'),
                        ],
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 24),

              // Submit Button
              ElevatedButton(
                onPressed: _isLoading ? null : _submitEntry,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: theme.primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: _isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Save Entry', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),

              const SizedBox(height: 16),
              Text(
                'Tip: Enter either amount or quantity. The other will be calculated automatically.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
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
  final bool isBold;

  const _SummaryRow({required this.label, required this.value, this.isBold = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600], fontWeight: isBold ? FontWeight.w500 : FontWeight.normal)),
        const Spacer(),
        Text(value, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, fontSize: isBold ? 16 : 14)),
      ],
    );
  }
}
