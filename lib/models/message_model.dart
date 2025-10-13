// lib/models/message_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

/// Message model for ChatPal app
class MessageModel {
  final String senderEmail;   // Only store email for sender
  final String type;          // 'sent' or 'received'
  final DateTime sentDate;
  final String message;
  final bool viewStatus;      // true if read
  final String? media;        // optional image/video URL

  MessageModel({
    required this.senderEmail,
    required this.type,
    required this.sentDate,
    required this.message,
    this.viewStatus = false,
    this.media,
  });

  /// Convert MessageModel to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'senderEmail': senderEmail,
      'type': type,
      'sentDate': sentDate,
      'message': message,
      'viewStatus': viewStatus,
      'media': media ?? '',
    };
  }

  /// Convert Firestore document to MessageModel
  factory MessageModel.fromMap(Map<String, dynamic> map) {
    return MessageModel(
      senderEmail: map['senderEmail'] ?? '',
      type: map['type'] ?? 'sent',
      sentDate: (map['sentDate'] as Timestamp).toDate(),
      message: map['message'] ?? '',
      viewStatus: map['viewStatus'] ?? false,
      media: map['media'] ?? '',
    );
  }
}

/// Firestore helper for messages
class MessageService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Send a message (creates chat collection if not exists)
  Future<void> sendMessage({
    required String userEmail,        // sender email
    required String chatId,           // unique message ID
    required MessageModel message,
  }) async {
    try {
      await _db
          .collection('db_email')
          .doc(userEmail)
          .collection('chats')
          .doc(chatId)
          .set(message.toMap());
      print('Message sent for $userEmail with id $chatId');
    } catch (e) {
      print('Error sending message: $e');
    }
  }

  /// Fetch all messages for a user
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

  /// Update view status of a message
  Future<void> markAsRead({
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
