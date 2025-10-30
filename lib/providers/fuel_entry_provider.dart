import 'package:flutter/foundation.dart';
import '../models/fuel_entry.dart';
import '../services/database_service.dart';

class FuelEntryProvider with ChangeNotifier {
  final DatabaseService _db = DatabaseService.instance;
  List<FuelEntry> _entries = [];
  bool _isLoading = false;
  int? _currentVehicleId;

  List<FuelEntry> get entries => _entries;
  bool get isLoading => _isLoading;

  // Load fuel entries for a specific vehicle
  Future<void> loadEntries(int vehicleId) async {
    if (_currentVehicleId == vehicleId && _entries.isNotEmpty) {
      return; // Already loaded for this vehicle
    }

    _isLoading = true;
    _currentVehicleId = vehicleId;
    notifyListeners();

    try {
      _entries = await _db.getFuelEntriesByVehicle(vehicleId);
    } catch (e) {
      debugPrint('Error loading fuel entries: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add new fuel entry
  Future<FuelEntry?> addEntry(FuelEntry entry) async {
    try {
      final newEntry = await _db.createFuelEntry(entry);
      _entries.insert(0, newEntry);
      notifyListeners();
      return newEntry;
    } catch (e) {
      debugPrint('Error adding fuel entry: $e');
      return null;
    }
  }

  // Update fuel entry
  Future<bool> updateEntry(FuelEntry entry) async {
    try {
      await _db.updateFuelEntry(entry);
      final index = _entries.indexWhere((e) => e.id == entry.id);
      
      if (index != -1) {
        _entries[index] = entry;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error updating fuel entry: $e');
      return false;
    }
  }

  // Delete fuel entry
  Future<bool> deleteEntry(int id) async {
    try {
      await _db.deleteFuelEntry(id);
      _entries.removeWhere((e) => e.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error deleting fuel entry: $e');
      return false;
    }
  }

  // Get last fuel entry for odometer reference
  Future<FuelEntry?> getLastEntry(int vehicleId) async {
    try {
      return await _db.getLastFuelEntry(vehicleId);
    } catch (e) {
      debugPrint('Error getting last entry: $e');
      return null;
    }
  }

  // Get entries for a date range (for reports)
  Future<List<FuelEntry>> getEntriesByDateRange(
    int vehicleId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      return await _db.getFuelEntriesByDateRange(
        vehicleId,
        startDate,
        endDate,
      );
    } catch (e) {
      debugPrint('Error getting entries by date range: $e');
      return [];
    }
  }

  // Calculate total spending
  double getTotalSpending() {
    return _entries.fold(0.0, (sum, entry) {
      final rupees = entry.getFuelRupees();
      return sum + (rupees ?? 0.0);
    });
  }

  // Calculate average efficiency
  double? getAverageEfficiency() {
    final efficiencies = <double>[];
    
    for (var i = 0; i < _entries.length; i++) {
      if (i < _entries.length - 1) {
        final current = _entries[i];
        final previous = _entries[i + 1];
        final efficiency = current.calculateEfficiency(previous.odometerReading);
        if (efficiency != null && efficiency > 0) {
          efficiencies.add(efficiency);
        }
      }
    }

    if (efficiencies.isEmpty) return null;
    return efficiencies.reduce((a, b) => a + b) / efficiencies.length;
  }

  // Calculate total distance traveled
  double? getTotalDistance() {
    if (_entries.isEmpty || _entries.length < 2) return null;
    
    final latest = _entries.first.odometerReading;
    final oldest = _entries.last.odometerReading;
    return latest - oldest;
  }

  // Calculate cost per km
  double? getCostPerKm() {
    final totalSpent = getTotalSpending();
    final totalDistance = getTotalDistance();
    
    if (totalDistance == null || totalDistance <= 0) return null;
    return totalSpent / totalDistance;
  }

  // Refresh entries
  Future<void> refresh() async {
    if (_currentVehicleId != null) {
      await loadEntries(_currentVehicleId!);
    }
  }
}

