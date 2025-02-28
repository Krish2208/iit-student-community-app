import 'package:flutter/material.dart';
import 'package:iiti_student_community/models/event.dart';
import 'package:iiti_student_community/screens/map_view.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:iiti_student_community/screens/clubs_details_screen.dart';

class EventCard extends StatelessWidget {
  final Event event;
  final bool showOrganizer;

  const EventCard({
    Key? key,
    required this.event,
    this.showOrganizer = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('E, MMM d, yyyy • h:mm a');

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 4.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Event Poster (if available)
          if (event.posterUrl != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12.0)),
              child: Image.network(
                event.posterUrl!,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 100,
                    color: Colors.grey[300],
                    child: const Center(
                      child: Icon(Icons.error, color: Colors.grey),
                    ),
                  );
                },
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Event Name
                Text(
                  event.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8.0),

                // Date and Time
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 16, color: Colors.blue),
                    const SizedBox(width: 8.0),
                    Text(
                      dateFormat.format(event.dateTime),
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ],
                ),

                const SizedBox(height: 8.0),

                // Location with optional map button
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Colors.red),
                    const SizedBox(width: 8.0),
                    Expanded(
                      child: Text(
                        event.location,
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                    ),
                    if (event.coordinates != null)
                      IconButton(
                        icon: const Icon(Icons.map, color: Colors.blue),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MapViewPage(event: event),
                            ),
                          );
                        },
                        tooltip: 'View on map',
                      ),
                  ],
                ),

                // Description (if available)
                if (event.description != null) ...[
                  const SizedBox(height: 12.0),
                  Text(
                    event.description!,
                    style: TextStyle(color: Colors.grey[800]),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                // Organizer with Avatar (optional)
                if (showOrganizer) ...[
                  const SizedBox(height: 16.0),
                  FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('clubs')
                        .doc(event.organizerId)
                        .get(),
                    builder: (context, snapshot) {
                      String organizerName = 'Unknown Club';
                      String? organizerPhotoUrl;

                      if (snapshot.hasData && snapshot.data!.exists) {
                        final data = snapshot.data!.data() as Map<String, dynamic>;
                        organizerName = data['name'] ?? 'Unknown Club';
                        organizerPhotoUrl = data['photoUrl'];
                      }

                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ClubDetailsPage(clubId: event.organizerId),
                            ),
                          );
                        },
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundImage: organizerPhotoUrl != null
                                  ? NetworkImage(organizerPhotoUrl)
                                  : null,
                              child: organizerPhotoUrl == null
                                  ? const Icon(Icons.groups, size: 16)
                                  : null,
                            ),
                            const SizedBox(width: 8.0),
                            Text(
                              'Organized by: $organizerName',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
