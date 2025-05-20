import 'package:flutter/material.dart';
import 'dart:async';
import 'package:photography_app/services/open-meteo-api.dart';

Timer? timer;

class WeatherDetailPage extends StatelessWidget {
  final String location;
  const WeatherDetailPage({super.key, required this.location});

  @override
  Widget build(BuildContext context) {
    final initial_data = callApiTest();
    timer = Timer.periodic(Duration(seconds: 15), (Timer t) => callApiTest());
    return Scaffold(
      appBar: AppBar(
        title: Text(location),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: Center(
        child: Text(
          'Detailed weather for $location',
          style: const TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
