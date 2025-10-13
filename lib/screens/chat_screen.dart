// lib/screens/chat_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chatpal/widgets/message_bubble.dart';
import 'package:chatpal/services/firestore_service.dart';
import 'package:chatpal/models/message_model.dart';

class ChatScreen extends StatefulWidget {
  final String receiverEmail;

  const ChatScreen({Key? key, required this.receiverEmail}) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FirestoreService _firestoreService = FirestoreService();
  final String currentUserEmail = FirebaseAuth.instance.currentUser!.email!;

  void sendMessage() async {
    String messageText = _messageController.text.trim();
    if (messageText.isEmpty) return;

    final message = MessageModel(
      message: messageText,
      senderEmail: currentUserEmail,
      type: 'text',
      sentDate: DateTime.now(),
      viewStatus: false,
    );

    final chatId = DateTime.now().millisecondsSinceEpoch.toString();

    // Save message for sender
    await _firestoreService.createChatDocument(
      userEmail: currentUserEmail,
      chatId: chatId,
      message: message,
    );

    // Save message for receiver
    await _firestoreService.createChatDocument(
      userEmail: widget.receiverEmail,
      chatId: chatId,
      message: message,
    );

    _messageController.clear();
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent + 70,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double textScale = MediaQuery.textScaleFactorOf(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.receiverEmail,
          style: TextStyle(fontSize: 18 * textScale),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('db_email')
                  .doc(currentUserEmail)
                  .collection('chats')
                  .orderBy('sentDate')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;
                return ListView.builder(
                  controller: _scrollController,
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var data = docs[index].data() as Map<String, dynamic>;
                    bool isMe = data['sender'] == currentUserEmail;

                    return MessageBubble(
                      message: data['message'] ?? '',
                      isMe: isMe,
                      viewStatus: data['viewStatus'] ?? false,
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Type a message',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  CircleAvatar(
                    radius: 24,
                    child: IconButton(
                      icon: Icon(Icons.send),
                      onPressed: sendMessage,
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
