import 'dart:convert';
import 'package:encrypt/encrypt.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

class EncryptionService {
  static final EncryptionService instance = EncryptionService._init();
  final _storage = const FlutterSecureStorage();
  final _deviceInfo = DeviceInfoPlugin();
  
  static const String _keyStorageKey = 'encrypted_api_key';
  // TODO: Replace with your OpenAI API key or load from environment
  // For production, store this securely or load from a config file
  static const String _hardcodedApiKey = 'YOUR_OPENAI_API_KEY_HERE';

  EncryptionService._init();

  // Get device-specific encryption key
  Future<String> _getDeviceId() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        // Combine multiple identifiers for better uniqueness
        return '${androidInfo.id}_${androidInfo.device}_${androidInfo.model}';
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        return iosInfo.identifierForVendor ?? 'default_ios_id';
      }
    } catch (e) {
      // Fallback to a constant if device info fails
      return 'fallback_device_id';
    }
    return 'default_device_id';
  }

  // Create encryption key from device ID
  Future<Key> _getEncryptionKey() async {
    final deviceId = await _getDeviceId();
    // Create a 32-byte key using SHA-256 hash of device ID
    final bytes = utf8.encode(deviceId);
    final hash = sha256.convert(bytes);
    return Key.fromBase64(base64.encode(hash.bytes));
  }

  // Encrypt the API key
  Future<String> _encryptApiKey(String apiKey) async {
    final key = await _getEncryptionKey();
    final iv = IV.fromLength(16); // Initialization vector
    final encrypter = Encrypter(AES(key));
    
    final encrypted = encrypter.encrypt(apiKey, iv: iv);
    // Store both IV and encrypted data
    return '${iv.base64}:${encrypted.base64}';
  }

  // Decrypt the API key
  Future<String> _decryptApiKey(String encryptedData) async {
    final key = await _getEncryptionKey();
    final parts = encryptedData.split(':');
    
    if (parts.length != 2) {
      throw Exception('Invalid encrypted data format');
    }
    
    final iv = IV.fromBase64(parts[0]);
    final encrypted = Encrypted.fromBase64(parts[1]);
    final encrypter = Encrypter(AES(key));
    
    return encrypter.decrypt(encrypted, iv: iv);
  }

  // Initialize and store the encrypted API key (call once on first run)
  Future<void> initializeApiKey() async {
    try {
      // Check if already stored
      final existing = await _storage.read(key: _keyStorageKey);
      if (existing == null) {
        // Encrypt and store the hardcoded API key
        final encrypted = await _encryptApiKey(_hardcodedApiKey);
        await _storage.write(key: _keyStorageKey, value: encrypted);
      }
    } catch (e) {
      throw Exception('Failed to initialize API key: $e');
    }
  }

  // Get the decrypted API key for use
  Future<String> getApiKey() async {
    try {
      final encryptedKey = await _storage.read(key: _keyStorageKey);
      
      if (encryptedKey == null) {
        // Initialize if not found
        await initializeApiKey();
        return getApiKey();
      }
      
      return await _decryptApiKey(encryptedKey);
    } catch (e) {
      throw Exception('Failed to retrieve API key: $e');
    }
  }

  // Clear stored API key (for testing or reset)
  Future<void> clearApiKey() async {
    await _storage.delete(key: _keyStorageKey);
  }

  // Verify if API key is properly stored
  Future<bool> isApiKeyStored() async {
    final key = await _storage.read(key: _keyStorageKey);
    return key != null;
  }
}

