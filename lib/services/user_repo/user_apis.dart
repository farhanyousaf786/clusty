import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'user_repository.dart';
import 'package:clusty/models/user_model.dart';

class UserApi implements IUserRepository {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    final userCredential = await _firebaseAuth.signInWithEmailAndPassword(email: email, password: password);
    return userCredential.user;
  }

  @override
  Future<String> createUserWithEmailAndPassword({
    required String firstName,
    required String lastName,
    required String username, // Add this line
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(email: email.trim(), password: password);
      final User? user = userCredential.user;
      if (user != null) {
        final token = await getToken();
        final userModel = UserModel(
          uid: user.uid,
          firstName: firstName,
          lastName: lastName,
          username: username, // Add this line
          email: email,
          password: password,
          token: token,
          imageUrl: "",
          createdAt: Timestamp.now(),
          registeredNumbers: [],
        );
        await addUser(userModel);
        return "success";
      }
      return "User creation failed";
    } on FirebaseAuthException catch (e) {
      return e.message.toString();
    }
  }

  @override
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  @override
  Stream<UserModel> get getCurrentUser {
    return _firestore.collection('users').doc(_firebaseAuth.currentUser!.uid).snapshots().map((docSnapshot) {
      final data = docSnapshot.data();
      if (data != null) {
        return UserModel.fromDocumentSnapshot(docSnapshot);
      } else {
        throw Exception('Document data is null');
      }
    });
  }

  @override
  Stream<User?> get authState => FirebaseAuth.instance.authStateChanges();

  @override
  User? get currentUser => _firebaseAuth.currentUser;

  @override
  Future<void> addUser(UserModel userModel) async {
    await _firestore.collection('users').doc(userModel.uid).set(userModel.toMap());
  }

  @override
  String? getUid() {
    final user = _firebaseAuth.currentUser;
    return user?.uid;
  }

  @override
  Future<UserModel?> getUserData() async {
    final doc = await _firestore.collection('users').doc(_firebaseAuth.currentUser!.uid).get();
    return UserModel.fromDocumentSnapshot(doc);
  }

  @override
  Future<String> getToken() async {
    final token = await _firebaseAuth.currentUser?.getIdToken();
    return token ?? '';
  }

  @override
  Future<void> updateUser(Map<String, dynamic> map) async {
    await _firestore.collection('users').doc(_firebaseAuth.currentUser!.uid).update(map);
  }

  @override
  Future<bool> isUsernameUnique(String username) async {
    final result = await _firestore.collection('users').where('username', isEqualTo: username).get();
    return result.docs.isEmpty;
  }
}
