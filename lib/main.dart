import 'package:flutter/material.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await dotenv.load(fileName: ".env");
    if (dotenv.env['WEATHER_API_KEY'] == null) {
      throw Exception('WEATHER_API_KEY not found in .env file');
    }else if (dotenv.env['OPEN_WEATHER_MAP_API_KEY'] == null){
      throw Exception('OPEN_WEATHER_MAP API Key not found in env file!');
    }
  } catch (e) {
    print('Error loading .env file: $e');
    // Continue running the app even if .env fails to load
  }
  
  runApp(const MyApp());
}