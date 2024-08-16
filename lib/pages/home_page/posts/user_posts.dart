import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../models/post_model.dart';
import '../../../providers/follow_provder.dart';
import '../../../utils/app_constants.dart';

class UserPosts extends StatelessWidget {
  final List<Post> posts;

  const UserPosts({Key? key, required this.posts}) : super(key: key);

  void likePost(BuildContext context, Post post) async {
    final followProvider = Provider.of<FollowProvider>(context, listen: false);
    final userId = followProvider.user?.uid;

    if (userId != null) {
      final postRef = FirebaseFirestore.instance.collection('posts').doc(post.id);
      final userPostRef = FirebaseFirestore.instance
          .collection('users')
          .doc(post.userId)
          .collection('user_posts')
          .doc(post.id);

      FirebaseFirestore.instance.runTransaction((transaction) async {
        final postSnapshot = await transaction.get(postRef);
        final userPostSnapshot = await transaction.get(userPostRef);

        if (postSnapshot.exists && userPostSnapshot.exists) {
          final likes = List<String>.from(postSnapshot['likes'] ?? []);

          if (likes.contains(userId)) {
            likes.remove(userId);
          } else {
            likes.add(userId);
          }

          transaction.update(postRef, {'likes': likes});
          transaction.update(userPostRef, {'likes': likes});
        }
      });
    }
  }



  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final post = posts[index];
        final userImageUrl = post.userImageUrl.isNotEmpty
            ? post.userImageUrl
            : AppConstants.defaultImageUrl;
        final followProvider = Provider.of<FollowProvider>(context, listen: false);
        final userId = followProvider.user?.uid;

        return Card(
          margin: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundImage: NetworkImage(userImageUrl),
                    ),
                    SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.username,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          timeago.format(post.createdAt.toDate()),
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Text(
                  post.caption,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Image.network(post.imageUrl),
                SizedBox(height: 10),
                Text(post.description),
                SizedBox(height: 10),
                Text(
                  post.mood,
                  style: TextStyle(color: Colors.grey),
                ),
                Wrap(
                  spacing: 6.0,
                  runSpacing: 6.0,
                  children: post.tags.map((tag) {
                    return Chip(
                      label: Text(tag),
                    );
                  }).toList(),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.thumb_up,
                        color: post.likes.contains(userId) ? Colors.blue : Colors.grey,
                      ),
                      onPressed: () => likePost(context, post),
                    ),
                    Text(post.likes.length.toString()),

                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
