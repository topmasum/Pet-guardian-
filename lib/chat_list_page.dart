import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'chat_page.dart';

class ChatListPage extends StatefulWidget {
  @override
  _ChatListPageState createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Map<String, Map<String, dynamic>> _userCache = {};

  Stream<QuerySnapshot> _getChatRoomsStream() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return const Stream.empty();

    return _firestore
        .collection('chatRooms')
        .where('users', arrayContains: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots(includeMetadataChanges: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chats'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _getChatRoomsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            debugPrint('Firestore Error: ${snapshot.error}');
            return _buildErrorWidget(snapshot.error);
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No chats yet'));
          }

          return _buildChatList(snapshot.data!.docs);
        },
      ),
    );
  }

  Widget _buildErrorWidget(dynamic error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Error loading chats'),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => setState(() {}),
            child: Text('Retry'),
          ),
          SizedBox(height: 16),
          Text(
            'If this persists, please check your internet connection',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildChatList(List<QueryDocumentSnapshot> chatRooms) {
    // Get all other user IDs at once
    final otherUserIds = chatRooms.map((chatRoom) {
      final users = List<String>.from(chatRoom['users']);
      return users.firstWhere((id) => id != _auth.currentUser?.uid);
    }).where((id) => id != null).toList();

    return FutureBuilder<QuerySnapshot>(
      future: _firestore.collection('users')
          .where(FieldPath.documentId, whereIn: otherUserIds)
          .get(),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        // Cache user data
        if (userSnapshot.hasData) {
          for (final doc in userSnapshot.data!.docs) {
            _userCache[doc.id] = doc.data() as Map<String, dynamic>;
          }
        }

        return ListView.builder(
          itemCount: chatRooms.length,
          itemBuilder: (context, index) {
            final chatRoom = chatRooms[index];
            final users = List<String>.from(chatRoom['users']);
            final otherUserId = users.firstWhere(
                  (id) => id != _auth.currentUser?.uid,
              orElse: () => '',
            );

            if (otherUserId.isEmpty) return SizedBox();

            final userData = _userCache[otherUserId];
            final userName = userData?['username'] ?? 'Unknown';
            final userImage = userData?['profileImage'];
            final lastMessage = chatRoom['lastMessage'] ?? '';
            final lastMessageTime = chatRoom['lastMessageTime']?.toDate();
            final isUnread = chatRoom['lastMessageSender'] != _auth.currentUser?.uid &&
                !(chatRoom['lastMessageRead'] ?? false);

            return ListTile(
              leading: CircleAvatar(
                backgroundImage: userImage != null
                    ? NetworkImage(userImage) as ImageProvider
                    : AssetImage('assets/images/profile_placeholder.png') as ImageProvider,
              ),
              title: Text(userName),
              subtitle: Text(
                lastMessage,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (lastMessageTime != null)
                    Text(
                      DateFormat('HH:mm').format(lastMessageTime),
                      style: TextStyle(fontSize: 12),
                    ),
                  if (isUnread)
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatPage(
                      chatRoomId: chatRoom.id,
                      otherUserId: otherUserId,
                      otherUserName: userName,
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}