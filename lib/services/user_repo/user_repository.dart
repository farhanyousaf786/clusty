import 'package:clusty_stf/models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

abstract class IUserRepository {
  Future<User?> signInWithEmailAndPassword(String email, String password);

  Future<String> createUserWithEmailAndPassword({
    required String firstName,
    required String lastName,
    required String username, // Add this line
    required String email,
    required String password,
  });

  Future<void> signOut();

  Stream<UserModel> get getCurrentUser;

  Stream<User?> get authState;

  User? get currentUser;

  Future<void> addUser(UserModel userModel);

  String? getUid();

  Future<UserModel?> getUserData();

  Future<String> getToken();

  Future<void> updateUser(Map<String, dynamic> map);

  Future<bool> isUsernameUnique(String username); // Add this line
}
