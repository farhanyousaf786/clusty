import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_database/firebase_database.dart' as rtdb;
import '../models/user_model.dart';
import '../utils/logger.dart';
import 'auth_provider.dart';

// Cached user data to avoid frequent reloads
final _userCache = <String, UserModel>{};

// Main user provider that combines base data and stats
final userProvider = Provider.family<AsyncValue<UserModel?>, String>((ref, userId) {
  final baseData = ref.watch(_userBaseDataProvider(userId));
  final stats = ref.watch(_userStatsProvider(userId));
  
  return baseData.when(
    data: (user) => stats.when(
      data: (statsData) {
        if (user == null) return const AsyncValue.data(null);
        final updatedUser = user.copyWith(
          followersCount: statsData['followers'] ?? 0,
          followingCount: statsData['following'] ?? 0,
          postsCount: statsData['posts'] ?? 0,
        );
        _userCache[userId] = updatedUser;
        return AsyncValue.data(updatedUser);
      },
      loading: () => AsyncValue.data(_userCache[userId] ?? user),
      error: (e, s) {
        Logger.e('Error loading user stats', e, s);
        return AsyncValue.data(_userCache[userId] ?? user);
      },
    ),
    loading: () => const AsyncValue.loading(),
    error: (e, s) => AsyncValue.error(e, s),
  );
});

// Provider for base user data (everything except counts)
final _userBaseDataProvider = StreamProvider.family<UserModel?, String>((ref, userId) async* {
  final database = rtdb.FirebaseDatabase.instance;
  final userRef = database.ref().child('users').child(userId);

  try {
    await for (final event in userRef.onValue) {
      if (!event.snapshot.exists || event.snapshot.value == null) {
        yield null;
        continue;
      }

      final userData = Map<String, dynamic>.from(event.snapshot.value as Map);
      userData['id'] = userId;
      
      // Use cached counts if available while loading new ones
      if (_userCache.containsKey(userId)) {
        userData['followersCount'] = _userCache[userId]!.followersCount;
        userData['followingCount'] = _userCache[userId]!.followingCount;
        userData['postsCount'] = _userCache[userId]!.postsCount;
      }

      yield UserModel.fromJson(userData);
    }
  } catch (e, stack) {
    Logger.e('Error in user stream', e, stack);
    yield* Stream.error(e, stack);
  }
});

// Separate provider for user stats that updates less frequently
final _userStatsProvider = StreamProvider.family<Map<String, int>, String>((ref, userId) async* {
  final database = rtdb.FirebaseDatabase.instance;
  final statsRef = database.ref().child('user-stats').child(userId);
  
  try {
    // First, yield cached data if available
    if (_userCache.containsKey(userId)) {
      final cached = _userCache[userId]!;
      yield {
        'followers': cached.followersCount,
        'following': cached.followingCount,
        'posts': cached.postsCount,
      };
    }

    // Then start listening for updates
    await for (final event in statsRef.onValue) {
      if (!event.snapshot.exists || event.snapshot.value == null) {
        // If no stats exist yet, calculate them once
        final counts = await _calculateUserStats(userId);
        await statsRef.set(counts);
        yield counts;
        continue;
      }

      final stats = Map<String, dynamic>.from(event.snapshot.value as Map);
      yield {
        'followers': stats['followers'] ?? 0,
        'following': stats['following'] ?? 0,
        'posts': stats['posts'] ?? 0,
      };
    }
  } catch (e, stack) {
    Logger.e('Error in stats stream', e, stack);
    yield* Stream.error(e, stack);
  }
});

Future<Map<String, int>> _calculateUserStats(String userId) async {
  final database = rtdb.FirebaseDatabase.instance;
  
  try {
    final followersSnapshot = await database.ref()
        .child('users')
        .child(userId)
        .child('followers')
        .get();
        
    final followingSnapshot = await database.ref()
        .child('users')
        .child(userId)
        .child('following')
        .get();
        
    final postsSnapshot = await database.ref()
        .child('user-posts')
        .child(userId)
        .get();

    return {
      'followers': followersSnapshot.exists ? (followersSnapshot.value as Map).length : 0,
      'following': followingSnapshot.exists ? (followingSnapshot.value as Map).length : 0,
      'posts': postsSnapshot.exists ? (postsSnapshot.value as Map).length : 0,
    };
  } catch (e) {
    Logger.e('Error calculating user stats', e);
    return {'followers': 0, 'following': 0, 'posts': 0};
  }
}

final userCoinsProvider = StateNotifierProvider<UserCoinsNotifier, int>((ref) {
  return UserCoinsNotifier();
});

class UserCoinsNotifier extends StateNotifier<int> {
  UserCoinsNotifier() : super(0);

  void setCoins(int coins) {
    state = coins;
  }

  void addCoins(int amount) {
    state += amount;
  }

  void subtractCoins(int amount) {
    state = (state - amount).clamp(0, double.infinity).toInt();
  }
}
