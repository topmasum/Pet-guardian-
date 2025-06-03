import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'request_page.dart';
import 'tips_page.dart';
import 'profile_page.dart';
import 'chat_list_page.dart';

class HomeActivity extends StatefulWidget {
  @override
  _HomeActivityState createState() => _HomeActivityState();
}

class _HomeActivityState extends State<HomeActivity> {
  int _selectedIndex = 0;
  User? _currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  void _checkAuthState() async {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      setState(() {
        _currentUser = user;
      });
    });
  }

  final List<Widget> _pages = [
    RequestsPage(),
    TipsPage(),
    ChatListPage(),
    ProfilePage(),
  ];

  void _onItemTapped(int index) {
    if (_currentUser == null && index != 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please login to access this feature'),
          duration: Duration(seconds: 2),
        ),
      );
      setState(() {
        _selectedIndex = 3;
      });
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.teal[700],
        unselectedItemColor: Colors.grey[600],
        selectedLabelStyle: TextStyle(fontSize: 12),
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.pets),
            activeIcon: Icon(Icons.pets, color: Colors.teal[700]),
            label: 'Requests',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.lightbulb_outline),
            activeIcon: Icon(Icons.lightbulb, color: Colors.teal[700]),
            label: 'Tips',
          ),
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                Icon(Icons.chat_bubble_outline),
                Positioned(
                  right: 0,
                  child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: _currentUser != null
                        ? _firestore
                        .collection('chatRooms')
                        .where('users', arrayContains: _currentUser!.uid)
                        .where('lastMessageSender', isNotEqualTo: _currentUser!.uid)
                        .where('lastMessageRead', isEqualTo: false)
                        .snapshots()
                        : Stream<QuerySnapshot<Map<String, dynamic>>>.empty(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                        return Container(
                          padding: EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          constraints: BoxConstraints(
                            minWidth: 12,
                            minHeight: 12,
                          ),
                        );
                      }
                      return SizedBox.shrink();
                    },
                  ),
                ),
              ],
            ),
            activeIcon: Icon(Icons.chat, color: Colors.teal[700]),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person, color: Colors.teal[700]),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}