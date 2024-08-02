import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/get_it_locator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserProvider with ChangeNotifier {
  UserModel? _user;
  bool _isLoading = true;
  List<Map<String, dynamic>> _registeredNumbers = [];
  bool _isDisposed = false;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  List<Map<String, dynamic>> get registeredNumbers => _registeredNumbers;

  UserProvider() {
    loadUserData();
  }

  Future<void> loadUserData() async {
    try {
      UserModel? user = await userRepository.getUserData();
      _user = user;
    } catch (e) {
      print("Error loading user data: $e");
    } finally {
      _isLoading = false;
      _safeNotifyListeners();
    }
  }


  void loadFromSign() {
    loadUserData();
    _safeNotifyListeners();
  }

  void clearUser() {
    _user = null;
    _registeredNumbers = [];
    _safeNotifyListeners();
  }

  void _safeNotifyListeners() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
