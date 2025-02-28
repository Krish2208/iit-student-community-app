import 'package:flutter/material.dart';
import 'package:iiti_student_community/models/event.dart';
import 'package:iiti_student_community/screens/map_view.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:iiti_student_community/screens/clubs_details_screen.dart';
import 'package:iiti_student_community/screens/event_details_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EventCard extends StatelessWidget {
  final Event event;
  final bool showOrganizer;

  const EventCard({Key? key, required this.event, this.showOrganizer = true})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('E, MMM d, yyyy • h:mm a');
    final isRegistered = event.attendees.contains(
      FirebaseAuth.instance.currentUser?.uid,
    );

    return GestureDetector(
      onTap:
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EventDetailsPage(event: event),
            ),
          ),
      child: Card(
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
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12.0),
                ),
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
                  // Event Name and Register button in a row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Event Name with flexible width
                      Expanded(
                        child: Text(
                          event.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      // Register button
                      GestureDetector(
                        onTap:
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => EventDetailsPage(event: event),
                              ),
                            ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12.0,
                            vertical: 6.0,
                          ),
                          decoration: BoxDecoration(
                            color: isRegistered ? Colors.green : Colors.blue,
                            borderRadius: BorderRadius.circular(20.0),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isRegistered
                                    ? Icons.check
                                    : Icons.event_available,
                                color: Colors.white,
                                size: 16.0,
                              ),
                              const SizedBox(width: 4.0),
                              Text(
                                isRegistered ? 'Registered' : 'Register',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12.0,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8.0),

                  // Date and Time
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 8.0),
                      Text(
                        dateFormat.format(event.dateTime),
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                    ],
                  ),
                  // Location with optional map button
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 16,
                        color: Colors.red,
                      ),
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
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
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

                  // Organizer with Avatar (optional)
                  if (showOrganizer) ...[
                    FutureBuilder<DocumentSnapshot>(
                      future:
                          FirebaseFirestore.instance
                              .collection('clubs')
                              .doc(event.organizerId)
                              .get(),
                      builder: (context, snapshot) {
                        String organizerName = 'Unknown Club';
                        String? organizerPhotoUrl;

                        if (snapshot.hasData && snapshot.data!.exists) {
                          final data =
                              snapshot.data!.data() as Map<String, dynamic>;
                          organizerName = data['name'] ?? 'Unknown Club';
                          organizerPhotoUrl = data['photoUrl'];
                        }

                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => ClubDetailsPage(
                                      clubId: event.organizerId,
                                    ),
                              ),
                            );
                          },
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundImage:
                                    organizerPhotoUrl != null
                                        ? NetworkImage(organizerPhotoUrl)
                                        : null,
                                child:
                                    organizerPhotoUrl == null
                                        ? const Icon(Icons.groups, size: 16)
                                        : null,
                              ),
                              const SizedBox(width: 8.0),
                              Expanded(
                                child: Text(
                                  'Organized by: $organizerName',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
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
      ),
    );
  }
}
