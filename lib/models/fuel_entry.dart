class FuelEntry {
  final int? id;
  final int vehicleId;
  final DateTime date;
  final double odometerReading;
  final double? fuelLiters;
  final double? fuelRupees;
  final double? pricePerLiter;
  final DateTime createdAt;

  FuelEntry({
    this.id,
    required this.vehicleId,
    required this.date,
    required this.odometerReading,
    this.fuelLiters,
    this.fuelRupees,
    this.pricePerLiter,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // Calculate fuel efficiency (km/l)
  double? calculateEfficiency(double? previousOdometer) {
    if (previousOdometer == null || fuelLiters == null || fuelLiters == 0) {
      return null;
    }
    final distance = odometerReading - previousOdometer;
    if (distance <= 0) return null;
    return distance / fuelLiters!;
  }

  // Calculate cost per km
  double? calculateCostPerKm(double? previousOdometer) {
    if (previousOdometer == null || fuelRupees == null) {
      return null;
    }
    final distance = odometerReading - previousOdometer;
    if (distance <= 0) return null;
    return fuelRupees! / distance;
  }

  // Get fuel liters - either direct input or calculated from rupees
  double? getFuelLiters() {
    if (fuelLiters != null) return fuelLiters;
    if (fuelRupees != null && pricePerLiter != null && pricePerLiter! > 0) {
      return fuelRupees! / pricePerLiter!;
    }
    return null;
  }

  // Get fuel rupees - either direct input or calculated from liters
  double? getFuelRupees() {
    if (fuelRupees != null) return fuelRupees;
    if (fuelLiters != null && pricePerLiter != null) {
      return fuelLiters! * pricePerLiter!;
    }
    return null;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'vehicle_id': vehicleId,
      'date': date.toIso8601String(),
      'odometer_reading': odometerReading,
      'fuel_liters': fuelLiters,
      'fuel_rupees': fuelRupees,
      'price_per_liter': pricePerLiter,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory FuelEntry.fromMap(Map<String, dynamic> map) {
    return FuelEntry(
      id: map['id'] as int?,
      vehicleId: map['vehicle_id'] as int,
      date: DateTime.parse(map['date'] as String),
      odometerReading: (map['odometer_reading'] as num).toDouble(),
      fuelLiters: map['fuel_liters'] != null 
          ? (map['fuel_liters'] as num).toDouble() 
          : null,
      fuelRupees: map['fuel_rupees'] != null 
          ? (map['fuel_rupees'] as num).toDouble() 
          : null,
      pricePerLiter: map['price_per_liter'] != null 
          ? (map['price_per_liter'] as num).toDouble() 
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  FuelEntry copyWith({
    int? id,
    int? vehicleId,
    DateTime? date,
    double? odometerReading,
    double? fuelLiters,
    double? fuelRupees,
    double? pricePerLiter,
    DateTime? createdAt,
  }) {
    return FuelEntry(
      id: id ?? this.id,
      vehicleId: vehicleId ?? this.vehicleId,
      date: date ?? this.date,
      odometerReading: odometerReading ?? this.odometerReading,
      fuelLiters: fuelLiters ?? this.fuelLiters,
      fuelRupees: fuelRupees ?? this.fuelRupees,
      pricePerLiter: pricePerLiter ?? this.pricePerLiter,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

