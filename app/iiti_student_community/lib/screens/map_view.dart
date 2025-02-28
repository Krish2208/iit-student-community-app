import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:iiti_student_community/models/event.dart';

class MapViewPage extends StatefulWidget {
  final Event event;

  const MapViewPage({Key? key, required this.event}) : super(key: key);

  @override
  State<MapViewPage> createState() => _MapViewPageState();
}

class _MapViewPageState extends State<MapViewPage> {
  late GoogleMapController mapController;

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.event.coordinates == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Location')),
        body: const Center(child: Text('No coordinates available')),
      );
    }

    final Set<Marker> markers = {
      Marker(
        markerId: MarkerId(widget.event.id),
        position: widget.event.coordinates!,
        infoWindow: InfoWindow(
          title: widget.event.name,
          snippet: widget.event.location,
        ),
      ),
    };

    return Scaffold(
      appBar: AppBar(title: Text(widget.event.location)),
      body: GoogleMap(
        onMapCreated: _onMapCreated,
        initialCameraPosition: CameraPosition(
          target: widget.event.coordinates!,
          zoom: 15.0,
        ),
        markers: markers,
      ),
    );
  }
}
