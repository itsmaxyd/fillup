import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:image/image.dart' as img;
import 'encryption_service.dart';

class ApiService {
  static final ApiService instance = ApiService._init();
  late final Dio _dio;
  final EncryptionService _encryptionService = EncryptionService.instance;

  ApiService._init() {
    _dio = Dio(
      BaseOptions(
        baseUrl: 'https://api.openai.com/v1',
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
        },
      ),
    );
  }

  // Extract odometer reading from image using GPT-4o-mini Vision
  Future<String?> extractOdometerReading(File imageFile) async {
    try {
      // Get decrypted API key
      final apiKey = await _encryptionService.getApiKey();

      // Compress and resize image to reduce API costs
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);
      
      if (image == null) {
        throw Exception('Failed to decode image');
      }

      // Resize if image is too large (max 800px width)
      img.Image resized = image;
      if (image.width > 800) {
        resized = img.copyResize(image, width: 800);
      }

      // Compress to JPEG with 85% quality
      final compressed = img.encodeJpg(resized, quality: 85);
      final base64Image = base64Encode(compressed);

      // Prepare request to GPT-4o-mini Vision API
      final response = await _dio.post(
        '/chat/completions',
        options: Options(
          headers: {
            'Authorization': 'Bearer $apiKey',
          },
        ),
        data: {
          'model': 'gpt-4o-mini',
          'messages': [
            {
              'role': 'user',
              'content': [
                {
                  'type': 'text',
                  'text': 'Extract only the numeric odometer reading from this vehicle dashboard image. Return only the number without any units, commas, or additional text. If you cannot find an odometer reading, return "ERROR".',
                },
                {
                  'type': 'image_url',
                  'image_url': {
                    'url': 'data:image/jpeg;base64,$base64Image',
                  },
                },
              ],
            },
          ],
          'max_tokens': 50,
          'temperature': 0.1,
        },
      );

      // Parse response
      final content = response.data['choices'][0]['message']['content'] as String;
      final cleaned = content.trim().replaceAll(RegExp(r'[^\d.]'), '');
      
      if (cleaned.isEmpty || content.toUpperCase().contains('ERROR')) {
        return null;
      }

      return cleaned;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Invalid API key. Please check your OpenAI API key.');
      } else if (e.response?.statusCode == 429) {
        throw Exception('API rate limit exceeded. Please try again later.');
      }
      throw Exception('Failed to process image: ${e.message}');
    } catch (e) {
      throw Exception('Error extracting odometer reading: $e');
    }
  }

  // Test API key validity
  Future<bool> testApiKey() async {
    try {
      final apiKey = await _encryptionService.getApiKey();
      
      final response = await _dio.get(
        '/models',
        options: Options(
          headers: {
            'Authorization': 'Bearer $apiKey',
          },
        ),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}

