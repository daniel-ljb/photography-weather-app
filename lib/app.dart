import 'package:flutter/material.dart';
import 'package:weather_app/services/notification_manager.dart';
import 'package:background_fetch/background_fetch.dart';

import 'pages/map_page.dart';
import 'pages/alerts_page.dart';
import 'pages/add_alert.dart';
import 'pages/weather_detail_page.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => new _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int _status = 0;

  @override
  void initState() {
    super.initState();
    configureBackgroundFetching();
  }

  // runs every 60 mins in order to check for weather events
  void configureBackgroundFetching() async {
    // Configure BackgroundFetch.
    int status = await BackgroundFetch.configure(BackgroundFetchConfig(
        minimumFetchInterval: 60,
        stopOnTerminate: false,
        enableHeadless: true,
        requiresBatteryNotLow: false,
        requiresCharging: false,
        requiresStorageNotLow: false,
        requiresDeviceIdle: false,
        requiredNetworkType: NetworkType.NONE
    ), (String taskId) async { 
      print("[BackgroundFetch] Event received $taskId");

      // call the same function that headless notifications call
      sendNotifications();

      BackgroundFetch.finish(taskId);
    }, (String taskId) async {  // <-- Task timeout handler.
      // This task has exceeded its allowed running-time.  You must stop what you're doing and immediately .finish(taskId)
      print("[BackgroundFetch] TASK TIMEOUT taskId: $taskId");
      BackgroundFetch.finish(taskId);
    });
    print('[BackgroundFetch] configure success: $status');
    setState(() {
      _status = status;
    });

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;
  }


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
          final locationName = args is String ? args : 'Unknown Location';
          return WeatherDetailPage();
        },
      },
    );
  }
}
