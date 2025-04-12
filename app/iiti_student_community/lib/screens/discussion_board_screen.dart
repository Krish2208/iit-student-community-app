import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:iiti_student_community/models/discussion_board.dart';
import 'package:cached_network_image/cached_network_image.dart';

class DiscussionPostScreen extends StatefulWidget {
  final DiscussionPost post;
  final Map<String, Map<String, dynamic>> userCache;
  final Function(BuildContext, String) onViewUserProfile;

  const DiscussionPostScreen({
    Key? key,
    required this.post,
    required this.userCache,
    required this.onViewUserProfile,
  }) : super(key: key);

  @override
  State<DiscussionPostScreen> createState() => _DiscussionPostScreenState();
}

class _DiscussionPostScreenState extends State<DiscussionPostScreen> {
  final TextEditingController _commentController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final user = FirebaseAuth.instance.currentUser;
  bool _isLoading = true;
  List<Map<String, dynamic>> _comments = [];
  Map<String, Map<String, dynamic>> _userCache = {};

  @override
  void initState() {
    super.initState();
    _userCache = Map.from(widget.userCache);
    _fetchComments();
  }

  Future<void> _fetchComments() async {
    setState(() => _isLoading = true);

    try {
      final snapshot =
          await _firestore
              .collection('discussion_posts')
              .doc(widget.post.id)
              .collection('comments')
              .orderBy('timestamp', descending: false)
              .get();

      final comments =
          snapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'id': doc.id,
              'content': data['content'] ?? '',
              'userId': data['userId'] ?? '',
              'userEmail': data['userEmail'] ?? '',
              'timestamp':
                  (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
            };
          }).toList();

      // Fetch user details for all comment authors
      final Set<String> userIds =
          comments.map((comment) => comment['userId'].toString()).toSet();
      await _fetchUserDetails(userIds);

      setState(() {
        _comments = comments;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error fetching comments: $e')));
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error adding comment: $e')));
    }
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

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy • h:mm a');
    final isMyPost = widget.post.userId == user?.uid;

    // Get user details from cache or use default
    final authorName = _userCache[widget.post.userId]?['name'] ?? 'Anonymous';
    final authorProfileImage =
        _userCache[widget.post.userId]?['photoUrl'] ?? '';

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
              itemBuilder:
                  (_) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Text('Edit Post'),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete Post'),
                    ),
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      InkWell(
                        onTap:
                            () => widget.onViewUserProfile(
                              context,
                              widget.post.userId,
                            ),
                        child: _buildProfileImage(
                          authorProfileImage,
                          authorName,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              authorName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
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
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _comments.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No comments yet',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Be the first to comment!',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12,
                            ),
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
                        final commentUserId = comment['userId'].toString();

                        // Get commenter details from cache
                        final commenterName =
                            _userCache[commentUserId]?['name'] ?? 'Anonymous';
                        final commenterImage =
                            _userCache[commentUserId]?['photoUrl'] ?? '';

                        return Card(
                          margin: const EdgeInsets.symmetric(
                            vertical: 4,
                            horizontal: 8,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    InkWell(
                                      onTap:
                                          () => widget.onViewUserProfile(
                                            context,
                                            commentUserId,
                                          ),
                                      child: _buildProfileImage(
                                        commenterImage,
                                        commenterName,
                                        size: 28,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      commenterName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      DateFormat(
                                        'MMM d • h:mm a',
                                      ).format(comment['timestamp']),
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                    if (isMyComment)
                                      IconButton(
                                        icon: const Icon(
                                          Icons.more_vert,
                                          size: 16,
                                        ),
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
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
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
