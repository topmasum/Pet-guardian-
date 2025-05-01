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
        SnackBar(
          content: Text('Failed to delete notification'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _deleteAllRead() async {
    final readNotifications = _notifications.where((n) => (n.data() as Map<String, dynamic>)['read'] == true).toList();

    if (readNotifications.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No read notifications to delete'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _notifications.removeWhere((n) => (n.data() as Map<String, dynamic>)['read'] == true);
    });

    try {
      final batch = _firestore.batch();
      for (var doc in readNotifications) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Deleted ${readNotifications.length} notifications'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      setState(() {
        _notifications.addAll(readNotifications);
        _notifications.sort((a, b) => (b.data() as Map<String, dynamic>)['timestamp']
            .compareTo((a.data() as Map<String, dynamic>)['timestamp']));
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete notifications'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  IconData _getNotificationIcon(String type, String? status) {
    if (type == 'status_update') {
      if (status?.toLowerCase().contains('approved') == true) {
        return Icons.check_circle;
      } else if (status?.toLowerCase().contains('rejected') == true) {
        return Icons.cancel;
      }
    }

    switch (type) {
      case 'booking': return Icons.calendar_today;
      case 'request': return Icons.pets;
      default: return Icons.notifications;
    }
  }

  Color _getNotificationColor(String type, String? status) {
    if (type == 'status_update') {
      if (status?.toLowerCase().contains('approved') == true) {
        return Colors.green;
      } else if (status?.toLowerCase().contains('rejected') == true) {
        return Colors.red;
      }
      return Colors.purple;
    }

    switch (type) {
      case 'booking': return Colors.blue;
      case 'request': return Colors.orange;
      default: return Colors.indigo;
    }
  }

  String _formatTimestamp(Timestamp timestamp) {
    final date = timestamp.toDate();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(Duration(days: 1));

    if (date.isAfter(today)) {
      return 'Today at ${_twoDigits(date.hour)}:${_twoDigits(date.minute)}';
    } else if (date.isAfter(yesterday)) {
      return 'Yesterday at ${_twoDigits(date.hour)}:${_twoDigits(date.minute)}';
    } else {
      return '${_twoDigits(date.day)}/${_twoDigits(date.month)}/${date.year}';
    }
  }

  String _twoDigits(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Notifications',
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
        iconTheme: IconThemeData(color: Colors.white), // This makes the back button white
        actions: [
          IconButton(
            icon: Icon(Icons.delete_sweep, size: 24, color: Colors.white),
            tooltip: 'Clear read notifications',
            onPressed: _deleteAllRead,
          ),
        ],
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
        stream: _firestore.collection('notifications')
            .where('userId', isEqualTo: _auth.currentUser?.uid)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && _notifications.isEmpty) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 50, color: Colors.red),
                  SizedBox(height: 16),
                  Text(
                    'Error loading notifications',
                    style: TextStyle(fontSize: 16, color: Colors.red),
                  ),
                ],
              ),
            );
          }

          if (snapshot.hasData) {
            _notifications = snapshot.data!.docs;
          }

          if (_notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none, size: 60, color: Colors.grey[400]),
                  SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'You\'ll see notifications here when you get them',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              // Force refresh by getting the data again
              final snapshot = await _firestore.collection('notifications')
                  .where('userId', isEqualTo: _auth.currentUser?.uid)
                  .orderBy('timestamp', descending: true)
                  .get();
              setState(() {
                _notifications = snapshot.docs;
              });
            },
            child: ListView.separated(
              itemCount: _notifications.length,
              separatorBuilder: (context, index) => Divider(height: 1),
              itemBuilder: (context, index) {
                var notification = _notifications[index];
                var data = notification.data() as Map<String, dynamic>;
                final isRead = data['read'] ?? false;
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
                          title: Text('Delete Notification'),
                          content: Text('Are you sure you want to delete this notification?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: Text(
                                'Delete',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  background: Container(
                    color: Colors.red[400],
                    alignment: Alignment.centerRight,
                    padding: EdgeInsets.only(right: 20),
                    child: Icon(Icons.delete_forever, color: Colors.white),
                  ),
                  onDismissed: (direction) => _deleteNotification(notification),
                  child: InkWell(
                    onTap: () {
                      if (!isRead) {
                        _markAsRead(notification.id);
                      }
                    },
                    child: Container(
                      color: isRead ? Colors.white : Colors.blue[50],
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: EdgeInsets.only(right: 16),
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _getNotificationColor(
                                data['type'] ?? 'default',
                                data['message']?.toString(),
                              ).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              _getNotificationIcon(
                                data['type'] ?? 'default',
                                data['message']?.toString(),
                              ),
                              color: _getNotificationColor(
                                data['type'] ?? 'default',
                                data['message']?.toString(),
                              ),
                              size: 24,
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data['title'] ?? 'Notification',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                    color: isRead ? Colors.grey[700] : Colors.black,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  data['message'] ?? '',
                                  style: TextStyle(
                                    color: isRead ? Colors.grey[600] : Colors.grey[800],
                                  ),
                                ),
                                SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.access_time,
                                      size: 14,
                                      color: Colors.grey,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      _formatTimestamp(data['timestamp']),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    Spacer(),
                                    if (isApproved || isRejected)
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: isApproved
                                              ? Colors.green[50]
                                              : Colors.red[50],
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              isApproved
                                                  ? Icons.check_circle
                                                  : Icons.cancel,
                                              size: 14,
                                              color: isApproved
                                                  ? Colors.green
                                                  : Colors.red,
                                            ),
                                            SizedBox(width: 4),
                                            Text(
                                              isApproved ? 'Approved' : 'Rejected',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: isApproved
                                                    ? Colors.green
                                                    : Colors.red,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          if (!isRead)
                            Container(
                              width: 8,
                              height: 8,
                              margin: EdgeInsets.only(left: 8),
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}