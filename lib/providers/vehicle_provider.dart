import 'package:flutter/foundation.dart';
import '../models/vehicle.dart';
import '../services/database_service.dart';

class VehicleProvider with ChangeNotifier {
  final DatabaseService _db = DatabaseService.instance;
  List<Vehicle> _vehicles = [];
  Vehicle? _selectedVehicle;
  bool _isLoading = false;

  List<Vehicle> get vehicles => _vehicles;
  Vehicle? get selectedVehicle => _selectedVehicle;
  bool get isLoading => _isLoading;

  // Initialize and load vehicles
  Future<void> initialize() async {
    await loadVehicles();
  }

  // Load all vehicles from database
  Future<void> loadVehicles() async {
    _isLoading = true;
    notifyListeners();

    try {
      _vehicles = await _db.getAllVehicles();
      
      // Auto-select first vehicle if none selected
      if (_vehicles.isNotEmpty && _selectedVehicle == null) {
        _selectedVehicle = _vehicles.first;
      }
    } catch (e) {
      debugPrint('Error loading vehicles: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Add new vehicle
  Future<Vehicle?> addVehicle(Vehicle vehicle) async {
    try {
      final newVehicle = await _db.createVehicle(vehicle);
      _vehicles.insert(0, newVehicle);
      
      // Auto-select if it's the first vehicle
      if (_vehicles.length == 1) {
        _selectedVehicle = newVehicle;
      }
      
      notifyListeners();
      return newVehicle;
    } catch (e) {
      debugPrint('Error adding vehicle: $e');
      return null;
    }
  }

  // Update vehicle
  Future<bool> updateVehicle(Vehicle vehicle) async {
    try {
      await _db.updateVehicle(vehicle);
      final index = _vehicles.indexWhere((v) => v.id == vehicle.id);
      
      if (index != -1) {
        _vehicles[index] = vehicle;
        
        // Update selected vehicle if it's the one being updated
        if (_selectedVehicle?.id == vehicle.id) {
          _selectedVehicle = vehicle;
        }
        
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error updating vehicle: $e');
      return false;
    }
  }

  // Delete vehicle
  Future<bool> deleteVehicle(int id) async {
    try {
      await _db.deleteVehicle(id);
      _vehicles.removeWhere((v) => v.id == id);
      
      // Update selected vehicle if deleted
      if (_selectedVehicle?.id == id) {
        _selectedVehicle = _vehicles.isNotEmpty ? _vehicles.first : null;
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error deleting vehicle: $e');
      return false;
    }
  }

  // Select vehicle
  void selectVehicle(Vehicle vehicle) {
    _selectedVehicle = vehicle;
    notifyListeners();
  }

  // Check if any vehicles exist
  Future<bool> hasVehicles() async {
    return await _db.hasVehicles();
  }
}

