import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:weather_app/models/location_manager.dart';
import 'package:weather_app/services/reverse_geocoding.dart';

class HoldContextMenu extends StatefulWidget {
  final Offset? tapPosition;
  final LatLng? tapLatLng;
  final VoidCallback onClose;

  const HoldContextMenu({
    super.key,
    required this.tapPosition,
    required this.tapLatLng,
    required this.onClose,
  });

  @override
  State<HoldContextMenu> createState() => _HoldContextMenu();
}

class _HoldContextMenu extends State<HoldContextMenu> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: widget.tapPosition!.dx,
      top: widget.tapPosition!.dy,
      width: 150.0,
      height: 120.0,
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
                title: const Text(
                  'Add Pin',
                  style: TextStyle(color: Colors.black, fontSize: 14),
                ),
                onTap: () async {
                  // Do something with _tapLatLng
                  await LocationManager().addLocationLatLng(widget.tapLatLng!);
                  widget.onClose();
                },
              ),
              ListTile(
                title: const Text(
                  'Open Weather',
                  style: TextStyle(color: Colors.black, fontSize: 14),
                ),
                onTap: () async {
                  // Do something with _tapLatLng
                  Map<String, dynamic> location = await ReverseGeocoding()
                      .getLocation(widget.tapLatLng!);
                  String chosenName = "";
                  if (location['city'] != null) {
                    chosenName = location['city'];
                  } else if (location['county'] != null) {
                    chosenName = location['county'];
                  } else {
                    chosenName = "UK";
                  }

                  // Navigate to the detailed weather view, passing the name and coordinates
                  await Navigator.pushNamed(
                    context,
                    '/weather/detail',
                    arguments:
                        "${widget.tapLatLng!.latitude},${widget.tapLatLng!.longitude},$chosenName",
                  );
                  widget.onClose();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
