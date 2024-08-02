import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  String uid;
  String firstName; // Change this line
  String lastName; // Change this line
  String username;
  String email;
  String password;
  String token;
  Timestamp createdAt;
  List<Map<String, dynamic>> registeredNumbers;
  String imageUrl;

  UserModel({
    required this.uid,
    required this.firstName, // Change this line
    required this.lastName, // Change this line
    required this.username,
    required this.email,
    required this.password,
    required this.token,
    required this.createdAt,
    required this.registeredNumbers,
    required this.imageUrl,
  });

  // Convert a UserModel into a Map
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'firstName': firstName, // Change this line
      'lastName': lastName, // Change this line
      'username': username,
      'email': email,
      'password': password,
      'token': token,
      'createdAt': createdAt,
      'registeredNumbers': registeredNumbers,
      'imageUrl': imageUrl,
    };
  }

  // Create a UserModel from a Firestore DocumentSnapshot
  factory UserModel.fromDocumentSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      firstName: data['firstName'], // Change this line
      lastName: data['lastName'], // Change this line
      username: data['username'],
      email: data['email'],
      password: data['password'],
      token: data['token'],
      createdAt: data['createdAt'],
      registeredNumbers: data['registeredNumbers'] != null
          ? List<Map<String, dynamic>>.from(data['registeredNumbers'])
          : [],
      imageUrl: data['imageUrl'],
    );
  }
}
