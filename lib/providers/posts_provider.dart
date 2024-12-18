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

final userPostsProvider = StreamProvider.family<List<PostModel>, String?>((ref, userId) async* {
  if (userId == null) {
    yield [];
    return;
  }

  final database = rtdb.FirebaseDatabase.instance;
  final userPostsRef = database.ref().child('user-posts').child(userId);

  try {
    await for (final event in userPostsRef.onValue) {
      if (!event.snapshot.exists || event.snapshot.value == null) {
        yield [];
        continue;
      }

      final postsData = Map<String, dynamic>.from(event.snapshot.value as Map);
      final posts = postsData.entries.map((entry) {
        final postData = Map<String, dynamic>.from(entry.value as Map);
        postData['id'] = entry.key;
        postData['userId'] = userId;
        return PostModel.fromJson(postData);
      }).toList();

      // Sort posts by timestamp in descending order (newest first)
      posts.sort((a, b) => (b.timestamp ?? 0).compareTo(a.timestamp ?? 0));
      
      yield posts;
    }
  } catch (e, stack) {
    Logger.e('Error fetching user posts', e, stack);
    yield* Stream.error(e, stack);
  }
});

class PostsNotifier extends StateNotifier<AsyncValue<List<PostModel>>> {
  final Ref _ref;
  final _database = rtdb.FirebaseDatabase.instance;
  final _storage = FirebaseStorage.instance;
  rtdb.DatabaseReference get _postsRef => _database.ref().child('posts');
  rtdb.DatabaseReference get _userPostsRef => _database.ref().child('user-posts');
  rtdb.DatabaseReference get _followingRef => _database.ref().child('following');
  List<PostModel> _posts = [];
  rtdb.DatabaseReference? _currentListener;
  Map<String, rtdb.DatabaseReference> _followingListeners = {};

  PostsNotifier(this._ref) : super(const AsyncValue.loading()) {
    _initPostsListener();
  }

  void _initPostsListener() {
    final currentUser = _ref.read(authProvider).value;
    if (currentUser == null) {
      state = const AsyncValue.data([]);
      return;
    }

    // Remove previous listeners
    _currentListener?.onValue.drain();
    _currentListener = null;
    _followingListeners.values.forEach((listener) => listener.onValue.drain());
    _followingListeners.clear();

    // Listen to all posts
    _postsRef.onValue.listen((event) async {
      try {
        List<PostModel> allPosts = [];

        if (event.snapshot.exists && event.snapshot.value != null) {
          final postsData = Map<String, dynamic>.from(event.snapshot.value as Map);
          final posts = postsData.entries.map((entry) {
            final postData = Map<String, dynamic>.from(entry.value as Map);
            postData['id'] = entry.key;
            return PostModel.fromJson(postData);
          }).toList();
          allPosts.addAll(posts);
        }

        // Sort posts by timestamp
        allPosts.sort((a, b) => (b.timestamp ?? 0).compareTo(a.timestamp ?? 0));
        state = AsyncValue.data(allPosts);
      } catch (e, stack) {
        Logger.e('Error in posts listener', e, stack);
        state = AsyncValue.error(e, stack);
      }
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

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final newPostRef = _postsRef.push();
      final postId = newPostRef.key!;
      
      final post = PostModel(
        id: postId,
        userId: currentUser.id,
        username: currentUser.username,
        userPhotoUrl: currentUser.photoUrl,
        content: content,
        imageUrl: imageUrl,
        isMeme: isMeme,
        likes: 0,
        comments: 0,
        timestamp: timestamp,
      );

      // Create a multi-path update
      final updates = {
        '/posts/$postId': post.toJson(),
        '/user-posts/${currentUser.id}/$postId': post.toJson(),
      };

      // Update all paths atomically
      await _database.ref().update(updates);

      // Update user's post count in a transaction
      final userRef = _database.ref().child('users/${currentUser.id}');
      await userRef.child('postsCount').runTransaction((Object? value) {
        return rtdb.Transaction.success((value as int? ?? 0) + 1);
      });

      Logger.i('Post created successfully: $postId');
    } catch (e, stack) {
      Logger.e('Error creating post', e, stack);
      state = AsyncValue.error(e, stack);
      rethrow;
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

  Future<bool> isFollowing(String userId) async {
    try {
      final currentUser = _ref.read(authProvider).value;
      if (currentUser == null) return false;

      final followingRef = _database.ref()
          .child('users')
          .child(currentUser.id)
          .child('following')
          .child(userId);
      
      final snapshot = await followingRef.get();
      return snapshot.exists;
    } catch (e) {
      Logger.e('Error checking follow status', e);
      return false;
    }
  }

  Future<void> followUser(String userId) async {
    try {
      final currentUser = _ref.read(authProvider).value;
      if (currentUser == null) throw Exception('Not logged in');

      // Add to current user's following
      await _database.ref()
          .child('users')
          .child(currentUser.id)
          .child('following')
          .child(userId)
          .set(true);

      // Add to target user's followers
      await _database.ref()
          .child('users')
          .child(userId)
          .child('followers')
          .child(currentUser.id)
          .set(true);

      // Update current user's following count
      await _database.ref()
          .child('users')
          .child(currentUser.id)
          .child('followingCount')
          .runTransaction((Object? value) {
        return rtdb.Transaction.success((value as int? ?? 0) + 1);
      });

      // Update target user's followers count
      await _database.ref()
          .child('users')
          .child(userId)
          .child('followersCount')
          .runTransaction((Object? value) {
        return rtdb.Transaction.success((value as int? ?? 0) + 1);
      });

      Logger.i('Successfully followed user: $userId');
    } catch (e) {
      Logger.e('Error following user', e);
      rethrow;
    }
  }

  Future<void> unfollowUser(String userId) async {
    try {
      final currentUser = _ref.read(authProvider).value;
      if (currentUser == null) throw Exception('Not logged in');

      // Remove from current user's following
      await _database.ref()
          .child('users')
          .child(currentUser.id)
          .child('following')
          .child(userId)
          .remove();

      // Remove from target user's followers
      await _database.ref()
          .child('users')
          .child(userId)
          .child('followers')
          .child(currentUser.id)
          .remove();

      // Update current user's following count
      await _database.ref()
          .child('users')
          .child(currentUser.id)
          .child('followingCount')
          .runTransaction((Object? value) {
        final current = value as int? ?? 0;
        return rtdb.Transaction.success(current > 0 ? current - 1 : 0);
      });

      // Update target user's followers count
      await _database.ref()
          .child('users')
          .child(userId)
          .child('followersCount')
          .runTransaction((Object? value) {
        final current = value as int? ?? 0;
        return rtdb.Transaction.success(current > 0 ? current - 1 : 0);
      });

      Logger.i('Successfully unfollowed user: $userId');
    } catch (e) {
      Logger.e('Error unfollowing user', e);
      rethrow;
    }
  }
}
