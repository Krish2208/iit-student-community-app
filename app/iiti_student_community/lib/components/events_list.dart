import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:iiti_student_community/models/event.dart';
import 'package:iiti_student_community/components/event_card.dart';

class EventsListSection extends StatelessWidget {
  const EventsListSection({Key? key}) : super(key: key);

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
          .where('dateTime', isGreaterThanOrEqualTo: Timestamp.fromDate(today))
          .orderBy('dateTime', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No events found'));
        }

        // Convert the documents to Event objects
        final events = snapshot.data!.docs
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
  }
}
