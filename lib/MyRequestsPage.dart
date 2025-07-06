import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'caregiver_profile_page.dart';

class MyRequestsPage extends StatefulWidget {
  @override
  _MyRequestsPageState createState() => _MyRequestsPageState();
}

class _MyRequestsPageState extends State<MyRequestsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late Future<List<DocumentSnapshot>> _futureRequests;
  Set<String> expandedCards = {};

  @override
  void initState() {
    super.initState();
    _futureRequests = getRequests();
  }

  Future<List<DocumentSnapshot>> getRequests() async {
    try {
      var user = _auth.currentUser;
      if (user == null) return [];

      QuerySnapshot snapshot = await _firestore
          .collection('requests')
          .where('userId', isEqualTo: user.uid)
          .get();

      return snapshot.docs;
    } catch (e) {
      print('[ERROR] Error getting requests: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchApplicants(String requestId) async {
    try {
      final bookingsSnapshot = await _firestore
          .collection('bookings')
          .where('requestId', isEqualTo: requestId)
          .get();

      List<Map<String, dynamic>> applicants = [];

      for (var bookingDoc in bookingsSnapshot.docs) {
        var bookingData = bookingDoc.data() as Map<String, dynamic>;
        var applicantId = bookingData['userId'];

        var userDoc = await _firestore.collection('users').doc(applicantId).get();

        if (userDoc.exists) {
          var userData = userDoc.data() as Map<String, dynamic>;

          // Get cached rating from booking if it exists, otherwise fetch from user profile
          double rating = bookingData['cachedRating']?.toDouble() ??
              userData['rating']?.toDouble() ?? 0.0;
          int ratingCount = bookingData['cachedRatingCount'] ??
              userData['ratingCount'] ?? 0;

          applicants.add({
            'name': '${userData['first_name']} ${userData['last_name']}',
            'email': userData['email'],
            'phone': userData['phone'],
            'bookingId': bookingDoc.id,
            'status': bookingData['status'] ?? 'Applied',
            'userId': applicantId,
            'rating': rating,
            'ratingCount': ratingCount,
            'hasRated': bookingData['hasRated'] ?? false,
          });
        }
      }

      return applicants;
    } catch (e) {
      print('[ERROR] Error fetching applicants: $e');
      return [];
    }
  }

  Future<void> _updateBookingStatus(String bookingId, String status) async {
    try {
      await _firestore.collection('bookings').doc(bookingId).update({
        'status': status,
        'processedAt': Timestamp.now(),
      });

      var bookingDoc = await _firestore.collection('bookings').doc(bookingId).get();
      var bookingData = bookingDoc.data() as Map<String, dynamic>;
      var requestDoc = await _firestore.collection('requests').doc(bookingData['requestId']).get();
      var requestData = requestDoc.data() as Map<String, dynamic>;

      await _sendStatusNotification(
        bookingData['userId'],
        requestData['petName'] ?? 'your pet',
        status,
      );

      setState(() {
        _futureRequests = getRequests();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update status: $e')),
      );
    }
  }

  Future<void> _sendStatusNotification(String userId, String petName, String status) async {
    try {
      var userDoc = await _firestore.collection('users').doc(_auth.currentUser!.uid).get();
      var userName = userDoc['username'] ?? 'The pet owner';

      await _firestore.collection('notifications').add({
        'userId': userId,
        'title': 'Booking $status',
        'message': '$userName has $status your application for $petName',
        'type': 'status_update',
        'read': false,
        'timestamp': Timestamp.now(),
        'relatedId': '',
      });
    } catch (e) {
      print('Error sending status notification: $e');
    }
  }

  Future<void> _deleteRequest(String requestId) async {
    try {
      // 1. Get all bookings for this request
      final bookings = await _firestore
          .collection('bookings')
          .where('requestId', isEqualTo: requestId)
          .get();

      // 2. Process each booking to preserve reviews
      for (var booking in bookings.docs) {
        final bookingData = booking.data();

        // Only modify if this booking has ratings we need to preserve
        if (bookingData['hasRated'] == true) {
          // Update booking to remove request reference but keep review data
          await booking.reference.update({
            'requestId': FieldValue.delete(),  // Remove the request reference
            'isActive': false,  // Mark as inactive
            // Keep all rating-related fields intact
          });
        } else {
          // For bookings without ratings, delete normally
          await booking.reference.delete();
        }
      }

      // 3. Delete the request document
      await _firestore.collection('requests').doc(requestId).delete();

      // 4. Update UI
      setState(() {
        _futureRequests = getRequests();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Request deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete request: ${e.toString()}')),
      );
    }
  }
  Future<void> _showRatingDialog(String bookingId, String userId, String userName) async {
    double rating = 0;
    TextEditingController commentController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.8,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Rate $userName',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 16),
                      Text('How would you rate their service?'),
                      SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (index) {
                          return IconButton(
                            padding: EdgeInsets.symmetric(horizontal: 4),
                            icon: Icon(
                              index < rating ? Icons.star : Icons.star_border,
                              color: Colors.amber,
                              size: 30,
                            ),
                            onPressed: () {
                              setState(() {
                                rating = index + 1.0;
                              });
                            },
                          );
                        }),
                      ),
                      SizedBox(height: 10),
                      Text('${rating.toInt()} stars', style: TextStyle(fontSize: 16)),
                      SizedBox(height: 20),
                      TextField(
                        controller: commentController,
                        decoration: InputDecoration(
                          labelText: 'Leave a comment (optional)',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                      SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text('Cancel'),
                          ),
                          SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: rating > 0
                                ? () async {
                              await _submitRating(
                                bookingId,
                                userId,
                                rating,
                                commentController.text.trim(),
                              );
                              Navigator.pop(context);
                            }
                                : null,
                            child: Text('Submit'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _submitRating(String bookingId, String userId, double rating, String comment) async {
    try {
      // First, get all necessary data before making any updates
      final bookingDoc = await _firestore.collection('bookings').doc(bookingId).get();
      if (!bookingDoc.exists) throw Exception('Booking not found');

      final bookingData = bookingDoc.data() as Map<String, dynamic>;
      final requestId = bookingData['requestId'];

      // Get request data to preserve pet information
      final requestDoc = await _firestore.collection('requests').doc(requestId).get();
      final requestData = requestDoc.data() as Map<String, dynamic>? ?? {};

      // Get reviewer (pet owner) information
      final reviewerDoc = await _firestore.collection('users').doc(_auth.currentUser!.uid).get();
      final reviewerData = reviewerDoc.data() as Map<String, dynamic>;

      // 1. Create a standalone review document
      await _firestore.collection('reviews').add({
        'caregiverId': userId,
        'reviewerId': _auth.currentUser!.uid,
        'reviewerName': '${reviewerData['first_name']} ${reviewerData['last_name']}',
        'bookingId': bookingId,
        'requestId': requestId,
        'rating': rating,
        'comment': comment.isNotEmpty ? comment : null,
        'timestamp': Timestamp.now(),
        'petName': requestData['petName'] ?? 'Unknown Pet',
        'petCategory': requestData['petCategory'] ?? 'Unknown',
        'isActive': true,
      });

      // 2. Update the booking document (original implementation)
      await _firestore.collection('bookings').doc(bookingId).update({
        'hasRated': true,
        'originalRating': rating,
        'originalComment': comment.isNotEmpty ? comment : null,
        'ratingSeen': false,
      });

      // 3. Update the user's aggregated rating
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(userId).get();
      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

      double currentRating = userData['rating']?.toDouble() ?? 0.0;
      int ratingCount = userData['ratingCount'] ?? 0;

      double newRating = ((currentRating * ratingCount) + rating) / (ratingCount + 1);

      // 4. Store the review in the user's subcollection (for easy access)
      await _firestore.collection('users').doc(userId).collection('reviews').add({
        'rating': rating,
        'comment': comment.isNotEmpty ? comment : null,
        'timestamp': Timestamp.now(),
        'bookingId': bookingId,
        'requestId': requestId,
        'ratedById': _auth.currentUser!.uid,
        'ratedByName': '${reviewerData['first_name']} ${reviewerData['last_name']}',
        'petName': requestData['petName'] ?? 'Unknown Pet',
        'petCategory': requestData['petCategory'] ?? 'Unknown',
      });

      // 5. Update the user's main rating data
      await _firestore.collection('users').doc(userId).update({
        'rating': newRating,
        'ratingCount': ratingCount + 1,
      });

      // 6. Update the cached values in the booking
      await _firestore.collection('bookings').doc(bookingId).update({
        'cachedRating': newRating,
        'cachedRatingCount': ratingCount + 1,
      });

      // 7. Send notification to the caregiver about the new review
      await _firestore.collection('notifications').add({
        'userId': userId,
        'title': 'New Rating Received',
        'message': '${reviewerData['first_name']} has rated your service for ${requestData['petName'] ?? 'a pet'}',
        'type': 'new_review',
        'read': false,
        'timestamp': Timestamp.now(),
        'relatedId': bookingId,
      });

      setState(() {
        _futureRequests = getRequests();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Rating submitted successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit rating: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Requests',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            letterSpacing: 0.8,
          ),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 70,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
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
      body: FutureBuilder<List<DocumentSnapshot>>(
        future: _futureRequests,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error loading requests. Please try again.'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('No requests found'),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => setState(() {
                      _futureRequests = getRequests();
                    }),
                    child: Text('Refresh'),
                  ),
                ],
              ),
            );
          }

          var requests = snapshot.data!;

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _futureRequests = getRequests();
              });
            },
            child: ListView.builder(
              itemCount: requests.length,
              itemBuilder: (context, index) {
                var request = requests[index].data() as Map<String, dynamic>;
                String requestId = requests[index].id;
                bool isExpanded = expandedCards.contains(requestId);

                return Card(
                  margin: EdgeInsets.all(10),
                  elevation: 5,
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        if (isExpanded) {
                          expandedCards.remove(requestId);
                        } else {
                          expandedCards.add(requestId);
                        }
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListTile(
                            title: Text(
                              request['petName'] ?? 'Unnamed Pet',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Category: ${request['petCategory'] ?? 'Unknown'}'),
                                Text('Location: ${request['location'] ?? 'Unknown'}'),
                                Text('Date: ${request['reqDate'] ?? 'Unknown'}'),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _showDeleteDialog(requestId),
                                ),
                                Icon(
                                  isExpanded ? Icons.expand_less : Icons.expand_more,
                                  color: Colors.blue,
                                ),
                              ],
                            ),
                          ),
                          if (isExpanded)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Divider(),
                                  Text('Care Details:', style: TextStyle(fontWeight: FontWeight.bold)),
                                  Text(request['careDetails'] ?? 'No details provided'),
                                  SizedBox(height: 16),
                                  Text('Applicants:', style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  )),
                                  SizedBox(height: 8),
                                  FutureBuilder<List<Map<String, dynamic>>>(
                                    future: fetchApplicants(requestId),
                                    builder: (context, applicantSnapshot) {
                                      if (applicantSnapshot.connectionState == ConnectionState.waiting) {
                                        return Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Center(child: CircularProgressIndicator()),
                                        );
                                      }

                                      if (applicantSnapshot.hasError) {
                                        return Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text('Error loading applicants'),
                                        );
                                      }

                                      if (!applicantSnapshot.hasData || applicantSnapshot.data!.isEmpty) {
                                        return Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text('No applicants yet'),
                                        );
                                      }

                                      return ListView.builder(
                                        physics: NeverScrollableScrollPhysics(),
                                        shrinkWrap: true,
                                        itemCount: applicantSnapshot.data!.length,
                                        itemBuilder: (context, index) {
                                          var applicant = applicantSnapshot.data![index];
                                          return Container(
                                            margin: EdgeInsets.only(bottom: 8),
                                            decoration: BoxDecoration(
                                              border: Border.all(color: Colors.grey[300]!),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Padding(
                                              padding: const EdgeInsets.all(12.0),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      Expanded(
                                                        child: Column(
                                                          crossAxisAlignment: CrossAxisAlignment.start,
                                                          children: [
                                                            GestureDetector(
                                                              onTap: () {
                                                                Navigator.push(
                                                                  context,
                                                                  MaterialPageRoute(
                                                                    builder: (context) => CaregiverProfilePage(userId: applicant['userId']),
                                                                  ),
                                                                );
                                                              },
                                                              child: Text(
                                                                applicant['name'],
                                                                style: TextStyle(
                                                                  fontWeight: FontWeight.bold,
                                                                  fontSize: 16,
                                                                  color: Colors.blue, // Make it look clickable
                                                                  //decoration: TextDecoration.underline,
                                                                ),
                                                              ),
                                                            ),
                                                            if (applicant['ratingCount'] > 0)
                                                              Row(
                                                                children: [
                                                                  Icon(Icons.star, color: Colors.amber, size: 16),
                                                                  SizedBox(width: 4),
                                                                  Text(
                                                                    '${applicant['rating'].toStringAsFixed(1)} (${applicant['ratingCount']} votes)',
                                                                    style: TextStyle(fontSize: 12),
                                                                  ),
                                                                ],
                                                              ),
                                                          ],
                                                        ),
                                                      ),
                                                      Container(
                                                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                        decoration: BoxDecoration(
                                                          color: applicant['status'] == 'Approved'
                                                              ? Colors.green.withOpacity(0.2)
                                                              : applicant['status'] == 'Rejected'
                                                              ? Colors.red.withOpacity(0.2)
                                                              : Colors.orange.withOpacity(0.2),
                                                          borderRadius: BorderRadius.circular(12),
                                                        ),
                                                        child: Text(
                                                          applicant['status'],
                                                          style: TextStyle(
                                                            color: applicant['status'] == 'Approved'
                                                                ? Colors.green
                                                                : applicant['status'] == 'Rejected'
                                                                ? Colors.red
                                                                : Colors.orange,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  SizedBox(height: 8),
                                                  _buildDetailRow(Icons.email, applicant['email']),
                                                  _buildDetailRow(Icons.phone, applicant['phone']),
                                                  if (applicant['status'] == 'Applied')
                                                    Row(
                                                      mainAxisAlignment: MainAxisAlignment.end,
                                                      children: [
                                                        TextButton(
                                                          onPressed: () => _updateBookingStatus(applicant['bookingId'], 'Rejected'),
                                                          child: Text('Reject', style: TextStyle(color: Colors.red)),
                                                        ),
                                                        SizedBox(width: 12),
                                                        ElevatedButton(
                                                          onPressed: () => _updateBookingStatus(applicant['bookingId'], 'Approved'),
                                                          style: ElevatedButton.styleFrom(
                                                            backgroundColor: Colors.green,
                                                          ),
                                                          child: Text('Approve', style: TextStyle(color: Colors.white)),
                                                        ),
                                                      ],
                                                    ),
                                                  if (applicant['status'] == 'Approved' && !applicant['hasRated'])
                                                    Row(
                                                      mainAxisAlignment: MainAxisAlignment.end,
                                                      children: [
                                                        ElevatedButton(
                                                          onPressed: () => _showRatingDialog(
                                                            applicant['bookingId'],
                                                            applicant['userId'],
                                                            applicant['name'],
                                                          ),
                                                          style: ElevatedButton.styleFrom(
                                                            backgroundColor: Colors.blue,
                                                          ),
                                                          child: Text('Rate My Service', style: TextStyle(color: Colors.white)),
                                                        ),
                                                      ],
                                                    ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      );
                                    },
                                  ),
                                ],
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

  Widget _buildDetailRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  void _showDeleteDialog(String requestId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Request'),
          content: Text('Are you sure you want to delete this request? This will also remove all associated bookings.'),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteRequest(requestId);
              },
            ),
          ],
        );
      },
    );
  }
}