import 'package:flutter/material.dart';

class RequestsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.request_page, size: 100, color: Colors.teal),
          SizedBox(height: 20),
          Text(
            'Manage your pet care requests here.',
            style: TextStyle(fontSize: 18, color: Colors.black54, fontFamily: 'OpenSans'),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
