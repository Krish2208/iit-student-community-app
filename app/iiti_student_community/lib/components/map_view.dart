import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapViewScreen extends StatelessWidget {
  final LatLng location;
  final String title;

  const MapViewScreen({Key? key, required this.location, required this.title})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(target: location, zoom: 15),
        markers: {
          Marker(
            markerId: const MarkerId('location'),
            position: location,
            infoWindow: InfoWindow(title: title),
          ),
        },
      ),
    );
  }
}
