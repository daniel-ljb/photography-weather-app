import 'package:flutter/material.dart';


class WeatherReportPage extends StatefulWidget {
  const WeatherReportPage({super.key, required this.title});
  final String title;
  @override
  State<WeatherReportPage> createState() => _WeatherReportState();
}

class _WeatherReportState extends State<WeatherReportPage> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('WEATHER'),
          ],
        ),
      ),
    );
  }
}