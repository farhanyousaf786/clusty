import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';

final userProvider = StreamProvider.family<UserModel, String>((ref, userId) {
  return FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .snapshots()
      .map((doc) => UserModel.fromJson(doc.data()!));
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
    state = (state - amount).clamp(0, double.infinity).toInt();
  }
}
