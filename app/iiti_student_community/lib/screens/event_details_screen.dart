import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:iiti_student_community/models/event.dart';
import 'package:iiti_student_community/models/user.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:iiti_student_community/services/calendar_service.dart';

class EventDetailsPage extends StatefulWidget {
  final Event event;

  const EventDetailsPage({Key? key, required this.event}) : super(key: key);

  @override
  State<EventDetailsPage> createState() => _EventDetailsPageState();
}

class _EventDetailsPageState extends State<EventDetailsPage> {
  bool _isRegistering = false;
  late Stream<DocumentSnapshot> _eventStream;
  late Event _currentEvent;

  @override
  void initState() {
    super.initState();
    _currentEvent = widget.event;
    _eventStream =
        FirebaseFirestore.instance
            .collection('events')
            .doc(widget.event.id)
            .snapshots();
  }

  Future<void> _toggleRegistration() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to register')),
      );
      return;
    }

    setState(() => _isRegistering = true);

    try {
      final eventRef = FirebaseFirestore.instance
          .collection('events')
          .doc(_currentEvent.id);

      if (_currentEvent.attendees.contains(user.uid)) {
        await eventRef.update({
          'attendees': FieldValue.arrayRemove([user.uid]),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You have unregistered from this event'),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        await eventRef.update({
          'attendees': FieldValue.arrayUnion([user.uid]),
        });

        await CalendarService.addEventToCalendar(widget.event);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You are now registered for this event!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    } finally {
      setState(() => _isRegistering = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _eventStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Event Details')),
            body: const Center(child: Text('Something went wrong')),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(title: const Text('Event Details')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData && snapshot.data!.exists) {
          _currentEvent = Event.fromFirestore(snapshot.data!);
        }

        return Scaffold(
          appBar: AppBar(title: Text(_currentEvent.name), elevation: 0),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Event poster
                if (_currentEvent.posterUrl != null)
                  Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: NetworkImage(_currentEvent.posterUrl!),
                        fit: BoxFit.cover,
                      ),
                    ),
                  )
                else
                  Container(
                    height: 180,
                    width: double.infinity,
                    color: Theme.of(context).colorScheme.primaryContainer,
                    child: Center(
                      child: Icon(
                        Icons.event,
                        size: 80,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),

                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Event date and time
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 16,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              DateFormat(
                                'EEEE, MMM d, yyyy • h:mm a',
                              ).format(_currentEvent.dateTime),
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Event name
                      Text(
                        _currentEvent.name,
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),

                      const SizedBox(height: 16),

                      // Location
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _currentEvent.location,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Registration button
                      _buildRegistrationButton(),

                      const SizedBox(height: 24),

                      // Event description
                      if (_currentEvent.description != null) ...[
                        const Text(
                          'About This Event',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _currentEvent.description!,
                          style: const TextStyle(fontSize: 16, height: 1.5),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Map (if coordinates are available)
                      if (_currentEvent.coordinates != null) _buildMapView(),

                      const SizedBox(height: 24),

                      // Attendees
                      const Text(
                        'Attendees',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildAttendeesList(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRegistrationButton() {
    final user = FirebaseAuth.instance.currentUser;
    final isRegistered =
        user != null && _currentEvent.attendees.contains(user.uid);

    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        icon:
            _isRegistering
                ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                : Icon(
                  isRegistered ? Icons.check_circle : Icons.add_circle_outline,
                ),
        label: Text(
          isRegistered ? 'Registered' : 'Register Now',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isRegistered
                  ? Colors.green
                  : Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
        ),
        onPressed: _isRegistering ? null : _toggleRegistration,
      ),
    );
  }

  Widget _buildMapView() {
    final Set<Marker> markers = {
      Marker(
        markerId: const MarkerId('eventLocation'),
        position: _currentEvent.coordinates!,
        infoWindow: InfoWindow(
          title: _currentEvent.name,
          snippet: _currentEvent.location,
        ),
      ),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Location',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 200,
            width: double.infinity,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _currentEvent.coordinates!,
                zoom: 15,
              ),
              markers: markers,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAttendeesList() {
    if (_currentEvent.attendees.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16.0),
        child: Center(
          child: Text(
            'No attendees yet. Be the first to register!',
            style: TextStyle(
              fontSize: 16,
              fontStyle: FontStyle.italic,
              color: Colors.grey,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${_currentEvent.attendees.length} people attending',
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        StreamBuilder<QuerySnapshot>(
          stream:
              FirebaseFirestore.instance
                  .collection('users')
                  .where(FieldPath.documentId, whereIn: _currentEvent.attendees)
                  .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            final users =
                snapshot.data!.docs
                    .map((doc) => AppUser.fromFirestore(doc))
                    .toList();

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundImage:
                        user.photoUrl != null
                            ? NetworkImage(user.photoUrl!)
                            : null,
                    child:
                        user.photoUrl == null ? const Icon(Icons.person) : null,
                  ),
                  title: Text(
                    user.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(user.email),
                );
              },
            );
          },
        ),
      ],
    );
  }
}
