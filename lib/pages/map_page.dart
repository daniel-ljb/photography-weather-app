import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_cancellable_tile_provider/flutter_map_cancellable_tile_provider.dart';
import 'package:latlong2/latlong.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key, required this.title});

  final String title;

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final TextEditingController _searchController = TextEditingController();

  // Track the state of each layer
  bool _temperatureLayer = false;
  bool _precipitationLayer = false;
  bool _windLayer = false;

  // Add controller for DraggableScrollableSheet
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

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
            ListTile(
              leading: const Icon(Icons.cloud),
              title: const Text('Temperature'),
              trailing: Checkbox(
                value: _temperatureLayer,
                onChanged: (bool? value) {
                  setState(() {
                    _temperatureLayer = value ?? false;
                  });
                },
              ),
              onTap: () {
                setState(() {
                  _temperatureLayer = !_temperatureLayer;
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.water_drop),
              title: const Text('Precipitation'),
              trailing: Checkbox(
                value: _precipitationLayer,
                onChanged: (bool? value) {
                  setState(() {
                    _precipitationLayer = value ?? false;
                  });
                },
              ),
              onTap: () {
                setState(() {
                  _precipitationLayer = !_precipitationLayer;
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.air),
              title: const Text('Wind'),
              trailing: Checkbox(
                value: _windLayer,
                onChanged: (bool? value) {
                  setState(() {
                    _windLayer = value ?? false;
                  });
                },
              ),
              onTap: () {
                setState(() {
                  _windLayer = !_windLayer;
                });
              },
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
                mapController: MapController(),
                options: MapOptions(
                  cameraConstraint: CameraConstraint.contain(bounds:LatLngBounds(LatLng(62, -15),  LatLng(40, 10))),
                  initialCenter: LatLng(53.5,-3),
                  initialZoom: 6,
                  maxZoom: 19
                ),
                children: [
                  TileLayer( // Bring your own tiles
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', // For demonstration only
                    userAgentPackageName: 'com.example.app', // Add your app identifier
                   ),
                   RichAttributionWidget( // Include a stylish prebuilt attribution widget that meets all requirments
                  attributions: [
                    TextSourceAttribution(
                      'OpenStreetMap contributors',
                      onTap: () => 1, // (external)
                    )
                    // Also add images...
                  ],
                ),
                   ],
            )
          ),
          // Floating search bar and layers button
          Positioned(
            top: MediaQuery.of(context).padding.top,
            left: 16,
            right: 16,
            child: Row(
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
                              boxShadow: [
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
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'Search location...',
                        prefixIcon: Icon(Icons.search),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Alert button in bottom right, 23% of the screen height above the bottom
          Positioned(
            right: 24,
            bottom: MediaQuery.of(context).size.height * 0.23,
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
            initialChildSize: 0.2,
            minChildSize: 0.2,
            maxChildSize: 0.9,
            snap: true,
            snapSizes: const [0.2, 0.9],
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
                    // Forecast box for selected location
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/weather/detail',
                            arguments: 'Cambridge',
                          );
                        },
                        child: _ForecastBox(),
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

// Forecast box widget
class _ForecastBox extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.location_on, size: 20, color: Colors.blue),
                  SizedBox(width: 4),
                  Text(
                    'Cambridge',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: const [
                  Row(
                    children: [
                      Icon(Icons.wb_sunny, size: 16, color: Colors.orange),
                      SizedBox(width: 2),
                      Text('5:08am'),
                    ],
                  ),
                  SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        Icons.nights_stay,
                        size: 16,
                        color: Colors.deepOrange,
                      ),
                      SizedBox(width: 2),
                      Text('8:45pm'),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 90,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 8,
              separatorBuilder: (context, index) => const SizedBox(width: 16),
              itemBuilder: (context, index) {
                // Example data
                final hours = [
                  '4pm',
                  '5pm',
                  '6pm',
                  '7pm',
                  '8pm',
                  '9pm',
                  '10pm',
                  '11pm',
                ];
                final temps = [15, 16, 17, 15, 12, 9, 7, 6];
                final icons = [
                  Icons.wb_sunny,
                  Icons.wb_sunny,
                  Icons.wb_sunny,
                  Icons.cloud,
                  Icons.nights_stay,
                  Icons.nights_stay,
                  Icons.nights_stay,
                  Icons.nights_stay,
                ];
                return Column(
                  children: [
                    Text(hours[index], style: const TextStyle(fontSize: 14)),
                    Icon(icons[index], size: 24, color: Colors.blueGrey),
                    Text(
                      '${temps[index]}°C',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
