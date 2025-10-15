import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// -------------------------------
  /// USER OPERATIONS
  /// -------------------------------
  Future<void> createUser(UserModel user) async {
    await _db.collection('db_user').doc(user.uid).set(user.toMap());
  }

  Future<UserModel?> getUser(String uid) async {
    final doc = await _db.collection('db_user').doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromMap(uid, doc.data()!);
  }

  Future<List<UserModel>> getAllUsers() async {
    final snapshot = await _db.collection('db_user').get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return UserModel.fromMap(doc.id, data);
    }).toList();
  }

  /// -------------------------------
  /// CHAT OPERATIONS
  /// -------------------------------
  final String chatsCollection = 'chats';

  String getChatId(String uid1, String uid2) {
    final ids = [uid1, uid2]..sort();
    return ids.join('_');
  }

  Future<void> sendMessage({
    required String senderUid,
    required String receiverUid,
    required String message,
  }) async {
    final chatId = getChatId(senderUid, receiverUid);
    final msgRef = _db.collection(chatsCollection).doc(chatId).collection('messages').doc();

    // Add message with initial "sending" status
    await msgRef.set({
      'senderUid': senderUid,
      'receiverUid': receiverUid,
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'sending',
    });

    // Update status to "sent"
    await msgRef.update({'status': 'sent'});
  }

  Stream<List<Map<String, dynamic>>> getMessages({
    required String userUid,
    required String chatPartnerUid,
  }) {
    final chatId = getChatId(userUid, chatPartnerUid);
    return _db
        .collection(chatsCollection)
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  Future<void> markAsDelivered({
    required String senderUid,
    required String receiverUid,
  }) async {
    final chatId = getChatId(senderUid, receiverUid);
    final snapshot = await _db
        .collection(chatsCollection)
        .doc(chatId)
        .collection('messages')
        .where('receiverUid', isEqualTo: receiverUid)
        .where('status', isEqualTo: 'sent')
        .get();

    for (final doc in snapshot.docs) {
      await doc.reference.update({'status': 'delivered'});
    }
  }

  Future<void> markAsRead({
    required String messageId,
    required String chatId,
  }) async {
    await _db
        .collection(chatsCollection)
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .update({'status': 'read'});
  }

  /// -------------------------------
  /// UNREAD MESSAGE COUNT
  /// -------------------------------
  /// Returns the number of unread messages between two users.
  ///
  Future<int> getUnreadMessageCount({
    required String senderUid,
    required String receiverUid,
  }) async {
    final chatId = getChatId(senderUid, receiverUid);
    final snapshot = await _db
        .collection(chatsCollection)
        .doc(chatId)
        .collection('messages')
        .where('receiverUid', isEqualTo: receiverUid)
        .where('status', isEqualTo: 'sent') // or 'delivered' if you count delivered but unread
        .get();

    return snapshot.docs.length;
  }

}
