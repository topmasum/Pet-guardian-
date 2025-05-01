import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ReviewsPage extends StatefulWidget {
  @override
  _ReviewsPageState createState() => _ReviewsPageState();
}

class _ReviewsPageState extends State<ReviewsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DateFormat _dateFormat = DateFormat('MMM dd, yyyy');
  Set<String> _unseenReviews = {};

  @override
  void initState() {
    super.initState();
    _checkForNewReviews();
  }

  Future<void> _checkForNewReviews() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    final snapshot = await _firestore
        .collection('bookings')
        .where('userId', isEqualTo: userId)
        .where('hasRated', isEqualTo: true)
        .where('ratingSeen', isEqualTo: false)
        .get();

    setState(() {
      _unseenReviews = Set.from(snapshot.docs.map((doc) => doc.id));
    });
  }

  Future<void> _markAsSeen(String bookingId) async {
    await _firestore.collection('bookings').doc(bookingId).update({
      'ratingSeen': true,
    });
    setState(() {
      _unseenReviews.remove(bookingId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text('My Reviews'),
            if (_unseenReviews.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
        backgroundColor: Colors.teal[700],
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('bookings')
            .where('userId', isEqualTo: _auth.currentUser?.uid)
            .where('hasRated', isEqualTo: true)
            .orderBy('processedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.reviews, size: 48, color: Colors.grey[400]),
                  SizedBox(height: 16),
                  Text(
                    'No reviews yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Your ratings will appear here after pet owners rate your services',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var booking = snapshot.data!.docs[index];
              return _buildReviewCard(booking);
            },
          );
        },
      ),
    );
  }

  Widget _buildReviewCard(DocumentSnapshot booking) {
    final data = booking.data() as Map<String, dynamic>;
    final originalRatingRaw = data['originalRating'];
    final originalRating = (originalRatingRaw is num) ? originalRatingRaw.toDouble() : 0.0;
    final originalComment = data['originalComment'] as String?; // Get the comment
    final timestamp = data['processedAt']?.toDate() ?? DateTime.now();
    final isNew = _unseenReviews.contains(booking.id);

    return FutureBuilder<DocumentSnapshot>(
      future: _firestore.collection('requests').doc(data['requestId']).get(),
      builder: (context, requestSnapshot) {
        if (requestSnapshot.connectionState == ConnectionState.waiting) {
          return Card(
            margin: EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        if (!requestSnapshot.hasData || !requestSnapshot.data!.exists) {
          return Card(
            margin: EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('Deleted request'),
            ),
          );
        }

        final requestData = requestSnapshot.data!.data() as Map<String, dynamic>;
        final petName = requestData['petName'] ?? 'Unknown Pet';
        final petCategory = requestData['petCategory'] ?? 'Unknown Category';

        return FutureBuilder<DocumentSnapshot>(
          future: _firestore.collection('users').doc(requestData['userId']).get(),
          builder: (context, userSnapshot) {
            final userName = userSnapshot.hasData && userSnapshot.data!.exists
                ? '${userSnapshot.data!['first_name']} ${userSnapshot.data!['last_name']}'
                : 'Unknown User';

            if (isNew) {
              _markAsSeen(booking.id);
            }

            return Card(
              margin: EdgeInsets.only(bottom: 16),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.teal[100],
                          child: Icon(Icons.person, color: Colors.teal[800], size: 24),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Rated by: $userName',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.teal[700],
                                ),
                              ),
                              Text(
                                'Original Rating',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isNew)
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 16),
                    _buildOriginalRatingStars(originalRating),

                    // Add the comment section here
                    if (originalComment != null && originalComment.isNotEmpty) ...[
                      SizedBox(height: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Comment:',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(height: 4),
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              originalComment,
                              style: TextStyle(
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],

                    SizedBox(height: 16),
                    Divider(height: 1, thickness: 0.5),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pet Service',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              petName,
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                            Text(
                              petCategory,
                              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                        _buildCurrentRating(data),
                      ],
                    ),
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                        SizedBox(width: 8),
                        Text(
                          _dateFormat.format(timestamp),
                          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        ),
                        Spacer(),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red[400]),
                          onPressed: () => _showDeleteDialog(booking.id),
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
    );
  }

  Widget _buildOriginalRatingStars(double rating) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Original Rating Given:',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        SizedBox(height: 4),
        Row(
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                rating.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber[800],
                ),
              ),
            ),
            SizedBox(width: 8),
            Row(
              children: List.generate(5, (index) {
                return Icon(
                  index < rating.floor() ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 20,
                );
              }),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCurrentRating(Map<String, dynamic> bookingData) {
    final currentRating = (bookingData['cachedRating'] is num)
        ? bookingData['cachedRating'].toDouble()
        : 0.0;
    final ratingCount = bookingData['cachedRatingCount'] ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          'Your Current Rating',
          style: TextStyle(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.w500),
        ),
        SizedBox(height: 4),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.amber.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Text(
                currentRating.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber[800],
                ),
              ),
              Text(
                '($ratingCount ${ratingCount == 1 ? 'rating' : 'ratings'})',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showDeleteDialog(String bookingId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Review'),
          content: Text('Are you sure you want to delete this review? This action cannot be undone.'),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () async {
                Navigator.of(context).pop();
                await _deleteReview(bookingId);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteReview(String bookingId) async {
    try {
      DocumentSnapshot bookingDoc = await _firestore.collection('bookings').doc(bookingId).get();
      if (!bookingDoc.exists) return;

      Map<String, dynamic> bookingData = bookingDoc.data() as Map<String, dynamic>;

      if (bookingData['hasRated'] == true) {
        await _firestore.collection('bookings').doc(bookingId).update({
          'hasRated': false,
          'originalRating': FieldValue.delete(),
          'originalComment': FieldValue.delete(),
          'cachedRating': FieldValue.delete(),
          'cachedRatingCount': FieldValue.delete(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Review deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete review: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}