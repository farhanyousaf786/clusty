import 'package:clusty/pages/navigation_page/navigation_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../services/get_it_locator.dart';
import '../intro_page/intro_page.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: userRepository.authState,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          User? user = snapshot.data;
          if (user == null) {
            return const IntroPage();
          } else {
            if (user.isAnonymous) {
              return Scaffold(
                appBar: AppBar(
                  title: const Text("Anon user"),
                ),
                body: Center(
                  child: Text('Welcome, anonymous user!'),
                ),
              );
            } else {
              return MultiProvider(
                providers: [
                  StreamProvider(
                    create: (context) => userRepository.getCurrentUser,
                    initialData: null,
                  ),
                  ChangeNotifierProvider(create: (_) => UserProvider()),
                ],
                child: Provider<User>.value(
                  value: user,
                  child: NavigationPage(user: user,),
                ),
              );
            }
          }
        } else {
          return Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: CircularProgressIndicator(
                color: Colors.blue.shade700,
              ),
            ),
          );
        }
      },
    );
  }
}
