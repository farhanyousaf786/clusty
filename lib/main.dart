import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'firebase_options.dart';
import 'screens/landing_page.dart';
import 'package:flutter/foundation.dart';
import 'utils/logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Enable verbose logging in debug mode
  if (kDebugMode) {
    Logger.i('Starting app in debug mode');
  }

  try {
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    Logger.i('Firebase initialized successfully');

    // Initialize Realtime Database
    FirebaseDatabase.instance.setPersistenceEnabled(true);
    FirebaseDatabase.instance.ref().keepSynced(true);
    Logger.i('Firebase Realtime Database initialized');

    // Configure Firebase Auth settings
    await FirebaseAuth.instance.setSettings(
      appVerificationDisabledForTesting: kDebugMode,
    );
    Logger.i('Firebase Auth settings configured');

    runApp(const ProviderScope(child: MyApp()));
  } catch (e, stack) {
    Logger.e('Failed to initialize Firebase', e, stack);
    rethrow;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Clusty',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const LandingPage(),
    );
  }
}
