import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:weather_app/models/location_manager.dart';
import '../models/alert.dart';
import '../models/alert_manager.dart';

class AddAlertPage extends StatefulWidget {
  final String title;
  const AddAlertPage({super.key, required this.title});

  @override
  State<AddAlertPage> createState() => _AddAlertPageState();
}

class _AddAlertPageState extends State<AddAlertPage> {
  bool _initialized = false;
  final TextEditingController _nameController = TextEditingController();
  int _selectedDays = 0;
  int _selectedHours = 1; // Start at 1 for new alerts
  final List<Map<String, int>> _alertTimes = [];

  // Use unique names and explicit types
  Set<int> _precipitationSet = <int>{};
  Set<int> _cloudCoverageSet = <int>{};
  Map<String, dynamic>? _selectedLocation;

  // Add controllers for the wheels
  final FixedExtentScrollController _daysController =
      FixedExtentScrollController();
  final FixedExtentScrollController _hoursController =
      FixedExtentScrollController();

  // Add for time of day
  final List<String> _timeOfDayOptions = [
    'Blue Hour AM',
    'Sunrise',
    'Golden Hour AM',
    'Morning',
    'Midday',
    'Afternoon',
    'Evening',
    'Golden Hour PM',
    'Sunset',
    'Blue Hour PM',
    'Night',
  ];
  Set<int> _selectedTimesOfDay = <int>{};

