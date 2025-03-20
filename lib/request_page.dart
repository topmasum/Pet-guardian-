import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class RequestsPage extends StatefulWidget {
  @override
  _RequestsPageState createState() => _RequestsPageState();
}

class _RequestsPageState extends State<RequestsPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _petNameController = TextEditingController();
  final TextEditingController _careDetailsController = TextEditingController();
  final TextEditingController _petCategoryController = TextEditingController();
  final TextEditingController _reqDateController = TextEditingController();

  void _submitRequest() {
    FirebaseFirestore.instance.collection('requests').add({
      'petName': _petNameController.text,
      'careDetails': _careDetailsController.text,
      'petCategory': _petCategoryController.text,
      'reqDate': _reqDateController.text,
      'timestamp': FieldValue.serverTimestamp(),
    }).then((value) {
      setState(() {
        _petNameController.clear();
        _careDetailsController.clear();
        _petCategoryController.clear();
        _reqDateController.clear();
      });
    });
  }

  void _showFormDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Request Pet Care"),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _petNameController,
                  decoration: InputDecoration(labelText: 'Pet Name'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the pet name';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _careDetailsController,
                  decoration: InputDecoration(labelText: 'Care Details'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter care details';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _petCategoryController,
                  decoration: InputDecoration(labelText: 'Pet Category'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the pet category';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _reqDateController,
                  decoration: InputDecoration(labelText: 'Request Date'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the request date';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (_formKey.currentState?.validate() ?? false) {
                  _submitRequest();
                  Navigator.of(context).pop();
                }
              },
              child: Text('Submit'),
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
            final petName = request['petName'];
            final careDetails = request['careDetails'];
            final petCategory = request['petCategory'];
            final reqDate = request['reqDate'];
            final timestamp = request['timestamp']?.toDate();

            return Card(
              margin: EdgeInsets.all(8),
              elevation: 4,
              child: ListTile(
                contentPadding: EdgeInsets.all(16),
                title: Text(petName, style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Care Details: $careDetails'),
                    Text('Category: $petCategory'),
                    Text('Request Date: $reqDate'),
                    Text('Timestamp: ${timestamp?.toLocal()}'),
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
          Expanded(
            child: _buildRequestList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showFormDialog,
        child: Icon(Icons.add),
        tooltip: 'Add Request',
        backgroundColor: Color(0xFF009688), // Set the color to #009688FF
      ),
    );
  }
}
