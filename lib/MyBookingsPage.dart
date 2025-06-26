import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class MyBookingsPage extends StatefulWidget {
  @override
  _MyBookingsPageState createState() => _MyBookingsPageState();
}

class _MyBookingsPageState extends State<MyBookingsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late Future<List<Booking>> _futureBookings;
  final _dateFormatter = DateFormat('MMM dd, yyyy - hh:mm a');
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  void _loadBookings() {
    setState(() {
      _futureBookings = _fetchBookings();
    });
  }

  Future<List<Booking>> _fetchBookings() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final snapshot = await _firestore
          .collection('bookings')
          .where('userId', isEqualTo: user.uid)
          .orderBy('bookingDate', descending: true)
          .get();

      final bookings = <Booking>[];

      for (final doc in snapshot.docs) {
        try {
          final booking = doc.data();
          if (booking['requesterId'] == null) continue;

          final requesterDoc = await _firestore
              .collection('users')
              .doc(booking['requesterId'])
              .get();

          bookings.add(Booking(
            id: doc.id,
            petName: booking['petName'] ?? 'Unknown Pet',
            petCategory: booking['petCategory'] ?? 'Unknown',
            requesterName: requesterDoc['username'] ?? 'Unknown User',
            date: _formatDate(booking['reqDate']),
            location: booking['location'] ?? 'Location not specified',
            status: _parseBookingStatus(booking['status'] ?? 'Applied'),
            bookingDate: booking['bookingDate'] as Timestamp?,
          ));
        } catch (e) {
          debugPrint("Error processing booking ${doc.id}: $e");
        }
      }

      return bookings;
    } catch (e) {
      debugPrint("Error fetching bookings: $e");
      throw Exception('Failed to load bookings');
    }
  }

  String _formatDate(dynamic date) {
    if (date is Timestamp) {
      return _dateFormatter.format(date.toDate());
    } else if (date is String) {
      return date;
    }
    return 'Date not specified';
  }

  BookingStatus _parseBookingStatus(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return BookingStatus.approved;
      case 'rejected':
        return BookingStatus.rejected;
      case 'completed':
        return BookingStatus.completed;
      default:
        return BookingStatus.applied;
    }
  }

  Future<void> _cancelBooking(String bookingId) async {
    await _performBookingAction(
      action: () => _firestore.collection('bookings').doc(bookingId).delete(),
      successMessage: 'Booking cancelled successfully',
      errorMessage: 'Failed to cancel booking',
    );
  }

  Future<void> _deleteBooking(String bookingId) async {
    await _performBookingAction(
      action: () => _firestore.collection('bookings').doc(bookingId).delete(),
      successMessage: 'Booking deleted successfully',
      errorMessage: 'Failed to delete booking',
    );
  }

  Future<void> _performBookingAction({
    required Future Function() action,
    required String successMessage,
    required String errorMessage,
  }) async {
    setState(() => _isLoading = true);

    try {
      await action();
      _loadBookings();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(successMessage),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      debugPrint('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Bookings',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            letterSpacing: 0.8,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        toolbarHeight: 70,
        iconTheme: IconThemeData(color: Colors.white),
        flexibleSpace: _buildAppBarGradient(),
      ),
      body: _isLoading
          ? _buildLoadingIndicator()
          : Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: FutureBuilder<List<Booking>>(
          future: _futureBookings,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingIndicator();
            }

            if (snapshot.hasError) {
              return _buildErrorState(snapshot.error.toString());
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return _buildEmptyState();
            }

            return _buildBookingsList(snapshot.data!);
          },
        ),
      ),
    );
  }

  Widget _buildAppBarGradient() {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(20),
        bottomRight: Radius.circular(20),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF008080),
              Color(0xFF006D6D),
            ],
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
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: Colors.red[400], size: 50),
          const SizedBox(height: 16),
          Text(
            'Failed to load bookings',
            style: TextStyle(fontSize: 18, color: Colors.grey[800]),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadBookings,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Retry', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_note, size: 60, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No bookings yet',
            style: TextStyle(fontSize: 18, color: Colors.grey[800]),
          ),
          const SizedBox(height: 8),
          Text(
            'Your bookings will appear here when you apply',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingsList(List<Booking> bookings) {
    return RefreshIndicator(
      onRefresh: () async => _loadBookings(),
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: bookings.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) => _buildBookingCard(bookings[index]),
      ),
    );
  }

  Widget _buildBookingCard(Booking booking) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    booking.petName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                _buildStatusChip(booking.status),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            _buildDetailRow(Icons.person_outline, 'Requester:', booking.requesterName),
            _buildDetailRow(Icons.pets, 'Pet Type:', booking.petCategory),
            _buildDetailRow(Icons.calendar_today, 'Date:', booking.date),
            _buildDetailRow(Icons.location_on_outlined, 'Location:', booking.location),
            const SizedBox(height: 8),
            _buildActionButton(booking),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(Booking booking) {
    if (booking.status == BookingStatus.applied) {
      return _buildTextButton(
        text: 'Cancel Application',
        onPressed: () => _showConfirmationDialog(
          title: 'Cancel Booking?',
          content: 'This action cannot be undone. Are you sure?',
          action: () => _cancelBooking(booking.id),
        ),
      );
    } else {
      return _buildTextButton(
        text: 'Delete Booking',
        onPressed: () => _showConfirmationDialog(
          title: 'Delete Booking?',
          content: 'This will permanently remove this booking from your history.',
          action: () => _deleteBooking(booking.id),
        ),
      );
    }
  }

  Widget _buildTextButton({required String text, required VoidCallback onPressed}) {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        style: TextButton.styleFrom(
          foregroundColor: Colors.red[400],
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        onPressed: onPressed,
        child: Text(text),
      ),
    );
  }

  void _showConfirmationDialog({
    required String title,
    required String content,
    required VoidCallback action,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Go Back'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              action();
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(BookingStatus status) {
    final (color, text) = switch (status) {
      BookingStatus.approved => (Colors.green, 'Approved'),
      BookingStatus.applied => (Colors.orange, 'Applied'),
      BookingStatus.rejected => (Colors.red, 'Rejected'),
      BookingStatus.completed => (Colors.teal, 'Completed'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  color: Colors.grey[800],
                  fontSize: 14,
                ),
                children: [
                  TextSpan(
                    text: '$label ',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  TextSpan(text: value),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum BookingStatus { applied, approved, rejected, completed }

class Booking {
  final String id;
  final String petName;
  final String petCategory;
  final String requesterName;
  final String date;
  final String location;
  final BookingStatus status;
  final Timestamp? bookingDate;

  Booking({
    required this.id,
    required this.petName,
    required this.petCategory,
    required this.requesterName,
    required this.date,
    required this.location,
    required this.status,
    this.bookingDate,
  });
}