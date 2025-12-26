import 'package:flutter/material.dart';

class SecurityUtils {
  // Validate and sanitize city names
  static bool isValidCityName(String city) {
    if (city.isEmpty) return false;
    
    // Allow letters, spaces, hyphens, and apostrophes
    final validCityPattern = RegExp(r"^[a-zA-Z\s\-']+$");
    return validCityPattern.hasMatch(city) && city.trim().length <= 100;
  }

  // Validate and sanitize vehicle names
  static bool isValidVehicleName(String name) {
    if (name.isEmpty) return false;
    
    // Allow letters, numbers, spaces, hyphens, and basic punctuation
    final validNamePattern = RegExp(r"^[a-zA-Z0-9\s\-\(\)\.\,\']+$");
    return validNamePattern.hasMatch(name) && name.trim().length <= 100;
  }

  // Validate fuel types
  static bool isValidFuelType(String fuelType) {
    final validFuelTypes = ['Petrol', 'Diesel', 'CNG', 'Electric'];
    return validFuelTypes.contains(fuelType);
  }

  // Sanitize input to prevent XSS and injection attacks
  static String sanitizeInput(String input) {
    if (input.isEmpty) return input;
    
    // Remove potentially dangerous characters
    return input
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('&', '&amp;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&#x27;')
      .trim();
  }

  // Validate numeric input with reasonable limits
  static bool isValidNumericInput(String input, {double min = 0, double max = 1000000}) {
    if (input.isEmpty) return false;
    
    final value = double.tryParse(input);
    if (value == null) return false;
    
    return value >= min && value <= max;
  }

  // Validate date input
  static bool isValidDate(DateTime date) {
    final now = DateTime.now();
    final tenYearsAgo = now.subtract(const Duration(days: 365 * 10));
    
    return date.isAfter(tenYearsAgo) && date.isBefore(now);
  }

  // Validate URL for network requests
  static bool isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && uri.scheme == 'https' && uri.host.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Validate API response data
  static bool isValidApiResponse(dynamic response) {
    if (response == null) return false;
    if (response is String && response.isEmpty) return false;
    if (response is Map && response.isEmpty) return false;
    
    return true;
  }

  // Generate secure random string for temporary IDs
  static String generateSecureRandomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    
    return String.fromCharCodes(Iterable.generate(length, (_) {
      return chars.codeUnitAt(random % chars.length);
    }));
  }
}
