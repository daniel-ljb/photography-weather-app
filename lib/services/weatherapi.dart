import 'package:http/http.dart' as http;


const url = "http://api.weatherapi.com/v1/forecast.json?key=ffd29b7d6fd940d59ae143722252005&q=London&days=1&aqi=no&alerts=no";

callApiTest() async {
  final response = await fetchURL(url);

  print(response);
}

Future<http.Response> fetchURL(String url) {
  return http.get(Uri.parse(url));
}