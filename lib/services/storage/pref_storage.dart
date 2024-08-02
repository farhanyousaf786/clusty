import 'package:clusty/services/storage/storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrefsStorage implements IStorage {
  PrefsStorage._prefsStorage();

  static final PrefsStorage _instance = PrefsStorage._prefsStorage();
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  static PrefsStorage get instance => _instance;
  static late SharedPreferences _prefs;

  factory PrefsStorage() {
    return _instance;
  }


  @override
  Future<void> init() async => _prefs = await SharedPreferences.getInstance();


}

