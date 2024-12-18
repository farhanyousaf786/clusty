import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_database/firebase_database.dart' as rtdb;
import '../models/reaction_model.dart';
import 'auth_provider.dart';

class ReactionsNotifier extends StateNotifier<Map<String, bool>> {
  final Ref _ref;
  final _database = rtdb.FirebaseDatabase.instance;

  ReactionsNotifier(this._ref) : super({});

  Future<void> toggleReaction(String postId, String type) async {
    try {
      // Set loading state for this specific reaction
      state = {...state, '$postId:$type': true};
      
      final currentUser = _ref.read(authProvider).value;
      if (currentUser == null) {
        state = {...state, '$postId:$type': false};
        return;
      }

      final reactionsRef = _database
          .ref()
          .child('reactions')
          .child(postId)
          .child(currentUser.id);

      final snapshot = await reactionsRef.get();
      
      if (snapshot.exists) {
        final existingType = (snapshot.value as Map)['type'];
        if (existingType == type) {
          // Remove reaction if clicking the same type
          await reactionsRef.remove();
          state = {...state, '$postId:$type': false};
          return;
        }
      }

      // Add or update reaction
      await reactionsRef.set({
        'userId': currentUser.id,
        'postId': postId,
        'type': type,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });

      state = {...state, '$postId:$type': false};
    } catch (e) {
      state = {...state, '$postId:$type': false};
    }
  }

  bool isLoading(String postId, String type) {
    return state['$postId:$type'] ?? false;
  }
}

final reactionsProvider = StateNotifierProvider<ReactionsNotifier, Map<String, bool>>((ref) {
  return ReactionsNotifier(ref);
});

final userReactionProvider = StreamProvider.family<ReactionModel?, String>((ref, postId) {
  final currentUser = ref.watch(authProvider).value;
  if (currentUser == null) return Stream.value(null);

  return rtdb.FirebaseDatabase.instance
      .ref()
      .child('reactions')
      .child(postId)
      .child(currentUser.id)
      .onValue
      .map((event) {
        if (!event.snapshot.exists || event.snapshot.value == null) return null;
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        data['id'] = event.snapshot.key;
        return ReactionModel.fromJson(data);
      });
});

final postReactionsProvider = StreamProvider.family<Map<String, int>, String>((ref, postId) {
  return rtdb.FirebaseDatabase.instance
      .ref()
      .child('reactions')
      .child(postId)
      .onValue
      .map((event) {
        if (!event.snapshot.exists || event.snapshot.value == null) {
          return {};
        }

        final reactions = Map<String, dynamic>.from(event.snapshot.value as Map);
        final counts = <String, int>{};

        reactions.values.forEach((reaction) {
          final type = (reaction as Map)['type'] as String;
          counts[type] = (counts[type] ?? 0) + 1;
        });

        return counts;
      });
});
