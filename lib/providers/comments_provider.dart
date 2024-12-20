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
    _commentsRef.onChildAdded.listen((event) {
      if (!event.snapshot.exists || event.snapshot.value == null) return;

      try {
        final commentData = Map<String, dynamic>.from(event.snapshot.value as Map);
        final comment = CommentModel.fromJson(commentData, event.snapshot.key!);
        
        state = CommentsState(
          comments: [...state.comments, comment]
            ..sort((a, b) => b.timestamp.compareTo(a.timestamp)),
        );
      } catch (e) {
        print('Error adding comment: $e');
      }
    });

    _commentsRef.onChildRemoved.listen((event) {
      if (!event.snapshot.exists) return;

      state = CommentsState(
        comments: state.comments
            .where((c) => c.id != event.snapshot.key)
            .toList(),
      );
    });
  }

  Future<void> addComment(String postId, String content) async {
    final currentUser = _ref.read(authProvider).value;
    if (currentUser == null) return;

    final commentRef = _commentsRef.push();
    final comment = CommentModel(
      id: commentRef.key!,
      userId: currentUser.id,
      postId: postId,
      content: content,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      username: currentUser.username ?? 'Anonymous',
      userPhotoUrl: currentUser.photoUrl,
    );

    await commentRef.set(comment.toJson());
  }

  Future<void> deleteComment(String postId, String commentId) async {
    final currentUser = _ref.read(authProvider).value;
    if (currentUser == null) return;

    final comment = state.comments.firstWhere(
      (c) => c.id == commentId,
      orElse: () => throw Exception('Comment not found'),
    );

    if (comment.userId != currentUser.id) {
      throw Exception('Not authorized to delete this comment');
    }

    try {
      await _commentsRef.child(commentId).remove();
      
      // Update state immediately
      state = CommentsState(
        comments: state.comments.where((c) => c.id != commentId).toList(),
      );
    } catch (e) {
      print('Error deleting comment: $e');
      throw Exception('Failed to delete comment');
    }
  }
}

final commentsProvider = StateNotifierProvider<CommentsNotifier, CommentsState>((ref) {
  return CommentsNotifier(ref);
});

final postCommentsProvider = Provider.family<AsyncValue<List<CommentModel>>, String>((ref, postId) {
  final commentsState = ref.watch(commentsProvider);
  
  if (commentsState.error != null) {
    return AsyncValue.error(commentsState.error!, StackTrace.current);
  }

  final postComments = commentsState.comments
      .where((comment) => comment.postId == postId)
      .toList()
    ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

  return AsyncValue.data(postComments);
});
