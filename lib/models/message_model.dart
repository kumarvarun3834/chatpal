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

  /// Stream of unread message count
  static Stream<int> unreadMessageCountStream({
    required String senderUid,
    required String receiverUid,
  }) {
    final docRef = FirebaseFirestore.instance
        .collection('db_user')
        .doc(receiverUid)
        .collection('chats')
        .doc(senderUid);

    return docRef.snapshots().map((snapshot) {
      if (!snapshot.exists) return 0;
      final messages = List<Map<String, dynamic>>.from(snapshot.data()?['messages'] ?? []);
      return messages.where((msg) => msg['viewStatus'] == false && msg['senderUid'] == senderUid).length;
    });
  }
}

/// Service for sending and streaming messages
class MessageService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Send a message to both sender and receiver paths
  Future<void> sendMessage({
    required String senderEmail,
    required String receiverEmail,
    required MessageModel message,
  }) async {
    final senderRef = _db.collection('db_user').doc(senderEmail).collection(receiverEmail).doc();
    final receiverRef = _db.collection('db_user').doc(receiverEmail).collection(senderEmail).doc();

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
  }

  /// Stream messages between two users
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
        .map((snapshot) => snapshot.docs.map((d) => MessageModel.fromMap(d.data())).toList());
  }

  /// Mark all unread messages from sender as read
  Future<void> markMessagesAsRead({
    required String receiverEmail,
    required String senderEmail,
  }) async {
    final query = await _db
        .collection('db_user')
        .doc(receiverEmail)
        .collection(senderEmail)
        .where('viewStatus', isEqualTo: false)
        .get();

    for (var doc in query.docs) {
      await doc.reference.update({'viewStatus': true});
    }
  }
}
