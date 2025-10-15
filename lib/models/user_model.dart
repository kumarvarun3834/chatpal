import 'package:cloud_firestore/cloud_firestore.dart';

/// User model for ChatPal app with unread message support
class UserModel {
  final String uid;             // Firestore UID
  final String email;
  final String name;
  final String bio;
  final String profilePicture;  // Firebase Storage URL

  int unreadCount;              // Not stored in Firestore, dynamic

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.bio,
    required this.profilePicture,
    this.unreadCount = 0,
  });

  /// Convert UserModel to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'bio': bio,
      'profilePicture': profilePicture,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  /// Convert Firestore document to UserModel
  factory UserModel.fromMap(String uid, Map<String, dynamic> map, {int unreadCount = 0}) {
    return UserModel(
      uid: uid,
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      bio: map['bio'] ?? '',
      profilePicture: map['profilePicture'] ?? '',
      unreadCount: unreadCount,
    );
  }
}

/// Firestore service for user and chat operations
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Create or update user
  Future<void> createUser(UserModel user) async {
    try {
      await _db.collection('db_user').doc(user.uid).set(user.toMap());
      print('✅ User created/updated: ${user.email}');
    } catch (e) {
      print('❌ Error creating user: $e');
    }
  }

  /// Fetch all users
  Future<List<UserModel>> getAllUsers() async {
    try {
      final snapshot = await _db.collection('db_user').get();
      return snapshot.docs.map((doc) {
        return UserModel.fromMap(doc.id, doc.data());
      }).toList();
    } catch (e) {
      print('❌ Error fetching users: $e');
      return [];
    }
  }

  /// Get unread message count
  Future<int> getUnreadMessageCount({
    required String senderUid,
    required String receiverUid,
  }) async {
    try {
      final docRef = _db.collection('db_user').doc(receiverUid).collection('chats').doc(senderUid);
      final snapshot = await docRef.get();
      if (!snapshot.exists) return 0;

      final messages = List<Map<String, dynamic>>.from(snapshot.data()?['messages'] ?? []);
      return messages.where((msg) => msg['viewStatus'] == false && msg['senderUid'] == senderUid).length;
    } catch (e) {
      print('❌ Error fetching unread count: $e');
      return 0;
    }
  }

  /// Stream of unread message count
  Stream<int> unreadMessageCountStream({
    required String senderUid,
    required String receiverUid,
  }) {
    final docRef = _db.collection('db_user').doc(receiverUid).collection('chats').doc(senderUid);
    return docRef.snapshots().map((snapshot) {
      if (!snapshot.exists) return 0;
      final messages = List<Map<String, dynamic>>.from(snapshot.data()?['messages'] ?? []);
      return messages.where((msg) => msg['viewStatus'] == false && msg['senderUid'] == senderUid).length;
    });
  }

  /// Send a message (stored under both sender & receiver)
  Future<void> sendMessage({
    required String senderUid,
    required String receiverUid,
    required String message,
  }) async {
    final timestamp = FieldValue.serverTimestamp();

    final msgDataForReceiver = {
      'senderUid': senderUid,
      'receiverUid': receiverUid,
      'message': message,
      'timestamp': timestamp,
      'viewStatus': false, // UNREAD for receiver
    };

    final msgDataForSender = {
      'senderUid': senderUid,
      'receiverUid': receiverUid,
      'message': message,
      'timestamp': timestamp,
      'viewStatus': true, // always read for sender
    };

    final senderRef = _db.collection('db_user').doc(senderUid).collection('chats').doc(receiverUid);
    final receiverRef = _db.collection('db_user').doc(receiverUid).collection('chats').doc(senderUid);

    await senderRef.set({'messages': FieldValue.arrayUnion([msgDataForSender])}, SetOptions(merge: true));
    await receiverRef.set({'messages': FieldValue.arrayUnion([msgDataForReceiver])}, SetOptions(merge: true));
  }

  /// Mark messages as read
  Future<void> markMessagesAsRead({
    required String receiverUid,
    required String senderUid,
  }) async {
    final docRef = _db.collection('db_user').doc(receiverUid).collection('chats').doc(senderUid);
    final snapshot = await docRef.get();
    if (!snapshot.exists) return;

    final messages = List<Map<String, dynamic>>.from(snapshot.data()?['messages'] ?? []);
    final updatedMessages = messages.map((msg) {
      if (msg['viewStatus'] == false && msg['senderUid'] == senderUid) msg['viewStatus'] = true;
      return msg;
    }).toList();

    await docRef.update({'messages': updatedMessages});
  }
}
