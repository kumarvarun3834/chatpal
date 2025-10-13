// lib/models/user_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

/// User model for ChatPal app
class UserModel {
  final String email;           // acts as unique ID
  final String name;
  final String bio;
  final String profilePicture;  // Firebase Storage URL

  UserModel({
    required this.email,
    required this.name,
    required this.bio,
    required this.profilePicture,
  });

  /// Convert UserModel to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'bio': bio,
      'profilePicture': profilePicture,
    };
  }

  /// Convert Firestore document to UserModel
  factory UserModel.fromMap(String email, Map<String, dynamic> map) {
    return UserModel(
      email: email,
      name: map['name'] ?? '',
      bio: map['bio'] ?? '',
      profilePicture: map['profilePicture'] ?? '',
    );
  }
}

/// Firestore helper for users
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Create or update user in db_user collection
  Future<void> createUser(UserModel user) async {
    try {
      await _db.collection('db_user').doc(user.email).set(user.toMap());
      print('User created/updated: ${user.email}');
    } catch (e) {
      print('Error creating user: $e');
    }
  }

  /// Fetch user by email
  Future<UserModel?> getUser(String email) async {
    try {
      DocumentSnapshot doc = await _db.collection('db_user').doc(email).get();
      if (doc.exists) {
        return UserModel.fromMap(email, doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Error fetching user: $e');
      return null;
    }
  }

  /// Search users by name (for search feature)
  Future<List<UserModel>> searchUsersByName(String query) async {
    try {
      QuerySnapshot snapshot = await _db
          .collection('db_user')
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: query + '\uf8ff')
          .get();

      return snapshot.docs
          .map((doc) => UserModel.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error searching users: $e');
      return [];
    }
  }
}
