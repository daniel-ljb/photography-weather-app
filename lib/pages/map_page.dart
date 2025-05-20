import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../widgets/layer_toggle.dart';
import '../widgets/search_bar.dart';
import '../widgets/forecast_box.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key, required this.title});

  final String title;

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final TextEditingController _searchController = TextEditingController();

  final MapController _mapController = MapController();

  // Track the state of each layer
  bool _temperatureLayer = false;
  bool _precipitationLayer = false;
  bool _cloudLayer = false;
  bool _windLayer = false;
  bool _visibilityLayer = false;
  bool _lightPollutionLayer = false;
  bool _shadeLayer = false;

  // Add controller for DraggableScrollableSheet
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  String _currentLocation = 'Cambridge';

  void _onLocationSelected(Map<String, dynamic> location) {
    // Move map to selected location
    _mapController.move(
      LatLng(location['lat'], location['lon']),
      10.0, // zoom level
    );
    
    // Navigate to the detailed weather view, passing just the location name
    Navigator.pushNamed(
      context,
      '/weather/detail',
      arguments: location['name'], // Pass only the location name string
    );

    // Do NOT update _currentLocation here to prevent the bottom sheet from changing
    // setState(() {
    //   _currentLocation = location['name'];
    // });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _sheetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
              ),
              child: const Text(
                'Weather Layers',
                style: TextStyle(color: Colors.white, fontSize: 24),
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
            const Divider(),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                // TODO: Navigate to settings
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          // Main content (map placeholder)
          Positioned.fill(
            child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  cameraConstraint: CameraConstraint.contain(bounds:LatLngBounds(LatLng(62, -15),  LatLng(40, 10))),
                  initialCenter: LatLng(53.5,-3),
                  initialZoom: 6,
                  maxZoom: 19
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.photography.app',
                   ),
                   ],
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
              child: const Icon(Icons.notifications, color: Colors.white),
              tooltip: 'Set Weather Alert',
            ),
          ),
          // Pull-up tab with snap
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
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                      child: ForecastBox(
                        location: _currentLocation,
                      ),
                    ),
                    // TODO: Add more boxes for other locations when expanded
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
