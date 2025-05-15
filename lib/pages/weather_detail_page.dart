import 'package:flutter/material.dart';

class WeatherDetailPage extends StatelessWidget {
  final String location;
  const WeatherDetailPage({super.key, required this.location});

  @override
  Widget build(BuildContext context) {
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
