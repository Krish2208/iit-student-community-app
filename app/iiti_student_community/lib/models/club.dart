import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:iiti_student_community/services/notification_service.dart';

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

  // Add this method to your Club class
  Future<void> toggleSubscriptionWithNotification(BuildContext context) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;
    
    final clubRef = FirebaseFirestore.instance.collection('clubs').doc(id);
    final NotificationService notificationService = NotificationService();
    
    if (!isSubscribed) {
      // Subscribe
      await clubRef.update({
        'subscribers': FieldValue.arrayUnion([userId]),
      });
      await notificationService.subscribeToClub(id);
      isSubscribed = true;
    } else {
      // Unsubscribe
      await clubRef.update({
        'subscribers': FieldValue.arrayRemove([userId]),
      });
      await notificationService.unsubscribeFromClub(id);
      isSubscribed = false;
    }
  }
}
