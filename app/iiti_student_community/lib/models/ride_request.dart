import 'package:cloud_firestore/cloud_firestore.dart';

class RideRequest {
  final String id;
  final String userId;
  final String locationName;
  final GeoPoint location;
  final DateTime dateTime;
  final DateTime createdAt;
  final String? notes;
  final int seats;

  RideRequest({
    required this.id,
    required this.userId,
    required this.locationName,
    required this.location,
    required this.dateTime,
    required this.createdAt,
    this.notes,
    required this.seats,
  });

  factory RideRequest.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return RideRequest(
      id: doc.id,
      userId: data['userId'] ?? '',
      locationName: data['locationName'] ?? '',
      location: data['location'] ?? const GeoPoint(0, 0),
      dateTime: (data['dateTime'] as Timestamp).toDate(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      notes: data['notes'],
      seats: data['seats'] ?? 1,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'locationName': locationName,
      'location': location,
      'dateTime': Timestamp.fromDate(dateTime),
      'createdAt': Timestamp.fromDate(createdAt),
      'notes': notes,
      'seats': seats,
    };
  }
}
