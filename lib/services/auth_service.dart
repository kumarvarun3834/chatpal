// lib/services/auth_service.dart

import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// ------------------------------
  /// SIGN UP
  /// ------------------------------
  Future<User?> signUp(String email, String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } on FirebaseAuthException catch (e) {
      print('Sign-Up Error: ${e.code} - ${e.message}');
      return null;
    } catch (e) {
      print('Sign-Up Error: $e');
      return null;
    }
  }

  /// ------------------------------
  /// LOGIN
  /// ------------------------------
  Future<User?> login(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } on FirebaseAuthException catch (e) {
      print('Login Error: ${e.code} - ${e.message}');
      return null;
    } catch (e) {
      print('Login Error: $e');
      return null;
    }
  }

  /// ------------------------------
  /// LOGOUT
  /// ------------------------------
  Future<void> logout() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('Logout Error: $e');
    }
  }

  /// ------------------------------
  /// CURRENT USER
  /// ------------------------------
  User? getCurrentUser() {
    return _auth.currentUser;
  }
}
