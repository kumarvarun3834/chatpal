import 'package:cloud_firestore/cloud_firestore.dart';

/// Message model for ChatPal app
class MessageModel {
  final String senderEmail;   // who sent the message
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
      'sentDate': Timestamp.fromDate(sentDate),
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

  /// Send a message to both sender and receiver paths
  Future<void> sendMessage({
    required String senderEmail,
    required String receiverEmail,
    required MessageModel message,
  }) async {
    try {
      // References to both users’ chat paths
      final senderRef = _db
          .collection('db_user')
          .doc(senderEmail)
          .collection(receiverEmail)
          .doc(); // auto message ID

      final receiverRef = _db
          .collection('db_user')
          .doc(receiverEmail)
          .collection(senderEmail)
          .doc(); // same mirrored message

      await _db.runTransaction((txn) async {
        // Add "sent" message for sender
        txn.set(senderRef, message.toMap());

        // Add mirrored "received" message for receiver
        txn.set(
          receiverRef,
          MessageModel(
            senderEmail: senderEmail,
            type: 'received',
            sentDate: message.sentDate,
            message: message.message,
            viewStatus: false,
            media: message.media,
          ).toMap(),
        );
      });

      print('✅ Message sent between $senderEmail and $receiverEmail');
    } catch (e) {
      print('❌ Error sending message: $e');
    }
  }

  /// Stream messages between two users (live updates)
  Stream<List<MessageModel>> streamMessages({
    required String userEmail,
    required String chatPartnerEmail,
  }) {
    return _db
        .collection('db_user')
        .doc(userEmail)
        .collection(chatPartnerEmail)
        .orderBy('sentDate', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => MessageModel.fromMap(doc.data()))
        .toList());
  }

  /// Mark all unread messages from sender as read
  Future<void> markMessagesAsRead({
    required String receiverEmail,
    required String senderEmail,
  }) async {
    try {
      final query = await _db
          .collection('db_user')
          .doc(receiverEmail)
          .collection(senderEmail)
          .where('viewStatus', isEqualTo: false)
          .get();

      for (var doc in query.docs) {
        await doc.reference.update({'viewStatus': true});
      }

      print('✅ Marked messages as read for $receiverEmail from $senderEmail');
    } catch (e) {
      print('❌ Error marking messages as read: $e');
    }
  }
}

//
// db_user
// └── bee@gmail.com
// ├── xyz@gmail.com     ← chat partner
// │    ├── autoMsgId1
// │    │     ├── senderEmail: "bee@gmail.com"
// │    │     ├── message: "Hey"
// │    │     ├── type: "sent"
// │    │     ├── viewStatus: true
// │    │     ├── sentDate: ...
// │    │     └── media: ""
// │    └── autoMsgId2 ...
//