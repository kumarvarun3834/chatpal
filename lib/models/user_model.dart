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

/// Firestore helper for user and chat operations
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Create or update user in db_user collection
  Future<void> createUser(UserModel user) async {
    try {
      await _db.collection('db_user').doc(user.email).set(user.toMap());
      print('✅ User created/updated: ${user.email}');
    } catch (e) {
      print('❌ Error creating user: $e');
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
      print('❌ Error fetching user: $e');
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
      print('❌ Error searching users: $e');
      return [];
    }
  }

  // ----------------------------------------------------------------
  // 🔹 CHAT OPERATIONS (following your preferred structure)
  // ----------------------------------------------------------------

  /// Send a message (stored under both sender & receiver)
  Future<void> sendMessage({
    required String senderEmail,
    required String receiverEmail,
    required String message,
  }) async {
    final timestamp = FieldValue.serverTimestamp();

    final msgData = {
      'message': message,
      'timestamp': timestamp,
      'status': 'sent',
      'type': 'sent',
    };

    final receiverMsgData = {
      'message': message,
      'timestamp': timestamp,
      'status': 'delivered',
      'type': 'received',
    };

    // Sender document → receiver subdoc
    final senderChatRef = _db
        .collection('db_user')
        .doc(senderEmail)
        .collection('chats')
        .doc(receiverEmail);

    // Receiver document → sender subdoc
    final receiverChatRef = _db
        .collection('db_user')
        .doc(receiverEmail)
        .collection('chats')
        .doc(senderEmail);

    try {
      await senderChatRef.set({
        'messages': FieldValue.arrayUnion([msgData])
      }, SetOptions(merge: true));

      await receiverChatRef.set({
        'messages': FieldValue.arrayUnion([receiverMsgData])
      }, SetOptions(merge: true));

      print('✅ Message sent from $senderEmail to $receiverEmail');
    } catch (e) {
      print('❌ Error sending message: $e');
    }
  }

  /// Stream messages between two users
  Stream<List<Map<String, dynamic>>> getMessages({
    required String userEmail,
    required String chatPartnerEmail,
  }) {
    return _db
        .collection('db_user')
        .doc(userEmail)
        .collection('chats')
        .doc(chatPartnerEmail)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return [];
      final data = doc.data();
      return List<Map<String, dynamic>>.from(data?['messages'] ?? []);
    });
  }

  /// Mark messages as read
  Future<void> markMessagesAsRead({
    required String receiverEmail,
    required String senderEmail,
  }) async {
    final docRef = _db
        .collection('db_user')
        .doc(receiverEmail)
        .collection('chats')
        .doc(senderEmail);

    final snapshot = await docRef.get();
    if (!snapshot.exists) return;

    final messages = List<Map<String, dynamic>>.from(snapshot.data()?['messages'] ?? []);
    final updatedMessages = messages.map((msg) {
      if (msg['status'] == 'delivered') msg['status'] = 'read';
      return msg;
    }).toList();

    await docRef.update({'messages': updatedMessages});
    print('✅ Messages marked as read');
  }
}
