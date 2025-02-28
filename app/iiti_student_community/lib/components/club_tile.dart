import 'package:flutter/material.dart';
import 'package:iiti_student_community/models/club.dart';
import 'package:iiti_student_community/screens/clubs_details_screen.dart';

class ClubTile extends StatelessWidget {
  final Club club;

  const ClubTile({Key? key, required this.club}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ClubDetailsPage(clubId: club.id),
          ),
        );
      },
      child: Card(
        elevation: 3.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 30,
              backgroundImage: club.photoUrl != null
                  ? NetworkImage(club.photoUrl!)
                  : null,
              child: club.photoUrl == null
                  ? const Icon(Icons.groups, size: 30)
                  : null,
            ),
            const SizedBox(height: 8.0),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                club.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
