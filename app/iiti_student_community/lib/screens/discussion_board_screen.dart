import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:iiti_student_community/models/discussion_board.dart';

class DiscussionPostScreen extends StatefulWidget {
  final DiscussionPost post;

  const DiscussionPostScreen({Key? key, required this.post}) : super(key: key);

  @override
  State<DiscussionPostScreen> createState() => _DiscussionPostScreenState();
}

class _DiscussionPostScreenState extends State<DiscussionPostScreen> {
  final TextEditingController _commentController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final user = FirebaseAuth.instance.currentUser;
  bool _isLoading = true;
  List<Map<String, dynamic>> _comments = [];

  @override
  void initState() {
    super.initState();
    _fetchComments();
  }

  Future<void> _fetchComments() async {
    setState(() => _isLoading = true);
    
    try {
      final snapshot = await _firestore
          .collection('discussion_posts')
          .doc(widget.post.id)
          .collection('comments')
          .orderBy('timestamp', descending: false)
          .get();
      
      final comments = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'content': data['content'] ?? '',
          'userId': data['userId'] ?? '',
          'userEmail': data['userEmail'] ?? '',
          'timestamp': (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
        };
      }).toList();
      
      setState(() {
        _comments = comments;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching comments: $e')),
      );
    }
  }

  Future<void> _addComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    try {
      await _firestore
          .collection('discussion_posts')
          .doc(widget.post.id)
          .collection('comments')
          .add({
            'content': content,
            'timestamp': FieldValue.serverTimestamp(),
            'userId': user?.uid ?? '',
            'userEmail': user?.email ?? 'Anonymous',
          });

      _commentController.clear();
      _fetchComments();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding comment: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy • h:mm a');
    final isMyPost = widget.post.userId == user?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Discussion Post'),
        actions: [
          if (isMyPost)
            PopupMenuButton<String>(
              onSelected: (value) {
                // Implementation for edit/delete actions
                Navigator.pop(context);
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit Post')),
                const PopupMenuItem(value: 'delete', child: Text('Delete Post')),
              ],
            ),
        ],
      ),
      body: Column(
        children: [
          // Original post
          Card(
            margin: const EdgeInsets.all(12),
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Theme.of(context).primaryColor.withOpacity(0.8),
                        child: Text(
                          widget.post.userEmail.isNotEmpty ? widget.post.userEmail[0].toUpperCase() : '?',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.post.userEmail,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              dateFormat.format(widget.post.timestamp),
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.post.content,
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          ),

          // Comments section
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(Icons.comment, size: 20),
                SizedBox(width: 8),
                Text(
                  'Comments',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          
          // Comments list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _comments.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey[400]),
                            const SizedBox(height: 12),
                            Text(
                              'No comments yet',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Be the first to comment!',
                              style: TextStyle(color: Colors.grey[500], fontSize: 12),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: _comments.length,
                        itemBuilder: (context, index) {
                          final comment = _comments[index];
                          final isMyComment = comment['userId'] == user?.uid;
                          
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 14,
                                        backgroundColor: Colors.grey[300],
                                        child: Text(
                                          comment['userEmail'].toString().isNotEmpty
                                              ? comment['userEmail'][0].toUpperCase()
                                              : '?',
                                          style: TextStyle(fontSize: 12, color: Colors.grey[800]),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        comment['userEmail'],
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                      const Spacer(),
                                      Text(
                                        DateFormat('MMM d • h:mm a').format(comment['timestamp']),
                                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                      ),
                                      if (isMyComment)
                                        IconButton(
                                          icon: const Icon(Icons.more_vert, size: 16),
                                          onPressed: () {
                                            // Implementation for comment actions
                                          },
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(comment['content']),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),

          // Comment input field
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: 'Add a comment...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _addComment,
                  style: ElevatedButton.styleFrom(
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(12),
                  ),
                  child: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}