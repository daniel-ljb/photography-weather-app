class Alert {
  final String name;
  final List<Map<String, int>> times;
  final Set<int> precipitation;
  final Set<int> cloudCoverage;
  final Set<int> timesOfDay;
  final Map<String,dynamic> location;

  Alert({
    required this.name,
    required this.times,
    required this.precipitation,
    required this.cloudCoverage,
    required this.timesOfDay,
    required this.location
  });
} 