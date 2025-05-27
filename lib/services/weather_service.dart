import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../config/api_config.dart';

class WeatherService {
  static const String baseUrl = 'http://api.weatherapi.com/v1';
  final String apiKey = dotenv.env['WEATHER_API_KEY'] ?? '';

  Future<Map<String, dynamic>> getWeatherForecast(String coordinates) async {

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/forecast.json?key=$apiKey&q=$coordinates&days=14&aqi=no'),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load weather data');
      }
    } catch (e) {
      throw Exception('Error fetching weather data: $e');
    }
  }

  List<Map<String, dynamic>> parseHourlyForecast(Map<String, dynamic> data) {
    final List<dynamic> hourlyData = data['forecast']['forecastday'][0]['hour'];
    return hourlyData.map((hour) {
      return {
        'time': DateTime.parse(hour['time']),
        'temp_c': hour['temp_c'],
        'condition': hour['condition']['text'],
        'icon': _getIconFromCondition(hour['condition']['code']),
      };
    }).toList();
  }

  IconData _getIconFromCondition(int conditionCode) {
    // Basic mapping of condition codes to icons
    if (conditionCode >= 1000 && conditionCode <= 1003) {
      return Icons.wb_sunny;
    } else if (conditionCode >= 1006 && conditionCode <= 1009) {
      return Icons.cloud;
    } else if (conditionCode >= 1030 && conditionCode <= 1032) {
      return Icons.cloud;
    } else if (conditionCode >= 1063 && conditionCode <= 1069) {
      return Icons.grain;
    } else if (conditionCode >= 1072 && conditionCode <= 1072) {
      return Icons.grain;
    } else if (conditionCode >= 1087 && conditionCode <= 1087) {
      return Icons.flash_on;
    } else if (conditionCode >= 1135 && conditionCode <= 1147) {
      return Icons.cloud;
    } else if (conditionCode >= 1150 && conditionCode <= 1153) {
      return Icons.grain;
    } else if (conditionCode >= 1180 && conditionCode <= 1189) {
      return Icons.grain;
    } else if (conditionCode >= 1192 && conditionCode <= 1195) {
      return Icons.grain;
    } else if (conditionCode >= 1198 && conditionCode <= 1201) {
      return Icons.ac_unit;
    } else if (conditionCode >= 1204 && conditionCode <= 1207) {
      return Icons.ac_unit;
    } else if (conditionCode >= 1210 && conditionCode <= 1212) {
      return Icons.ac_unit;
    } else if (conditionCode >= 1213 && conditionCode <= 1219) {
      return Icons.ac_unit;
    } else if (conditionCode >= 1220 && conditionCode <= 1225) {
      return Icons.ac_unit;
    } else if (conditionCode >= 1237 && conditionCode <= 1237) {
      return Icons.ac_unit;
    } else if (conditionCode >= 1240 && conditionCode <= 1246) {
      return Icons.grain;
    } else if (conditionCode >= 1249 && conditionCode <= 1252) {
      return Icons.ac_unit;
    } else if (conditionCode >= 1255 && conditionCode <= 1261) {
      return Icons.ac_unit;
    } else if (conditionCode >= 1263 && conditionCode <= 1264) {
      return Icons.ac_unit;
    } else {
      return Icons.wb_sunny;
    }
  }

  String getWeatherIcon(String condition) {
    // Map weather conditions to appropriate icons
    switch (condition.toLowerCase()) {
      case 'sunny':
      case 'clear':
        return '☀️';
      case 'partly cloudy':
        return '⛅';
      case 'cloudy':
      case 'overcast':
        return '☁️';
      case 'rain':
      case 'light rain':
        return '🌧️';
      case 'heavy rain':
        return '⛈️';
      case 'snow':
        return '❄️';
      case 'fog':
      case 'mist':
        return '🌫️';
      default:
        return '🌡️';
    }
  }

  Future<List<Map<String, dynamic>>> searchLocations(String query) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/search.json?key=$apiKey&q=$query'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((location) => {
          'name': location['name'],
          'region': location['region'],
          'country': location['country'],
          'lat': location['lat'],
          'lon': location['lon'],
        }).toList();
      } else {
        throw Exception('Failed to search locations');
      }
    } catch (e) {
      throw Exception('Error searching locations: $e');
    }
  }
} 