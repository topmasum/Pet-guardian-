import 'package:flutter/material.dart';

class HomeActivity extends StatefulWidget {
  @override
  _HomeActivityState createState() => _HomeActivityState();
}

class _HomeActivityState extends State<HomeActivity> {
  int _selectedIndex = 0;

  final List<String> _titles = ['Requests', 'Tips', 'Profile'];
  final List<Widget> _pages = [
    _buildRequestsPage(),
    _buildTipsPage(),
    _buildProfilePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _titles[_selectedIndex],
          style: TextStyle(
            fontFamily: 'OpenSans',
            fontSize: 30,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),

        centerTitle: true,
        backgroundColor: Colors.teal,
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.request_page),
            label: 'Requests',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.lightbulb_outline),
            label: 'Tips',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.teal,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }

  static Widget _buildRequestsPage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.request_page, size: 100, color: Colors.teal),
          SizedBox(height: 20),
          Text(
            'Manage your pet care requests here.',
            style: TextStyle(fontSize: 18, color: Colors.black54,fontFamily: 'OpenSans'),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  static Widget _buildTipsPage() {
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

  static Widget _buildProfilePage() {
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
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold,fontFamily: 'OpenSans'),
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

