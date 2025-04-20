import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'MyRequestsPage.dart'; // Import the page to show requested cards
import 'MyBookingsPage.dart'; // Import the page to show booking cards

class ProfilePage extends StatelessWidget {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, dynamic>?> getUserData() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        return userDoc.data() as Map<String, dynamic>;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: getUserData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error loading profile'));
        } else if (!snapshot.hasData || snapshot.data == null) {
          return Center(child: Text('No user data found'));
        }

        var userData = snapshot.data!;
        String name = userData['username'] ?? 'Unknown';
        String email = userData['email'] ?? 'No Email';
        String profileImage = userData['profileImage'] ?? 'assets/images/profile_placeholder.png';

        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Profile Header Section
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        height: 220,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.teal, Colors.blue],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius: 60,
                              backgroundImage: profileImage.startsWith('http')
                                  ? NetworkImage(profileImage) as ImageProvider
                                  : AssetImage(profileImage),
                            ),
                            SizedBox(height: 15),
                            Text(
                              name,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontFamily: 'OpenSans',
                              ),
                            ),
                            SizedBox(height: 5),
                            Text(
                              email,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 20),

                    // Profile Action Buttons
                    Card(
                      elevation: 5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          children: [
                            // Edit Profile Button
                            ElevatedButton.icon(
                              onPressed: () {
                                // Navigate to profile edit page
                              },
                              icon: Icon(Icons.edit, color: Colors.white),
                              label: Text('Edit Profile', style: TextStyle(fontSize: 16, color: Colors.white)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal,
                                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                            ),
                            SizedBox(height: 20),

                            // My Requests Button
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => MyRequestsPage()),
                                );
                              },
                              icon: Icon(Icons.list, color: Colors.white),
                              label: Text('My Requests', style: TextStyle(fontSize: 16, color: Colors.white)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal,
                                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                            ),
                            SizedBox(height: 10),

                            // My Bookings Button
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => MyBookingsPage()),
                                );
                              },
                              icon: Icon(Icons.bookmark, color: Colors.white),
                              label: Text('My Bookings', style: TextStyle(fontSize: 16, color: Colors.white)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal,
                                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
