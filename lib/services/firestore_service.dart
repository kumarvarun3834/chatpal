// lib/services/firestore_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/message_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// -------------------------------
  /// USER OPERATIONS
  /// -------------------------------

  Future<void> createUser(UserModel user) async {
    try {
      await _db.collection('db_user').doc(user.email).set(user.toMap());
      print('✅ User created/updated: ${user.email}');
    } catch (e) {
      print('❌ Error creating user: $e');
    }
  }

  Future<UserModel?> getUser(String email) async {
    try {
      DocumentSnapshot doc = await _db.collection('db_user').doc(email).get();
      if (doc.exists) {
        return UserModel.fromMap(email, doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('❌ Error fetching user: $e');
      return null;
    }
  }

  Future<List<UserModel>> getAllUsers() async {
    try {
      QuerySnapshot snapshot = await _db.collection('db_user').get();
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return UserModel(
          email: doc.id,
          name: data['name'] ?? '',
          bio: data['bio'] ?? '',
          profilePicture: data['profilePicture'] ?? '',
          uid: data['uid'] ?? '', // fetch UID from Firestore if stored
        );

      }).toList();
    } catch (e) {
      print('❌ Error fetching users: $e');
      return [];
    }
  }

  /// -------------------------------
  /// CHAT OPERATIONS (UID-based)
  /// -------------------------------

  /// Send a message (stored under both sender & receiver)
  Future<void> sendMessage({
    required String senderUid,
    required String receiverUid,
    required String message,
  }) async {
    final chatId = [senderUid, receiverUid]..sort();
    final chatDoc = FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId.join('_'));

    final msgRef = chatDoc.collection('messages').doc();

    await msgRef.set({
      'senderUid': senderUid,
      'receiverUid': receiverUid,
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'sending',
    });

    // Simulate upload success → update to "sent"
    await msgRef.update({'status': 'sent'});
  }

  Future<void> markAsDelivered({
    required String senderUid,
    required String receiverUid,
  }) async {
    final chatId = [senderUid, receiverUid]..sort();
    final messages = await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId.join('_'))
        .collection('messages')
        .where('receiverUid', isEqualTo: receiverUid)
        .where('status', isEqualTo: 'sent')
        .get();

    for (final doc in messages.docs) {
      await doc.reference.update({'status': 'delivered'});
    }
  }

  Future<void> markAsRead(String messageId, String chatId) async {
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .update({'status': 'read'});
  }

  /// Stream messages between two users
  Stream<List<Map<String, dynamic>>> getMessages({
    required String userUid,
    required String chatPartnerUid,
  }) {
    return _db
        .collection('db_user')
        .doc(userUid)
        .collection('chats')
        .doc(chatPartnerUid)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return [];
      final data = doc.data();
      return List<Map<String, dynamic>>.from(data?['messages'] ?? []);
    });
  }

  /// Mark all messages as read
  Future<void> markMessagesAsRead({
    required String userUid,
    required String chatPartnerUid,
  }) async {
    final docRef = _db
        .collection('db_user')
        .doc(userUid)
        .collection('chats')
        .doc(chatPartnerUid);

    final snapshot = await docRef.get();
    if (!snapshot.exists) return;

    final messages = List<Map<String, dynamic>>.from(snapshot.data()?['messages'] ?? []);
    final updatedMessages = messages.map((msg) {
      msg['viewStatus'] = true;
      return msg;
    }).toList();

    await docRef.update({'messages': updatedMessages});
    print('✅ Messages marked as read for $userUid');
  }
}
