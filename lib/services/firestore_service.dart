// lib/services/firestore_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/message_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Save a new user (creates db_user collection if not exists)
  Future<void> createUser(UserModel user) async {
    try {
      await _db.collection('db_user').doc(user.email).set(user.toMap());
      print('User created: ${user.email}');
    } catch (e) {
      print('Error creating user: $e');
    }
  }

  /// Fetch a user by email
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

  /// Search users by name
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

  /// -------------------------------
  /// MESSAGE OPERATIONS (db_email)
  /// -------------------------------

  /// Create chat document for a user (db_email/<email>/chats)
  Future<void> createChatDocument({
    required String userEmail,
    required MessageModel message,
    required String chatId,
  }) async {
    try {
      await _db
          .collection('db_email')
          .doc(userEmail)
          .collection('chats')
          .doc(chatId)
          .set(message.toMap());
      print('Chat created for $userEmail with id $chatId');
    } catch (e) {
      print('Error creating chat: $e');
    }
  }

  /// Fetch messages for a user
  Future<List<MessageModel>> getMessages(String userEmail) async {
    try {
      QuerySnapshot snapshot = await _db
          .collection('db_email')
          .doc(userEmail)
          .collection('chats')
          .orderBy('sentDate', descending: false)
          .get();

      return snapshot.docs
          .map((doc) => MessageModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error fetching messages: $e');
      return [];
    }
  }

  /// Mark message as read
  Future<void> markMessageAsRead({
    required String userEmail,
    required String chatId,
  }) async {
    try {
      await _db
          .collection('db_email')
          .doc(userEmail)
          .collection('chats')
          .doc(chatId)
          .update({'viewStatus': true});
      print('Message $chatId marked as read for $userEmail');
    } catch (e) {
      print('Error updating view status: $e');
    }
  }
}
