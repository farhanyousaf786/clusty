import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_database/firebase_database.dart' as rtdb;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;
import '../models/post_model.dart';
import '../utils/logger.dart';
import 'auth_provider.dart';

final postsProvider = StateNotifierProvider<PostsNotifier, AsyncValue<List<PostModel>>>((ref) {
  return PostsNotifier(ref);
});

class PostsNotifier extends StateNotifier<AsyncValue<List<PostModel>>> {
  final Ref _ref;
  final _database = rtdb.FirebaseDatabase.instance;
  final _storage = FirebaseStorage.instance;
  rtdb.DatabaseReference get _postsRef => _database.ref().child('posts');
  List<PostModel> _posts = [];
  rtdb.DatabaseReference? _currentListener;

  PostsNotifier(this._ref) : super(const AsyncValue.loading()) {
    _initPostsListener();
  }

  void _initPostsListener() {
    final currentUser = _ref.read(authProvider).value;
    if (currentUser == null) {
      state = const AsyncValue.data([]);
      return;
    }

    // Remove previous listener if exists
    _currentListener?.onValue.drain();
    _currentListener = null;

    // Set up new listener
    final query = _postsRef.orderByChild('timestamp');
    query.onValue.listen((event) {
      try {
        final postsData = event.snapshot.value as Map?;
        if (postsData == null) {
          _posts = [];
          state = const AsyncValue.data([]);
          return;
        }

        _posts = postsData.entries.map((entry) {
          final postData = Map<String, dynamic>.from(entry.value as Map);
          postData['id'] = entry.key;
          return PostModel.fromJson(postData);
        }).toList();

        // Sort by timestamp descending
        _posts.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        state = AsyncValue.data(_posts);
      } catch (e, stack) {
        state = AsyncValue.error(e, stack);
      }
    }, onError: (error, stack) {
      state = AsyncValue.error(error, stack);
    });
  }

  Future<String?> _uploadImage(File imageFile) async {
    try {
      final ext = path.extension(imageFile.path);
      final ref = _storage.ref().child('post_images/${DateTime.now().millisecondsSinceEpoch}$ext');
      await ref.putFile(imageFile);
      return await ref.getDownloadURL();
    } catch (e) {
      Logger.e('Error uploading image', e);
      return null;
    }
  }

  Future<void> addPost(String content, {File? imageFile, bool isMeme = false}) async {
    try {
      final currentUser = _ref.read(authProvider).value;
      if (currentUser == null) throw Exception('User must be logged in to post');

      String? imageUrl;
      if (imageFile != null) {
        imageUrl = await _uploadImage(imageFile);
        if (imageUrl == null) throw Exception('Failed to upload image');
      }

      final newPostRef = _postsRef.push();
      final post = PostModel(
        id: newPostRef.key!,
        userId: currentUser.id,
        username: currentUser.username,
        userPhotoUrl: currentUser.photoUrl,
        content: content,
        imageUrl: imageUrl,
        isMeme: isMeme,
        likes: 0,
        comments: 0,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );

      await newPostRef.set(post.toJson());

      // Update user's post count
      final userRef = _database.ref().child('users/${currentUser.id}');
      await userRef.child('postsCount').runTransaction((Object? value) {
        return rtdb.Transaction.success((value as int? ?? 0) + 1);
      });
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> likePost(String postId) async {
    try {
      final currentUser = _ref.read(authProvider).value;
      if (currentUser == null) throw Exception('User must be logged in to like posts');

      final postLikesRef = _database.ref().child('post-likes/$postId/${currentUser.id}');
      final likeSnapshot = await postLikesRef.get();
      
      final transaction = await _postsRef.child('$postId/likes').runTransaction((Object? value) {
        if (value == null) {
          return rtdb.Transaction.success(1);
        }
        return rtdb.Transaction.success((value as int) + (likeSnapshot.exists ? -1 : 1));
      });

      if (transaction.committed) {
        if (likeSnapshot.exists) {
          await postLikesRef.remove();
        } else {
          await postLikesRef.set({
            'timestamp': rtdb.ServerValue.timestamp,
          });
        }
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addComment(String postId, String comment) async {
    try {
      final currentUser = _ref.read(authProvider).value;
      if (currentUser == null) throw Exception('User must be logged in to comment');

      final commentsRef = _database.ref().child('post-comments/$postId');
      final newCommentRef = commentsRef.push();
      
      await newCommentRef.set({
        'userId': currentUser.id,
        'username': currentUser.username,
        'userPhotoUrl': currentUser.photoUrl,
        'comment': comment,
        'timestamp': rtdb.ServerValue.timestamp,
      });

      // Update comment count
      await _postsRef.child('$postId/comments').runTransaction((Object? value) {
        if (value == null) {
          return rtdb.Transaction.success(1);
        }
        return rtdb.Transaction.success((value as int) + 1);
      });
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<List<Map<String, dynamic>>> getComments(String postId) async {
    try {
      final commentsRef = _database.ref().child('post-comments/$postId');
      final snapshot = await commentsRef.orderByChild('timestamp').get();
      
      if (!snapshot.exists) return [];

      final commentsData = Map<String, dynamic>.from(snapshot.value as Map);
      return commentsData.entries.map((entry) {
        final data = Map<String, dynamic>.from(entry.value as Map);
        data['id'] = entry.key;
        return data;
      }).toList();
    } catch (e) {
      Logger.e('Error fetching comments', e);
      return [];
    }
  }

  Future<bool> hasUserLiked(String postId) async {
    try {
      final currentUser = _ref.read(authProvider).value;
      if (currentUser == null) return false;

      final likeRef = _database.ref().child('post-likes/$postId/${currentUser.id}');
      final snapshot = await likeRef.get();
      return snapshot.exists;
    } catch (e) {
      Logger.e('Error checking like status', e);
      return false;
    }
  }
}
