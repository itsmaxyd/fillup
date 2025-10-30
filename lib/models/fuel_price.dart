class FuelPrice {
  final int? id;
  final String city;
  final String fuelType;
  final double price;
  final DateTime fetchedAt;

  FuelPrice({
    this.id,
    required this.city,
    required this.fuelType,
    required this.price,
    DateTime? fetchedAt,
  }) : fetchedAt = fetchedAt ?? DateTime.now();

  // Check if price is stale (older than 24 hours)
  bool isStale() {
    final now = DateTime.now();
    final difference = now.difference(fetchedAt);
    return difference.inHours >= 24;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'city': city,
      'fuel_type': fuelType,
      'price': price,
      'fetched_at': fetchedAt.toIso8601String(),
    };
  }

  factory FuelPrice.fromMap(Map<String, dynamic> map) {
    return FuelPrice(
      id: map['id'] as int?,
      city: map['city'] as String,
      fuelType: map['fuel_type'] as String,
      price: (map['price'] as num).toDouble(),
      fetchedAt: DateTime.parse(map['fetched_at'] as String),
    );
  }

  FuelPrice copyWith({
    int? id,
    String? city,
    String? fuelType,
    double? price,
    DateTime? fetchedAt,
  }) {
    return FuelPrice(
      id: id ?? this.id,
      city: city ?? this.city,
      fuelType: fuelType ?? this.fuelType,
      price: price ?? this.price,
      fetchedAt: fetchedAt ?? this.fetchedAt,
    );
  }
}

