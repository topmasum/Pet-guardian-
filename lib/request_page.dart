import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class RequestsPage extends StatefulWidget {
  @override
  _RequestsPageState createState() => _RequestsPageState();
}

class _RequestsPageState extends State<RequestsPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _petNameController = TextEditingController();
  final TextEditingController _careDetailsController = TextEditingController();

  String _selectedPetCategory = 'Dog';
  String _selectedLocation = 'Dhanmondi';
  DateTime? _selectedDate;
  bool _isSubmitting = false;

  List<String> locations = ['Dhanmondi', 'Gulshan', 'Banani', 'Uttara', 'Mirpur'];
  List<String> petTypes = ['Dog', 'Cat', 'Bird', 'Others'];

  String? _filterType;
  String? _filterValue;

  void _pickDate(BuildContext context) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  void _submitRequest() async {
    if (_formKey.currentState?.validate() ?? false) {
      if (_selectedDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please select a date')),
        );
        return;
      }

      if (_isSubmitting) return;

      setState(() {
        _isSubmitting = true;
      });

      try {
        User? user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          DocumentSnapshot userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

          String username = userDoc.exists
              ? (userDoc['username'] ?? 'Unknown')
              : 'Unknown';

          await FirebaseFirestore.instance.collection('requests').add({
            'userId': user.uid,
            'requester': username,
            'petName': _petNameController.text.trim(),
            'petCategory': _selectedPetCategory,
            'careDetails': _careDetailsController.text.trim(),
            'location': _selectedLocation,
            'reqDate': DateFormat('yyyy-MM-dd').format(_selectedDate!),
            'timestamp': FieldValue.serverTimestamp(),
          });

          setState(() {
            _petNameController.clear();
            _careDetailsController.clear();
            _selectedPetCategory = 'Dog';
            _selectedLocation = 'Dhanmondi';
            _selectedDate = null;
            _isSubmitting = false;
          });

          Navigator.of(context).pop();
        }
      } catch (e) {
        print("Error saving request: $e");
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showFormDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Center(child: Text("Request Pet Care", style: TextStyle(fontWeight: FontWeight.bold))),
          content: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: StatefulBuilder(
                builder: (context, setStateSB) {
                  return Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildTextField(_petNameController, 'Pet Name', 'Enter your petsname'),
                        DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            labelText: 'Pet Category',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          value: _selectedPetCategory,
                          items: ['Dog', 'Cat', 'Bird', 'Others'].map((category) {
                            return DropdownMenuItem<String>(
                              value: category,
                              child: Text(category),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setStateSB(() {
                              _selectedPetCategory = value!;
                            });
                          },
                        ),
                        SizedBox(height: 15),
                        _buildTextField(_careDetailsController, 'Care Details', 'Enter care details'),
                        InkWell(
                          onTap: () async {
                            DateTime? pickedDate = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime.now(),
                              lastDate: DateTime(2100),
                            );
                            if (pickedDate != null) {
                              setStateSB(() {
                                _selectedDate = pickedDate;
                              });
                            }
                          },
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Request Date',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _selectedDate != null
                                      ? DateFormat('yyyy-MM-dd').format(_selectedDate!)
                                      : 'Select a date',
                                  style: TextStyle(fontSize: 16),
                                ),
                                Icon(Icons.calendar_today, color: Colors.teal),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 15),
                        DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            labelText: 'Location',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          value: _selectedLocation,
                          items: locations.map((location) {
                            return DropdownMenuItem<String>(
                              value: location,
                              child: Text(location),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setStateSB(() {
                              _selectedLocation = value!;
                            });
                          },
                        ),
                        SizedBox(height: 20),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: _submitRequest,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
              child: Text('Submit', style: TextStyle(color: Colors.white)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _showRequesterProfile(String userId) async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      if (userDoc.exists) {
        Map<String, dynamic>? userData = userDoc.data() as Map<String, dynamic>?;
        if (userData != null) {
          String name = userData['username'] ?? 'Unknown';
          String email = userData['email'] ?? 'No Email';
          String profileImage = userData['profileImage'] ?? 'assets/images/profile_placeholder.png';
          double rating = userData['rating']?.toDouble() ?? 0.0;
          int ratingCount = userData['ratingCount'] ?? 0;

          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: Text("Requester Profile"),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundImage: profileImage.startsWith('http')
                          ? NetworkImage(profileImage)
                          : AssetImage(profileImage) as ImageProvider,
                    ),
                    SizedBox(height: 10),
                    Text(name, style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 5),
                    Text(email, style: TextStyle(color: Colors.grey)),
                    SizedBox(height: 10),
                    if (ratingCount > 0)
                      Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.star, color: Colors.amber, size: 20),
                              SizedBox(width: 4),
                              Text(
                                rating.toStringAsFixed(1),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '(${ratingCount} ${ratingCount == 1 ? 'rating' : 'ratings'})',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      )
                    else
                      Text(
                        'No ratings yet',
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: Colors.grey,
                        ),
                      ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text("Close"),
                  ),
                ],
              );
            },
          );
        }
      }
    } catch (e) {
      print("Error fetching user profile: $e");
    }
  }

  Future<bool> checkIfBooked(String requestId) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('bookings')
        .where('userId', isEqualTo: user.uid)
        .where('requestId', isEqualTo: requestId)
        .limit(1)
        .get();

    return snapshot.docs.isNotEmpty;
  }

  void _handleBookNow(String requestId, String requesterId) async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Booking'),
        content: Text('Are you sure you want to book this request?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Yes'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        // Get the request details first
        DocumentSnapshot requestDoc = await FirebaseFirestore.instance
            .collection('requests')
            .doc(requestId)
            .get();

        if (requestDoc.exists) {
          Map<String, dynamic> requestData = requestDoc.data() as Map<String, dynamic>;

          // Create a booking document
          await FirebaseFirestore.instance.collection('bookings').add({
            'userId': currentUser.uid,
            'requestId': requestId,
            'requesterId': requesterId,
            'petName': requestData['petName'],
            'petCategory': requestData['petCategory'],
            'careDetails': requestData['careDetails'],
            'location': requestData['location'],
            'reqDate': requestData['reqDate'],
            'bookingDate': FieldValue.serverTimestamp(),
            'status': 'Applied',
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Booking applied successfully!')),
          );

          // Refresh the UI
          setState(() {});
        }
      } catch (e) {
        print("Error creating booking: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to apply booking')),
        );
      }
    }
  }

  Stream<QuerySnapshot> getFilteredStream() {
    CollectionReference ref = FirebaseFirestore.instance.collection('requests');
    Query query = ref.orderBy('timestamp', descending: true);

    if (_filterType == 'Pet Type' && _filterValue != null) {
      query = query.where('petCategory', isEqualTo: _filterValue);
    } else if (_filterType == 'Area' && _filterValue != null) {
      query = query.where('location', isEqualTo: _filterValue);
    }

    return query.snapshots();
  }

  void _showFilterDialog(String type, List<String> options) {
    String selectedValue = options.first;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Select $type'),
          content: StatefulBuilder(
            builder: (context, setStateSB) {
              return DropdownButton<String>(
                value: selectedValue,
                isExpanded: true,
                items: options.map((option) {
                  return DropdownMenuItem(
                    value: option,
                    child: Text(option),
                  );
                }).toList(),
                onChanged: (value) {
                  setStateSB(() {
                    selectedValue = value!;
                  });
                },
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _filterType = type;
                  _filterValue = selectedValue;
                });
                Navigator.pop(context);
              },
              child: Text("Apply"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRequestList() {
    return StreamBuilder(
      stream: getFilteredStream(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final requests = snapshot.data?.docs ?? [];

        return ListView.builder(
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final request = requests[index];
            final requester = request['requester'] ?? 'Unknown';
            final petName = request['petName'];
            final petCategory = request['petCategory'];
            final careDetails = request['careDetails'];
            final reqDate = request['reqDate'];
            final location = request['location'] ?? 'Not specified';
            final userId = request['userId'];

            return Card(
              margin: EdgeInsets.all(8),
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(petName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    GestureDetector(
                      onTap: () => _showRequesterProfile(userId),
                      child: Text(
                        'Requester: $requester',
                        style: TextStyle(fontStyle: FontStyle.italic, color: Colors.blue),
                      ),
                    ),
                    Text('Category: $petCategory'),
                    Text('Care Details: $careDetails'),
                    Text('Request Date: $reqDate'),
                    Text('Location: $location', style: TextStyle(color: Colors.teal)),
                    SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FutureBuilder<bool>(
                        future: checkIfBooked(request.id),
                        builder: (context, snapshot) {
                          bool isBooked = snapshot.data ?? false;
                          return ElevatedButton(
                            onPressed: isBooked ? null : () => _handleBookNow(request.id, userId),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isBooked ? Colors.grey : Colors.teal,
                            ),
                            child: Text(
                              isBooked ? 'Applied' : 'Book Now',
                              style: TextStyle(color: Colors.white),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, String hint) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        validator: (value) => value!.isEmpty ? 'Please enter $label' : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.filter_list),
            onSelected: (value) {
              if (value == 'Pet Type') {
                _showFilterDialog('Pet Type', petTypes);
              } else if (value == 'Area') {
                _showFilterDialog('Area', locations);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'Pet Type', child: Text('Search by Pet Type')),
              PopupMenuItem(value: 'Area', child: Text('Search by Area')),
            ],
          ),
          IconButton(
            icon: Icon(Icons.clear),
            tooltip: 'Clear Filter',
            onPressed: () {
              setState(() {
                _filterType = null;
                _filterValue = null;
              });
            },
          ),
        ],
      ),
      body: _buildRequestList(),
      floatingActionButton: FloatingActionButton(
        onPressed: _showFormDialog,
        child: Icon(Icons.add),
        backgroundColor: Colors.teal,
      ),
    );
  }
}
