import 'package:flutter/material.dart';
import 'package:chatpal/screens/chat_screen.dart';
import 'package:chatpal/screens/profile_module.dart';
import 'package:chatpal/models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
// import '../services/firestore_service.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<UserModel> users = [];
  List<UserModel> filteredUsers = [];
  String searchQuery = '';

  Map<String, int> unreadCounts = {}; // unread messages per user
  Map<String, Stream<int>> unreadStreams = {}; // store streams

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  void fetchUsers() async {
    List<UserModel> fetchedUsers = await _firestoreService.getAllUsers();
    setState(() {
      users = fetchedUsers;
      filteredUsers = fetchedUsers;
    });

    // Listen for unread counts for each user
    for (var user in users) {
      if (user.uid == _auth.currentUser!.uid) continue;
      if (unreadStreams[user.uid] != null) continue; // already listening

      Stream<int> stream = _firestoreService.unreadMessageCountStream(
        senderUid: user.uid,
        receiverUid: _auth.currentUser!.uid,
      );

      stream.listen((count) {
        setState(() {
          unreadCounts[user.uid] = count;
        });
      });

      unreadStreams[user.uid] = stream;
    }
  }

  void logout() async {
    await _auth.signOut();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => LoginScreen()),
    );
  }

  void _filterUsers(String query) {
    final lowerQuery = query.toLowerCase();
    setState(() {
      searchQuery = query;
      filteredUsers = users
          .where((user) => user.name.toLowerCase().contains(lowerQuery))
          .toList();
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
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Theme.of(context).primaryColor),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: NetworkImage(
                      'https://i.pravatar.cc/150?img=3',
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    _auth.currentUser?.email ?? 'No Email',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.person),
              title: Text('Profile'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProfileSetupScreen(
                      email: _auth.currentUser?.email ?? '',
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('Logout'),
              onTap: logout,
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search users...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: _filterUsers,
            ),
          ),

          // Users list
          Expanded(
            child: filteredUsers.isEmpty
                ? Center(child: Text('No users found'))
                : ListView.builder(
              itemCount: filteredUsers.length,
              itemBuilder: (context, index) {
                final user = filteredUsers[index];
                if (user.uid == _auth.currentUser!.uid) return SizedBox.shrink();

                int unreadCount = unreadCounts[user.uid] ?? 0;

                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: user.profilePicture.isNotEmpty
                        ? NetworkImage(user.profilePicture)
                        : null,
                    child: user.profilePicture.isEmpty ? Icon(Icons.person) : null,
                  ),
                  title: Text(
                    user.name,
                    style: TextStyle(fontSize: 16 * textScale),
                  ),
                  subtitle: Text(
                    user.bio,
                    style: TextStyle(fontSize: 14 * textScale),
                  ),
                  trailing: unreadCount > 0
                      ? Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      unreadCount.toString(),
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  )
                      : null,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(
                          receiverUid: user.uid,
                          receiverName: user.name,
                        ),
                      ),
                    ).then((_) => fetchUsers());
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: Icon(Icons.chat),
      ),
    );
  }
}
