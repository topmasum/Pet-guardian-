import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MyBookingsPage extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> getBookings() async {
    try {
      var user = FirebaseAuth.instance.currentUser;
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

          // Skip if booking data is invalid
          if (booking['requesterId'] == null) continue;

          // Get requester details with error handling
          DocumentSnapshot requesterDoc = await _firestore
              .collection('users')
              .doc(booking['requesterId'])
              .get();

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
          // Continue with next booking even if one fails
          continue;
        }
      }

      return bookingsWithDetails;
    } catch (e) {
      print("Error fetching bookings: $e");
      throw e; // Rethrow to be caught by FutureBuilder
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
        future: getBookings(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: Colors.red, size: 50),
                  SizedBox(height: 16),
                  Text(
                    'Failed to load bookings',
                    style: TextStyle(fontSize: 18),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Please check your internet connection',
                    style: TextStyle(color: Colors.grey),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      // Refresh the page
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MyBookingsPage(),
                        ),
                      );
                    },
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
                  Text(
                    'No bookings yet',
                    style: TextStyle(fontSize: 18),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Your bookings will appear here',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          var bookings = snapshot.data!;
          return ListView.builder(
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
                                : Colors.green,
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
                    ],
                  ),
                ),
              );
            },
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
          Text(
            label,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(width: 4),
          Expanded(
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}