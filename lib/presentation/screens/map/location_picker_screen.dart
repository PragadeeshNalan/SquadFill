import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:squadfill/core/theme/app_theme.dart';

/// A screen that allows users to pick a location using the free OpenStreetMap engine.
class LocationPickerScreen extends StatefulWidget {
  final double initialLat;
  final double initialLng;

  const LocationPickerScreen({
    super.key,
    required this.initialLat,
    required this.initialLng,
  });

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  late LatLng _selectedLocation;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _selectedLocation = LatLng(widget.initialLat, widget.initialLng);
  }

  /// Fetches current GPS position and moves the map camera.
  Future<void> _goToCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    Position position = await Geolocator.getCurrentPosition();
    final newPos = LatLng(position.latitude, position.longitude);

    _mapController.move(newPos, 15.0);
    setState(() {
      _selectedLocation = newPos;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pick Venue Location'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: AppTheme.primaryColor),
            onPressed: () => Navigator.pop(context, _selectedLocation),
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _selectedLocation,
              initialZoom: 15.0,
              onTap: (tapPosition, latLng) {
                setState(() {
                  _selectedLocation = latLng;
                });
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.squadfill.app',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _selectedLocation,
                    width: 80,
                    height: 80,
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.red,
                      size: 40,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            bottom: 24,
            right: 20,
            child: FloatingActionButton(
              backgroundColor: AppTheme.cardColor,
              child: const Icon(Icons.my_location, color: AppTheme.primaryColor),
              onPressed: _goToCurrentLocation,
            ),
          ),
        ],
      ),
    );
  }
}