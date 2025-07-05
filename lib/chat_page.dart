import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class ChatPage extends StatefulWidget {
  final String chatRoomId;
  final String otherUserId;
  final String otherUserName;

  const ChatPage({
    required this.chatRoomId,
    required this.otherUserId,
    required this.otherUserName,
  });

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  late User _currentUser;
  late DocumentReference _chatRoomRef;
  bool _isFirstLoad = true;

  @override
  void initState() {
    super.initState();
    _currentUser = _auth.currentUser!;
    _chatRoomRef = _firestore.collection('chatRooms').doc(widget.chatRoomId);
    _updateReadStatus();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    }
  }

  Future<void> _updateReadStatus() async {
    try {
      final unreadMessages = await _chatRoomRef
          .collection('messages')
          .where('senderId', isEqualTo: widget.otherUserId)
          .where('read', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (var doc in unreadMessages.docs) {
        batch.update(doc.reference, {'read': true});
      }
      await batch.commit();

      await _chatRoomRef.update({
        'lastMessageRead': true,
      });
    } catch (e) {
      debugPrint('Error updating read status: $e');
    }
  }

  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty) return;

    try {
      final batch = _firestore.batch();
      final messageRef = _chatRoomRef.collection('messages').doc();

      batch.set(messageRef, {
        'senderId': _currentUser.uid,
        'text': messageText,
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });

      batch.update(_chatRoomRef, {
        'lastMessage': messageText,
        'lastMessageSender': _currentUser.uid,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageRead': false,
      });

      await batch.commit();
      _messageController.clear();
      _scrollToBottom();
    } catch (e) {
      debugPrint('Error sending message: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send message. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.otherUserName),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _chatRoomRef
                  .collection('messages')
                  .orderBy('timestamp', descending: false) // Oldest first
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error loading messages'));
                }

                final messages = snapshot.data?.docs ?? [];

                if (_isFirstLoad && messages.isNotEmpty) {
                  _isFirstLoad = false;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _scrollToBottom();
                  });
                }

                return NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    if (notification is ScrollUpdateNotification) {
                      // Auto-scroll when new messages arrive if near bottom
                      final isNearBottom = _scrollController.position.pixels >
                          _scrollController.position.maxScrollExtent - 100;
                      if (isNearBottom) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          _scrollToBottom();
                        });
                      }
                    }
                    return false;
                  },
                  child: ListView.builder(
                    controller: _scrollController,
                    reverse: false, // Oldest at top, newest at bottom
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final isMe = message['senderId'] == _currentUser.uid;

                      return Container(
                        margin: EdgeInsets.symmetric(
                          vertical: 4,
                          horizontal: 8,
                        ),
                        alignment: isMe
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isMe ? Colors.blue[100] : Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(message['text']),
                              SizedBox(height: 4),
                              Text(
                                _formatTimestamp(message['timestamp']),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(Timestamp timestamp) {
    final dateTime = timestamp.toDate();
    return DateFormat('HH:mm').format(dateTime);
  }
}