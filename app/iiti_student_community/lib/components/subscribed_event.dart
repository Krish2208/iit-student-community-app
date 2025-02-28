import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:iiti_student_community/models/event.dart';
import 'package:iiti_student_community/components/event_card.dart';

class SubscribedEventsSection extends StatelessWidget {
  const SubscribedEventsSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      return const Center(
        child: Text('Please sign in to see events from your subscribed clubs'),
      );
    }

    // Get today's date at midnight (00:00:00)
    final DateTime today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('clubs')
          .where('subscribers', arrayContains: userId)
          .snapshots(),
      builder: (context, clubsSnapshot) {
        if (clubsSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (clubsSnapshot.hasError) {
          return Center(child: Text('Error: ${clubsSnapshot.error}'));
        }

        if (!clubsSnapshot.hasData || clubsSnapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text('Subscribe to clubs to see their events here'),
          );
        }

        // Get list of club IDs the user is subscribed to
        final clubIds = clubsSnapshot.data!.docs.map((doc) => doc.id).toList();

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('events')
              .where('organizerId', whereIn: clubIds)
              .where('dateTime', isGreaterThanOrEqualTo: Timestamp.fromDate(today))
              .orderBy('dateTime', descending: false)
              .snapshots(),
          builder: (context, eventsSnapshot) {
            if (eventsSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (eventsSnapshot.hasError) {
              return Center(child: Text('Error: ${eventsSnapshot.error}'));
            }

            if (!eventsSnapshot.hasData || eventsSnapshot.data!.docs.isEmpty) {
              return const Center(
                child: Text('No upcoming events from your subscribed clubs'),
              );
            }

            // Convert the documents to Event objects
            final events = eventsSnapshot.data!.docs
                .map((doc) => Event.fromFirestore(doc))
                .toList();

            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: events.length,
              itemBuilder: (context, index) {
                final event = events[index];
                return EventCard(event: event);
              },
            );
          },
        );
      },
    );
  }
}
