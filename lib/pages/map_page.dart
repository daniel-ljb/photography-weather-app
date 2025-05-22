import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../widgets/layer_toggle.dart';
import '../widgets/search_bar.dart';
import '../widgets/forecast_box.dart';
import '../models/location_manager.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key, required this.title});
  
  final String title;

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final TextEditingController _searchController = TextEditingController();
  
  final MapController _mapController = MapController();

  final LatLngBounds mapBounds = LatLngBounds(LatLng(62, -15),  LatLng(40, 10));

  // Track the state of each layer
  bool _temperatureLayer = false;
  bool _precipitationLayer = false;
  bool _cloudLayer = false;
  bool _windLayer = false;
  bool _visibilityLayer = false;
  bool _lightPollutionLayer = false;
  bool _shadeLayer = false;

  // Context menu
  Offset? _tapPosition;
  LatLng? _tapLatLng;
  bool _showContextMenu = false;


  // Add controller for DraggableScrollableSheet
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  final String _openWeatherMapApiKey = dotenv.env['OPEN_WEATHER_MAP_API_KEY'] ?? '';

  @override
  void initState() {
    super.initState();
    // Set the initial location from the first saved location if available
    final savedLocations = LocationManager().savedLocations;
    if (savedLocations.isNotEmpty) {
       // Move map to the initial saved location
       WidgetsBinding.instance.addPostFrameCallback((_) {
         _mapController.move(
           LatLng(savedLocations.first['lat'], savedLocations.first['lon']),
           6.0, // initial zoom level
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
              arguments: location['name'],
            );
          },
          child: Tooltip( // Add a tooltip for hovering/long press
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
    _mapController.move(
      LatLng(location['lat'], location['lon']),
      10.0, // zoom level
    );


    // Navigate to the detailed weather view, passing just the location name
    await Navigator.pushNamed(
      context,
      '/weather/detail',
      arguments: location['name'], // Pass only the location name string
    );

    // When returning from the detail page, refresh the UI to show saved locations
    setState(() {
      // The list of saved locations is managed by the singleton LocationManager
      // No local state update is needed here, just trigger a rebuild.
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
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
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
            LayerToggle(
              title: 'Visibility',
              icon: Icons.visibility,
              value: _visibilityLayer,
              onChanged: (value) => setState(() => _visibilityLayer = value),
            ),
            LayerToggle(
              title: 'Light Pollution',
              icon: Icons.flourescent,
              value: _lightPollutionLayer,
              onChanged: (value) => setState(() => _lightPollutionLayer = value),
            ),
            LayerToggle(
              title: 'Shade',
              icon: Icons.wb_shade,
              value: _shadeLayer,
              onChanged: (value) => setState(() => _shadeLayer = value),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          // Main content
          Positioned.fill(
            child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  cameraConstraint: CameraConstraint.contain(bounds:mapBounds),
                  interactionOptions: const InteractionOptions(flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag | InteractiveFlag.scrollWheelZoom),
                  initialCenter: LatLng(53.5,-3),
                  initialZoom: 6,
                  maxZoom: 19,
                  onLongPress:(tapPosition, point) {
                    setState(() {
                      _tapPosition = Offset(tapPosition.global.dx, tapPosition.global.dy);
                      _tapLatLng = point;
                      _showContextMenu = true;
                    });
                  },
                  onPointerDown: (tapPosition, point) {
                    // print("tap");
                    if (_showContextMenu) {
                      setState(() {
                        _showContextMenu = false;
                      });
                    }
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.photography.app',
                   ),
                   if (_temperatureLayer) // Only show if _temperatureLayer is true
                     Opacity( // Use Opacity widget to control transparency
                       opacity: 0.95, // Make it semi-transparent so base map is visible
                       child: TileLayer(
                         // OpenWeatherMap Temperature Layer URL
                         // Replace YOUR_OPENWEATHERMAP_API_KEY with your actual key
                         urlTemplate: 'https://tile.openweathermap.org/map/temp_new/{z}/{x}/{y}.png?appid=$_openWeatherMapApiKey',
                         userAgentPackageName: 'com.photography.app.weather_layer',
                       ),
                     ),
                   MarkerLayer(
                     markers: _buildLocationMarkers(), // Call the helper method to get the list of markers
                   ),
                   ],
            ),
          ),
          // Context Menu
          if (_showContextMenu && _tapPosition != null) 
            Positioned(
              left: _tapPosition!.dx,
              top: _tapPosition!.dy,
              width: 140.0,
              height: 50.0,
              child: GestureDetector(
                onTap: () {}, // prevent tap from propagating
                child: Material(
                  elevation: 4,
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        title: const Text('Add Pin',style: TextStyle(color: Colors.black, fontSize: 14),),
                        onTap: () {
                          // Do something with _tapLatLng
                          print("Tapped at $_tapLatLng");
                          setState(() {
                            _showContextMenu = false;
                          });
                        },
                      ),
                      ],
                  ),
                ),
              ),
            ),
          // Floating search bar and layers button
          Positioned(
            top: MediaQuery.of(context).padding.top,
            left: 16,
            right: 16,
            child: Row(
              children: [
                Builder(
                  builder: (context) => Material(
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
                        child: const Icon(Icons.layers, color: Colors.blue),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: WeatherSearchBar(
                    controller: _searchController,
                    onLocationSelected: _onLocationSelected,
                  ),
                ),
              ],
            ),
          ),
          // Alert button in bottom right
          Positioned(
            right: 24,
            bottom: MediaQuery.of(context).size.height * 0.33,
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
                        child: Center(child: Text('Search for locations to save them here.', style: TextStyle(fontSize: 16, color: Colors.grey[600]))),
                      ) // Message when no locations are saved
                    else
                       ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: savedLocations.length,
                        itemBuilder: (context, index) {
                          final location = savedLocations[index];
                          return Padding(
                             padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                            child: ForecastBox(
                              location: location['name'],
                               onTap: () {
                                 // Navigate to the detailed weather view for the tapped saved location
                                 Navigator.pushNamed(
                                   context,
                                   '/weather/detail',
                                   arguments: location['name'],
                                 );
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
