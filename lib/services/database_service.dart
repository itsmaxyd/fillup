import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/vehicle.dart';
import '../models/fuel_entry.dart';
import '../models/fuel_price.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('fillup.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const realType = 'REAL NOT NULL';
    const textTypeNullable = 'TEXT';
    const realTypeNullable = 'REAL';

    // Vehicles table
    await db.execute('''
      CREATE TABLE vehicles (
        id $idType,
        name $textType,
        fuel_type $textType,
        city $textType,
        initial_mileage $realType,
        created_at $textType
      )
    ''');

    // Fuel entries table
    await db.execute('''
      CREATE TABLE fuel_entries (
        id $idType,
        vehicle_id INTEGER NOT NULL,
        date $textType,
        odometer_reading $realType,
        fuel_liters $realTypeNullable,
        fuel_rupees $realTypeNullable,
        price_per_liter $realTypeNullable,
        created_at $textType,
        FOREIGN KEY (vehicle_id) REFERENCES vehicles (id) ON DELETE CASCADE
      )
    ''');

    // Fuel prices table
    await db.execute('''
      CREATE TABLE fuel_prices (
        id $idType,
        city $textType,
        fuel_type $textType,
        price $realType,
        fetched_at $textType,
        UNIQUE(city, fuel_type)
      )
    ''');

    // Create index for faster queries
    await db.execute('''
      CREATE INDEX idx_fuel_entries_vehicle_id ON fuel_entries(vehicle_id)
    ''');

    await db.execute('''
      CREATE INDEX idx_fuel_entries_date ON fuel_entries(date)
    ''');
  }

  // Vehicle CRUD operations
  Future<Vehicle> createVehicle(Vehicle vehicle) async {
    final db = await instance.database;
    final id = await db.insert('vehicles', vehicle.toMap());
    return vehicle.copyWith(id: id);
  }

  Future<Vehicle?> getVehicle(int id) async {
    final db = await instance.database;
    final maps = await db.query(
      'vehicles',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Vehicle.fromMap(maps.first);
    }
    return null;
  }

  Future<List<Vehicle>> getAllVehicles() async {
    final db = await instance.database;
    const orderBy = 'created_at DESC';
    final result = await db.query('vehicles', orderBy: orderBy);
    return result.map((json) => Vehicle.fromMap(json)).toList();
  }

  Future<int> updateVehicle(Vehicle vehicle) async {
    final db = await instance.database;
    return db.update(
      'vehicles',
      vehicle.toMap(),
      where: 'id = ?',
      whereArgs: [vehicle.id],
    );
  }

  Future<int> deleteVehicle(int id) async {
    final db = await instance.database;
    return await db.delete(
      'vehicles',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Fuel Entry CRUD operations
  Future<FuelEntry> createFuelEntry(FuelEntry entry) async {
    final db = await instance.database;
    final id = await db.insert('fuel_entries', entry.toMap());
    return entry.copyWith(id: id);
  }

  Future<FuelEntry?> getFuelEntry(int id) async {
    final db = await instance.database;
    final maps = await db.query(
      'fuel_entries',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return FuelEntry.fromMap(maps.first);
    }
    return null;
  }

  Future<List<FuelEntry>> getFuelEntriesByVehicle(int vehicleId) async {
    final db = await instance.database;
    final result = await db.query(
      'fuel_entries',
      where: 'vehicle_id = ?',
      whereArgs: [vehicleId],
      orderBy: 'date DESC',
    );
    return result.map((json) => FuelEntry.fromMap(json)).toList();
  }

  Future<FuelEntry?> getLastFuelEntry(int vehicleId) async {
    final db = await instance.database;
    final result = await db.query(
      'fuel_entries',
      where: 'vehicle_id = ?',
      whereArgs: [vehicleId],
      orderBy: 'date DESC',
      limit: 1,
    );
    
    if (result.isNotEmpty) {
      return FuelEntry.fromMap(result.first);
    }
    return null;
  }

  Future<List<FuelEntry>> getFuelEntriesByDateRange(
    int vehicleId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await instance.database;
    final result = await db.query(
      'fuel_entries',
      where: 'vehicle_id = ? AND date BETWEEN ? AND ?',
      whereArgs: [
        vehicleId,
        startDate.toIso8601String(),
        endDate.toIso8601String(),
      ],
      orderBy: 'date ASC',
    );
    return result.map((json) => FuelEntry.fromMap(json)).toList();
  }

  Future<int> updateFuelEntry(FuelEntry entry) async {
    final db = await instance.database;
    return db.update(
      'fuel_entries',
      entry.toMap(),
      where: 'id = ?',
      whereArgs: [entry.id],
    );
  }

  Future<int> deleteFuelEntry(int id) async {
    final db = await instance.database;
    return await db.delete(
      'fuel_entries',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Fuel Price operations
  Future<int> saveFuelPrice(FuelPrice price) async {
    final db = await instance.database;
    return await db.insert(
      'fuel_prices',
      price.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<FuelPrice?> getFuelPrice(String city, String fuelType) async {
    final db = await instance.database;
    final maps = await db.query(
      'fuel_prices',
      where: 'city = ? AND fuel_type = ?',
      whereArgs: [city, fuelType],
    );

    if (maps.isNotEmpty) {
      return FuelPrice.fromMap(maps.first);
    }
    return null;
  }

  Future<List<FuelPrice>> getAllFuelPrices() async {
    final db = await instance.database;
    final result = await db.query('fuel_prices', orderBy: 'fetched_at DESC');
    return result.map((json) => FuelPrice.fromMap(json)).toList();
  }

  // Utility methods
  Future<bool> hasVehicles() async {
    final vehicles = await getAllVehicles();
    return vehicles.isNotEmpty;
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}

