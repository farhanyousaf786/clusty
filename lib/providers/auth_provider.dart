import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_database/firebase_database.dart' as rtdb;
import '../models/user_model.dart';
import '../utils/logger.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AsyncValue<UserModel?>>((ref) {
  return AuthNotifier();
});

class AuthNotifier extends StateNotifier<AsyncValue<UserModel?>> {
  final _auth = FirebaseAuth.instance;
  final _database = rtdb.FirebaseDatabase.instance;
  rtdb.DatabaseReference get _usersRef => _database.ref().child('users');
  rtdb.DatabaseReference get _usernamesRef => _database.ref().child('usernames');
  User? _currentUser;

  AuthNotifier() : super(const AsyncValue.loading()) {
    Logger.i('Initializing AuthNotifier');
    _init();
  }

  void _init() {
    _auth.authStateChanges().listen((user) {
      Logger.d('Auth state changed: ${user?.uid ?? 'No user'}');
      _currentUser = user;
      _fetchUserData();
    });
  }

  Future<void> _fetchUserData() async {
    if (_currentUser == null) {
      if (mounted) state = const AsyncValue.data(null);
      return;
    }

    try {
      final userRef = _usersRef.child(_currentUser!.uid);
      final snapshot = await userRef.get();
      Logger.d('Fetched user data: ${snapshot.exists ? 'exists' : 'does not exist'}');
      
      if (!mounted) return;

      if (snapshot.exists && snapshot.value != null) {
        final userData = Map<String, dynamic>.from(snapshot.value as Map);
        userData['id'] = _currentUser!.uid; // Ensure ID is set
        state = AsyncValue.data(UserModel.fromJson(userData));
      } else {
        state = const AsyncValue.data(null);
      }
    } catch (e, stack) {
      Logger.e('Error fetching user data', e);
      if (mounted) state = AsyncValue.error(e, stack);
    }
  }

  Future<bool> isUsernameAvailable(String username) async {
    try {
      // Basic validation
      if (username.length < 3) return false;
      if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(username)) return false;
      
      // Check in Realtime Database
      final lowercaseUsername = username.toLowerCase();
      final snapshot = await _database.ref()
        .child('usernames')
        .child(lowercaseUsername)
        .get();
      
      return !snapshot.exists;
    } catch (e) {
      Logger.e('Error checking username availability', e);
      rethrow;
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String username,
    String? photoUrl,
  }) async {
    try {
      state = const AsyncValue.loading();
      
      // Check username availability
      if (!await isUsernameAvailable(username)) {
        throw Exception('Username is already taken');
      }

      // Create auth user
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) throw Exception('Failed to create user');

      // Create user data
      final userData = UserModel(
        id: user.uid,
        email: email,
        username: username,
        photoUrl: photoUrl,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        followersCount: 0,
        followingCount: 0,
        postsCount: 0,
      );

      // Save user data
      await _usersRef.child(user.uid).set(userData.toJson());

      // Reserve username
      await _usernamesRef.child(username.toLowerCase()).set({
        'uid': user.uid,
        'timestamp': rtdb.ServerValue.timestamp,
      });

      state = AsyncValue.data(userData);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    try {
      state = const AsyncValue.loading();
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<void> updateProfile({String? username, String? photoUrl}) async {
    try {
      final currentUser = state.value;
      if (currentUser == null) throw Exception('No user logged in');

      final updates = <String, dynamic>{};
      
      if (username != null && username != currentUser.username) {
        if (!await isUsernameAvailable(username)) {
          throw Exception('Username is already taken');
        }
        updates['username'] = username;
        
        // Update username mapping
        if (currentUser.username?.isNotEmpty == true) {
          await _usernamesRef.child(currentUser.username!.toLowerCase()).remove();
        }
        await _usernamesRef.child(username.toLowerCase()).set({
          'uid': currentUser.id,
          'timestamp': rtdb.ServerValue.timestamp,
        });
      }

      if (photoUrl != null) {
        updates['photoUrl'] = photoUrl;
      }

      if (updates.isNotEmpty) {
        await _usersRef.child(currentUser.id).update(updates);
        
        state = AsyncValue.data(currentUser.copyWith(
          username: username ?? currentUser.username,
          photoUrl: photoUrl ?? currentUser.photoUrl,
        ));
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  Future<void> updateFollowersCount(String userId, int delta) async {
    try {
      final userRef = _usersRef.child(userId).child('followersCount');
      await userRef.runTransaction((Object? value) {
        return rtdb.Transaction.success((value as int? ?? 0) + delta);
      });
    } catch (e) {
      Logger.e('Error updating followers count', e);
      rethrow;
    }
  }

  Future<void> updateFollowingCount(String userId, int delta) async {
    try {
      final userRef = _usersRef.child(userId).child('followingCount');
      await userRef.runTransaction((Object? value) {
        return rtdb.Transaction.success((value as int? ?? 0) + delta);
      });
    } catch (e) {
      Logger.e('Error updating following count', e);
      rethrow;
    }
  }
}
