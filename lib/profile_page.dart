import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 50,
            backgroundImage: AssetImage('assets/images/profile_placeholder.png'),
          ),
          SizedBox(height: 20),
          Text(
            'Your Name',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'OpenSans'),
          ),
          SizedBox(height: 10),
          Text(
            'email@example.com',
            style: TextStyle(fontSize: 16, color: Colors.black54),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              // Add profile editing logic
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
  }
}
