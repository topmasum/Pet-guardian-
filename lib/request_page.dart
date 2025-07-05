import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'chat_page.dart';

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

  // Color scheme
  final Color primaryColor = Color(0xFF00897B); // Teal 600
  final Color secondaryColor = Color(0xFFB2DFDB); // Teal 100
  final Color accentColor = Color(0xFF4DB6AC); // Teal 300
  final Color backgroundColor = Color(0xFFE0F2F1); // Teal 50

  @override
  void dispose() {
    _petNameController.dispose();
    _careDetailsController.dispose();
    super.dispose();
  }

  void _pickDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: primaryColor,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      setState(() => _selectedDate = pickedDate);
    }
  }

  void _submitRequest() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a date')),
      );
      return;
    }

    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        String username = userDoc.exists ? (userDoc['username'] ?? 'Unknown') : 'Unknown';

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

        // Clear form
        _petNameController.clear();
        _careDetailsController.clear();
        setState(() {
          _selectedPetCategory = 'Dog';
          _selectedLocation = 'Dhanmondi';
          _selectedDate = null;
          _isSubmitting = false;
        });

        Navigator.of(context).pop();
      }
    } catch (e) {
      print("Error saving request: $e");
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit request')),
      );
    }
  }

  void _showFormDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
          child: Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Request Pet Care",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  SizedBox(height: 20),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildTextField(_petNameController, 'Pet Name', 'Enter your pet\'s name'),
                        SizedBox(height: 12),
                        _buildDropdown(
                          value: _selectedPetCategory,
                          items: petTypes,
                          label: 'Pet Category',
                          onChanged: (value) => setState(() => _selectedPetCategory = value!),
                        ),
                        SizedBox(height: 12),
                        _buildTextField(_careDetailsController, 'Care Details', 'Enter care details'),
                        SizedBox(height: 12),
                        _buildDatePicker(),
                        SizedBox(height: 12),
                        _buildDropdown(
                          value: _selectedLocation,
                          items: locations,
                          label: 'Location',
                          onChanged: (value) => setState(() => _selectedLocation = value!),
                        ),
                        SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text(
                                'Cancel',
                                style: TextStyle(color: Colors.grey[600]),
                              ),),
                            SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: _isSubmitting ? null : _submitRequest,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              ),
                              child: _isSubmitting
                                  ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                                  : Text(
                                'Submit',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
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
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required String label,
    required Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      items: items.map((item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(item),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildDatePicker() {
    return InkWell(
      onTap: () => _pickDate(context),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Request Date',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          filled: true,
          fillColor: Colors.grey[50],
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
            Icon(Icons.calendar_today, color: primaryColor),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, String hint) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      validator: (value) => value!.isEmpty ? 'Please enter $label' : null,
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
              return Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundImage: profileImage.startsWith('http')
                            ? NetworkImage(profileImage)
                            : AssetImage(profileImage) as ImageProvider,
                      ),
                      SizedBox(height: 16),
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        email,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 16),
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
                      SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[500],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              'Close',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () async {
                              Navigator.pop(context);

                              User? currentUser = FirebaseAuth.instance.currentUser;
                              if (currentUser == null) return;

                              String myId = currentUser.uid;
                              String otherId = userId;

                              // Generate unique chatRoomId (same for both users)
                              List<String> ids = [myId, otherId];
                              ids.sort();
                              String chatRoomId = ids.join('_');

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChatPage(
                                    chatRoomId: chatRoomId,
                                    otherUserId: otherId,
                                    otherUserName: name,
                                  ),
                                ),
                              );
                            },

                            icon: Icon(Icons.chat, color: Colors.white),
                            label: Text(
                              'Chat',
                              style: TextStyle(color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        }
      }
    } catch (e) {
      print("Error fetching user profile: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load profile')),
      );
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
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        DocumentSnapshot requestDoc = await FirebaseFirestore.instance
            .collection('requests')
            .doc(requestId)
            .get();

        if (requestDoc.exists) {
          Map<String, dynamic> requestData = requestDoc.data() as Map<String, dynamic>;

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

  void _showFilterDialog(String type, List<String> options) {
    String selectedValue = options.first;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Filter by $type'),
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
              child: Text(
                "Cancel",
                style: TextStyle(
                  color: Colors.red, // <-- text color set to white
                ),
              ),

            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _filterType = type;
                  _filterValue = selectedValue;
                });
                Navigator.pop(context);
              },
              child: Text(
                "Apply",
                style: TextStyle(
                  color: Colors.white, // <-- text color set to white
                ),
              ),
              style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
            ),
          ],
        );
      },
    );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          'Requests',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            letterSpacing: 0.8,
          ),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 72,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
        ),
        flexibleSpace: ClipRRect(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF008080),  // Professional teal
                  Color(0xFF006D6D),  // Darker teal
                ],
                stops: [0.0, 1.0],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 12,
                  spreadRadius: 0.5,
                  offset: Offset(0, 6),
                ),
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.filter_alt, color: Colors.white),
            tooltip: 'Filter',
            iconSize: 30,
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (context) {
                  return Container(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Filter Requests',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                        SizedBox(height: 16),
                        ListTile(
                          leading: Icon(Icons.pets, color: primaryColor),
                          title: Text('By Pet Type'),
                          onTap: () {
                            Navigator.pop(context);
                            _showFilterDialog('Pet Type', petTypes);
                          },
                        ),
                        ListTile(
                          leading: Icon(Icons.location_on, color: primaryColor),
                          title: Text('By Area'),
                          onTap: () {
                            Navigator.pop(context);
                            _showFilterDialog('Area', locations);
                          },
                        ),
                        if (_filterValue != null)
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _filterType = null;
                                  _filterValue = null;
                                });
                                Navigator.pop(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red[400],
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                "Clear filter",
                                style: TextStyle(
                                  color: Colors.white, // <-- text color set to white
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
      body: _buildRequestList(),
      floatingActionButton: FloatingActionButton(
        onPressed: _showFormDialog,
        child: Icon(Icons.add, size: 28,color: Colors.white,),
        backgroundColor: primaryColor,
        elevation: 4,
      ),
    );
  }

  Widget _buildRequestList() {
    return StreamBuilder(
      stream: getFilteredStream(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: primaryColor));
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error loading requests'));
        }

        final requests = snapshot.data?.docs ?? [];

        if (requests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.pets, size: 64, color: Colors.grey[400]),
                SizedBox(height: 16),
                Text(
                  'No requests found',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                if (_filterValue != null)
                  TextButton(
                    onPressed: () => setState(() {
                      _filterType = null;
                      _filterValue = null;
                    }),
                    child: Text('Clear filter'),
                  ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(8),
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
              margin: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {},
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            petName,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: secondaryColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              petCategory,
                              style: TextStyle(
                                color: primaryColor,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => _showRequesterProfile(userId),
                        child: RichText(
                          text: TextSpan(
                            style: TextStyle(color: Colors.black87),
                            children: [
                              TextSpan(
                                text: 'Requester: ',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              TextSpan(
                                text: requester,
                                style: TextStyle(
                                  color: Colors.blue,

                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        careDetails,
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                      SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                          SizedBox(width: 4),
                          Text('Service Date: $reqDate'),
                          SizedBox(width: 16),
                          Icon(Icons.location_on, size: 16, color: Colors.grey),
                          SizedBox(width: 4),
                          Text(location),
                        ],
                      ),

                      SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: FutureBuilder<bool>(
                          future: checkIfBooked(request.id),
                          builder: (context, snapshot) {
                            bool isBooked = snapshot.data ?? false;
                            return ElevatedButton(
                              onPressed: isBooked ? null : () => _handleBookNow(request.id, userId),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isBooked ? Colors.grey : primaryColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              ),
                              child: Text(
                                isBooked ? 'Already Applied' : 'Book Now',
                                style: TextStyle(color: Colors.white),
                              ),
                            );
                          },
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
    );
  }
}
