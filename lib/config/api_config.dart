import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  static String get weatherApiKey {
    final key = dotenv.env['WEATHER_API_KEY'];
    if (key == null || key.isEmpty) {
      throw Exception('WEATHER_API_KEY not found in .env file');
    }
    return key;
  }
} 