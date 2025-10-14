import 'package:cloud_firestore/cloud_firestore.dart';

/// User model for ChatPal app (UID-based)
class UserModel {
  final String uid;             // Firestore UID
  final String email;
  final String name;
  final String bio;
  final String profilePicture;  // Firebase Storage URL

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.bio,
    required this.profilePicture,
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
  factory UserModel.fromMap(String uid, Map<String, dynamic> map) {
    return UserModel(
      uid: uid,
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      bio: map['bio'] ?? '',
      profilePicture: map['profilePicture'] ?? '',
    );
  }
}

/// Firestore helper for user and chat operations
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Create or update user in db_user collection (using UID)
  Future<void> createUser(UserModel user) async {
    try {
      await _db.collection('db_user').doc(user.uid).set(user.toMap());
      print('✅ User created/updated: ${user.email}');
    } catch (e) {
      print('❌ Error creating user: $e');
    }
  }

  /// Fetch user by UID
  Future<UserModel?> getUser(String uid) async {
    try {
      final doc = await _db.collection('db_user').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromMap(uid, doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('❌ Error fetching user: $e');
      return null;
    }
  }

  /// Fetch all users
  Future<List<UserModel>> getAllUsers() async {
    try {
      final snapshot = await _db.collection('db_user').get();
      return snapshot.docs.map((doc) {
        return UserModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      print('❌ Error fetching users: $e');
      return [];
    }
  }

  // ----------------------------------------------------------------
  // 🔹 CHAT OPERATIONS (UID-based)
  // ----------------------------------------------------------------

  /// Send a message (stored under both sender & receiver)
  Future<void> sendMessage({
    required String senderUid,
    required String receiverUid,
    required String message,
  }) async {
    final timestamp = FieldValue.serverTimestamp();

    final msgData = {
      'message': message,
      'senderUid': senderUid,
      'sentDate': timestamp,
      'viewStatus': false,
    };

    final senderRef = _db.collection('db_user').doc(senderUid).collection('chats').doc(receiverUid);
    final receiverRef = _db.collection('db_user').doc(receiverUid).collection('chats').doc(senderUid);

    try {
      await senderRef.set({
        'messages': FieldValue.arrayUnion([msgData])
      }, SetOptions(merge: true));

      await receiverRef.set({
        'messages': FieldValue.arrayUnion([msgData])
      }, SetOptions(merge: true));

      print('✅ Message sent from $senderUid to $receiverUid');
    } catch (e) {
      print('❌ Error sending message: $e');
    }
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
    print('✅ Messages marked as read');
  }
}
