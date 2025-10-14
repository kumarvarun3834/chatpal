import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Firebase Random User Test',
      debugShowCheckedModeBanner: false,
      home: RandomUserSignupScreen(),
    );
  }
}

class RandomUserSignupScreen extends StatefulWidget {
  @override
  _RandomUserSignupScreenState createState() => _RandomUserSignupScreenState();
}

class _RandomUserSignupScreenState extends State<RandomUserSignupScreen> {
  bool _isLoading = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Generate random email
  String _generateRandomEmail() {
    int timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'user$timestamp@test.com';
  }

  Future<void> _createRandomUser() async {
    setState(() => _isLoading = true);

    String email = _generateRandomEmail();
    String password = 'Test@1234';

    try {
      // 1️⃣ Create Firebase Auth user
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;

      if (user != null) {
        // 2️⃣ Create Firestore doc with same UID
        await _firestore.collection('db_user').doc(user.uid).set({
          'email': email,
          'name': 'TestUser${DateTime.now().millisecondsSinceEpoch % 10000}',
          'bio': 'This is a test user',
          'profilePicture': '',
          'createdAt': FieldValue.serverTimestamp(),
        });

        print('✅ Added user: $email (UID: ${user.uid})');
      }

      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Created user: ${user?.email}')),
      );
    } on FirebaseAuthException catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Auth Error: ${e.message}')),
      );
      print('Auth Error: ${e.message}');
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unexpected Error: $e')),
      );
      print('Unexpected Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Random Firebase Users')),
      body: Center(
        child: _isLoading
            ? CircularProgressIndicator()
            : ElevatedButton(
          onPressed: _createRandomUser,
          child: Text('Create Random User'),
        ),
      ),
    );
  }
}
