import 'package:http/http.dart' as http;



callApiTest(double lat, double lng) async {
  final url = "http://api.weatherapi.com/v1/forecast.json?key=ffd29b7d6fd940d59ae143722252005&q=$lat,$lng&days=7&aqi=no&alerts=no";

  final response = await fetchURL(url);

  print(response);
}

Future<http.Response> fetchURL(String url) {
  return http.get(Uri.parse(url));
}