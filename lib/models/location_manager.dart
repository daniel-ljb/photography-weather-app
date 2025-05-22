class LocationManager {
  // Singleton instance
  static final LocationManager _instance = LocationManager._internal();

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

  // Method to add a location
  void addLocation(Map<String, dynamic> location) {
    // Prevent adding duplicates based on name and country
    if (!_savedLocations.any((loc) => loc['name'] == location['name'] && loc['country'] == location['country'])) {
      _savedLocations.add(location);
    }
  }

  void removeLocation(Map<String, dynamic> location) {
    // Remove the location based on its name and country
    _savedLocations.removeWhere(
      (loc) => loc['name'] == location['name'] && loc['country'] == location['country']
    );
  }

  // Method to check if a location is saved
  bool isLocationSaved(String locationName) {
    return _savedLocations.any((loc) => loc['name'] == locationName);
  }

  // TODO: Add remove location method if needed later
} 