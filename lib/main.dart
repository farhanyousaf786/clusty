import 'package:clusty_stf/firebase_options.dart';
import 'package:clusty_stf/pages/landing_page/landing_page.dart';
import 'package:clusty_stf/providers/follow_provder.dart';
import 'package:clusty_stf/providers/theme_provider.dart';
import 'package:clusty_stf/providers/user_provider.dart';
import 'package:clusty_stf/services/get_it_locator.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  DependencyInjectionEnvironment.setup();
  await storage.init();
  runApp(MultiProvider(providers: [
    StreamProvider(
        create: (_) => userRepository.getCurrentUser, initialData: null),
    ChangeNotifierProvider(create: (_) => UserProvider()),
    ChangeNotifierProvider(create: (_) => ThemeProvider()), // Add ThemeProvider
    ChangeNotifierProvider<FollowProvider>(create: (_) => FollowProvider()),

  ], child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Clusty',
      theme: themeProvider.isDarkMode ? darkTheme : lightTheme,
      home: const LandingPage(),
    );
  }
}
