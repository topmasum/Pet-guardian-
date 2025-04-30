import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'MyRequestsPage.dart';
import 'MyBookingsPage.dart';
import 'NotificationsPage.dart';
import 'EditProfilePage.dart';
import 'help.dart';
import 'ReviewsPage.dart';

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
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
              ),
            );
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
                    child: Text('Retry', style: TextStyle(color: Colors.teal)),
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

          return SingleChildScrollView(
              child: Column(
                  children: [
              // Header Section
              Container(
              padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 16),
          decoration: BoxDecoration(
          gradient: LinearGradient(
          colors: [Colors.teal[700]!, Colors.blue[600]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
          ),
          ),
          child: Column(
          children: [
          Align(
          alignment: Alignment.topLeft,

          ),
          SizedBox(height: 16),
          Stack(
          alignment: Alignment.bottomRight,
          children: [
          Container(
          padding: EdgeInsets.all(6),
          decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          boxShadow: [
          BoxShadow(
          color: Colors.black26,
          blurRadius: 10,
          offset: Offset(0, 4),
          ),
          ],
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
          horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
          color: Colors.amber[700],
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
          BoxShadow(
          color: Colors.black12,
          blurRadius: 6,
          offset: Offset(0, 2),
          ),
          ]),

          child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
          Icon(Icons.star,
          size: 18, color: Colors.white),
          SizedBox(width: 4),
          Text(
          '${rating.toStringAsFixed(1)} (${ratingCount})',
          style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 14,
          ),
          ),
          ],
          ),
          ),
          ],
          ),
          SizedBox(height: 20),
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
          SizedBox(height: 30),
          ],
          ),
          ),
          // Content Section
          Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
          children: [
          // Activity Section
          _buildSectionCard(
          context,
          title: 'Activity',
          items: [
          _ProfileItem(
          icon: Icons.notifications_outlined,
          label: 'Notifications',
          badgeStream: _firestore
              .collection('notifications')
              .where('userId', isEqualTo: _auth.currentUser?.uid)
              .where('read', isEqualTo: false)
              .snapshots(),
          onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
          builder: (context) => NotificationsPage()),
          ),
          ),
          _ProfileItem(
          icon: Icons.list_alt_outlined,
          label: 'My Requests',
          onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
          builder: (context) => MyRequestsPage()),
          ),
          ),
          _ProfileItem(
          icon: Icons.bookmark_outline,
          label: 'My Bookings',
          onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
          builder: (context) => MyBookingsPage()),
          ),
          ),
          _ProfileItem(
          icon: Icons.edit_outlined,
          label: 'Edit Profile',
          onTap: () {
          Navigator.push(
          context,
          MaterialPageRoute(
          builder: (context) => EditProfilePage()),
          );
          },
          ),
            _ProfileItem(
              icon: Icons.reviews_outlined,  // New icon for reviews
              label: 'My Reviews',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ReviewsPage()),
              ),
            ),
          ],
          ),
          SizedBox(height: 20),
          // Account Section
            _buildSectionCard(
              context,
              title: 'Account',
              items: [
                _ProfileItem(  // Add this new item
                  icon: Icons.help_outline,
                  label: 'Help & Support',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => HelpPage()),
                    );
                  },
                ),
                _ProfileItem(
                  icon: Icons.logout,
                  label: 'Sign Out',
                  isDestructive: true,
                  onTap: () async {
                    await _auth.signOut();
                    // Navigate to login screen
                  },
                ),
              ],
            ),
          ],
          ),
          ),
          ],
          ),
          );
          },
      ),
    );
  }

  Widget _buildSectionCard(BuildContext context,
      {required String title, required List<_ProfileItem> items}) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ),
            Divider(height: 1, thickness: 0.5),
            ...items.map((item) => _buildListItem(context, item)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildListItem(BuildContext context, _ProfileItem item) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: item.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: item.isDestructive
                      ? Colors.red[50]
                      : Colors.teal.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  item.icon,
                  color: item.isDestructive ? Colors.red[400] : Colors.teal[600],
                  size: 22,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 16,
                    color: item.isDestructive ? Colors.red[400] : Colors.grey[800],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (item.badgeStream != null)
                StreamBuilder<QuerySnapshot>(
                  stream: item.badgeStream,
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
              SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                color: Colors.grey[400],
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;
  final Stream<QuerySnapshot>? badgeStream;

  _ProfileItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
    this.badgeStream,
  });
}