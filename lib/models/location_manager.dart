import 'package:flutter_map_math/flutter_geo_math.dart';
import 'package:latlong2/latlong.dart';
import 'package:weather_app/services/reverse_geocoding.dart';

class LocationManager {
  // Singleton instance
  static final LocationManager _instance = LocationManager._internal();

  // API to get the location
  final ReverseGeocoding _reverseGeocoding = ReverseGeocoding();

  // Factory constructor to return the same instance
  factory LocationManager() {
    return _instance;
  }

  // Internal constructor
  LocationManager._internal() {
    // Initialize with a default location if the list is empty
    if (_savedLocations.isEmpty) {
      _savedLocations.add({
        'name': 'Cambridge',
        'region': 'Cambridgeshire',
        'country': 'United Kingdom',
        'lat': 52.2053,
        'lon': 0.1218,
      });
    }
  }

  // List to hold saved locations (using a simple structure for now)
  final List<Map<String, dynamic>> _savedLocations = [];

  // Getter for saved locations
  List<Map<String, dynamic>> get savedLocations => _savedLocations;

  Future addLocationLatLng(LatLng coords) async {
    if (!isLocationSaved({'lat': coords.latitude, 'lon': coords.longitude})) {
      try {
        Map<String, dynamic> placename = await _reverseGeocoding.getLocation(
          coords,
        );
        _savedLocations.add({
          'name': placename['city'],
          'region': placename['county'],
          'country': placename['country'],
          'lat': coords.latitude,
          'lon': coords.longitude,
        });
        print(placename);
      } on NoLocationException {
        print("This Location does not have a name");
      } catch (e) {
        print("An error has occured $e");
      }
    }
  }

  List<Map<String, dynamic>> getLocations() {
    return _savedLocations;
  }

  // Method to add a location
  void addLocation(Map<String, dynamic> location) {
    // Prevent adding duplicates based on latitude and longitude within 10 meters
    if (!isLocationSaved(location)) {
      _savedLocations.add(location);
    }
  }

  void removeLocation(Map<String, dynamic> location) {
    // Remove the location based on its name and country
    _savedLocations.removeWhere((loc) => withinTenMetres(loc, location));
  }

  bool isLocationSaved(Map<String, dynamic> location) {
    return _savedLocations.any((loc) => withinTenMetres(loc, location));
  }

  bool withinTenMetres(Map<String, dynamic> loc1, Map<String, dynamic> loc2) {
    return FlutterMapMath().distanceBetween(
          loc1['lat'],
          loc1['lon'],
          loc2['lat'],
          loc2['lon'],
          "meters",
        ) <=
        10;
  }
}
