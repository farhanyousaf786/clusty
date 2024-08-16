import 'package:clusty_stf/pages/auth_page/clusty_privacy_policy.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/user_repo/user_apis.dart';
import '../navigation_page/navigation_page.dart';

class SignUpPage extends StatefulWidget {
  @override
  _SignUpPageState createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final UserApi _userApi = UserApi();
  bool _isUsernameUnique = true;
  bool _isTermsAccepted = false;

  void _signUp() async {
    try {
      if (!_isUsernameUnique) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Username is already taken')),
        );
        return;
      }

      String result = await _userApi.createUserWithEmailAndPassword(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (result == "success") {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => NavigationPage(user: _auth.currentUser!)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result)),
        );
      }
    } on FirebaseAuthException catch (e) {
      print(e.message);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Unknown error')),
      );
    }
  }

  void _checkUsername() async {
    final username = _usernameController.text.trim();
    final isUnique = await _userApi.isUsernameUnique(username);
    setState(() {
      _isUsernameUnique = isUnique;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Sign Up')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _firstNameController,
              decoration: InputDecoration(labelText: 'First Name'),
            ),
            TextField(
              controller: _lastNameController,
              decoration: InputDecoration(labelText: 'Last Name'),
            ),
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(
                labelText: 'Username',
                suffixIcon: _usernameController.text.isNotEmpty
                    ? Icon(
                  _isUsernameUnique ? Icons.check : Icons.close,
                  color: _isUsernameUnique ? Colors.green : Colors.red,
                )
                    : null,
              ),
              onChanged: (value) => _checkUsername(),
            ),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            Row(
              children: [
                Checkbox(
                  value: _isTermsAccepted,
                  onChanged: (value) {
                    setState(() {
                      _isTermsAccepted = value!;
                    });
                  },
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => ClustyPrivacyPolicy()),
                      );
                    },
                    child: Text(
                      'I accept the Terms and Conditions and Privacy Policy',
                      style: TextStyle(decoration: TextDecoration.underline),
                    ),
                  ),
                ),
              ],
            ),
            ElevatedButton(
              onPressed: _isTermsAccepted ? _signUp : null,
              child: Text('Sign Up'),
            ),
          ],
        ),
      ),
    );
  }
}
