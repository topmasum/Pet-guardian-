import 'package:flutter/material.dart';

class TipsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(16.0),
      children: [
        Card(
          child: ListTile(
            leading: Icon(Icons.pets, color: Colors.teal),
            title: Text('Pet Care Tip 1'),
            subtitle: Text('Always provide fresh water for your pets.'),
          ),
        ),
        Card(
          child: ListTile(
            leading: Icon(Icons.pets, color: Colors.teal),
            title: Text('Pet Care Tip 2'),
            subtitle: Text('Regularly groom your pets to keep them healthy.'),
          ),
        ),
        // Add more tips as needed
      ],
    );
  }
}
