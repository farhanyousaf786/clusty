import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_database/firebase_database.dart' as rtdb;
import '../models/user_model.dart';
import '../utils/logger.dart';

final searchProvider = StateNotifierProvider<SearchNotifier, AsyncValue<List<UserModel>>>((ref) {
  return SearchNotifier();
});

class SearchNotifier extends StateNotifier<AsyncValue<List<UserModel>>> {
  final _database = rtdb.FirebaseDatabase.instance;
  rtdb.DatabaseReference get _usersRef => _database.ref().child('users');

  SearchNotifier() : super(const AsyncValue.data([]));

  Future<void> searchUsers(String query) async {
    if (query.isEmpty) {
      state = const AsyncValue.data([]);
      return;
    }

    state = const AsyncValue.loading();

    try {
      final snapshot = await _usersRef.get();
      if (!snapshot.exists) {
        state = const AsyncValue.data([]);
        return;
      }

      final usersData = Map<String, dynamic>.from(snapshot.value as Map);
      final users = usersData.entries.map((entry) {
        final userData = Map<String, dynamic>.from(entry.value as Map);
        userData['id'] = entry.key;
        return UserModel.fromJson(userData);
      }).where((user) {
        final username = user.username?.toLowerCase() ?? '';
        final searchQuery = query.toLowerCase();
        return username.contains(searchQuery);
      }).toList();

      users.sort((a, b) => (a.username ?? '').compareTo((b.username ?? '')));
      state = AsyncValue.data(users);
      Logger.i('Found ${users.length} users matching "$query"');
    } catch (e, stack) {
      Logger.e('Error searching users', e, stack);
      state = AsyncValue.error(e, stack);
    }
  }
}
