import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_database/firebase_database.dart' as rtdb;
import '../models/user_model.dart';
import '../utils/logger.dart';
import 'auth_provider.dart';

// Cached user data to avoid frequent reloads
final _userCache = <String, UserModel>{};

// Main user provider
final userProvider = StreamProvider.family<UserModel?, String>((ref, userId) async* {
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
      
      final user = UserModel.fromJson(userData);
      _userCache[userId] = user;
      yield user;
    }
  } catch (e, stack) {
    Logger.e('Error in user stream', e, stack);
    yield* Stream.error(e, stack);
  }
});

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
    state = state > amount ? state - amount : 0;
  }
}
