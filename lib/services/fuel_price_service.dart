import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;
import '../models/fuel_price.dart';
import 'database_service.dart';
import '../utils/security_utils.dart';

class FuelPriceService {
  static final FuelPriceService instance = FuelPriceService._init();
  final DatabaseService _db = DatabaseService.instance;

  FuelPriceService._init();

  // Normalize city name to match website format
  String _normalizeCityName(String city) {
    return city.trim();
  }

  // Fetch current fuel price from mypetrolprice.com
  Future<FuelPrice?> fetchFuelPrice(String city, String fuelType) async {
    try {
      // Validate inputs to prevent injection attacks
      if (!SecurityUtils.isValidCityName(city)) {
        throw Exception('Invalid city name');
      }
      
      if (!SecurityUtils.isValidFuelType(fuelType)) {
        throw Exception('Invalid fuel type');
      }

      // Check if we have a recent cached price (less than 24 hours old)
      final cachedPrice = await _db.getFuelPrice(city, fuelType);
      if (cachedPrice != null && !cachedPrice.isStale()) {
        return cachedPrice;
      }

      // Fetch from website
      final normalizedCity = _normalizeCityName(city);
      final url = fuelType.toLowerCase() == 'petrol'
          ? 'https://www.mypetrolprice.com/petrol-price-in-india.aspx'
          : 'https://www.mypetrolprice.com/diesel-price-in-india.aspx';

      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        throw Exception('Failed to fetch fuel prices: ${response.statusCode}');
      }

      // Parse HTML
      final document = html_parser.parse(response.body);
      
      // Search for city price - the structure is city name followed by price
      // Looking for patterns like: "Delhi ▼ ₹ 94.81"
      final bodyText = document.body?.text ?? '';
      
      // Try to find the city and extract price
      final cityPattern = RegExp(
        '${RegExp.escape(normalizedCity)}[^₹]*₹\\s*([\\d.]+)',
        caseSensitive: false,
      );
      
      final match = cityPattern.firstMatch(bodyText);
      
      if (match != null && match.groupCount >= 1) {
        final priceStr = match.group(1);
        if (priceStr != null) {
          final price = double.tryParse(priceStr);
          if (price != null) {
            final fuelPrice = FuelPrice(
              city: city,
              fuelType: fuelType,
              price: price,
            );
            
            // Cache the price
            await _db.saveFuelPrice(fuelPrice);
            return fuelPrice;
          }
        }
      }

      // If parsing failed, return cached price even if stale
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
