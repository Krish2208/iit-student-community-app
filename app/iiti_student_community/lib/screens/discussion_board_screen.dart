import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DiscussionBoardScreen extends StatefulWidget {
  const DiscussionBoardScreen({Key? key}) : super(key: key);

  @override
  State<DiscussionBoardScreen> createState() => _DiscussionBoardScreenState();
}

class _DiscussionBoardScreenState extends State<DiscussionBoardScreen> {
  final TextEditingController _postController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final user = FirebaseAuth.instance.currentUser;

  void _createPost() async {
    final content = _postController.text.trim();
    if (content.isEmpty) return;

    await _firestore.collection('discussion_posts').add({
      'content': content,
      'timestamp': FieldValue.serverTimestamp(),
      'userId': user?.uid,
      'userEmail': user?.email,
    });

    _postController.clear();
  }

  void _deletePost(String postId) async {
    await _firestore.collection('discussion_posts').doc(postId).delete();
  }

  void _editPost(String postId, String oldContent) {
    showDialog(
      context: context,
      builder: (_) {
        final controller = TextEditingController(text: oldContent);
        return AlertDialog(
          title: const Text('Edit Post'),
          content: TextField(
            controller: controller,
            maxLines: null,
            decoration: const InputDecoration(hintText: 'Update your post...'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                _firestore.collection('discussion_posts').doc(postId).update({
                  'content': controller.text.trim(),
                });
                Navigator.pop(context);
              },
              child: const Text('Update'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPostItem(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final isMyPost = data['userId'] == user?.uid;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: ListTile(
        title: Text(data['content']),
        subtitle: Text(data['userEmail'] ?? 'Anonymous'),
        trailing: isMyPost
            ? PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    _editPost(doc.id, data['content']);
                  } else if (value == 'delete') {
                    _deletePost(doc.id);
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  const PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              )
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Community Discussion Board'),
      ),
      body: Column(
        children: [
          // Post input field
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _postController,
                    maxLines: null,
                    decoration: const InputDecoration(
                      hintText: 'Share something with the community...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _createPost,
                ),
              ],
            ),
          ),
          const Divider(),

          // Posts list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('discussion_posts')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Something went wrong'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return const Center(child: Text('No posts yet'));
                }

                return ListView(
                  children: docs.map((doc) => _buildPostItem(doc)).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
