import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'chat_page.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({Key? key}) : super(key: key);

  @override
  _ChatListPageState createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _auth.authStateChanges().listen((User? user) {
      setState(() {
        _currentUser = user;
      });
    });
  }

  Widget _buildChatListItem(DocumentSnapshot chatRoomDoc) {
    if (_currentUser == null) {
      return const SizedBox();
    }

    final chatRoomData = chatRoomDoc.data() as Map<String, dynamic>;
    final users = chatRoomData['users'] as Map<String, dynamic>? ?? {};
    final lastMessage = chatRoomData['lastMessage'] as String? ?? '';
    final lastMessageTime = chatRoomData['lastMessageTime'] as Timestamp?;
    final lastMessageSender = chatRoomData['lastMessageSender'] as String? ?? '';
    final unreadCount = chatRoomData['unreadCount'] as int? ?? 0;
    final isLastMessageRead = chatRoomData['lastMessageRead'] as bool? ?? true;

    // Get the other user's ID
    String otherUserId = users.keys.firstWhere(
          (userId) => userId != _currentUser!.uid,
      orElse: () => '',
    );

    if (otherUserId.isEmpty) return const SizedBox();

    return FutureBuilder<DocumentSnapshot>(
      future: _firestore.collection('users').doc(otherUserId).get(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
          return ListTile(
            title: Text('Unknown User ($otherUserId)'),
            subtitle: Text(lastMessage),
          );
        }

        final userData = userSnapshot.data!.data() as Map<String, dynamic>;
        final firstName = userData['first_name'] as String? ?? '';
        final lastName = userData['last_name'] as String? ?? '';
        final userName = '$firstName $lastName';
        final userPhoto = userData['profileImage'] as String?;

        return ListTile(
          leading: CircleAvatar(
            radius: 28,
            backgroundImage: userPhoto != null ? NetworkImage(userPhoto) : null,
            child: userPhoto == null
                ? Text(
              userName.isNotEmpty ? userName[0].toUpperCase() : '?',
              style: const TextStyle(fontSize: 20),
            )
                : null,
          ),
          title: Text(
            userName,
            style: TextStyle(
              fontWeight: unreadCount > 0 || !isLastMessageRead
                  ? FontWeight.bold
                  : FontWeight.normal,
            ),
          ),
          subtitle: Text(
            lastMessageSender == _currentUser!.uid
                ? 'You: $lastMessage'
                : lastMessage,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: unreadCount > 0 || !isLastMessageRead
                  ? FontWeight.bold
                  : FontWeight.normal,
              color: unreadCount > 0 || !isLastMessageRead
                  ? Colors.black
                  : Colors.grey,
            ),
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                lastMessageTime != null
                    ? _formatLastMessageTime(lastMessageTime.toDate())
                    : '',
                style: TextStyle(
                  color: unreadCount > 0 || !isLastMessageRead
                      ? Colors.teal
                      : Colors.grey,
                  fontSize: 12,
                ),
              ),
              if (unreadCount > 0)
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.teal,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    unreadCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatPage(
                  chatRoomId: chatRoomDoc.id,
                  otherUserId: otherUserId,
                  otherUserName: userName,
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _formatLastMessageTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);

    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (messageDate == today) {
      return DateFormat('h:mm a').format(dateTime);
    } else if (messageDate == yesterday) {
      return 'Yesterday';
    } else {
      return DateFormat('MMM d').format(dateTime);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Messages',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            letterSpacing: 0.8,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 70,
        iconTheme: IconThemeData(color: Colors.white),
        flexibleSpace: ClipRRect(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF008080),
                  Color(0xFF006D6D),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 12,
                  spreadRadius: 0.5,
                  offset: Offset(0, 6),
                ),
              ],
            ),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('chatRooms')
            .where('users.${_currentUser!.uid}', isEqualTo: true)
            .orderBy('lastMessageTime', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final chatRooms = snapshot.data?.docs ?? [];

          if (chatRooms.isEmpty) {
            return const Center(
              child: Text('No conversations yet'),
            );
          }

          return ListView.builder(
            itemCount: chatRooms.length,
            itemBuilder: (context, index) {
              return _buildChatListItem(chatRooms[index]);
            },
          );
        },
      ),
    );
  }
}