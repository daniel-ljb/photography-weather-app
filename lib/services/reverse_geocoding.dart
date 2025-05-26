import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:latlong2/latlong.dart';
import '../config/api_config.dart';

class NoLocationException implements Exception {
  String cause;
  NoLocationException(this.cause);
}

class ReverseGeocoding {
  static const String baseUrl = 'https://us1.locationiq.com/v1';
  final String apiKey = dotenv.env['LOCATIONIQ_API_KEY'] ?? '';

  Future<Map<String, dynamic>> getLocation(LatLng location) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/reverse?key=$apiKey&lat=${location.latitude}&lon=${location.longitude}&normalizecity=1&format=json'),
      );

      if (response.statusCode == 200) {
        Map<String, dynamic> json_decoded = json.decode(response.body)['address'];
        if (json_decoded['city'] == null) {
          json_decoded['city'] = "";
        }
        return json_decoded;
        
      } else if (response.statusCode == 404) {
        throw NoLocationException('No Place');
      } else {
        throw Exception('Failed the http request Status code: ${response.statusCode}\n${response.body}');
      }
    } catch (e) {
      print(dotenv.env['LOCATIONIQ_API_KEY']);
      print(apiKey);
      throw Exception('Error fetching location data: $e');
    }
  }
} 