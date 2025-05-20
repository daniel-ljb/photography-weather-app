import 'package:flutter/material.dart';
import '../services/weather_service.dart';
import 'package:intl/intl.dart';

class ForecastBox extends StatefulWidget {
  final String location;
  final VoidCallback? onTap;

  const ForecastBox({
    super.key,
    this.location = 'Cambridge',
    this.onTap,
  });

  @override
  State<ForecastBox> createState() => _ForecastBoxState();
}

class _ForecastBoxState extends State<ForecastBox> {
  final WeatherService _weatherService = WeatherService();
  Map<String, dynamic>? _weatherData;
  bool _isLoading = true;
  String? _error;
  final ScrollController _scrollController = ScrollController();
  String _currentDate = '';

  @override
  void initState() {
    super.initState();
    _fetchWeatherData();
    _scrollController.addListener(_updateCurrentDate);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_updateCurrentDate);
    _scrollController.dispose();
    super.dispose();
  }

  void _updateCurrentDate() {
    if (_weatherData == null || !_scrollController.hasClients) return;

    final forecast = _getHourlyForecast();
    if (forecast.isEmpty) return;

    // Find the index of the item that is currently at the very left edge or slightly beyond.
    // This is an estimation based on scroll offset and item width.
    const double itemWidthEstimate = 55.0 + 16.0; // Item width + separator width
    final double scrollOffset = _scrollController.offset;

    // Calculate the index of the first item whose *start* is visible or just past the edge
    int effectiveIndex = (scrollOffset / itemWidthEstimate).floor();

    // Clamp the index to the valid range of forecast items
    effectiveIndex = effectiveIndex.clamp(0, forecast.length - 1);

    final visibleItemTime = forecast[effectiveIndex]['time'] as DateTime;
    final newDate = _formatDate(visibleItemTime);

    if (_currentDate != newDate) {
      setState(() {
        _currentDate = newDate;
      });
    }
  }

  Future<void> _fetchWeatherData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final data = await _weatherService.getWeatherForecast(widget.location);
      setState(() {
        _weatherData = data;
        _isLoading = false;
      });
      
      // Set initial date after data is fetched
      if (data != null) {
        final forecast = _getHourlyForecast();
        if (forecast.isNotEmpty) {
          final time = forecast[0]['time'] as DateTime;
          setState(() {
             _currentDate = _formatDate(time);
          });
        }
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _getHourlyForecast() {
    if (_weatherData == null) return [];
    
    final now = DateTime.now();
    final List<Map<String, dynamic>> allHours = [];
    
    // Get all forecast days
    final forecastDays = _weatherData!['forecast']['forecastday'] as List;
    
    // Process each day's hourly data
    for (var day in forecastDays) {
      final hourlyData = day['hour'] as List;
      
      // For the first day, find the current hour or the next hour
      if (day == forecastDays[0]) {
        int startIndex = 0;
         for (int i = 0; i < hourlyData.length; i++) {
          final hourTime = DateTime.parse(hourlyData[i]['time']);
          // Find the first hour greater than or equal to the current time
          // Include the current hour if its minute is 0
          if (hourTime.isAfter(now) || (hourTime.isAtSameMomentAs(now) && hourTime.minute == 0)) {
             // If it's exactly the current hour, include it. Otherwise, start from the next hour.
            startIndex = i; // Start from this hour
             break;
          }
           // If loop finishes without finding an hour >= now, take the last hour
           if (i == hourlyData.length -1) startIndex = hourlyData.length - 1;
        }

        // Add hours from current time onwards for the first day
        allHours.addAll(hourlyData.sublist(startIndex).map((hour) {
          final time = DateTime.parse(hour['time']);
          return {
            'time': time,
            'temp_c': hour['temp_c'],
            'condition': hour['condition']['text'],
            'isMidnight': time.hour == 0,
          };
        }));
      } else {
        // Add all hours for subsequent days
        allHours.addAll(hourlyData.map((hour) {
           final time = DateTime.parse(hour['time']);
          return {
            'time': time,
            'temp_c': hour['temp_c'],
            'condition': hour['condition']['text'],
            'isMidnight': time.hour == 0,
          };
        }));
      }
    }
    
    return allHours;
  }

   Map<String, dynamic>? _getAstroDataForCurrentDate() {
     if (_weatherData == null || _currentDate.isEmpty) return null;

     final forecastDays = _weatherData!['forecast']['forecastday'] as List;
     try {
        // Parse the date from the header (MM/DD)
        // Need to be careful with year for parsing, let's find the actual DateTime object
        // from the forecast data that matches the current date string.
        for (var day in forecastDays) {
           final dayDate = DateTime.parse(day['date']);
           if (_formatDate(dayDate) == _currentDate) {
             return day['astro'];
           }
        }
     } catch (e) {
        print('Error parsing date or finding astro data: $e');
     }
     return null;
   }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:00';
  }

  String _formatDate(DateTime time) {
    return '${time.month}/${time.day}';
  }

  @override
  Widget build(BuildContext context) {
    final astroData = _getAstroDataForCurrentDate();
    final sunrise = astroData?['sunrise'] ?? '--:-- AM';
    final sunset = astroData?['sunset'] ?? '--:-- PM';

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red),
                        const SizedBox(height: 8),
                        Text(_error!, style: const TextStyle(color: Colors.red)),
                        TextButton(
                          onPressed: _fetchWeatherData,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.location_on, size: 20, color: Colors.blue),
                              const SizedBox(width: 4),
                              Text(
                                widget.location,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.wb_sunny, size: 16, color: Colors.orange),
                                  const SizedBox(width: 2),
                                  Text(sunrise),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  const Icon(Icons.nights_stay, size: 16, color: Colors.deepOrange),
                                  const SizedBox(width: 2),
                                  Text(sunset),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                      // Date header
                      Text(
                        _currentDate,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      if (_weatherData != null)
                        SizedBox(
                          height: 102,
                          child: ListView.separated(
                            controller: _scrollController,
                            scrollDirection: Axis.horizontal,
                            itemCount: _getHourlyForecast().length,
                            separatorBuilder: (context, index) => const SizedBox(width: 8),
                            itemBuilder: (context, index) {
                              final hourData = _getHourlyForecast()[index];
                              final time = hourData['time'] as DateTime;
                              final temp = hourData['temp_c'].round();
                              final condition = hourData['condition'];
                              final icon = _weatherService.getWeatherIcon(condition);
                              final isMidnight = hourData['isMidnight'];

                              return SizedBox(
                                width: 55,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Visibility(
                                      visible: isMidnight,
                                      maintainSize: true,
                                      maintainAnimation: true,
                                      maintainState: true,
                                      child: Text(
                                        _formatDate(time),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      _formatTime(time),
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(icon, style: const TextStyle(fontSize: 24)),
                                    const SizedBox(height: 4),
                                    Text(
                                      '$temp°C',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
      ),
    );
  }
} 