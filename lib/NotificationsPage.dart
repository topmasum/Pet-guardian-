import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationsPage extends StatefulWidget {
  @override
  _NotificationsPageState createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<DocumentSnapshot> _notifications = [];

  Future<void> _markAsRead(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).update({
      'read': true,
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }

  void _deleteNotification(DocumentSnapshot notification) async {
    setState(() {
      _notifications.removeWhere((n) => n.id == notification.id);
    });

    try {
      await notification.reference.delete();
    } catch (e) {
      setState(() {
        _notifications.add(notification);
        _notifications.sort((a, b) => (b.data() as Map<String, dynamic>)['timestamp']
            .compareTo((a.data() as Map<String, dynamic>)['timestamp']));
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete notification')),
      );
    }
  }

  void _deleteAllRead() async {
    final readNotifications = _notifications.where((n) => (n.data() as Map<String, dynamic>)['read'] == true).toList();

    setState(() {
      _notifications.removeWhere((n) => (n.data() as Map<String, dynamic>)['read'] == true);
    });

    try {
      final batch = _firestore.batch();
      for (var doc in readNotifications) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      setState(() {
        _notifications.addAll(readNotifications);
        _notifications.sort((a, b) => (b.data() as Map<String, dynamic>)['timestamp']
            .compareTo((a.data() as Map<String, dynamic>)['timestamp']));
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete notifications')),
      );
    }
  }

  IconData _getNotificationIcon(String type, String? status) {
    // For status updates, show tick or cross based on status
    if (type == 'status_update') {
      if (status?.toLowerCase().contains('approved') == true) {
        return Icons.check_circle;
      } else if (status?.toLowerCase().contains('rejected') == true) {
        return Icons.cancel;
      }
    }

    // Default icons for other types
    switch (type) {
      case 'booking': return Icons.bookmark;
      case 'request': return Icons.pets;
      default: return Icons.notifications;
    }
  }

  Color _getNotificationColor(String type, String? status) {
    // For status updates, show green or red based on status
    if (type == 'status_update') {
      if (status?.toLowerCase().contains('approved') == true) {
        return Colors.green;
      } else if (status?.toLowerCase().contains('rejected') == true) {
        return Colors.red;
      }
      return Colors.purple;
    }

    // Default colors for other types
    switch (type) {
      case 'booking': return Colors.blue;
      case 'request': return Colors.green;
      default: return Colors.orange;
    }
  }

  String _formatTimestamp(Timestamp timestamp) {
    DateTime date = timestamp.toDate();
    return '${_twoDigits(date.hour)}:${_twoDigits(date.minute)} ${_twoDigits(date.day)}/${_twoDigits(date.month)}/${date.year}';
  }

  String _twoDigits(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications'),
        actions: [
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: _deleteAllRead,
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('notifications')
            .where('userId', isEqualTo: _auth.currentUser?.uid)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && _notifications.isEmpty) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasData) {
            _notifications = snapshot.data!.docs;
          }

          if (_notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off, size: 50, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No notifications yet', style: TextStyle(fontSize: 18)),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: _notifications.length,
            itemBuilder: (context, index) {
              var notification = _notifications[index];
              var data = notification.data() as Map<String, dynamic>;
              final status = data['message']?.toString().toLowerCase() ?? '';
              final isApproved = status.contains('approved');
              final isRejected = status.contains('rejected');

              return Dismissible(
                key: Key(notification.id),
                direction: DismissDirection.endToStart,
                confirmDismiss: (direction) async {
                  return await showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text('Confirm'),
                        content: Text('Delete this notification?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: Text('Delete', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      );
                    },
                  );
                },
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: EdgeInsets.only(right: 20),
                  child: Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (direction) => _deleteNotification(notification),
                child: Card(
                  color: data['read'] ?? false ? Colors.white : Colors.grey[100],
                  margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                    leading: Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: _getNotificationColor(
                            data['type'] ?? 'default',
                            data['message']?.toString()
                        ).withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getNotificationIcon(
                            data['type'] ?? 'default',
                            data['message']?.toString()
                        ),
                        color: _getNotificationColor(
                            data['type'] ?? 'default',
                            data['message']?.toString()
                        ),
                        size: 28,
                      ),
                    ),
                    title: Text(data['title'] ?? 'Notification'),
                    subtitle: Text(data['message'] ?? ''),
                    trailing: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _formatTimestamp(data['timestamp']),
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                        if (isApproved || isRejected)
                          Padding(
                            padding: EdgeInsets.only(top: 4),
                            child: Icon(
                              isApproved ? Icons.check : Icons.close,
                              color: isApproved ? Colors.green : Colors.red,
                              size: 18,
                            ),
                          ),
                      ],
                    ),
                    onTap: () {
                      if (!(data['read'] ?? false)) {
                        _markAsRead(notification.id);
                      }
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}