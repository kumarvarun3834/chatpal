import 'package:flutter/material.dart';
import 'package:chatpal/screens/chat_screen.dart';
import 'package:chatpal/models/user_model.dart';
import 'package:chatpal/services/firestore_service.dart' as firestore_service;
import 'package:chatpal/models/message_model.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  List<UserModel> users = []; // Placeholder for users list

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  void fetchUsers() async {
    // Example: fetch all users (implement search/filter later)
    List<UserModel> fetchedUsers = await _firestoreService.searchUsersByName('');
    setState(() {
      users = fetchedUsers;
    });
  }

  @override
  Widget build(BuildContext context) {
    double textScale = MediaQuery.textScaleFactorOf(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'ChatPal',
          style: TextStyle(fontSize: 20 * textScale),
        ),
      ),
      body: users.isEmpty
          ? Center(child: Text('No users found'))
          : ListView.builder(
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundImage: user.profilePicture.isNotEmpty
                  ? NetworkImage(user.profilePicture)
                  : null,
              child: user.profilePicture.isEmpty
                  ? Icon(Icons.person)
                  : null,
            ),
            title: Text(
              user.name,
              style: TextStyle(fontSize: 16 * textScale),
            ),
            subtitle: Text(
              user.bio,
              style: TextStyle(fontSize: 14 * textScale),
            ),
            onTap: () {
              // Navigate to ChatScreen with user email
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatScreen(receiverEmail: user.email),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Implement search or new chat functionality later
        },
        child: Icon(Icons.chat),
      ),
    );
  }
}
