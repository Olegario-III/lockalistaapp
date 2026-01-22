// lib/features/stores/pick_location_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PickLocationPage extends StatefulWidget {
  const PickLocationPage({super.key});

  @override
  State<PickLocationPage> createState() => _PickLocationPageState();
}

class _PickLocationPageState extends State<PickLocationPage> {
  LatLng? selectedLatLng;

  // Binangonan bounds
  final LatLngBounds binangonanBounds = LatLngBounds(
    LatLng(14.4546, 121.1808), // southwest
    LatLng(14.6131, 121.2267), // northeast
  );

  bool _isInsideBounds(LatLng pos) {
    return pos.latitude >= binangonanBounds.south &&
        pos.latitude <= binangonanBounds.north &&
        pos.longitude >= binangonanBounds.west &&
        pos.longitude <= binangonanBounds.east;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pick Store Location'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: selectedLatLng == null
                ? null
                : () {
                    Navigator.pop(
                        context,
                        GeoPoint(
                            selectedLatLng!.latitude,
                            selectedLatLng!.longitude));
                  },
          )
        ],
      ),
      body: FlutterMap(
        options: MapOptions(
          center: LatLng(14.534, 121.204),
          zoom: 13,
          maxZoom: 18,
          minZoom: 12,
          onTap: (tapPos, latLng) {
            if (_isInsideBounds(latLng)) {
              setState(() => selectedLatLng = latLng);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please pick a location inside Binangonan'),
                ),
              );
            }
          },
        ),
        children: [
          TileLayer(
            urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
            subdomains: const ['a', 'b', 'c'],
            userAgentPackageName: 'com.example.lockalista',
          ),
          if (selectedLatLng != null)
            MarkerLayer(
              markers: [
                Marker(
                  width: 80,
                  height: 80,
                  point: selectedLatLng!,
                  builder: (ctx) => const Icon(
                    Icons.location_on,
                    color: Colors.red,
                    size: 40,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
