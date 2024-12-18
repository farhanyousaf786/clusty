import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'screens/landing_page.dart';
import 'package:flutter/foundation.dart';
import 'utils/logger.dart';
import 'providers/theme_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Enable verbose logging in debug mode
  if (kDebugMode) {
    Logger.i('Starting app in debug mode');
  }

  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    Logger.i('Firebase initialized successfully');
  } catch (e) {
    Logger.e('Failed to initialize Firebase', e);
  }

  // Configure Firebase Auth settings
  await FirebaseAuth.instance.setSettings(
    appVerificationDisabledForTesting: true,
  );
  Logger.i('Firebase Auth settings configured');

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    
    return MaterialApp(
      title: 'Clusty',
      debugShowCheckedModeBanner: false,
      theme: theme,
      home: const LandingPage(),
    );
  }
}
