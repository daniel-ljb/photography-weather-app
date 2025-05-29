import 'package:background_fetch/background_fetch.dart';
import 'package:weather_app/main.dart';
import 'package:weather_app/models/alert.dart';
import 'package:weather_app/models/alert_manager.dart';
import 'package:weather_app/services/weather_service.dart';

@pragma('vm:entry-point')
void backgroundFetchHeadlessTask(HeadlessTask task) async {
  String taskId = task.taskId;
  bool isTimeout = task.timeout;
  if (isTimeout) {
    // This task has exceeded its allowed running-time.
    // You must stop what you're doing and immediately .finish(taskId)
    print("[BackgroundFetch] Headless task timed-out: $taskId");
    BackgroundFetch.finish(taskId);
    return;
  }
  print('[BackgroundFetch] Headless event received.');
  // call the same function non headless fetches call
  sendNotifications();

  BackgroundFetch.finish(taskId);
}

final AlertManager alertManager = AlertManager();
final WeatherService weatherService = WeatherService();

void sendNotifications() async {

  List<Alert> alerts = alertManager.alerts;

  for (final Alert alert in alerts) {
    processAlert(alert);
  }
}

// final String name;
// final List<Map<String, int>> times;
// final Set<int> precipitation;
// final Set<int> cloudCoverage;
// final Set<int> timesOfDay;
// final Map<String, dynamic> location;

void processAlert(Alert alert) async {
  Map<String, dynamic> location = alert.location;
  Set<int> precipitation = alert.precipitation;
  Set<int> cloudCoverage = alert.cloudCoverage;
  Set<int> timesOfDay = alert.timesOfDay;

  // get the forecast for the next 14 days at this location
  Map<String, dynamic> forecast = await weatherService.getWeatherForecast("${location['lat']},${location['lon']}",days:8);
  
  List<dynamic> days = forecast["forecast"]["forecastday"];

  final DateTime timeNow = DateTime.now();

  // go through all of the time periods
  for (final Map<String,int> time in alert.times) {
    DateTime timeToCheck = timeNow.add(Duration(days: time['days']!, hours: time['hours']!));
    int hourOfDay = timeToCheck.hour;

    DateTime from = DateTime(timeNow.year, timeNow.month, timeNow.day);
    DateTime to = DateTime(timeToCheck.year, timeToCheck.month, timeToCheck.day);
    int dayDiff = (to.difference(from).inHours / 24).round();

    // current day is index 0, so day_diff of 0 will give the current day which is correct
    dynamic currentDay = days[dayDiff];
    dynamic hourForecast = currentDay['hour'][hourOfDay];
    dynamic timeofday = currentDay['astro'];


    double forecastRain = hourForecast['precip_mm'];
    int forecastCloudCoverage = hourForecast['cloud'];

    print("testing $time at ${location['name']}");
    // check if the precipitation is correct
    if (!checkPrecipitation(precipitation, forecastRain)) continue;
    print("passed precip");
    if (!checkCloudCover(cloudCoverage,forecastCloudCoverage)) continue;
    print("passed cloud");
    if (!checkTimeOfDay(timesOfDay,timeofday, hourOfDay)) continue;
    print("passed time");

    // all check have been passed, so send notification
    print("passed all checks!");
    showNotification(
      "Weather Alert: ${alert.name}",
      "Conditions for Alert: ${alert.name}, will be met in ${time['days']} days and ${time['hours']} hours.",
      "payload"
    );
  }
}

Map<int,List<double>> precipitationBounds = {
  0: [0.0,0.0], // None
  1: [0.1,2.4], // Light
  2: [2.5,3.9], // Moderate
  3: [4.0,1000.0] // High
};

bool checkPrecipitation(Set<int> wantedPrecipitation, forecastPrecipitation) {
  List<List<int>?> bounds = wantedPrecipitation.map((number) => cloudBounds[number]).toList();

  for (final bound in bounds) {
    int lower = bound![0];
    int higher = bound[1];

    // if it falls in any of the bounds then return true
    if (forecastPrecipitation >= lower && forecastPrecipitation <= higher) return true;
  }

  // if it reaches here then it didn't fall in any of the bounds, return false
  return false;
}

Map<int,List<int>> cloudBounds = {
  0: [0,0], // None
  1: [1,25], // Some
  2: [25,75], // Most
  3: [75,100] // All
};

bool checkCloudCover(Set<int> wantedCloudCover, forecastCloudCover) {
  List<List<int>?> bounds = wantedCloudCover.map((number) => cloudBounds[number]).toList();

  for (final bound in bounds) {
    int lower = bound![0];
    int higher = bound[1];

    // if it falls in any of the bounds then return true
    if (forecastCloudCover >= lower && forecastCloudCover <= higher) return true;
  }

  // if it reaches here then it didn't fall in any of the bounds, return false
  return false;
}




bool checkTimeOfDay(Set<int> wantedTime, forecastAstro, int hourInt) {
  String sunrise = forecastAstro['sunrise'].toString().split(' ')[0];
  double sunriseTime = double.parse(sunrise.split(':')[0]) + double.parse(sunrise.split(':')[1]) * (1/60);

  String sunset = forecastAstro['sunset'].toString().split(' ')[0];
  double sunsetTime = double.parse(sunset.split(':')[0]) + double.parse(sunset.split(':')[1]) * (1/60);

  Map<int,List<double>> timePeriodBounds = {
    0: [sunriseTime-1,sunriseTime], // Blue Hour Morning
    1: [sunriseTime.floor().toDouble(),(sunriseTime+0.001).ceil().toDouble()],// Sunrise
    2: [sunriseTime,sunriseTime+1],// Golden Hour Morning
    3: [sunriseTime,12],// Morning
    4: [11,15],// Midday
    5: [12,18],// Afternoon
    6: [18,sunsetTime],// Evening
    7: [sunsetTime-1,sunsetTime],// Golden Hour Evening
    8: [sunsetTime.floor().toDouble(),(sunsetTime+0.001).ceil().toDouble()],// Sunset
    9: [sunsetTime,sunsetTime+1],// Blue Hour Evening
    10: [sunsetTime,sunriseTime] // Night
  };


  double hourDouble = hourInt.toDouble() + 0.5; // continuity correction

  List<List<double>?> bounds = wantedTime.map((number) => timePeriodBounds[number]).toList();
  for (final bound in bounds) {
    double lower = bound![0];
    double higher = bound[1];

    // if it falls in any of the bounds then return true
    if (hourDouble >= lower && hourDouble <= higher) return true;
  }

  // if it reaches here then it didn't fall in any of the bounds, return false
  return false;
}
