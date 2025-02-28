import 'package:flutter/material.dart';
import 'package:iiti_student_community/components/subscribed_event.dart';
import 'package:iiti_student_community/screens/tabs/clubs_events.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Events & Clubs')),
      body: Column(
        children: [
          // Events from subscribed clubs section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                const Text(
                  'Upcoming Events',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ClubsEventsTab(),
                      ),
                    );
                  },
                  child: const Text('See All Events'),
                ),
              ],
            ),
          ),

          // Events list from subscribed clubs
          Expanded(
            child: SubscribedEventsSection(),
          ),
        ],
      ),
    );
  }
}