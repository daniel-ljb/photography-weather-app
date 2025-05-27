import 'package:flutter/material.dart';

class TimeSlider extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onChanged;
  final List<String> labels;

  const TimeSlider({
    super.key,
    required this.currentIndex,
    required this.onChanged,
    required this.labels,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(12),
        color: Colors.white.withOpacity(0.9),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            children: [
              Slider(
                value: currentIndex.toDouble(),
                min: 0,
                max: (labels.length - 1).toDouble(),
                divisions: labels.length - 1,
                label: labels[currentIndex],
                onChanged: (val) => onChanged(val.round()),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: labels
                    .map((label) => Text(label, style: TextStyle(fontSize: 10)))
                    .toList(),
              ),
            ],
          ),
        ),
      );
  }
}