  int? _editIndex;
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map && args['alert'] is Alert) {
      final Alert alert = args['alert'];
      print(alert.times);
      _editIndex = args['index'] as int?;
      _nameController.text = alert.name;
      _alertTimes.clear();
      _alertTimes.addAll(alert.times);
      _precipitationSet = Set<int>.from(alert.precipitation);
      _cloudCoverageSet = Set<int>.from(alert.cloudCoverage);
      _selectedTimesOfDay = Set<int>.from(alert.timesOfDay);
      _selectedLocation = alert.location;
      // Set initial days/hours to first alert time if available
      if (_alertTimes.isNotEmpty) {
        _selectedDays = _alertTimes[0]['days'] ?? 0;
        _selectedHours =
            _alertTimes[0]['hours'] ?? (_selectedDays == 0 ? 1 : 0);
      } else {
        _selectedDays = 0;
        _selectedHours = 1;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _daysController.jumpToItem(_selectedDays);
        _hoursController.jumpToItem(
          _selectedDays == 0 ? _selectedHours - 1 : _selectedHours,
        );
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _daysController.dispose();
    _hoursController.dispose();
    super.dispose();
  }

  void _updateHoursController() {
    // Set the correct position for the hours wheel
    int hoursIndex = _selectedDays == 0 ? _selectedHours - 1 : _selectedHours;
    int maxIndex = _selectedDays == 0 ? 22 : 23;
    if (hoursIndex < 0) hoursIndex = 0;
    if (hoursIndex > maxIndex) hoursIndex = maxIndex;
    _hoursController.jumpToItem(hoursIndex);
  }

  final List<Map<String, dynamic>> _savedLocations =
      LocationManager().getLocations();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(),
        title: const Text('Add Alert'),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () {
              // Check if location is selected
              if (_selectedLocation == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a location'),
                    duration: Duration(seconds: 1),
                  ),
                );
                return;
              }
              // check if there are any times#
              if (_alertTimes.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter at least 1 alert time'),
                    duration: Duration(seconds: 1),
                  ),
                );
                return;
              }
              // Save alert
              final alert = Alert(
                name:
                    _nameController.text.trim().isEmpty
                        ? 'Untitled Alert'
                        : _nameController.text.trim(),
                times: List<Map<String, int>>.from(_alertTimes),
                precipitation: Set<int>.from(_precipitationSet),
                cloudCoverage: Set<int>.from(_cloudCoverageSet),
                timesOfDay: Set<int>.from(_selectedTimesOfDay),
                location: _selectedLocation!,
              );
              if (_editIndex != null) {
                AlertManager().updateAlert(_editIndex!, alert);
              } else {
                AlertManager().addAlert(alert);
              }
              _initialized = false;
              Navigator.popUntil(context, ModalRoute.withName('/alerts'));
            },
            child: const Text(
              'Save',
              style: TextStyle(color: Colors.blue, fontSize: 16),
            ),
          ),
        ],
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: ListView(
          children: [
            // Name field
            Row(
              children: [
                const Text('Enter name:', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      isDense: true,
                      border: UnderlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Days/Hours picker centered
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Number picker for days
                SizedBox(
                  width: 50,
                  height: 80,
                  child: ListWheelScrollView.useDelegate(
                    controller: _daysController,
                    itemExtent: 32,
                    diameterRatio: 1.2,
                    onSelectedItemChanged: (i) {
                      setState(() {
                        _selectedDays = i;
                        // Adjust hours if out of range for new days value
                        int maxHour = _selectedDays == 0 ? 23 : 23;
                        int minHour = _selectedDays == 0 ? 1 : 0;
                        if (_selectedHours < minHour) _selectedHours = minHour;
                        if (_selectedHours > maxHour) _selectedHours = maxHour;
                        _updateHoursController();
                      });
                    },
                    physics: const FixedExtentScrollPhysics(),
                    childDelegate: ListWheelChildBuilderDelegate(
                      builder:
                          (context, i) => Center(
                            child: Text(
                              '$i',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight:
                                    i == _selectedDays
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                              ),
                            ),
                          ),
                      childCount: 8, // 0 to 7
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                // Static label for days
                Text(
                  _selectedDays == 1 ? 'day' : 'days',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(width: 16),
                // Number picker for hours
                SizedBox(
                  width: 50,
                  height: 80,
                  child: ListWheelScrollView.useDelegate(
                    controller: _hoursController,
                    itemExtent: 32,
                    diameterRatio: 1.2,
                    onSelectedItemChanged: (i) {
                      setState(() {
                        if (_selectedDays == 0) {
                          _selectedHours = i + 1; // 1-23
                        } else {
                          _selectedHours = i; // 0-23
                        }
                      });
                    },
                    physics: const FixedExtentScrollPhysics(),
                    childDelegate: ListWheelChildBuilderDelegate(
                      builder: (context, i) {
                        if (_selectedDays == 0) {
                          // 1-23
                          int hour = i + 1;
                          return Center(
                            child: Text(
                              '$hour',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight:
                                    hour == _selectedHours
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                              ),
                            ),
                          );
                        } else {
                          // 0-23
                          return Center(
                            child: Text(
                              '$i',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight:
                                    i == _selectedHours
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                              ),
                            ),
                          );
                        }
                      },
                      childCount: _selectedDays == 0 ? 23 : 24,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                // Static label for hours
                Text(
                  _selectedHours == 1 ? 'hour' : 'hours',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () {
                    setState(() {
                      // dont readd the same time
                      for (final alert in _alertTimes) {
                        if (alert['days'] == _selectedDays && alert['hours'] == _selectedHours) return;
                      }
                      _alertTimes.add({
                        'days': _selectedDays,
                        'hours': _selectedHours,
                      });
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            // List of added times (horizontal scrollable chips)
            if (_alertTimes.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Alert Times:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children:
                          _alertTimes
                              .asMap()
                              .entries
                              .map(
                                (entry) => Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  child: Chip(
                                    label: Text(
                                      '${entry.value['days']}d ${entry.value['hours']}h',
                                    ),
                                    deleteIcon: const Icon(
                                      Icons.close,
                                      size: 18,
                                    ),
                                    onDeleted: () {
                                      setState(() {
                                        _alertTimes.removeAt(entry.key);
                                      });
                                    },
                                  ),
                                ),
                              )
                              .toList(),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            // Select location
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  const Text(
                    "Select Location",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  DropdownButton<Map<String, dynamic>>(
                    isExpanded: true,
                    value: _selectedLocation,
                    hint: const Text('Choose a location'),
                    items:
                        _savedLocations.map((location) {
                          return DropdownMenuItem<Map<String, dynamic>>(
                            value: location,
                            child: Text(location['name']),
                          );
                        }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        _selectedLocation = newValue;
                      });
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            // Precipitation
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Precipitation',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildMultiCheckbox(
                        'None\n0mm',
                        0,
                        _precipitationSet,
                        (int v) => setState(
                          () =>
                              _precipitationSet = _onMultiCheck(
                                _precipitationSet,
                                v,
                              ),
                        ),
                      ),
                      _buildMultiCheckbox(
                        'Light\n-2.5mm',
                        1,
                        _precipitationSet,
                        (int v) => setState(
                          () =>
                              _precipitationSet = _onMultiCheck(
                                _precipitationSet,
                                v,
                              ),
                        ),
                      ),
                      _buildMultiCheckbox(
                        'Moderate\n2.5-4mm',
                        2,
                        _precipitationSet,
                        (int v) => setState(
                          () =>
                              _precipitationSet = _onMultiCheck(
                                _precipitationSet,
                                v,
                              ),
                        ),
                      ),
                      _buildMultiCheckbox(
                        'High\n4+ mm',
                        3,
                        _precipitationSet,
                        (int v) => setState(
                          () =>
                              _precipitationSet = _onMultiCheck(
                                _precipitationSet,
                                v,
                              ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Cloud coverage
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Cloud Coverage',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildMultiCheckbox(
                        'None',
                        0,
                        _cloudCoverageSet,
                        (int v) => setState(
                          () =>
                              _cloudCoverageSet = _onMultiCheck(
                                _cloudCoverageSet,
                                v,
                              ),
                        ),
                      ),
                      _buildMultiCheckbox(
                        'Some',
                        1,
                        _cloudCoverageSet,
                        (int v) => setState(
                          () =>
                              _cloudCoverageSet = _onMultiCheck(
                                _cloudCoverageSet,
                                v,
                              ),
                        ),
                      ),
                      _buildMultiCheckbox(
                        'Most',
                        2,
                        _cloudCoverageSet,
                        (int v) => setState(
                          () =>
                              _cloudCoverageSet = _onMultiCheck(
                                _cloudCoverageSet,
                                v,
                              ),
                        ),
                      ),
                      _buildMultiCheckbox(
                        'All',
                        3,
                        _cloudCoverageSet,
                        (int v) => setState(
                          () =>
                              _cloudCoverageSet = _onMultiCheck(
                                _cloudCoverageSet,
                                v,
                              ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Time of day section
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Time of Day',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(
                      _timeOfDayOptions.length,
                      (i) => FilterChip(
                        label: SizedBox(
                          width:125,
                          child: Text(_timeOfDayOptions[i])
                        ),
                        showCheckmark: false,
                        selectedColor: Color.fromARGB(255, 133, 148, 233),
                        elevation: 2,
                        selected: _selectedTimesOfDay.contains(i),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedTimesOfDay.add(i);
                            } else {
                              _selectedTimesOfDay.remove(i);
                            }
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMultiCheckbox(
    String label,
    int value,
    Set<int> group,
    ValueChanged<int> onChanged,
  ) {
    return Column(
      children: [
        Checkbox(
          activeColor: Color.fromARGB(255, 133, 148, 233),
          value: group.contains(value),
          onChanged: (_) {
            print('Checkbox tapped: $label, value: $value, group: $group');
            onChanged(value);
          },
        ),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13),
        ),
      ],
    );
  }

  Set<int> _onMultiCheck(Set<int> group, int value) {
    final newSet = Set<int>.from(group);
    if (newSet.contains(value)) {
      newSet.remove(value);
    } else {
      newSet.add(value);
    }
    return newSet;
  }
}
