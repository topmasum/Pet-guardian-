import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MyBookingsPage extends StatefulWidget {
  @override
  _MyBookingsPageState createState() => _MyBookingsPageState();
}

class _MyBookingsPageState extends State<MyBookingsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late Future<List<Map<String, dynamic>>> _futureBookings;

  @override
  void initState() {
    super.initState();
    _futureBookings = getBookings();
  }

  Future<List<Map<String, dynamic>>> getBookings() async {
    try {
      var user = _auth.currentUser;
      if (user == null) return [];

      QuerySnapshot snapshot = await _firestore
          .collection('bookings')
          .where('userId', isEqualTo: user.uid)
          .orderBy('bookingDate', descending: true)
          .get();

      List<Map<String, dynamic>> bookingsWithDetails = [];

      for (var doc in snapshot.docs) {
        try {
          var booking = doc.data() as Map<String, dynamic>;
          if (booking['requesterId'] == null) continue;

          DocumentSnapshot requesterDoc = await _firestore
              .collection('users')
              .doc(booking['requesterId'])
              .get();

          // Send notification to requester when booking is created
          if (doc.metadata.hasPendingWrites) {
            await _sendBookingNotification(
              booking['requesterId'],
              booking['petName'] ?? 'Unknown Pet',
            );
          }

          bookingsWithDetails.add({
            ...booking,
            'id': doc.id,
            'requesterName': requesterDoc['username'] ?? 'Unknown User',
            'petName': booking['petName'] ?? 'Unknown Pet',
            'petCategory': booking['petCategory'] ?? 'Unknown',
            'reqDate': booking['reqDate'] ?? 'Date not specified',
            'location': booking['location'] ?? 'Location not specified',
            'status': booking['status'] ?? 'Applied',
          });
        } catch (e) {
          print("Error processing booking ${doc.id}: $e");
          continue;
        }
      }

      return bookingsWithDetails;
    } catch (e) {
      print("Error fetching bookings: $e");
      throw e;
    }
  }

  Future<void> _sendBookingNotification(String requesterId, String petName) async {
    try {
      var userDoc = await _firestore.collection('users').doc(_auth.currentUser!.uid).get();
      var userName = userDoc['username'] ?? 'Someone';

      await _firestore.collection('notifications').add({
        'userId': requesterId,
        'title': 'New Booking Application',
        'message': '$userName has applied to care for $petName',
        'type': 'booking',
        'read': false,
        'timestamp': Timestamp.now(),
        'relatedId': '',
      });
    } catch (e) {
      print('Error sending booking notification: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Bookings'),
        centerTitle: true,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _futureBookings,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: Colors.red, size: 50),
                  SizedBox(height: 16),
                  Text('Failed to load bookings', style: TextStyle(fontSize: 18)),
                  SizedBox(height: 8),
                  Text('Please check your internet connection', style: TextStyle(color: Colors.grey)),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() {
                      _futureBookings = getBookings();
                    }),
                    child: Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_note, size: 50, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No bookings yet', style: TextStyle(fontSize: 18)),
                  SizedBox(height: 8),
                  Text('Your bookings will appear here', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          var bookings = snapshot.data!;
          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _futureBookings = getBookings();
              });
            },
            child: ListView.builder(
              padding: EdgeInsets.all(8),
              itemCount: bookings.length,
              itemBuilder: (context, index) {
                var booking = bookings[index];
                return Card(
                  margin: EdgeInsets.symmetric(vertical: 8),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              booking['petName'],
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Chip(
                              label: Text(
                                booking['status'],
                                style: TextStyle(color: Colors.white),
                              ),
                              backgroundColor: booking['status'] == 'Applied'
                                  ? Colors.orange
                                  : booking['status'] == 'Approved'
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Divider(),
                        SizedBox(height: 8),
                        _buildDetailRow(Icons.person, 'Requester:', booking['requesterName']),
                        _buildDetailRow(Icons.pets, 'Pet Type:', booking['petCategory']),
                        _buildDetailRow(Icons.calendar_today, 'Date:', booking['reqDate']),
                        _buildDetailRow(Icons.location_on, 'Location:', booking['location']),
                        if (booking['status'] == 'Applied')
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                _showCancelDialog(booking['id']);
                              },
                              child: Text(
                                'Cancel Application',
                                style: TextStyle(color: Colors.red),
                              ),
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
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          SizedBox(width: 8),
          Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(width: 4),
          Expanded(
            child: Text(value, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  void _showCancelDialog(String bookingId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Cancel Booking'),
          content: Text('Are you sure you want to cancel this booking application?'),
          actions: [
            TextButton(
              child: Text('No'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('Yes', style: TextStyle(color: Colors.red)),
              onPressed: () async {
                Navigator.of(context).pop();
                await _firestore.collection('bookings').doc(bookingId).delete();
                setState(() {
                  _futureBookings = getBookings();
                });
              },
            ),
          ],
        );
      },
    );
  }
}