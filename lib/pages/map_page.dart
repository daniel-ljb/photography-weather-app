import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_animations/flutter_map_animations.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:latlong2/latlong.dart';
import 'package:weather_app/services/notification_manager.dart';
import 'package:weather_app/widgets/hold_context_menu.dart';
import 'package:weather_app/widgets/time_slider.dart';
import '../widgets/layer_toggle.dart';
import '../widgets/search_bar.dart';
import '../widgets/forecast_box.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/location_manager.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key, required this.title});

  final String title;

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> with TickerProviderStateMixin {
  // Search bar
  final TextEditingController _searchController = TextEditingController();
  final WeatherSearchBarController _searchBarHideController =
      WeatherSearchBarController();

  // Map
  late final AnimatedMapController _mapController = AnimatedMapController(
    vsync: this,
  );
  final LatLngBounds mapBounds = LatLngBounds(LatLng(62, -15), LatLng(40, 10));

  // Track the state of each layer
  bool _temperatureLayer = false;
  bool _precipitationLayer = false;
  bool _cloudLayer = false;
  bool _windLayer = false;
  bool _visibilityLayer = false;
  bool _lightPollutionLayer = false;
  bool _shadeLayer = false;

  // Helper method to check if any layer is selected
  bool get _isAnyLayerSelected =>
      _temperatureLayer ||
      _precipitationLayer ||
      _cloudLayer ||
      _windLayer ||
      _visibilityLayer ||
      _shadeLayer;

  // Context menu
  Offset? _tapPosition;
  LatLng? _tapLatLng;
  bool _showContextMenu = false;
  
  // For the time slider
  int selectedTimeIndex = 0;
  final int _currentUNIX =
      (DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
        DateTime.now().hour,
      ).toUtc().millisecondsSinceEpoch) ~/
      1000;
  int? _setTime;

  // Add controller for DraggableScrollableSheet
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  final String _openWeatherMapApiKey =
      dotenv.env['OPEN_WEATHER_MAP_API_KEY'] ?? '';

  @override
  void initState() {
    _setTime = _currentUNIX;
    super.initState();
    // Set the initial location from the first saved location if available
    final savedLocations = LocationManager().savedLocations;
    if (savedLocations.isNotEmpty) {
      // Move map to the initial saved location
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mapController.animateTo(
          dest: LatLng(
            savedLocations.first['lat'],
            savedLocations.first['lon'],
          ),
          zoom: 6.0, // initial zoom level
        );
      });
    }
  }

  // Helper method to build markers from saved locations
  List<Marker> _buildLocationMarkers() {
    final savedLocations = LocationManager().savedLocations;
    return savedLocations.map((location) {
      return Marker(
        point: LatLng(location['lat'], location['lon']),
        width: 80.0, // Adjust marker size as needed
        height: 80.0,
        // The child widget for the marker (the "pin" visual)
        child: GestureDetector(
          onTap: () {
            // Navigate to the detail page when the marker is tapped
            Navigator.pushNamed(
              context,
              '/weather/detail',
              arguments:
                  "${location['lat']},${location['lon']},${location['name']}",
            ).then((result) {
              // If a location was removed, refresh the state
              if (result == true) {
                setState(() {});
              }
            });
          },
          child: Tooltip(
            // Add a tooltip for hovering/long press
            message: location['name'],
            child: const Icon(
              Icons.location_on, // Standard location pin icon
              color: Colors.blue, // Choose a color for your pins
              size: 40.0, // Adjust icon size
            ),
          ),
        ),
      );
    }).toList();
  }

  void _onLocationSelected(Map<String, dynamic> location) async {
    // Move map to selected location
    _mapController.animateTo(
      dest: LatLng(location['lat'], location['lon']),
      zoom: 10.0, // zoom level
    );

    // Show context menu at the center of the screen
    setState(() {
      _tapLatLng = LatLng(location['lat'], location['lon']);
      _tapPosition = Offset(
        MediaQuery.of(context).size.width / 3,
        MediaQuery.of(context).size.height / 6,
      );
      _showContextMenu = true;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _sheetController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Get the list of saved locations
    final savedLocations = LocationManager().savedLocations;

    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Text(
                    'Weather Layers',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Toggle map overlays',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            LayerToggle(
              title: 'Temperature',
              icon: Icons.thermostat,
              value: _temperatureLayer,
              onChanged: (value) => setState(() => _temperatureLayer = value),
            ),
            LayerToggle(
              title: 'Precipitation',
              icon: Icons.water_drop,
              value: _precipitationLayer,
              onChanged: (value) => setState(() => _precipitationLayer = value),
            ),
            LayerToggle(
              title: 'Clouds',
              icon: Icons.cloud,
              value: _cloudLayer,
              onChanged: (value) => setState(() => _cloudLayer = value),
            ),
            LayerToggle(
              title: 'Wind',
              icon: Icons.air,
              value: _windLayer,
              onChanged: (value) => setState(() => _windLayer = value),
            ),
            // LayerToggle(
            //   title: 'Visibility',
            //   icon: Icons.visibility,
            //   value: _visibilityLayer,
            //   onChanged: (value) => setState(() => _visibilityLayer = value),
            // ),
            LayerToggle(
              title: 'Light Pollution',
              icon: Icons.flourescent,
              value: _lightPollutionLayer,
              onChanged:
                  (value) => setState(() => _lightPollutionLayer = value),
            ),
            // LayerToggle(
            //   title: 'Shade',
            //   icon: Icons.wb_shade,
            //   value: _shadeLayer,
            //   onChanged: (value) => setState(() => _shadeLayer = value),
            // ),
          ],
        ),
      ),
      body: Stack(
        children: [
          // Main content
          Positioned.fill(
            child: FlutterMap(
              mapController: _mapController.mapController,
              options: MapOptions(
                cameraConstraint: CameraConstraint.contain(bounds: mapBounds),
                interactionOptions: const InteractionOptions(
                  flags:
                      InteractiveFlag.pinchZoom |
                      InteractiveFlag.drag |
                      InteractiveFlag.scrollWheelZoom,
                ),
                initialCenter: LatLng(53.5, -3),
                initialZoom: 6,
                maxZoom: 19,
                onLongPress: (tapPosition, point) {
                  setState(() {
                    _tapPosition = Offset(
                      tapPosition.global.dx,
                      tapPosition.global.dy,
                    );
                    _tapLatLng = point;
                    _showContextMenu = true;
                  });
                },
                onPointerDown: (tapPosition, point) {
                  // print("tap");
                  _searchBarHideController.removeOverlay();
                  if (_showContextMenu) {
                    setState(() {
                      _showContextMenu = false;
                      // Stop showing search bar
                    });
                  }
                },
              ),
              children: [
                // Map
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.photography.app',
                ),

                   // Temperature Layer
                   if (_temperatureLayer)
                    TileLayer(
                      // urlTemplate: 'https://tile.openweathermap.org/map/temp/{z}/{x}/{y}.png?appid=$_openWeatherMapApiKey',
                      urlTemplate: 
                        'http://maps.openweathermap.org/maps/2.0/weather/TA2/{z}/{x}/{y}?appid=$_openWeatherMapApiKey&palette=0:45A7FF;10:E3F043;25:FA6E43&opacity=0.7&date=$_setTime',
                      userAgentPackageName: 'com.photography.app',
                    ),

                // Precipitation Layer
                if (_precipitationLayer)
                  TileLayer(
                    // urlTemplate: 'https://tile.openweathermap.org/map/precipitation_new/{z}/{x}/{y}.png?appid=$_openWeatherMapApiKey&opacity=0.6',
                    urlTemplate:
                        'http://maps.openweathermap.org/maps/2.0/weather/PA0/{z}/{x}/{y}?appid=$_openWeatherMapApiKey&opacity=0.7&date=$_setTime',
                    userAgentPackageName: 'com.photography.app',
                  ),

                // Cloud Coverage Layer
                if (_cloudLayer)
                  TileLayer(
                    // urlTemplate: 'https://tile.openweathermap.org/map/clouds_new/{z}/{x}/{y}.png?appid=$_openWeatherMapApiKey&opacity=0.5',
                    urlTemplate:
                        'http://maps.openweathermap.org/maps/2.0/weather/CL/{z}/{x}/{y}?appid=$_openWeatherMapApiKey&opacity=0.7&date=$_setTime',
                    userAgentPackageName: 'com.photography.app',
                  ),

                // Wind Speed Layer
                if (_windLayer)
                  TileLayer(
                    // urlTemplate: 'https://tile.openweathermap.org/map/wind_new/{z}/{x}/{y}.png?appid=$_openWeatherMapApiKey&opacity=0.7',
                    urlTemplate:
                        'http://maps.openweathermap.org/maps/2.0/weather/WND/{z}/{x}/{y}?arrow_step=16&appid=$_openWeatherMapApiKey&date=$_setTime',
                    userAgentPackageName: 'com.photography.app',
                  ),
                if (_lightPollutionLayer)
                  OverlayImageLayer(
                    overlayImages: [
                      OverlayImage(
                        // Unrotated
                        bounds: LatLngBounds(
                          // LatLng(64.58032-1.03,-34.41551+8.7),
                          // LatLng((39.22808+5.4)-1.03,(23.53516-11)+8.7),
                          LatLng(64.58032, -34.41551),
                          LatLng(39.22808, 23.54516),
                        ),
                        imageProvider: AssetImage('assets/light_pollution.png'),
                        opacity: 0.5,
                      ),
                    ],
                  ),
                MarkerLayer(
                  markers:
                      _buildLocationMarkers(), // Call the helper method to get the list of markers
                ),
              ],
            ),
          ),
          // Context Menu
          if (_showContextMenu && _tapPosition != null)
            HoldContextMenu(
              tapLatLng: _tapLatLng,
              tapPosition: _tapPosition,
              onClose: () {
                setState(() {
                  _showContextMenu = false;
                });
              },
            ),
          // Floating search bar and layers button
          Positioned(
            top: MediaQuery.of(context).padding.top,
            left: 16,
            right: 16,
            child: Column(
              children: [
                Row(
                  children: [
                    Builder(
                      builder:
                          (context) => Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () {
                                Scaffold.of(context).openDrawer();
                              },
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.layers,
                                  color: Colors.blue,
                                ),
                              ),
                            ),
                          ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: WeatherSearchBar(
                        controller: _searchController,
                        weathersearchbarcontroller: _searchBarHideController,
                        onLocationSelected: _onLocationSelected,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_isAnyLayerSelected)
                  TimeSlider(
                    currentIndex: selectedTimeIndex,
                    onChanged: (newIndex) {
                      setState(() {
                        selectedTimeIndex = newIndex;
                        _setTime = _currentUNIX + 3600 * selectedTimeIndex;
                      });
                    },
                    labels: List.generate(
                      12 + 1,
                      (i) => i == 0 ? 'Now' : '+${i}h',
                    ),
                  ),
              ],
            ),
          ),
          // Alert button in bottom right
          Positioned(
            right: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom > 0 
              ? MediaQuery.of(context).viewInsets.bottom - 115
              : MediaQuery.of(context).size.height * 0.33,
            child: FloatingActionButton(
              heroTag: 'alertButton',
              backgroundColor: Colors.blue,
              onPressed: () {
                Navigator.pushNamed(context, '/alerts');
              },
              tooltip: 'Set Weather Alert',
              child: const Icon(Icons.notifications, color: Colors.white),
            ),
          ),
          // Pull-up tab
          DraggableScrollableSheet(
            controller: _sheetController,
            initialChildSize: 0.3,
            minChildSize: 0.3,
            maxChildSize: 0.9,
            snap: true,
            snapSizes: const [0.3, 0.9],
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 8,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),
                child: ListView(
                  controller: scrollController,
                  padding: EdgeInsets.zero,
                  children: [
                    // Display saved locations using ForecastBox
                    if (savedLocations.isEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                        child: Center(
                          child: Text(
                            'Search for locations to save them here.',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ) // Message when no locations are saved
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: savedLocations.length,
                        itemBuilder: (context, index) {
                          final location = savedLocations[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 8.0,
                            ),
                            child: ForecastBox(
                              location: location['name'],
                              coordinates:
                                  "${location['lat']},${location['lon']}",
                              onTap: () {
                                // Navigate to the detailed weather view for the tapped saved location
                                Navigator.pushNamed(
                                  context,
                                  '/weather/detail',
                                  arguments:
                                      "${location['lat']},${location['lon']},${location['name']}",
                                ).then((result) {
                                  // If a location was removed, refresh the state
                                  if (result == true) {
                                    setState(() {});
                                  }
                                });
                              },
                            ),
                          );
                        },
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
