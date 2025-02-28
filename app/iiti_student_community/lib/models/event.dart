import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class Event {
  final String id;
  final String name;
  final String? description;
  final String organizerId;
  final String location;
  final DateTime dateTime;
  final String? posterUrl;
  final LatLng? coordinates; // Add coordinates field

  String? organizerName;
  String? organizerPhotoUrl;

  Event({
    required this.id,
    required this.name,
    this.description,
    required this.organizerId,
    required this.location,
    required this.dateTime,
    this.posterUrl,
    this.coordinates,
    this.organizerName,
    this.organizerPhotoUrl,
  });

  factory Event.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // Parse coordinates if they exist
    LatLng? coordinates;
    if (data['coordinates'] != null) {
      final GeoPoint geoPoint = data['coordinates'] as GeoPoint;
      coordinates = LatLng(geoPoint.latitude, geoPoint.longitude);
    }

    return Event(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'],
      organizerId: data['organizerId'] ?? '',
      location: data['location'] ?? '',
      dateTime: (data['dateTime'] as Timestamp).toDate(),
      posterUrl: data['posterUrl'],
      coordinates: coordinates,
    );
  }

  Map<String, dynamic> toFirestore() {
    Map<String, dynamic> data = {
      'name': name,
      'description': description,
      'organizerId': organizerId,
      'location': location,
      'dateTime': Timestamp.fromDate(dateTime),
      'posterUrl': posterUrl,
    };

    // Add coordinates if they exist
    if (coordinates != null) {
      data['coordinates'] = GeoPoint(coordinates!.latitude, coordinates!.longitude);
    }

    return data;
  }
}
