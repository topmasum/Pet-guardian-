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
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTextField(_petNameController, 'Pet Name', 'Enter your pet’s name'),
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
                        setState(() {
                          _selectedPetCategory = value!;
                        });
                      },
                    ),
                    SizedBox(height: 15),
                    _buildTextField(_careDetailsController, 'Care Details', 'Enter care details'),
                    InkWell(
                      onTap: () => _pickDate(context),
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
                        setState(() {
                          _selectedLocation = value!;
                        });
                      },
                    ),
                    SizedBox(height: 20),
                  ],
                ),
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
                        style: TextStyle(fontStyle: FontStyle.italic, color: Colors.blue, decoration: TextDecoration.underline),
                      ),
                    ),
                    Text('Category: $petCategory'),
                    Text('Care Details: $careDetails'),
                    Text('Request Date: $reqDate'),
                    Text('Location: $location', style: TextStyle(color: Colors.teal)),
                    SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        onPressed: () {
                          print("Booking for $petName");
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                        child: Text('Book Now', style: TextStyle(color: Colors.white)),
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
        backgroundColor: Colors.teal,
        title: Text("Requests"),
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
