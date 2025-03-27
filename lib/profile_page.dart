import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

        // Extract user info
        var userData = snapshot.data!;
        String name = userData['username'] ?? 'Unknown';
        String email = userData['email'] ?? 'No Email';
        String profileImage = userData['profileImage'] ?? 'assets/images/profile_placeholder.png';

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 50,
                backgroundImage: profileImage.startsWith('http')
                    ? NetworkImage(profileImage) as ImageProvider
                    : AssetImage(profileImage),
              ),
              SizedBox(height: 20),
              Text(
                name,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'OpenSans'),
              ),
              SizedBox(height: 10),
              Text(
                email,
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  // Navigate to profile edit page
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                ),
                child: Text('Edit Profile', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        );
      },
    );
  }
}
