import 'package:flutter/material.dart';

class MessageBubble extends StatelessWidget {
  final String message;
  final bool isMe;          // true if message is sent by current user
  final bool viewStatus;    // for sent/delivered/read ticks
  final String? mediaUrl;   // optional image/video

  const MessageBubble({
    Key? key,
    required this.message,
    required this.isMe,
    this.viewStatus = false,
    this.mediaUrl,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
        decoration: BoxDecoration(
          color: isMe ? Colors.blueAccent : Colors.grey.shade300,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 0),
            bottomRight: Radius.circular(isMe ? 0 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment:
          isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // Show media if exists
            if (mediaUrl != null && mediaUrl!.isNotEmpty)
              Container(
                margin: EdgeInsets.only(bottom: 6),
                child: Image.network(
                  mediaUrl!,
                  fit: BoxFit.cover,
                ),
              ),

            // Message text
            Text(
              message,
              style: TextStyle(
                color: isMe ? Colors.white : Colors.black87,
                fontSize: 16,
              ),
            ),

            SizedBox(height: 4),

            // Sent/delivered/read tick
            if (isMe)
              Icon(
                viewStatus ? Icons.done_all : Icons.done,
                size: 16,
                color: viewStatus ? Colors.greenAccent : Colors.white70,
              ),
          ],
        ),
      ),
    );
  }
}
