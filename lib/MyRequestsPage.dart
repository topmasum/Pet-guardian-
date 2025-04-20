import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MyRequestsPage extends StatefulWidget {
  @override
  _MyRequestsPageState createState() => _MyRequestsPageState();
}

class _MyRequestsPageState extends State<MyRequestsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late Future<List<DocumentSnapshot>> _futureRequests;
  Set<String> expandedCards = {};

  @override
  void initState() {
    super.initState();
    _futureRequests = getRequests();
  }

  Future<List<DocumentSnapshot>> getRequests() async {
    try {
      var user = _auth.currentUser;
      print('[DEBUG] Current user UID: ${user?.uid}');

      if (user == null) {
        print('[DEBUG] No user logged in');
        return [];
      }

      print('[DEBUG] Fetching requests for user ${user.uid}');

      QuerySnapshot snapshot = await _firestore
          .collection('requests')
          .where('userId', isEqualTo: user.uid)
          .get();

      print('[DEBUG] Found ${snapshot.docs.length} requests');

      for (var doc in snapshot.docs) {
        print('[DEBUG] Request ID: ${doc.id} - Data: ${doc.data()}');
      }

      return snapshot.docs;
    } catch (e) {
      print('[ERROR] Error getting requests: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchApplicants(String requestId) async {
    try {
      print('[DEBUG] Fetching applicants for request $requestId');

      final bookingsSnapshot = await _firestore
          .collection('bookings')
          .where('requestId', isEqualTo: requestId)
          .get();

      print('[DEBUG] Found ${bookingsSnapshot.docs.length} bookings');

      List<Map<String, dynamic>> applicants = [];

      for (var bookingDoc in bookingsSnapshot.docs) {
        var bookingData = bookingDoc.data() as Map<String, dynamic>;
        var applicantId = bookingData['userId'];

        print('[DEBUG] Fetching user details for applicant $applicantId');

        var userDoc = await _firestore.collection('users').doc(applicantId).get();

        if (userDoc.exists) {
          var userData = userDoc.data() as Map<String, dynamic>;
          applicants.add({
            'name': '${userData['first_name']} ${userData['last_name']}',
            'email': userData['email'],
            'phone': userData['phone'],
            'bookingId': bookingDoc.id,
            'status': bookingData['status'] ?? 'Applied',
          });
        }
      }

      return applicants;
    } catch (e) {
      print('[ERROR] Error fetching applicants: $e');
      return [];
    }
  }

  Future<void> _deleteRequest(String requestId) async {
    try {
      // First delete all bookings associated with this request
      final bookings = await _firestore
          .collection('bookings')
          .where('requestId', isEqualTo: requestId)
          .get();

      for (var booking in bookings.docs) {
        await booking.reference.delete();
      }

      // Then delete the request itself
      await _firestore.collection('requests').doc(requestId).delete();

      // Refresh the list
      setState(() {
        _futureRequests = getRequests();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Request deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete request: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('My Requests')),
      body: FutureBuilder<List<DocumentSnapshot>>(
        future: _futureRequests,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            print('[ERROR] FutureBuilder error: ${snapshot.error}');
            return Center(child: Text('Error loading requests. Please try again.'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('No requests found'),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => setState(() {
                      _futureRequests = getRequests();
                    }),
                    child: Text('Refresh'),
                  ),
                ],
              ),
            );
          }

          var requests = snapshot.data!;

          return ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {
              var request = requests[index].data() as Map<String, dynamic>;
              String requestId = requests[index].id;
              bool isExpanded = expandedCards.contains(requestId);

              return Card(
                margin: EdgeInsets.all(10),
                elevation: 5,
                child: InkWell(
                  onTap: () {
                    setState(() {
                      if (isExpanded) {
                        expandedCards.remove(requestId);
                      } else {
                        expandedCards.add(requestId);
                      }
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          title: Text(
                            request['petName'] ?? 'Unnamed Pet',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Category: ${request['petCategory'] ?? 'Unknown'}'),
                              Text('Location: ${request['location'] ?? 'Unknown'}'),
                              Text('Date: ${request['reqDate'] ?? 'Unknown'}'),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _showDeleteDialog(requestId),
                              ),
                              Icon(
                                isExpanded ? Icons.expand_less : Icons.expand_more,
                                color: Colors.blue,
                              ),
                            ],
                          ),
                        ),
                        if (isExpanded)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Divider(),
                                Text(
                                  'Care Details:',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(request['careDetails'] ?? 'No details provided'),
                                SizedBox(height: 16),
                                Text(
                                  'Applicants:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                SizedBox(height: 8),
                                FutureBuilder<List<Map<String, dynamic>>>(
                                  future: fetchApplicants(requestId),
                                  builder: (context, applicantSnapshot) {
                                    if (applicantSnapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Center(child: CircularProgressIndicator()),
                                      );
                                    }

                                    if (applicantSnapshot.hasError) {
                                      return Text('Error loading applicants');
                                    }

                                    if (!applicantSnapshot.hasData ||
                                        applicantSnapshot.data!.isEmpty) {
                                      return Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text('No applicants yet'),
                                      );
                                    }

                                    return Column(
                                      children: applicantSnapshot.data!.map((applicant) {
                                        return Card(
                                          margin: EdgeInsets.only(bottom: 8),
                                          child: Padding(
                                            padding: const EdgeInsets.all(12.0),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  applicant['name'],
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                SizedBox(height: 4),
                                                Text(applicant['email']),
                                                SizedBox(height: 4),
                                                Text(applicant['phone']),
                                                SizedBox(height: 4),
                                                Text(
                                                  'Status: ${applicant['status']}',
                                                  style: TextStyle(
                                                    color: applicant['status'] == 'Approved'
                                                        ? Colors.green
                                                        : Colors.orange,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showDeleteDialog(String requestId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Request'),
          content: Text('Are you sure you want to delete this request? This will also remove all associated bookings.'),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteRequest(requestId);
              },
            ),
          ],
        );
      },
    );
  }
}