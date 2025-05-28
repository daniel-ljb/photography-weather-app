import 'package:flutter/material.dart';
import '../services/weather_service.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';

class WeatherSearchBarController {
  void Function()? _removeOverlayInternal;

  void removeOverlay() {
    _removeOverlayInternal?.call();
  }
}

class WeatherSearchBar extends StatefulWidget {
  final TextEditingController controller;
  final WeatherSearchBarController weathersearchbarcontroller;
  final String hintText;
  final Function(Map<String, dynamic>)? onLocationSelected;


  const WeatherSearchBar({
    super.key,
    required this.controller,
    required this.weathersearchbarcontroller,
    this.hintText = 'Search location...',
    this.onLocationSelected,
  });

  @override
  State<WeatherSearchBar> createState() => _WeatherSearchBarState();
}

class _WeatherSearchBarState extends State<WeatherSearchBar> {
  final WeatherService _weatherService = WeatherService();
  final LatLngBounds mapBounds = LatLngBounds(LatLng(62, -15),  LatLng(40, 10));
  final FocusNode _focusNode = FocusNode();

  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onSearchChanged);
    widget.weathersearchbarcontroller._removeOverlayInternal = _removeOverlay;
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onSearchChanged);
    widget.weathersearchbarcontroller._removeOverlayInternal = null;
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      _removeOverlay();
    }
  }

  void _onSearchChanged() {
    _performSearch(widget.controller.text);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      _removeOverlay();
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final results = await _weatherService.searchLocations(query);
      setState(() {
        _searchResults = results.where((location) => mapBounds.contains(LatLng(location["lat"], location["lon"]))).toList();
        _isSearching = false;
      });
      _showOverlay();
    } catch (e) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      _removeOverlay();
    }
  }

  void _showOverlay() {
    _removeOverlay();
    if (_searchResults.isEmpty) return;

    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, size.height - 1),
          child: Material(
            elevation: 4,
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12), top: Radius.circular(12)),
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.4,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(12), top: Radius.circular(12)),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final location = _searchResults[index];
                  return ListTile(
                    title: Text(location['name']),
                    subtitle: Text('${location['region']}, ${location['country']}'),
                    onTap: () {
                      widget.onLocationSelected?.call(location);
                      _removeOverlay();
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            TextField(
              controller: widget.controller,
              focusNode: _focusNode,
              decoration: InputDecoration(
                hintText: widget.hintText,
                prefixIcon: const Icon(Icons.search),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
            if (widget.controller.text.isNotEmpty)
              Positioned(
                right: 8,
                top: 0,
                bottom: 0,
                child: Center(
                  child: IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: () {
                      widget.controller.clear();
                      _removeOverlay();
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
} 