import 'package:cloud_firestore/cloud_firestore.dart';

class DiscussionPost {
  final String id;
  final String content;
  final String userId;
  final String userEmail;
  final DateTime timestamp;

  DiscussionPost({
    required this.id,
    required this.content,
    required this.userId,
    required this.userEmail,
    required this.timestamp,
  });

  factory DiscussionPost.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DiscussionPost(
      id: doc.id,
      content: data['content'] ?? '',
      userId: data['userId'] ?? '',
      userEmail: data['userEmail'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'content': content,
      'userId': userId,
      'userEmail': userEmail,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}
