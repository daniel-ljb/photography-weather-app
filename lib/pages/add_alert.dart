import 'package:flutter/material.dart';
import '../models/alert.dart';
import '../models/alert_manager.dart';

class AddAlertPage extends StatefulWidget {
  final String title;
  const AddAlertPage({super.key, required this.title});

  @override
  State<AddAlertPage> createState() => _AddAlertPageState();
}

class _AddAlertPageState extends State<AddAlertPage> {
  final TextEditingController _nameController = TextEditingController();
  int _selectedDays = 0;
  int _selectedHours = 1; // Start at 1 for new alerts
  final List<Map<String, int>> _alertTimes = [];

  // Use unique names and explicit types
  Set<int> _precipitationSet = <int>{};
  Set<int> _cloudCoverageSet = <int>{};

  // Add controllers for the wheels
  final FixedExtentScrollController _daysController =
      FixedExtentScrollController();
  final FixedExtentScrollController _hoursController =
      FixedExtentScrollController();

  // Add for time of day
  final List<String> _timeOfDayOptions = [
    'Sunrise',
    'Golden Hour Morning',
    'Blue Hour Morning',
    'Midday',
    'Afternoon',
    'Evening',
    'Blue Hour Evening',
    'Golden Hour Evening',
    'Sunset',
    'Night',
  ];
  Set<int> _selectedTimesOfDay = <int>{};

  int? _editIndex;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map && args['alert'] is Alert) {
      final Alert alert = args['alert'];
      _editIndex = args['index'] as int?;
      _nameController.text = alert.name;
      _alertTimes.clear();
      _alertTimes.addAll(alert.times);
      _precipitationSet = Set<int>.from(alert.precipitation);
      _cloudCoverageSet = Set<int>.from(alert.cloudCoverage);
      _selectedTimesOfDay = Set<int>.from(alert.timesOfDay);
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
              );
              if (_editIndex != null) {
                AlertManager().updateAlert(_editIndex!, alert);
              } else {
                AlertManager().addAlert(alert);
              }
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
                        'None',
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
                        'Low\n2.5–4mm',
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
                        'High\n4+ mm',
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
                        label: Text(_timeOfDayOptions[i]),
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
