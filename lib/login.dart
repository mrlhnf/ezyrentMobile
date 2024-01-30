import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final formKey = GlobalKey<FormState>();

  Future<void> _login() async {
    if (formKey.currentState!.validate()) {
      formKey.currentState!.save();
      try {
        UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text,
          password: _passwordController.text,
        );
        User? user = userCredential.user;
        print('User log in: ${user?.email}');

        final userUid = userCredential.user?.uid;
        DocumentSnapshot snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(userUid)
            .get();
        if (snapshot.exists) {
          final Map<String, dynamic>? data = snapshot.data() as Map<String, dynamic>?;
          if (data != null && data.containsKey('role')) {
            final userRole = data['role'];
            // Render the appropriate page based on the user's role
            if (userRole == 'Landlord') {
              Navigator.pushReplacementNamed(context, '/OwnerHomepage');
            } else if (userRole == 'Student') {
              Navigator.pushReplacementNamed(context, '/StudentHomepage');
            }
          }
        } else {
          print('User document does not exist');
        }
      } catch (e) {
        // Handle any errors that occurred during login
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Login failed. Please check your email and password.')));
        print('Error logging in: $e');
      }
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      final GoogleSignInAuthentication googleAuth = await googleUser!.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);

      final String? email = userCredential.user!.email;
      final String userid = userCredential.user!.uid;

      print('Signed in with Google and UID: $email $userid');

      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userid)
          .get();
      if (snapshot.exists) {
        final Map<String, dynamic>? data = snapshot.data() as Map<String, dynamic>?;
        if (data != null && data.containsKey('role')) {
          final userRole = data['role'];
          // Render the appropriate page based on the user's role
          if (userRole == 'Landlord') {
            Navigator.pushReplacementNamed(context, '/OwnerHomepage');
          } else if (userRole == 'Student') {
            Navigator.pushReplacementNamed(context, '/StudentHomepage');
          }
        }
      } else {
        print('User document does not exist');
      }

    } catch (e) {
      print('Error signing in with Google: $e');
    }
  }

  void _goToRegistration() {
    Navigator.pushReplacementNamed(context, '/register');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurpleAccent,
        title: const Text('Login'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: formKey,
            child: Column(
              children: [
                Image.asset(
                  'images/mylogo.png',
                  width: 200,
                  height: 200,
                ),
                const SizedBox(height: 16.0),
                TextFormField(
                  controller: _emailController,
                  validator: (value) {
                    if (value!.isEmpty) {
                      return 'Please enter your email';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    labelText: 'Email',
                    labelStyle: const TextStyle(
                      color: Colors.purple,
                      fontWeight: FontWeight.bold,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.purple, width: 2.0),
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.purple, width: 2.0),
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: const Icon(
                      Icons.alternate_email,
                      color: Colors.purple,
                    ),
                  ),
                ),
                TextFormField(
                  controller: _passwordController,
                  validator: (value) {
                    if (value!.isEmpty) {
                      return 'Please enter your password';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    labelText: 'Password',
                    labelStyle: const TextStyle(
                      color: Colors.purple,
                      fontWeight: FontWeight.bold,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.purple, width: 2.0),
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.purple, width: 2.0),
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    prefixIcon: const Icon(
                      Icons.password,
                      color: Colors.purple,
                    ),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 16.0),
                ElevatedButton.icon(
                  onPressed: _login,
                  label: const Icon(
                    Icons.email,
                    color: Colors.white,
                  ),
                  icon: const Text(
                    'Login using',
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                  style: ButtonStyle(
                    shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.0), // Set the desired border radius
                      ),
                    ),
                    minimumSize: MaterialStateProperty.all<Size>(
                      const Size(120.0, 40.0), // Set the desired width and height
                    ),
                    backgroundColor: MaterialStateProperty.all<Color>(Colors.blue[900]!),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: signInWithGoogle,
                  label: Image.asset(
                    'images/google.png',
                    width: 24,
                    height: 24,
                  ),
                  icon: const Text(
                    'Login using',
                    style: TextStyle(
                      color: Colors.black,
                    ),
                  ),
                  style: ButtonStyle(
                    shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.0),
                        side: const BorderSide(color: Colors.black),
                      ),
                    ),
                    minimumSize: MaterialStateProperty.all<Size>(
                      const Size(120.0, 40.0), // Set the desired width and height
                    ),
                    backgroundColor: MaterialStateProperty.all<Color>(Colors.white),
                  ),
                ),
                const SizedBox(height: 8.0),
                TextButton(
                  onPressed: _goToRegistration,
                  child: const Text('Create an account'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}