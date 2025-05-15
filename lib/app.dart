import 'package:flutter/material.dart';
import 'pages/map_page.dart';
import 'pages/alerts_page.dart';
import 'pages/add_alert.dart';
import 'pages/weather_detail_page.dart';

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
        '/alerts': (context) => AlertsPage(title: "alerts"),
        '/alerts/modify': (context) => AddAlertPage(title: "add alert"),
        '/weather/detail': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          final location = args is String ? args : 'Unknown';
          return WeatherDetailPage(location: location);
        },
      },
    );
  }
}
