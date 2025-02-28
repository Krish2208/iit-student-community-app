import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:iiti_student_community/components/event_card.dart';
import 'package:iiti_student_community/models/event.dart';

class ClubEventsSection extends StatelessWidget {
  final String clubId;

  const ClubEventsSection({Key? key, required this.clubId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final DateTime today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('events')
          .where('organizerId', isEqualTo: clubId)
          .where('dateTime', isGreaterThanOrEqualTo: Timestamp.fromDate(today))
          .orderBy('dateTime', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox(
            height: 200,
            child: Center(child: Text('No events found for this club')),
          );
        }

        // Convert the documents to Event objects
        final events = snapshot.data!.docs
            .map((doc) => Event.fromFirestore(doc))
            .toList();

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          itemCount: events.length,
          itemBuilder: (context, index) {
            final event = events[index];
            // Pass the club ID to avoid fetching club details again
            return EventCard(
              event: event,
              showOrganizer: false, // No need to show organizer in club page
            );
          },
        );
      },
    );
  }
}
