import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Club {
  final String id;
  final String name;
  final String? description;
  final String? photoUrl;
  final String? bannerUrl;
  bool isSubscribed;

  Club({
    required this.id,
    required this.name,
    this.description,
    this.photoUrl,
    this.bannerUrl,
    this.isSubscribed = false,
  });

  factory Club.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Club(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'],
      photoUrl: data['photoUrl'],
      bannerUrl: data['bannerUrl'],
      isSubscribed:
          data['subscribers']?.contains(
            FirebaseAuth.instance.currentUser?.uid,
          ) ??
          false,
    );
  }
}
