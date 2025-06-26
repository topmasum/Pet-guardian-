import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class CaregiverProfilePage extends StatelessWidget {
  final String userId;

  const CaregiverProfilePage({Key? key, required this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Caregiver Profile',
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
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text('Profile not found'));
          }

          var userData = snapshot.data!.data() as Map<String, dynamic>;

          return SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfileHeader(userData),
                SizedBox(height: 24),
                _buildBasicInfoSection(userData),
                SizedBox(height: 24),
                _buildRatingSection(userId),
                SizedBox(height: 24),
                _buildReviewsSection(userId),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(Map<String, dynamic> userData) {
    return Row(
      children: [
        CircleAvatar(
          radius: 40,
          backgroundColor: Colors.teal[100],
          child: Icon(Icons.person, size: 40, color: Colors.teal[800]),
        ),
        SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${userData['first_name']} ${userData['last_name']}',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 4),
            if (userData['rating'] != null)
              Row(
                children: [
                  Icon(Icons.star, color: Colors.amber, size: 20),
                  SizedBox(width: 4),
                  Text(
                    '${userData['rating']?.toStringAsFixed(1) ?? '0.0'} (${userData['ratingCount'] ?? 0} reviews)',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildBasicInfoSection(Map<String, dynamic> userData) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Basic Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Divider(),
            _buildInfoRow(Icons.email, 'Email', userData['email'] ?? 'Not provided'),
            _buildInfoRow(Icons.phone, 'Phone', userData['phone'] ?? 'Not provided'),
            _buildInfoRow(Icons.location_on, 'Location', userData['location'] ?? 'Not provided'),
            if (userData['bio'] != null)
              _buildInfoRow(Icons.info, 'Bio', userData['bio']),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingSection(String userId) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Rating Overview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Divider(),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(userId)
                  .collection('reviews')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return CircularProgressIndicator();

                var reviews = snapshot.data!.docs;
                if (reviews.isEmpty) return Text('No reviews yet');

                // Calculate rating distribution
                Map<int, int> ratingCounts = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
                reviews.forEach((review) {
                  int rating = (review['rating'] as num).toInt();
                  ratingCounts[rating] = ratingCounts[rating]! + 1;
                });

                return Column(
                  children: [
                    for (int i = 5; i >= 1; i--)
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            SizedBox(  // Fixed width container for text alignment
                              width: 60,
                              child: Text(
                                '$i star',
                                style: TextStyle(fontSize: 14),
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 4),
                                child: LinearProgressIndicator(
                                  value: ratingCounts[i]! / reviews.length,
                                  backgroundColor: Colors.grey[200],
                                  color: Colors.amber,
                                  minHeight: 8,  // Makes the progress bar thinner
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 30,  // Fixed width for count alignment
                              child: Text(
                                '${ratingCounts[i]}',
                                textAlign: TextAlign.right,  // Right-align the count
                                style: TextStyle(fontSize: 14),
                              ),
                            ),
                          ],
                        )
                      )],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewsSection(String userId) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Reviews', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(userId)
                      .collection('reviews')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return Text('... reviews');
                    return Text('${snapshot.data!.docs.length} reviews',
                        style: TextStyle(color: Colors.grey));
                  },
                ),
              ],
            ),
            Divider(),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(userId)
                  .collection('reviews')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return CircularProgressIndicator();

                var reviews = snapshot.data!.docs;
                if (reviews.isEmpty) return Text('No reviews yet');

                return ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: reviews.length,
                  itemBuilder: (context, index) {
                    var review = reviews[index];
                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .doc(review['ratedById'])
                          .get(),
                      builder: (context, userSnapshot) {
                        if (!userSnapshot.hasData) return SizedBox();

                        var reviewer = userSnapshot.data!.data() as Map<String, dynamic>;
                        return Padding(
                          padding: EdgeInsets.only(bottom: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    child: Icon(Icons.person, size: 16),
                                  ),
                                  SizedBox(width: 8),
                                  Text('${reviewer['first_name']} ${reviewer['last_name']}'),
                                  Spacer(),
                                  Row(
                                    children: List.generate(5, (i) {
                                      return Icon(
                                        i < review['rating'] ? Icons.star : Icons.star_border,
                                        color: Colors.amber,
                                        size: 16,
                                      );
                                    }),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              if (review['comment'] != null)
                                Text(
                                  review['comment'],
                                  style: TextStyle(fontSize: 14),
                                ),
                              SizedBox(height: 8),
                              Text(
                                _formatDate(review['timestamp']),
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                              if (index < reviews.length - 1) Divider(),
                            ],
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.teal),
          SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 2),
              Text(value),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(Timestamp timestamp) {
    return DateFormat('MMM d, y').format(timestamp.toDate());
  }
}