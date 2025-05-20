import 'package:http/http.dart' as http;


const url = "https://api.open-meteo.com/v1/forecast?latitude=52.52&longitude=13.41&daily=weather_code,sunrise,sunset,daylight_duration,sunshine_duration,rain_sum,temperature_2m_mean&hourly=temperature_2m,apparent_temperature,precipitation_probability,precipitation,rain,showers,snowfall,cloud_cover,cloud_cover_low,cloud_cover_mid,cloud_cover_high,visibility,wind_speed_10m,wind_gusts_10m,weather_code&timezone=GMT";

callApiTest() async {
  final response = await fetchURL(url);

  print(response);
}

Future<http.Response> fetchURL(String url) {
  return http.get(Uri.parse(url));
}