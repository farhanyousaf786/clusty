import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/post_model.dart';

final postsProvider = StateNotifierProvider<PostsNotifier, AsyncValue<List<PostModel>>>((ref) {
  return PostsNotifier();
});

class PostsNotifier extends StateNotifier<AsyncValue<List<PostModel>>> {
  PostsNotifier() : super(const AsyncValue.loading()) {
    loadPosts();
  }

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> loadPosts() async {
    try {
      state = const AsyncValue.loading();
      final snapshot = await _firestore
          .collection('posts')
          .orderBy('createdAt', descending: true)
          .get();

      final posts = snapshot.docs
          .map((doc) => PostModel.fromJson({...doc.data(), 'id': doc.id}))
          .toList();

      state = AsyncValue.data(posts);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> createPost(String content, String userId, {String? imageUrl}) async {
    try {
      final post = PostModel(
        id: '', // Firestore will generate this
        userId: userId,
        content: content,
        imageUrl: imageUrl,
        createdAt: DateTime.now(),
      );

      final docRef = await _firestore.collection('posts').add(post.toJson());
      
      // Reload posts to get the latest data
      await loadPosts();
    } catch (error) {
      rethrow;
    }
  }

  Future<void> likePost(String postId, String userId) async {
    try {
      final postRef = _firestore.collection('posts').doc(postId);
      final post = await postRef.get();
      
      if (post.exists) {
        final likes = List<String>.from(post.data()?['likes'] ?? []);
        
        if (likes.contains(userId)) {
          likes.remove(userId);
        } else {
          likes.add(userId);
        }
        
        await postRef.update({'likes': likes});
        await loadPosts();
      }
    } catch (error) {
      rethrow;
    }
  }

  Future<void> deletePost(String postId) async {
    try {
      await _firestore.collection('posts').doc(postId).delete();
      await loadPosts();
    } catch (error) {
      rethrow;
    }
  }
}
