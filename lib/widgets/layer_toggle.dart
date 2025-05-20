import 'package:flutter/material.dart';

class LayerToggle extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;

  const LayerToggle({
    super.key,
    required this.title,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: Checkbox(
        value: value,
        onChanged: (bool? newValue) {
          onChanged(newValue ?? false);
        },
      ),
      onTap: () {
        onChanged(!value);
      },
    );
  }
} 