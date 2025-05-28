import 'package:flutter/material.dart';
import '../services/weather_service.dart'; // We'll need this later
import 'package:intl/intl.dart'; // Import for date formatting
import '../models/location_manager.dart'; // Import the new manager
import 'dart:math';

class WeatherDetailPage extends StatefulWidget {
  const WeatherDetailPage({super.key});

  @override
  State<WeatherDetailPage> createState() => _WeatherDetailPageState();
}

class _WeatherDetailPageState extends State<WeatherDetailPage> {
  String _locationName = 'Loading...';
  final WeatherService _weatherService = WeatherService(); // Instantiate WeatherService
  Map<String, dynamic>? _weatherData; // State for weather data
  bool _isLoading = true; // State for loading status
  String? _error; // State for error message
  int _selectedDayIndex = 0; // State to track the selected day index
  final ScrollController _hourlyScrollController = ScrollController(); // Add ScrollController
  final ScrollController _dayScrollController = ScrollController(); // Add ScrollController for day tabs

  // Store the GlobalKey for each day item to get its render box
  final Map<int, GlobalKey> _dayKeys = {};
  bool _isLocationSaved = false; // State to track if the location is saved
  Map<String, dynamic>? _currentLocationData; // Store the full location data

  @override
  void initState() {
    super.initState();
    // Add listener to update selected day based on scroll position
    _hourlyScrollController.addListener(_updateSelectedDayOnScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Extract the location name passed as an argument
    final locationArg = ModalRoute.of(context)?.settings.arguments;
    if (locationArg != null && locationArg is String) {
      setState(() {
        _locationName = locationArg.split(',')[2];
         // Check if the location is already saved
        _isLocationSaved = LocationManager().isLocationSaved({
          'lat':double.parse(locationArg.split(',')[0]),
          'lon':double.parse(locationArg.split(',')[1])
        });
      });

      String coordinates = "${locationArg.split(',')[0]},${locationArg.split(',')[1]}";
      _searchAndFetchWeatherData(coordinates);
    } else {
       setState(() {
        _locationName = 'Unknown Location';
        _isLoading = false; // Stop loading if location is unknown
        _error = 'No location provided.'; // Set error message
      });
    }
  }

  // New method to search for location and then fetch weather data
  Future<void> _searchAndFetchWeatherData(String locationCoordinates) async {
     setState(() {
      _isLoading = true;
      _error = null;
      _weatherData = null;
      _selectedDayIndex = 0;
      _dayKeys.clear();
       _currentLocationData = null; // Clear previous location data
    });
    try {
      // Parse the coordinates
      final coords = locationCoordinates.split(',');
      final lat = double.parse(coords[0]);
      final lon = double.parse(coords[1]);
      
      // Create location data with the original coordinates
      _currentLocationData = {
        'lat': lat,
        'lon': lon,
        'name': _locationName, // Use the name we already have
      };

      // Fetch weather data using the coordinates directly
      final data = await _weatherService.getWeatherForecast('$lat,$lon');
      setState(() {
        _weatherData = data;
        _isLoading = false;
         if (_weatherData!['forecast'] != null) {
          final forecastDays = _weatherData!['forecast']['forecastday'] as List<dynamic>;
           for (int i = 0; i < forecastDays.length; i++) {
            _dayKeys[i] = GlobalKey();
          }
        }
      });
      // After data is fetched, ensure scroll controller is attached before using it
       WidgetsBinding.instance.addPostFrameCallback((_) {
         // Optionally scroll to the beginning of the forecast
         // _hourlyScrollController.jumpTo(0);
       });

    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _getAllHourlyForecast() {
    if (_weatherData == null || _weatherData!['forecast'] == null) return [];
    final forecastDays = _weatherData!['forecast']['forecastday'] as List<dynamic>;
    final List<Map<String, dynamic>> allHours = [];
    final now = DateTime.now();
    
    for (var day in forecastDays) {
      final hourlyData = (day['hour'] as List<dynamic>)
          .map((hour) => hour as Map<String, dynamic>)
          .toList();
      
      // For the first day, find the current hour
      if (day == forecastDays[0]) {
        int startIndex = 0;
        for (int i = 0; i < hourlyData.length; i++) {
          final hourTime = DateTime.parse(hourlyData[i]['time']);
          // Find the current hour (e.g., if it's 6:30, find 6:00)
          if (hourTime.hour == now.hour) {
            startIndex = i;
            break;
          }
          // If we've passed the current hour, start from the next hour
          if (hourTime.hour > now.hour) {
            startIndex = i;
            break;
          }
          // If loop finishes without finding a suitable hour, take the last hour
          if (i == hourlyData.length - 1) startIndex = hourlyData.length - 1;
        }
        // Add hours from current time onwards for the first day
        allHours.addAll(hourlyData.sublist(startIndex));
      } else {
        // Add all hours for subsequent days
        allHours.addAll(hourlyData);
      }
    }
    return allHours;
  }

   // Calculate the starting index of a given day in the combined hourly list
   int _getHourlyStartIndexForDay(int dayIndex) {
     if (_weatherData == null || _weatherData!['forecast'] == null) return 0;
     final forecastDays = _weatherData!['forecast']['forecastday'] as List<dynamic>;
     int startIndex = 0;
     for (int i = 0; i < dayIndex && i < forecastDays.length; i++) {
       startIndex += (forecastDays[i]['hour'] as List<dynamic>).length;
     }
     return startIndex;
   }

   // Update the selected day index based on the scroll position and scroll day tabs
   void _updateSelectedDayOnScroll() {
     if (!_hourlyScrollController.hasClients || !_dayScrollController.hasClients || _weatherData == null) return;

     const double itemWidth = 108.0;
     final double scrollOffset = _hourlyScrollController.offset;

     int currentHourIndex = (scrollOffset / itemWidth).floor();

     int dayIndex = 0;
     int hourCount = 0;
     final forecastDays = _weatherData!['forecast']['forecastday'] as List<dynamic>;
     for (int i = 0; i < forecastDays.length; i++) {
       final hoursInDay = (forecastDays[i]['hour'] as List<dynamic>).length;
       if (currentHourIndex < hourCount + hoursInDay) {
         dayIndex = i;
         break;
       }
       hourCount += hoursInDay;
     }

     if (_selectedDayIndex != dayIndex) {
       setState(() {
         _selectedDayIndex = dayIndex;
       });

       // Scroll the day tabs to make the selected day visible if not already
       _scrollToDayTab(dayIndex);
     }
   }

  // Scroll the day tabs to bring the widget at the given index into view
  void _scrollToDayTab(int index) {
    final key = _dayKeys[index];
    if (key == null || key.currentContext == null || !_dayScrollController.hasClients) return;

    final RenderObject? renderObject = key.currentContext!.findRenderObject();
    if (renderObject == null || renderObject is! RenderBox) return;

    final RenderBox dayRenderBox = renderObject;
    final RenderBox listViewRenderBox = _dayScrollController.position.context.storageContext.findRenderObject() as RenderBox;

    final double widgetStart = dayRenderBox.localToGlobal(Offset.zero, ancestor: listViewRenderBox).dx;
    final double widgetEnd = widgetStart + dayRenderBox.size.width;
    final double viewportStart = 0;
    final double viewportEnd = listViewRenderBox.size.width;

    // Only scroll if the widget is not fully visible
    if (widgetEnd > viewportEnd || widgetStart < viewportStart) {
       _dayScrollController.position.ensureVisible(
        dayRenderBox,
        alignment: 0.0, // Align to the left edge
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _toggleSavedLocation() {
    if (_currentLocationData != null) {
      if (_isLocationSaved) {
        LocationManager().removeLocation(_currentLocationData!);
        setState(() {
          _isLocationSaved = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location removed!'),
            duration: Duration(seconds: 1),
          ),
        );
        // Pop with a result to notify MapPage that a location was removed
        Navigator.pop(context, true);
      } else {
        LocationManager().addLocation(_currentLocationData!);
        setState(() {
          _isLocationSaved = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location saved!'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } else {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot save location: No location data available.'),
          backgroundColor: Colors.redAccent,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  String _getDayDisplay(String dateString, int index) {
    final date = DateTime.parse(dateString);
    if (index < 7) {
      return DateFormat('EEE').format(date); // Mon, Tue, etc. for the first week
    } else {
      return DateFormat('MMM d').format(date); // Jan 1, Feb 15, etc. for subsequent weeks
    }
  }

  String _formatTime(String time) {
     final dateTime = DateTime.parse(time);
     return DateFormat('h a').format(dateTime); // e.g., 1 PM, 3 AM
  }

  // Get wind direction as a compass direction
  String _getWindDirection(int degrees) {
    const directions = ['N', 'NNE', 'NE', 'ENE', 'E', 'ESE', 'SE', 'SSE', 'S', 'SSW', 'SW', 'WSW', 'W', 'WNW', 'NW', 'NNW'];
    final index = ((degrees + 11.25) / 22.5).floor() % 16;
    return directions[index];
  }

  // Get sun-related times for the selected day
  Map<String, String> _getSunTimes() {
    if (_weatherData == null || _weatherData!['forecast'] == null) return {};
    
    final forecastDays = _weatherData!['forecast']['forecastday'] as List<dynamic>;
    if (_selectedDayIndex >= forecastDays.length) return {};
    
    final astro = forecastDays[_selectedDayIndex]['astro'];
    final date = forecastDays[_selectedDayIndex]['date'];
    
    // Parse the time strings into DateTime objects
    DateTime parseTime(String timeStr) {
      final timeParts = timeStr.split(' ');
      final time = timeParts[0];
      final period = timeParts[1];
      final [hours, minutes] = time.split(':').map(int.parse).toList();
      final hour = period == 'PM' && hours != 12 ? hours + 12 : (period == 'AM' && hours == 12 ? 0 : hours);
      return DateTime.parse('$date ${hour.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:00');
    }

    final sunrise = parseTime(astro['sunrise']);
    final sunset = parseTime(astro['sunset']);

    // Calculate golden and blue hours
    final morningGoldenStart = sunrise;
    final morningGoldenEnd = sunrise.add(const Duration(hours: 1));
    final eveningGoldenStart = sunset.subtract(const Duration(hours: 1));
    final eveningGoldenEnd = sunset;

    final morningBlueStart = sunrise.subtract(const Duration(minutes: 30));
    final morningBlueEnd = sunrise;
    final eveningBlueStart = sunset;
    final eveningBlueEnd = sunset.add(const Duration(minutes: 30));

    return {
      'sunrise': astro['sunrise'],
      'sunset': astro['sunset'],
      'moonrise': astro['moonrise'],
      'moonset': astro['moonset'],
      'moon_phase': astro['moon_phase'],
      'moon_illumination': astro['moon_illumination'].toString(),
      'morning_golden_start': DateFormat('h:mm a').format(morningGoldenStart),
      'morning_golden_end': DateFormat('h:mm a').format(morningGoldenEnd),
      'evening_golden_start': DateFormat('h:mm a').format(eveningGoldenStart),
      'evening_golden_end': DateFormat('h:mm a').format(eveningGoldenEnd),
      'morning_blue_start': DateFormat('h:mm a').format(morningBlueStart),
      'morning_blue_end': DateFormat('h:mm a').format(morningBlueEnd),
      'evening_blue_start': DateFormat('h:mm a').format(eveningBlueStart),
      'evening_blue_end': DateFormat('h:mm a').format(eveningBlueEnd),
    };
  }

  String _getMoonPhaseEmoji(String phase) {
    switch (phase.toLowerCase()) {
      case 'new moon':
        return '🌑';
      case 'waxing crescent':
        return '🌒';
      case 'first quarter':
        return '🌓';
      case 'waxing gibbous':
        return '🌔';
      case 'full moon':
        return '🌕';
      case 'waning gibbous':
        return '🌖';
      case 'last quarter':
        return '🌗';
      case 'waning crescent':
        return '🌘';
      default:
        return '🌑';
    }
  }

  @override
  void dispose() {
    _hourlyScrollController.dispose(); // Dispose the controller
    _dayScrollController.dispose(); // Dispose the day scroll controller
    // Dispose _weatherService if necessary (depending on its implementation)
    // For this simple case, it might not have resources to dispose, but it's good practice.
    // _weatherService.dispose(); // Uncomment if WeatherService needs disposing
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allHourlyForecast = _getAllHourlyForecast(); // Get all hourly data
    final sunTimes = _getSunTimes();

    return Scaffold(
      appBar: AppBar(
        title: Text(_locationName),
        actions: [
          IconButton(
            icon: Icon(
              _isLocationSaved ? Icons.check_circle : Icons.add_circle_outline,
              color: Colors.green,
              size: 30,
            ),
            onPressed: _toggleSavedLocation,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error'))
              : _weatherData != null
                  ? SingleChildScrollView(
                      child: Column(
                        children: [
                          // Day tabs
                          if (_weatherData!['forecast'] != null)
                            SizedBox(
                              height: 60,
                              child: ListView.builder(
                                controller: _dayScrollController,
                                scrollDirection: Axis.horizontal,
                                itemCount: (_weatherData!['forecast']['forecastday'] as List).length,
                                itemBuilder: (context, index) {
                                  final dayData = (_weatherData!['forecast']['forecastday'] as List)[index];
                                  final dateString = dayData['date'] as String;
                                  final dayDisplay = _getDayDisplay(dateString, index);
                                  final isSelected = index == _selectedDayIndex;
                                   // Assign the GlobalKey to the day item
                                  final dayKey = _dayKeys[index] ?? GlobalKey();
                                  _dayKeys[index] = dayKey; // Store the key

                                  return GestureDetector(
                                    key: dayKey, // Assign the key
                                    onTap: () {
                                      setState(() {
                                        _selectedDayIndex = index;
                                      });
                                      // Scroll to the beginning of the selected day's hourly forecast
                                      final startIndex = _getHourlyStartIndexForDay(index);
                                      _hourlyScrollController.animateTo(
                                        startIndex * 108.0, // Item width: 100 + 4*2 padding/margin
                                        duration: const Duration(milliseconds: 300),
                                        curve: Curves.easeOut,
                                      );
                                      // Scroll the day tabs to make the selected day visible
                                      _scrollToDayTab(index);
                                    },
                                    child: Container(
                                      alignment: Alignment.center,
                                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                      margin: const EdgeInsets.symmetric(horizontal: 4.0),
                                      decoration: BoxDecoration(
                                        color: isSelected ? Colors.blueAccent : Colors.grey[300],
                                        borderRadius: BorderRadius.circular(8.0),
                                      ),
                                      child: Text(
                                        dayDisplay,
                                        style: TextStyle(
                                          color: isSelected ? Colors.white : Colors.black,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          const SizedBox(height: 16.0),
                          
                          // Hourly forecast with wind information
                          SizedBox(
                            height: 240,
                            child: ListView.builder(
                              controller: _hourlyScrollController,
                              scrollDirection: Axis.horizontal,
                              itemCount: allHourlyForecast.length,
                              itemBuilder: (context, index) {
                                final hourData = allHourlyForecast[index];
                                final time = _formatTime(hourData['time']);
                                final icon = hourData['condition']['icon'];
                                final temp = hourData['temp_c'].round();
                                final chanceOfRain = hourData['chance_of_rain'];
                                final rainAmount = hourData['precip_mm'];
                                final windSpeed = hourData['wind_kph'].round();
                                final windGust = hourData['gust_kph'].round();
                                final windDegree = hourData['wind_degree'];
                                final cloudCover = hourData['cloud'];

                                return Container(
                                  width: 100,
                                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                                  margin: const EdgeInsets.symmetric(horizontal: 4.0),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey[300]!),
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      Text(time, style: const TextStyle(fontWeight: FontWeight.bold)),
                                      Image.network("https:$icon", width: 24, height: 24),
                                      Text('$temp°C'),
                                      Text('$chanceOfRain%'),
                                      Text('$rainAmount mm'),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Transform.rotate(
                                            angle: (windDegree * pi) / 180,
                                            child: const Icon(Icons.arrow_upward, size: 16),
                                          ),
                                          const SizedBox(width: 4),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text('$windSpeed km/h'),
                                              Text('Gust: $windGust', style: const TextStyle(fontSize: 12)),
                                            ],
                                          ),
                                        ],
                                      ),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.cloud, size: 16),
                                          const SizedBox(width: 4),
                                          Text('$cloudCover%'),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),

                          // Sun and Moon Information
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    Column(
                                      children: [
                                        const Icon(Icons.wb_sunny, size: 40, color: Colors.orange),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Sunrise: ${sunTimes['sunrise'] ?? '--:--'}',
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                        Text(
                                          'Sunset: ${sunTimes['sunset'] ?? '--:--'}',
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                      ],
                                    ),
                                    Column(
                                      children: [
                                        const Icon(Icons.nightlight_round, size: 40, color: Colors.blueGrey),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Moonrise: ${sunTimes['moonrise'] ?? '--:--'}',
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                        Text(
                                          'Moonset: ${sunTimes['moonset'] ?? '--:--'}',
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    Column(
                                      children: [
                                        const Icon(Icons.wb_twilight, size: 30, color: Colors.amber),
                                        const SizedBox(height: 8),
                                        const Text('Golden Hour', style: TextStyle(fontWeight: FontWeight.bold)),
                                        Text(
                                          '${sunTimes['morning_golden_start']} - ${sunTimes['morning_golden_end']}',
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                        Text(
                                          '${sunTimes['evening_golden_start']} - ${sunTimes['evening_golden_end']}',
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      ],
                                    ),
                                    Column(
                                      children: [
                                        const Icon(Icons.nightlight, size: 30, color: Colors.blue),
                                        const SizedBox(height: 8),
                                        const Text('Blue Hour', style: TextStyle(fontWeight: FontWeight.bold)),
                                        Text(
                                          '${sunTimes['morning_blue_start']} - ${sunTimes['morning_blue_end']}',
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                        Text(
                                          '${sunTimes['evening_blue_start']} - ${sunTimes['evening_blue_end']}',
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Center(
                                  child: Text(
                                    '${_getMoonPhaseEmoji(sunTimes['moon_phase'] ?? '')} ${sunTimes['moon_phase'] ?? 'Unknown'}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  : const Center(child: Text('No weather data available.')),
    );
  }
}
