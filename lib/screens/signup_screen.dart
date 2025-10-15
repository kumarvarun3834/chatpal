import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
// import '../services/firestore_service.dart';
import 'profile_module.dart';

class ProfileCreationScreen extends StatefulWidget {
  @override
  _ProfileCreationScreenState createState() => _ProfileCreationScreenState();
}

class _ProfileCreationScreenState extends State<ProfileCreationScreen> {
  final AuthService _auth = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmController = TextEditingController();

  bool _isLoading = false;

  Future<void> createProfile() async {
    String email = emailController.text.trim();
    String password = passwordController.text.trim();
    String confirm = confirmController.text.trim();

    if (password != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Create new Firebase user
      UserCredential result = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      User? user = result.user;

      if (user != null) {
        // Send verification email
        if (!user.emailVerified) {
          await user.sendEmailVerification();
        }

        setState(() => _isLoading = false);

        // Show verification dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Verify Your Email'),
            content: Text(
              'A verification email has been sent to $email.\n'
                  'Please verify it before continuing.',
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  await user.reload();
                  User? refreshedUser = FirebaseAuth.instance.currentUser;

                  if (refreshedUser != null && refreshedUser.emailVerified) {
                    Navigator.pop(context); // Close dialog

                    // Add user to Firestore after verification
                    final newUser = UserModel(
                      uid: refreshedUser.uid,
                      email: email,
                      name: email,
                      bio: 'hey i am using chatpal',
                      profilePicture: '',
                    );
                    await _firestoreService.createUser(newUser);

                    // Navigate to Profile Setup
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProfileSetupScreen(email: email),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Email not verified yet. Please check your inbox.'),
                      ),
                    );
                  }
                },
                child: const Text('I Verified'),
              ),
              TextButton(
                onPressed: () async {
                  try {
                    await user.sendEmailVerification();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Verification email resent.')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to resend email: $e')),
                    );
                  }
                },
                child: const Text('Resend Email'),
              ),
            ],
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Sign-up failed')),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unexpected error: $e')),
      );
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: confirmController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Confirm Password'),
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
              onPressed: createProfile,
              child: const Text('Create Account'),
            ),
          ],
        ),
      ),
    );
  }
}
