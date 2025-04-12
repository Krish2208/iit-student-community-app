import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:iiti_student_community/models/discussion_board.dart';
import 'package:iiti_student_community/screens/discussion_board_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';

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
  Map<String, Map<String, dynamic>> _userCache = {};

  @override
  void initState() {
    super.initState();
    _fetchPosts();
  }

  Future<void> _fetchPosts() async {
    setState(() => _isLoading = true);
    try {
      final snapshot =
          await _firestore
              .collection('discussion_posts')
              .orderBy('timestamp', descending: true)
              .get();

      final posts =
          snapshot.docs
              .map((doc) => DiscussionPost.fromFirestore(doc))
              .toList();

      // Fetch user details for all post authors
      final Set<String> userIds = posts.map((post) => post.userId).toSet();
      await _fetchUserDetails(userIds);

      setState(() {
        _posts = posts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error fetching posts: $e')));
    }
  }

  Future<void> _fetchUserDetails(Set<String> userIds) async {
    for (final userId in userIds) {
      // Skip if we already have this user in cache or userId is empty
      if (_userCache.containsKey(userId) || userId.isEmpty) continue;

      try {
        final userDoc = await _firestore.collection('users').doc(userId).get();
        if (userDoc.exists) {
          _userCache[userId] = {
            'name': userDoc.data()?['name'] ?? 'Anonymous',
            'photoUrl': userDoc.data()?['photoUrl'] ?? '',
            'email': userDoc.data()?['email'] ?? '',
          };
        } else {
          _userCache[userId] = {
            'name': 'Anonymous',
            'photoUrl': '',
            'email': '',
          };
        }
      } catch (e) {
        print('Error fetching user details: $e');
        _userCache[userId] = {
          'name': 'Anonymous',
          'photoUrl': '',
          'email': '',
        };
      }
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error creating post: $e')));
    }
  }

  void _deletePost(String postId) async {
    try {
      await _firestore.collection('discussion_posts').doc(postId).delete();
      _fetchPosts();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error deleting post: $e')));
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
        builder:
            (context) => DiscussionPostScreen(
              post: post,
              userCache: _userCache,
              onViewUserProfile: _showUserProfileBottomSheet,
            ),
      ),
    ).then((_) => _fetchPosts());
  }

  void _showUserProfileBottomSheet(BuildContext context, String userId) {
    final userData =
        _userCache[userId] ??
        {'name': 'Anonymous', 'email': '', 'photoUrl': ''};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  margin: const EdgeInsets.only(bottom: 24),
                ),
                _buildProfileImage(
                  userData['photoUrl'],
                  userData['name'],
                  size: 80,
                ),
                const SizedBox(height: 16),
                Text(
                  userData['name'],
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (userData['email'].isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    userData['email'],
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ],
                const SizedBox(height: 32),
                // You can add more user information here if needed
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Close'),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
    );
  }

  Widget _buildProfileImage(String? imageUrl, String name, {double size = 40}) {
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: imageUrl,
        imageBuilder:
            (context, imageProvider) => Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(image: imageProvider, fit: BoxFit.cover),
              ),
            ),
        placeholder:
            (context, url) => CircleAvatar(
              radius: size / 2,
              backgroundColor: Theme.of(context).primaryColor.withAlpha(50),
              child: const CircularProgressIndicator(),
            ),
        errorWidget:
            (context, url, error) => _buildNameAvatar(name, size: size),
      );
    } else {
      return _buildNameAvatar(name, size: size);
    }
  }

  Widget _buildNameAvatar(String name, {double size = 40}) {
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: Theme.of(context).primaryColor.withAlpha(200),
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: TextStyle(color: Colors.white, fontSize: size * 0.4),
      ),
    );
  }

  Widget _buildPostItem(DiscussionPost post) {
    final isMyPost = post.userId == user?.uid;
    final dateFormat = DateFormat('MMM d, yyyy • h:mm a');

    // Get user details from cache or use default
    final userName = _userCache[post.userId]?['name'] ?? 'Anonymous';
    final profileImage = _userCache[post.userId]?['photoUrl'] ?? '';

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
                  InkWell(
                    onTap:
                        () => _showUserProfileBottomSheet(context, post.userId),
                    child: _buildProfileImage(profileImage, userName),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName,
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
                      itemBuilder:
                          (_) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Text('Edit'),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text('Delete'),
                            ),
                          ],
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(post.content, style: const TextStyle(fontSize: 16)),
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
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchPosts),
        ],
      ),
      body: Column(
        children: [
          // Post input field
          Padding(
            padding: const EdgeInsets.all(12),
            child: Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    _buildProfileImage(
                      user?.photoURL ?? '',
                      user?.displayName ?? 'Anonymous',
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
                      icon: Icon(
                        Icons.send,
                        color: Theme.of(context).primaryColor,
                      ),
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
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _posts.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.forum_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No posts yet',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
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
                        itemBuilder:
                            (context, index) => _buildPostItem(_posts[index]),
                      ),
                    ),
          ),
        ],
      ),
    );
  }
}
