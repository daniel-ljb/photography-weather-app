import 'package:flutter/material.dart';

class LayerToggleWidget extends StatelessWidget {
  final bool value;
  final String text;
  final IconData icon;
  final VoidCallback onToggle;

  const LayerToggleWidget({
    super.key,
    required this.value,
    required this.text,
    required this.icon,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(text),
      trailing: Checkbox(
        value: value,
        onChanged: (bool? newValue) {
          onToggle();
        },
      ),
      onTap: onToggle,
    );
  }
}