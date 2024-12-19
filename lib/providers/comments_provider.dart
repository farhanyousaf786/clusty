import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_database/firebase_database.dart' as rtdb;
import '../models/comment_model.dart';
import 'auth_provider.dart';

class CommentsState {
  final List<CommentModel> comments;
  final Set<String> loadingPosts;
  final String? error;

  const CommentsState({
    required this.comments,
    this.loadingPosts = const {},
    this.error,
  });

  bool isPostLoading(String postId) => loadingPosts.contains(postId);

  CommentsState copyWith({
    List<CommentModel>? comments,
    Set<String>? loadingPosts,
    String? error,
  }) {
    return CommentsState(
      comments: comments ?? this.comments,
      loadingPosts: loadingPosts ?? this.loadingPosts,
      error: error ?? this.error,
    );
  }

  CommentsState startLoading(String postId) {
    return copyWith(loadingPosts: {...loadingPosts, postId});
  }

  CommentsState stopLoading(String postId) {
    return copyWith(loadingPosts: {...loadingPosts}..remove(postId));
  }
}

class CommentsNotifier extends StateNotifier<CommentsState> {
  final Ref _ref;
  final _database = rtdb.FirebaseDatabase.instance;
  late final rtdb.DatabaseReference _commentsRef;

  CommentsNotifier(this._ref) : super(const CommentsState(comments: [])) {
    _commentsRef = _database.ref().child('comments');
    _initializeComments();
  }

  void _initializeComments() {
    _commentsRef.onValue.listen((event) {
      if (!event.snapshot.exists) {
        state = state.copyWith(comments: []);
        return;
      }

      try {
        final data = event.snapshot.value as Map;
        final comments = <CommentModel>[];

        data.forEach((postId, postComments) {
          if (postComments is Map) {
            postComments.forEach((commentId, comment) {
              if (comment is Map) {
                comments.add(CommentModel.fromMap(
                  Map<String, dynamic>.from(comment as Map),
                  commentId,
                ));
              }
            });
          }
        });

        state = state.copyWith(
          comments: comments..sort((a, b) => b.timestamp.compareTo(a.timestamp)),
        );
      } catch (e) {
        state = state.copyWith(error: e.toString());
      }
    });
  }

  Future<void> addComment(String postId, String content) async {
    try {
      state = state.startLoading(postId);
      final currentUser = _ref.read(authProvider).value;
      if (currentUser == null) return;

      final newCommentRef = _commentsRef.child(postId).push();
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      await newCommentRef.set({
        'userId': currentUser.id,
        'postId': postId,
        'content': content,
        'timestamp': timestamp,
      });
    } catch (e) {
      state = state.copyWith(error: e.toString());
    } finally {
      state = state.stopLoading(postId);
    }
  }

  Future<void> deleteComment(String postId, String commentId) async {
    try {
      state = state.startLoading(postId);
      final currentUser = _ref.read(authProvider).value;
      if (currentUser == null) return;

      final comment = state.comments.firstWhere((c) => c.id == commentId);
      if (comment.userId != currentUser.id) return;

      await _commentsRef.child(postId).child(commentId).remove();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    } finally {
      state = state.stopLoading(postId);
    }
  }
}

final commentsProvider = StateNotifierProvider<CommentsNotifier, CommentsState>((ref) {
  return CommentsNotifier(ref);
});

final postCommentsProvider = Provider.family<AsyncValue<List<CommentModel>>, String>((ref, postId) {
  final commentsState = ref.watch(commentsProvider);
  
  if (commentsState.isPostLoading(postId)) {
    return const AsyncValue.loading();
  }
  
  if (commentsState.error != null) {
    return AsyncValue.error(commentsState.error!, StackTrace.current);
  }
  
  return AsyncValue.data(
    commentsState.comments
        .where((comment) => comment.postId == postId)
        .toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp)),
  );
});
