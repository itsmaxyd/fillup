import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/fuel_price.dart';
import 'database_service.dart';
import '../utils/security_utils.dart';

class FuelPriceService {
  static final FuelPriceService instance = FuelPriceService._init();
  final DatabaseService _db = DatabaseService.instance;

  // Production API endpoint
  static const String _apiBaseUrl = 'https://maxdemon.site:4430';

  FuelPriceService._init();

  // Normalize city name for consistency
  String _normalizeCityName(String city) {
    return city.trim();
  }

  // Fetch current fuel price from API
  Future<FuelPrice?> fetchFuelPrice(String city, String fuelType) async {
    try {
      // Validate inputs
      if (!SecurityUtils.isValidCityName(city)) {
        throw Exception('Invalid city name');
      }

      if (!SecurityUtils.isValidFuelType(fuelType)) {
        throw Exception('Invalid fuel type');
      }

      final normalizedCity = _normalizeCityName(city);
      final normalizedFuelType = fuelType.toLowerCase();

      // Check if we have a recent cached price (less than 24 hours old)
      final cachedPrice = await _db.getFuelPrice(normalizedCity, fuelType);
      if (cachedPrice != null && !cachedPrice.isStale()) {
        return cachedPrice;
      }

      try {
        // Fetch from API
        final url = Uri.parse('$_apiBaseUrl/live_fuel_price/?fuel_type=$normalizedFuelType&location_type=city');
        final response = await http.get(url).timeout(const Duration(seconds: 30));

        if (response.statusCode == 200) {
          final List<dynamic> data = json.decode(response.body);

          // Find the city in the response
          for (final item in data) {
            final apiCity = item['city'] as String?;
            final priceStr = item['price'] as String?;
            final changeStr = item['change'] as String?;

            if (apiCity == normalizedCity && priceStr != null) {
              final price = double.tryParse(priceStr);
              if (price != null) {
                final fuelPrice = FuelPrice(
                  city: normalizedCity,
                  fuelType: fuelType,
                  price: price,
                  change: changeStr != null ? double.tryParse(changeStr) ?? 0.0 : 0.0,
                );

                // Cache the price
                await _db.saveFuelPrice(fuelPrice);
                return fuelPrice;
              }
            }
          }
        } else {
          throw Exception('API returned status code: ${response.statusCode}');
        }
      } catch (apiError) {
        // API call failed, try to use cached data
        if (cachedPrice != null) {
          return cachedPrice;
        }
        throw Exception('API unavailable: $apiError');
      }

      // If we get here, no data found
      if (cachedPrice != null) {
        return cachedPrice;
      }

      return null;
    } catch (e) {
      // On error, return cached price if available
      final cachedPrice = await _db.getFuelPrice(city, fuelType);
      if (cachedPrice != null) {
        return cachedPrice;
      }

      throw Exception('Failed to fetch fuel price: $e');
    }
  }

  // Get cached price or fetch new one
  Future<double?> getPrice(String city, String fuelType) async {
    final fuelPrice = await fetchFuelPrice(city, fuelType);
    return fuelPrice?.price;
  }

  // Fetch all cities from API
  Future<List<String>> fetchAllCities() async {
    try {
      final url = Uri.parse('$_apiBaseUrl/live_fuel_price/?fuel_type=petrol&location_type=city');
      final response = await http.get(url).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final cities = data.map((item) => item['city'] as String).toList();
        cities.sort(); // Sort alphabetically
        return cities;
      } else {
        throw Exception('API returned status code: ${response.statusCode}');
      }
    } catch (e) {
      // Fallback to hardcoded list if API fails
      return getMajorCities();
    }
  }

  // Get list of all cities (from API or cached)
  Future<List<String>> getAllCities() async {
    // For now, fetch from API each time. In production, you might want to cache this
    return await fetchAllCities();
  }

  // Refresh all cached prices
  Future<void> refreshAllPrices() async {
    final prices = await _db.getAllFuelPrices();
    
    for (final price in prices) {
      try {
        await fetchFuelPrice(price.city, price.fuelType);
      } catch (e) {
        // Continue with other prices even if one fails
        continue;
      }
    }
  }

  // Get list of major Indian cities
  static List<String> getMajorCities() {
    return [
      'Delhi',
      'Mumbai',
      'Bangalore',
      'Chennai',
      'Kolkata',
      'Hyderabad',
      'Pune',
      'Ahmedabad',
      'Jaipur',
      'Surat',
      'Lucknow',
      'Kanpur',
      'Nagpur',
      'Indore',
      'Thane',
      'Bhopal',
      'Visakhapatnam',
      'Patna',
      'Vadodara',
      'Ghaziabad',
      'Ludhiana',
      'Agra',
      'Nashik',
      'Faridabad',
      'Meerut',
      'Rajkot',
      'Varanasi',
      'Srinagar',
      'Aurangabad',
      'Dhanbad',
      'Amritsar',
      'Allahabad',
      'Ranchi',
      'Howrah',
      'Coimbatore',
      'Jabalpur',
      'Gwalior',
      'Vijayawada',
      'Jodhpur',
      'Madurai',
      'Raipur',
      'Kota',
      'Chandigarh',
      'Guwahati',
      'Mysore',
      'Tiruchirappalli',
      'Bareilly',
      'Aligarh',
      'Tiruppur',
      'Moradabad',
      'Gurgaon',
      'Noida',
    ];
  }

  // Get list of fuel types
  static List<String> getFuelTypes() {
    return ['Petrol', 'Diesel', 'CNG'];
  }
}
