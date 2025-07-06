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
  final Map<String, int> _unreadCounts = {};

  @override
  void initState() {
    super.initState();
    _preCacheUsers();
  }

  Future<void> _preCacheUsers() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    final chatRooms = await _firestore
        .collection('chatRooms')
        .where('users', arrayContains: userId)
        .get();

    final otherUserIds = chatRooms.docs.expand((chatRoom) {
      final users = List<String>.from(chatRoom['users']);
      return users.where((id) => id != userId);
    }).toSet().toList();

    if (otherUserIds.isNotEmpty) {
      final usersSnapshot = await _firestore
          .collection('users')
          .where(FieldPath.documentId, whereIn: otherUserIds)
          .get();

      for (final doc in usersSnapshot.docs) {
        _userCache[doc.id] = doc.data() as Map<String, dynamic>;
      }
    }
  }

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
        title: const Text(
          'Chats',
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        flexibleSpace: ClipRRect(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
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
                  offset: const Offset(0, 6),
                ),
              ],
            ),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _getChatRoomsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            debugPrint('Firestore Error: ${snapshot.error}');
            return _buildErrorWidget(snapshot.error);
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          return _buildChatList(snapshot.data!.docs);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            'No chats yet',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Text(
            'Start a conversation with someone!',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(dynamic error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          const Text('Error loading chats'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => setState(() {}),
            child: const Text('Retry'),
          ),
          const SizedBox(height: 16),
          Text(
            error.toString(),
            style: const TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildChatList(List<QueryDocumentSnapshot> chatRooms) {
    return ListView.builder(
      itemCount: chatRooms.length,
      itemBuilder: (context, index) {
        final chatRoom = chatRooms[index];
        final users = List<String>.from(chatRoom['users']);
        final otherUserId = users.firstWhere(
              (id) => id != _auth.currentUser?.uid,
          orElse: () => '',
        );

        if (otherUserId.isEmpty) return const SizedBox();

        final userData = _userCache[otherUserId] ?? {};
        final userName = userData['username'] ?? 'Unknown';
        final userImage = userData['profileImage'];
        final lastMessage = chatRoom['lastMessage'] ?? '';
        final lastMessageTime = chatRoom['lastMessageTime']?.toDate();
        final unreadCount = chatRoom['unreadCount'] ?? 0;
        final isUnread = unreadCount > 0 &&
            chatRoom['lastMessageSender'] != _auth.currentUser?.uid;

        return ListTile(
          leading: CircleAvatar(
            radius: 24,
            backgroundImage: userImage != null
                ? NetworkImage(userImage) as ImageProvider
                : const AssetImage('assets/images/profile_placeholder.png'),
          ),
          title: Text(
            userName,
            style: TextStyle(
              fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          subtitle: Text(
            lastMessage,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: isUnread ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (lastMessageTime != null)
                Text(
                  DateFormat('HH:mm').format(lastMessageTime),
                  style: TextStyle(
                    fontSize: 12,
                    color: isUnread ? Colors.blue : Colors.grey,
                  ),
                ),
              if (isUnread)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    unreadCount > 9 ? '9+' : unreadCount.toString(),
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
                  chatRoomId: chatRoom.id,
                  otherUserId: otherUserId,
                  otherUserName: userName,
                ),
              ),
            ).then((_) {
              // Refresh the chat list when returning from chat page
              if (mounted) setState(() {});
            });
          },
        );
      },
    );
  }
}