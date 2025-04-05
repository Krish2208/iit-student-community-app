import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:iiti_student_community/models/discussion_board.dart';
import 'package:iiti_student_community/screens/discussion_board_screen.dart';

class DiscussionBoardTab extends StatefulWidget {
  const DiscussionBoardTab({super.key});

  @override
  State<DiscussionBoardTab> createState() => _DiscussionBoardTabState();
}

class _DiscussionBoardTabState extends State<DiscussionBoardTab> {
  final TextEditingController _postController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final user = FirebaseAuth.instance.currentUser;
  bool _isLoading = true;
  List<DiscussionPost> _posts = [];

  @override
  void initState() {
    super.initState();
    _fetchPosts();
  }

  Future<void> _fetchPosts() async {
    setState(() => _isLoading = true);
    try {
      final snapshot = await _firestore
          .collection('discussion_posts')
          .orderBy('timestamp', descending: true)
          .get();
      
      setState(() {
        _posts = snapshot.docs.map((doc) => DiscussionPost.fromFirestore(doc)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching posts: $e')),
      );
    }
  }

  void _createPost() async {
    final content = _postController.text.trim();
    if (content.isEmpty) return;

    try {
      await _firestore.collection('discussion_posts').add({
        'content': content,
        'timestamp': FieldValue.serverTimestamp(),
        'userId': user?.uid ?? '',
        'userEmail': user?.email ?? 'Anonymous',
      });

      _postController.clear();
      _fetchPosts();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating post: $e')),
      );
    }
  }

  void _deletePost(String postId) async {
    try {
      await _firestore.collection('discussion_posts').doc(postId).delete();
      _fetchPosts();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting post: $e')),
      );
    }
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
                _fetchPosts();
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

  void _navigateToPostDetail(DiscussionPost post) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DiscussionPostScreen(post: post),
      ),
    ).then((_) => _fetchPosts());
  }

  Widget _buildPostItem(DiscussionPost post) {
    final isMyPost = post.userId == user?.uid;
    final dateFormat = DateFormat('MMM d, yyyy • h:mm a');
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _navigateToPostDetail(post),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Theme.of(context).primaryColor.withOpacity(0.8),
                    child: Text(
                      post.userEmail.isNotEmpty ? post.userEmail[0].toUpperCase() : '?',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.userEmail,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          dateFormat.format(post.timestamp),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isMyPost)
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') {
                          _editPost(post.id, post.content);
                        } else if (value == 'delete') {
                          _deletePost(post.id);
                        }
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(value: 'edit', child: Text('Edit')),
                        const PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                post.content,
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Community Discussion'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchPosts,
          ),
        ],
      ),
      body: Column(
        children: [
          // Post input field
          Padding(
            padding: const EdgeInsets.all(12),
            child: Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
                      child: Text(
                        user?.email != null ? user!.email![0].toUpperCase() : '?',
                        style: TextStyle(color: Theme.of(context).primaryColor),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _postController,
                        maxLines: null,
                        decoration: const InputDecoration(
                          hintText: 'Share something with the community...',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.send, color: Theme.of(context).primaryColor),
                      onPressed: _createPost,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Divider(height: 0),

          // Posts list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _posts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.forum_outlined, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'No posts yet',
                              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Be the first to start a discussion!',
                              style: TextStyle(color: Colors.grey[500]),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _fetchPosts,
                        child: ListView.builder(
                          padding: const EdgeInsets.only(bottom: 16),
                          itemCount: _posts.length,
                          itemBuilder: (context, index) => _buildPostItem(_posts[index]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}