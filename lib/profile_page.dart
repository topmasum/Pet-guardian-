import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'MyRequestsPage.dart';
import 'MyBookingsPage.dart';
import 'NotificationsPage.dart';
import 'help.dart';

class ProfilePage extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, dynamic>?> getUserData() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc =
      await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        return userDoc.data() as Map<String, dynamic>;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: FutureBuilder<Map<String, dynamic>?>(
        future: getUserData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
            ));
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
                  SizedBox(height: 16),
                  Text('Error loading profile',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[700],
                      )),
                  SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => ProfilePage()),
                    ),
                    child: Text('Retry',
                        style: TextStyle(color: Colors.teal)),
                  ),
                ],
              ),
            );
          } else if (!snapshot.hasData || snapshot.data == null) {
            return Center(
              child: Text('No user data found',
                  style: TextStyle(fontSize: 18, color: Colors.grey[700])),
            );
          }

          final userData = snapshot.data!;
          final name = userData['username'] ?? 'Unknown';
          final email = userData['email'] ?? 'No Email';
          final profileImage = userData['profileImage'] ??
              'assets/images/profile_placeholder.png';
          final rating = userData['rating']?.toDouble() ?? 0.0;
          final ratingCount = userData['ratingCount'] ?? 0;

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 280.0,
                floating: false,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.teal[700]!, Colors.blue[600]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 70.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              Container(
                                  padding: EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                  ),
                                  child: CircleAvatar(
                                    radius: 60,
                                    backgroundImage: profileImage.startsWith('http')
                                        ? NetworkImage(profileImage) as ImageProvider
                                        : AssetImage(profileImage),
                                  ),
                              ),

                              if (ratingCount > 0)
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.amber[700],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.star,
                                        size: 16, color: Colors.white),
                                    SizedBox(width: 4),
                                    Text(
                                      rating.toStringAsFixed(1),
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16),
                          Text(
                            name,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontFamily: 'Montserrat',
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            email,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                          if (ratingCount > 0)
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                '${ratingCount} ${ratingCount == 1 ? 'review' : 'reviews'}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withOpacity(0.8),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20.0, vertical: 20.0),
                  child: Column(
                    children: [
                      _ProfileSectionCard(
                        title: 'Activity',
                        children: [
                          _ProfileActionButton(
                            icon: Icons.notifications,
                            label: 'Notifications',
                            badgeStream: _firestore.collection('notifications')
                                .where('userId', isEqualTo: _auth.currentUser?.uid)
                                .where('read', isEqualTo: false)
                                .snapshots(),
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => NotificationsPage()),
                            ),
                          ),
                          _ProfileActionButton(
                            icon: Icons.list_alt,
                            label: 'My Requests',
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => MyRequestsPage()),
                            ),
                          ),
                          _ProfileActionButton(
                            icon: Icons.bookmark,
                            label: 'My Bookings',
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => MyBookingsPage()),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                      _ProfileSectionCard(
                        title: 'Account',
                        children: [
                          _ProfileActionButton(
                            icon: Icons.edit,
                            label: 'Edit Profile',
                            onPressed: () {
                              // Navigate to profile edit page
                            },
                          ),
                          _ProfileActionButton(
                            icon: Icons.settings,
                            label: 'Settings',
                            onPressed: () {
                              // Navigate to settings page
                            },
                          ),
                          _ProfileActionButton(
                            icon: Icons.help_outline,
                            label: 'Help & Support',
                              onPressed: () {
                                Navigator.push(context, MaterialPageRoute(builder: (context) => HelpPage()));
                              }
                          ),
                          _ProfileActionButton(
                            icon: Icons.exit_to_app,
                            label: 'Sign Out',
                            isDestructive: true,
                            onPressed: () async {
                              await _auth.signOut();
                              // Navigate to login screen or handle sign out
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ProfileSectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _ProfileSectionCard({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
            ),
            Divider(height: 1),
            Column(
              children: children
                  .map((child) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: child,
              ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool isDestructive;
  final Stream<QuerySnapshot>? badgeStream;

  const _ProfileActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.isDestructive = false,
    this.badgeStream,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isDestructive
                      ? Colors.red[50]
                      : Colors.teal.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: isDestructive ? Colors.red[400] : Colors.teal[600],
                  size: 20,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    color: isDestructive ? Colors.red[400] : Colors.grey[800],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (badgeStream != null)
                StreamBuilder<QuerySnapshot>(
                  stream: badgeStream,
                  builder: (context, snapshot) {
                    final count = snapshot.hasData ? snapshot.data!.docs.length : 0;
                    if (count > 0) {
                      return Container(
                        padding: EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.red[400],
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          count.toString(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    }
                    return SizedBox();
                  },
                ),
              Icon(
                Icons.chevron_right,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }
}