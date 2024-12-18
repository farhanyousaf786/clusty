import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../utils/logger.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AsyncValue<UserModel?>>((ref) {
  return AuthNotifier();
});

class AuthNotifier extends StateNotifier<AsyncValue<UserModel?>> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  AuthNotifier() : super(const AsyncValue.loading()) {
    Logger.i('Initializing AuthNotifier');
    _init();
  }

  void _init() {
    _auth.authStateChanges().listen((user) async {
      Logger.d('Auth state changed: ${user?.uid ?? 'No user'}');
      if (user == null) {
        state = const AsyncValue.data(null);
      } else {
        try {
          final userData = await _firestore.collection('users').doc(user.uid).get();
          Logger.d('Fetched user data: ${userData.exists ? 'exists' : 'does not exist'}');
          if (userData.exists) {
            state = AsyncValue.data(UserModel.fromJson(userData.data()!));
          } else {
            state = const AsyncValue.data(null);
          }
        } catch (e) {
          Logger.e('Error fetching user data', e);
          state = AsyncValue.error(e, StackTrace.current);
        }
      }
    });
  }

  Future<bool> isUsernameAvailable(String username) async {
    if (username.length < 3) return false;
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(username)) return false;
    
    final usernameDoc = await _firestore
        .collection('usernames')
        .doc(username.toLowerCase())
        .get();
    return !usernameDoc.exists;
  }

  Future<void> signUp({
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      state = const AsyncValue.loading();
      
      // Validate username
      if (username.length < 3) {
        throw 'Username must be at least 3 characters long';
      }
      if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(username)) {
        throw 'Username can only contain letters, numbers, and underscores';
      }
      
      // Check if username is available
      final isAvailable = await isUsernameAvailable(username);
      if (!isAvailable) {
        throw 'Username is already taken';
      }

      // Create auth user
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create user document
      final user = UserModel(
        id: userCredential.user!.uid,
        username: username.toLowerCase(),
        email: email,
        createdAt: DateTime.now(),
      );

      // Use a batch write for atomicity
      final batch = _firestore.batch();
      
      // Create user document
      batch.set(_firestore.collection('users').doc(user.id), user.toJson());
      
      // Reserve username
      batch.set(_firestore.collection('usernames').doc(username.toLowerCase()), {
        'uid': user.id,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();
      state = AsyncValue.data(user);
    } catch (e) {
      final errorMessage = e is FirebaseAuthException ? e.message ?? e.toString() : e.toString();
      state = AsyncValue.error(errorMessage, StackTrace.current);
      throw errorMessage;
    }
  }

  Future<void> signIn(String email, String password) async {
    try {
      Logger.i('Attempting sign in for email: $email');
      state = const AsyncValue.loading();
      
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      Logger.i('Sign in successful');
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'An error occurred during sign in';
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No user found with this email';
          break;
        case 'wrong-password':
          errorMessage = 'Wrong password provided';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email address';
          break;
        default:
          errorMessage = e.message ?? errorMessage;
      }
      Logger.e('Sign in failed', e, StackTrace.current);
      state = AsyncValue.error(errorMessage, StackTrace.current);
      throw errorMessage;
    } catch (e) {
      Logger.e('Unexpected error during sign in', e, StackTrace.current);
      final errorMessage = e.toString();
      state = AsyncValue.error(errorMessage, StackTrace.current);
      throw errorMessage;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> updateProfile({
    required String userId,
    String? name,
    String? photoUrl,
    DateTime? dateOfBirth,
    String? about,
  }) async {
    try {
      Logger.i('Updating profile for user: $userId');
      state = const AsyncValue.loading();

      // Get current user data
      final userData = await _firestore.collection('users').doc(userId).get();
      if (!userData.exists) {
        throw 'User document not found';
      }

      // Create updated user model
      final currentUser = UserModel.fromJson(userData.data()!);
      final updatedUser = currentUser.copyWith(
        name: name,
        photoUrl: photoUrl,
        dateOfBirth: dateOfBirth,
        about: about,
      );

      // Update in Firestore
      await _firestore.collection('users').doc(userId).update(updatedUser.toJson());

      // Update state
      state = AsyncValue.data(updatedUser);
      Logger.i('Profile updated successfully');
    } catch (e) {
      Logger.e('Error updating profile', e);
      state = AsyncValue.error(e, StackTrace.current);
      throw e.toString();
    }
  }
}
