import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:iiti_student_community/models/discussion_board.dart';
import 'package:iiti_student_community/screens/discussion_board_screen.dart';

class DiscussionBoardTab extends StatefulWidget {
  const DiscussionBoardTab({super.key});

  @override
  State<DiscussionBoardTab> createState() => _DiscussionBoardTabState();
}

class _DiscussionBoardTabState extends State<DiscussionBoardTab> {
  List<DiscussionPost> _posts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPosts();
  }

  Future<void> _fetchPosts() async {
    try {
      final snapshot = await FirebaseFirestore.instance
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

  void _navigateToPostScreen([DiscussionPost? post]) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DiscussionPostScreen(post: post),
      ),
    );
    _fetchPosts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Discussion Board'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _posts.isEmpty
              ? const Center(child: Text('No posts yet.'))
              : RefreshIndicator(
                  onRefresh: _fetchPosts,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _posts.length,
                    itemBuilder: (context, index) {
                      final post = _posts[index];
                      return Card(
                        elevation: 3,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          title: Text(post.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(post.authorName),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () => _navigateToPostScreen(post),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToPostScreen(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
