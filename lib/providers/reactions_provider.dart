import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_database/firebase_database.dart' as rtdb;
import '../models/reaction_type.dart';
import 'auth_provider.dart';

class Reaction {
  final String id;
  final String userId;
  final String postId;
  final ReactionType type;
  final int timestamp;

  Reaction({
    required this.id,
    required this.userId,
    required this.postId,
    required this.type,
    required this.timestamp,
  });

  factory Reaction.fromMap(Map<String, dynamic> map, String id) {
    return Reaction(
      id: id,
      userId: map['userId'],
      postId: map['postId'],
      type: ReactionType.values.firstWhere(
        (e) => e.toString() == map['type'],
        orElse: () => ReactionType.like,
      ),
      timestamp: map['timestamp'],
    );
  }
}

class ReactionsState {
  final List<Reaction> reactions;
  final Set<String> loadingPosts; // Track loading state per post
  final String? error;

  const ReactionsState({
    required this.reactions,
    this.loadingPosts = const {},
    this.error,
  });

  bool isPostLoading(String postId) => loadingPosts.contains(postId);

  ReactionsState copyWith({
    List<Reaction>? reactions,
    Set<String>? loadingPosts,
    String? error,
  }) {
    return ReactionsState(
      reactions: reactions ?? this.reactions,
      loadingPosts: loadingPosts ?? this.loadingPosts,
      error: error ?? this.error,
    );
  }

  ReactionsState startLoading(String postId) {
    return copyWith(loadingPosts: {...loadingPosts, postId});
  }

  ReactionsState stopLoading(String postId) {
    return copyWith(loadingPosts: {...loadingPosts}..remove(postId));
  }
}

class ReactionsNotifier extends StateNotifier<ReactionsState> {
  final Ref _ref;
  final _database = rtdb.FirebaseDatabase.instance;
  late final rtdb.DatabaseReference _reactionsRef;

  ReactionsNotifier(this._ref) : super(const ReactionsState(reactions: [])) {
    _reactionsRef = _database.ref().child('reactions');
    _initializeReactions();
  }

  void _initializeReactions() {
    _reactionsRef.onValue.listen((event) {
      if (!event.snapshot.exists) {
        state = state.copyWith(reactions: []);
        return;
      }

      try {
        final data = event.snapshot.value as Map;
        final reactions = <Reaction>[];

        data.forEach((postId, postReactions) {
          if (postReactions is Map) {
            postReactions.forEach((userId, reaction) {
              if (reaction is Map) {
                reactions.add(Reaction.fromMap(
                  Map<String, dynamic>.from(reaction as Map),
                  '$postId:$userId',
                ));
              }
            });
          }
        });

        state = state.copyWith(reactions: reactions);
      } catch (e) {
        state = state.copyWith(error: e.toString());
      }
    });
  }

  Future<void> addReaction(String postId, ReactionType type) async {
    try {
      state = state.startLoading(postId);
      final currentUser = _ref.read(authProvider).value;
      if (currentUser == null) return;

      final reactionsRef = _reactionsRef
          .child(postId)
          .child(currentUser.id);

      final snapshot = await reactionsRef.get();
      
      if (snapshot.exists) {
        final existingType = (snapshot.value as Map)['type'];
        if (existingType == type.toString()) {
          await reactionsRef.remove();
          return;
        }
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      await reactionsRef.set({
        'userId': currentUser.id,
        'postId': postId,
        'type': type.toString(),
        'timestamp': timestamp,
      });
    } catch (e) {
      state = state.copyWith(error: e.toString());
    } finally {
      state = state.stopLoading(postId);
    }
  }

  Future<void> removeReaction(String postId) async {
    try {
      state = state.startLoading(postId);
      final currentUser = _ref.read(authProvider).value;
      if (currentUser == null) return;

      await _reactionsRef
          .child(postId)
          .child(currentUser.id)
          .remove();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    } finally {
      state = state.stopLoading(postId);
    }
  }
}

final reactionsProvider = StateNotifierProvider<ReactionsNotifier, ReactionsState>((ref) {
  return ReactionsNotifier(ref);
});

final userReactionProvider = Provider.family<Reaction?, String>((ref, postId) {
  final reactions = ref.watch(reactionsProvider).reactions;
  final currentUser = ref.watch(authProvider).value;
  if (currentUser == null) return null;

  try {
    return reactions.firstWhere(
      (reaction) => reaction.postId == postId && reaction.userId == currentUser.id,
    );
  } catch (_) {
    return null;
  }
});

final postReactionsProvider = Provider.family<AsyncValue<List<Reaction>>, String>((ref, postId) {
  final reactionsState = ref.watch(reactionsProvider);
  
  if (reactionsState.isPostLoading(postId)) {
    return const AsyncValue.loading();
  }
  
  if (reactionsState.error != null) {
    return AsyncValue.error(reactionsState.error!, StackTrace.current);
  }
  
  return AsyncValue.data(
    reactionsState.reactions.where((reaction) => reaction.postId == postId).toList()
  );
});
