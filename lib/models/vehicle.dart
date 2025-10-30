class Vehicle {
  final int? id;
  final String name;
  final String fuelType;
  final String city;
  final double initialMileage;
  final DateTime createdAt;

  Vehicle({
    this.id,
    required this.name,
    required this.fuelType,
    required this.city,
    required this.initialMileage,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'fuel_type': fuelType,
      'city': city,
      'initial_mileage': initialMileage,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Vehicle.fromMap(Map<String, dynamic> map) {
    return Vehicle(
      id: map['id'] as int?,
      name: map['name'] as String,
      fuelType: map['fuel_type'] as String,
      city: map['city'] as String,
      initialMileage: (map['initial_mileage'] as num).toDouble(),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Vehicle copyWith({
    int? id,
    String? name,
    String? fuelType,
    String? city,
    double? initialMileage,
    DateTime? createdAt,
  }) {
    return Vehicle(
      id: id ?? this.id,
      name: name ?? this.name,
      fuelType: fuelType ?? this.fuelType,
      city: city ?? this.city,
      initialMileage: initialMileage ?? this.initialMileage,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

