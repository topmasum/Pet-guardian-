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
  DateTime? _selectedDate;
  String _currentUserId = '';
  String _currentUserName = '';

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc =
      await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        setState(() {
          _currentUserId = user.uid;
          _currentUserName = userDoc['name'] ?? 'Unknown';
        });
      }
    }
  }

  void _pickDate(BuildContext context) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate; // ✅ Updating the selected date
      });
    }
  }

  bool _isSubmitting = false; // ✅ Declare it at the top

  void _submitRequest() async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        if (_selectedDate == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Please select a date')),
          );
          return;
        }

        User? user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
          String userName = userDoc.exists ? (userDoc['username'] ?? 'Unknown User') : 'Unknown User';

          // ✅ Prevent multiple submissions
          if (_isSubmitting) return;
          setState(() {
            _isSubmitting = true;
          });

          await FirebaseFirestore.instance.collection('requests').add({
            'userId': user.uid,
            'username': userName,
            'petName': _petNameController.text.trim(),
            'petCategory': _selectedPetCategory,
            'careDetails': _careDetailsController.text.trim(),
            'reqDate': DateFormat('yyyy-MM-dd').format(_selectedDate!),
            'timestamp': FieldValue.serverTimestamp(),
          });

          // ✅ Clear form & close dialog
          setState(() {
            _petNameController.clear();
            _careDetailsController.clear();
            _selectedPetCategory = 'Dog';
            _selectedDate = null;
            _isSubmitting = false;
          });

          Navigator.of(context).pop(); // ✅ Close the form after submission
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

                    // Pet Category Dropdown
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

                    // Date Picker
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
                Navigator.of(context).pop(); // ✅ Just close the dialog, don't log out!
              },
              child: Text('Cancel'),
            ),

          ],
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

  Widget _buildRequestList() {
    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection('requests')
          .orderBy('timestamp', descending: true)
          .snapshots(),
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
            final username = request['username'] ?? 'Unknown User'; // ✅ Ensure it never shows null

            final petName = request['petName'];
            final petCategory = request['petCategory'];
            final careDetails = request['careDetails'];
            final reqDate = request['reqDate'];

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
                    SizedBox(height: 4),
                    Text('Requester: $username', style: TextStyle(fontSize: 16)),
                    Text('Category: $petCategory', style: TextStyle(fontSize: 16)),
                    Text('Care Details: $careDetails', style: TextStyle(fontSize: 16)),
                    Text('Request Date: $reqDate', style: TextStyle(fontSize: 16, color: Colors.teal)),
                    SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(child: _buildRequestList()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showFormDialog,
        child: Icon(Icons.add),
        tooltip: 'Add Request',
        backgroundColor: Colors.teal,
      ),
    );
  }
}
