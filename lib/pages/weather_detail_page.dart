import 'package:flutter/material.dart';
import '../services/weather_service.dart'; // We'll need this later
import 'package:intl/intl.dart'; // Import for date formatting
import '../models/location_manager.dart'; // Import the new manager

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

      // TODO: change to use coords instead of place name
      // We need the full location data to save it, so let's search for it.

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
  Future<void> _searchAndFetchWeatherData(String locationCoordiantes) async {
     setState(() {
      _isLoading = true;
      _error = null;
      _weatherData = null;
      _selectedDayIndex = 0;
      _dayKeys.clear();
       _currentLocationData = null; // Clear previous location data
    });
    try {
      // Search for the location to get full data (including lat/lon)
      final searchResults = await _weatherService.searchLocations(locationCoordiantes);
      if (searchResults.isNotEmpty) {
        _currentLocationData = searchResults.first; // Assuming the first result is the desired one
        // Now fetch weather data using the name from search result (or use lat/lon if API supports it consistently)
         final data = await _weatherService.getWeatherForecast(_currentLocationData!['name']);
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

      } else {
         setState(() {
          _error = 'Location not found.';
          _isLoading = false;
        });
      }
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
    for (var day in forecastDays) {
      allHours.addAll((day['hour'] as List<dynamic>)
          .map((hour) => hour as Map<String, dynamic>).toList());
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
        print('Removing location not yet implemented.');
      } else {
        LocationManager().addLocation(_currentLocationData!);
        setState(() {
          _isLocationSaved = true;
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location saved!'),
          duration: Duration(seconds: 1),
        ),
      );
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

    return Scaffold(
      appBar: AppBar(
        title: Text(_locationName),
         actions: [
          // Green plus/check mark icon
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
          ? const Center(
              child: CircularProgressIndicator(), // Show loading indicator
            )
          : _error != null
              ? Center(
                  child: Text('Error: $_error'), // Show error message
                )
              : _weatherData != null
                  ? Column(
                      children: [
                        // Horizontal scrollable days
                        if (_weatherData!['forecast'] != null)
                          SizedBox(
                            height: 60,
                            child: ListView.builder(
                              controller: _dayScrollController, // Assign the controller
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
                        // Hourly forecast for all days (horizontal scroll)
                        SizedBox(
                         height: 150,
                         child: ListView.builder(
                           controller: _hourlyScrollController, // Assign the controller
                           scrollDirection: Axis.horizontal,
                           itemCount: allHourlyForecast.length,
                           itemBuilder: (context, index) {
                             final hourData = allHourlyForecast[index];
                             final time = _formatTime(hourData['time']);
                             final icon = _weatherService.getWeatherIcon(hourData['condition']['text']);
                             final temp = hourData['temp_c'].round();
                             final chanceOfRain = hourData['chance_of_rain'];
                             final rainAmount = hourData['precip_mm'];

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
                                   Text(icon, style: const TextStyle(fontSize: 30)),
                                   Text('$temp°C'),
                                   Text('$chanceOfRain%'),
                                   Text('$rainAmount mm'),
                                 ],
                               ),
                             );
                           },
                         ),
                       ),
                      ],
                    )
                  : const Center(
                      child: Text('No weather data available.'), // Handle case with no data
                    ),
    );
  }
}
