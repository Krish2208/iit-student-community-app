import 'package:flutter/material.dart';
import 'package:iiti_student_community/models/club.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:iiti_student_community/components/club_events.dart';

class ClubDetailsPage extends StatefulWidget {
  final String clubId;

  const ClubDetailsPage({Key? key, required this.clubId}) : super(key: key);

  @override
  State<ClubDetailsPage> createState() => _ClubDetailsPageState();
}

class _ClubDetailsPageState extends State<ClubDetailsPage> {
  bool _isSubscribing = false;

  Future<void> _toggleSubscription(Club club) async {
    if (_isSubscribing) return;

    setState(() {
      _isSubscribing = true;
    });

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You need to be logged in to subscribe'),
          ),
        );
        return;
      }

      final clubRef = FirebaseFirestore.instance
          .collection('clubs')
          .doc(club.id);

      if (club.isSubscribed) {
        // Unsubscribe
        await clubRef.update({
          'subscribers': FieldValue.arrayRemove([userId]),
        });
      } else {
        // Subscribe
        await clubRef.update({
          'subscribers': FieldValue.arrayUnion([userId]),
        });
      }

      // Update local state
      setState(() {
        club.isSubscribed = !club.isSubscribed;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    } finally {
      setState(() {
        _isSubscribing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<DocumentSnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('clubs')
                .doc(widget.clubId)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Club not found'));
          }

          final club = Club.fromFirestore(snapshot.data!);

          return CustomScrollView(
            slivers: [
              // Banner and App Bar
              SliverAppBar(
                expandedHeight: 200.0,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background:
                      club.bannerUrl != null
                          ? Image.network(club.bannerUrl!, fit: BoxFit.cover)
                          : Container(
                            color: Colors.grey[300],
                            child: const Center(
                              child: Icon(
                                Icons.image,
                                size: 50,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                ),
              ),

              // Club Info
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundImage:
                                club.photoUrl != null
                                    ? NetworkImage(club.photoUrl!)
                                    : null,
                            child:
                                club.photoUrl == null
                                    ? const Icon(Icons.groups, size: 40)
                                    : null,
                          ),
                          const SizedBox(width: 16.0),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  club.name,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () => _toggleSubscription(club),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  club.isSubscribed
                                      ? Colors.grey
                                      : Theme.of(context).primaryColor,
                            ),
                            child:
                                _isSubscribing
                                    ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                    : Text(
                                      club.isSubscribed
                                          ? 'Unsubscribe'
                                          : 'Subscribe',
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                          ),
                        ],
                      ),
                      if (club.description != null) ...[
                        const SizedBox(height: 16.0),
                        Text(
                          club.description!,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                      const SizedBox(height: 24.0),
                      const Text(
                        'Events',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Club Events
              SliverToBoxAdapter(child: ClubEventsSection(clubId: club.id)),
            ],
          );
        },
      ),
    );
  }
}
