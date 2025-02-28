import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String id;
  final String name;
  final String email;
  final String? photoUrl;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.photoUrl,
  });

  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return AppUser(
      id: doc.id,
      name: data['name'],
      email: data['email'],
      photoUrl: data['photoUrl'],
    );
  }
}
