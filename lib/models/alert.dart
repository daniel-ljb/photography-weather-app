class Alert {
  final String name;
  final List<Map<String, int>> times;
  final Set<int> precipitation;
  final Set<int> cloudCoverage;
  final Set<int> timesOfDay;

  Alert({
    required this.name,
    required this.times,
    required this.precipitation,
    required this.cloudCoverage,
    required this.timesOfDay,
  });
} 