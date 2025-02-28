import 'package:flutter/material.dart';
import 'package:iiti_student_community/components/events_list.dart';
import 'package:iiti_student_community/components/clubs_grid.dart';

class ClubsEventsTab extends StatelessWidget {
  const ClubsEventsTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Clubs & Events')),
      body: Column(
        children: [
          // Clubs section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Clubs',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12.0),
                ClubsGridSection(),
              ],
            ),
          ),

          // Events section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: const Text(
              'Upcoming Events',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),

          // Events list
          Expanded(child: EventsListSection()),
        ],
      ),
    );
  }
}
