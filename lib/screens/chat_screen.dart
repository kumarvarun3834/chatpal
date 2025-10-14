import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chatpal/services/firestore_service.dart';

class ChatScreen extends StatefulWidget {
  final String receiverUid;
  final String receiverName;

  const ChatScreen({
    Key? key,
    required this.receiverUid,
    required this.receiverName,
  }) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FirestoreService _firestoreService = FirestoreService();
  final String currentUserUid = FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _markMessagesAsDelivered();
  }

  Future<void> _markMessagesAsDelivered() async {
    await _firestoreService.markAsDelivered(
      senderUid: widget.receiverUid,
      receiverUid: currentUserUid,
    );
  }

  Future<void> sendMessage() async {
    String messageText = _messageController.text.trim();
    if (messageText.isEmpty) return;

    try {
      await _firestoreService.sendMessage(
        senderUid: currentUserUid,
        receiverUid: widget.receiverUid,
        message: messageText,
      );

      _messageController.clear();
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 80,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error sending message: $e')),
      );
    }
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
          widget.receiverName,
          style: TextStyle(fontSize: 18 * textScale),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _firestoreService.getMessages(
                userUid: currentUserUid,
                chatPartnerUid: widget.receiverUid,
              ),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!;
                final isSending = messages.any((m) => m['status'] == 'sending');

                return Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        controller: _scrollController,
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final msg = messages[index];
                          bool isMe = msg['senderUid'] == currentUserUid;

                          return Align(
                            alignment: isMe
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              margin: EdgeInsets.symmetric(
                                  vertical: 4, horizontal: 8),
                              padding: EdgeInsets.symmetric(
                                  vertical: 8, horizontal: 12),
                              decoration: BoxDecoration(
                                color: isMe
                                    ? Colors.blue[100]
                                    : Colors.grey[200],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Flexible(
                                    child: Text(
                                      msg['message'] ?? '',
                                      style: TextStyle(fontSize: 15),
                                    ),
                                  ),
                                  if (isMe) ...[
                                    SizedBox(width: 6),
                                    _buildStatusIcon(msg['status']),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    // 🔶 Status bar for pending uploads
                    if (isSending)
                      Container(
                        color: Colors.orange.shade50,
                        padding: EdgeInsets.all(6),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.cloud_upload,
                                size: 16, color: Colors.orange),
                            SizedBox(width: 6),
                            Text(
                              'Sending messages...',
                              style: TextStyle(color: Colors.orange),
                            ),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
          ),

          // ✉️ Message input bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
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
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIcon(String? status) {
    switch (status) {
      case 'sending':
        return Icon(Icons.access_time, size: 16, color: Colors.grey);
      case 'sent':
        return Icon(Icons.done, size: 16, color: Colors.grey);
      case 'delivered':
        return Icon(Icons.done_all, size: 16, color: Colors.grey);
      case 'read':
        return Icon(Icons.done_all, size: 16, color: Colors.blueAccent);
      default:
        return SizedBox.shrink();
    }
  }
}
