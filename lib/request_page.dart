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
  final TextEditingController _requesterNameController = TextEditingController();

  void _submitRequest() {
    FirebaseFirestore.instance.collection('requests').add({
      'petName': _petNameController.text,
      'careDetails': _careDetailsController.text,
      'petCategory': _petCategoryController.text,
      'reqDate': _reqDateController.text,
      'requesterName': _requesterNameController.text,
      'timestamp': FieldValue.serverTimestamp(),
    }).then((value) {
      setState(() {
        _petNameController.clear();
        _careDetailsController.clear();
        _petCategoryController.clear();
        _reqDateController.clear();
        _requesterNameController.clear();
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
                  controller: _requesterNameController,
                  decoration: InputDecoration(labelText: 'Your Name'),
                  validator: (value) => value!.isEmpty ? 'Please enter your name' : null,
                ),
                TextFormField(
                  controller: _petNameController,
                  decoration: InputDecoration(labelText: 'Pet Name'),
                  validator: (value) => value!.isEmpty ? 'Please enter the pet name' : null,
                ),
                TextFormField(
                  controller: _careDetailsController,
                  decoration: InputDecoration(labelText: 'Care Details'),
                  validator: (value) => value!.isEmpty ? 'Please enter care details' : null,
                ),
                TextFormField(
                  controller: _petCategoryController,
                  decoration: InputDecoration(labelText: 'Pet Category'),
                  validator: (value) => value!.isEmpty ? 'Please enter the pet category' : null,
                ),
                TextFormField(
                  controller: _reqDateController,
                  decoration: InputDecoration(labelText: 'Request Date'),
                  validator: (value) => value!.isEmpty ? 'Please enter the request date' : null,
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
              onPressed: () => Navigator.of(context).pop(),
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
            final requesterName = request['requesterName'];
            final timestamp = request['timestamp']?.toDate();

            return Card(
              margin: EdgeInsets.all(8),
              elevation: 6,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      requesterName,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.teal),
                    ),
                    SizedBox(height: 8),
                    Text('Pet Name: $petName', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    SizedBox(height: 4),
                    Text('Category: $petCategory', style: TextStyle(fontSize: 14, color: Colors.grey[700])),
                    SizedBox(height: 4),
                    Text('Care Details: $careDetails', style: TextStyle(fontSize: 14)),
                    SizedBox(height: 4),
                    Text('Request Date: $reqDate', style: TextStyle(fontSize: 14, color: Colors.grey[700])),
                    if (timestamp != null)
                      Text(
                        'Submitted: ${timestamp.toLocal()}'.split('.')[0],
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
        backgroundColor: Color(0xFF009688),
      ),
    );
  }
}
