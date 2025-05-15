import 'package:flutter/material.dart';
import 'pages/map_page.dart';
import 'pages/weather_report_page.dart';
import 'pages/alerts_page.dart';
import 'pages/add_alert.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.lightBlueAccent),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => MapPage(title: "test"),
        '/weather': (context) => WeatherReportPage(title: "weather"),
        '/alerts': (context) => AlertsPage(title: "alerts"),
        '/alerts/modify': (context) => AddAlertPage(title: "add alert",)
      },
    );
  }
}