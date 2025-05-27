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