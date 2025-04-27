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

  @override
  void initState() {
    super.initState();
    _futureBookings = _fetchBookings();
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

          if (doc.metadata.hasPendingWrites) {
            await _sendBookingNotification(
              booking['requesterId'],
              booking['petName'] ?? 'Unknown Pet',
            );
          }

          bookings.add(Booking(
            id: doc.id,
            petName: booking['petName'] ?? 'Unknown Pet',
            petCategory: booking['petCategory'] ?? 'Unknown',
            requesterName: requesterDoc['username'] ?? 'Unknown User',
            date: _formatDate(booking['reqDate']),
            location: booking['location'] ?? 'Location not specified',
            status: _parseBookingStatus(booking['status'] ?? 'Applied'),
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

  Future<void> _sendBookingNotification(String requesterId, String petName) async {
    try {
      final userDoc = await _firestore.collection('users').doc(_auth.currentUser!.uid).get();
      final userName = userDoc['username'] ?? 'Someone';

      await _firestore.collection('notifications').add({
        'userId': requesterId,
        'title': 'New Booking Application',
        'message': '$userName has applied to care for $petName',
        'type': 'booking',
        'read': false,
        'timestamp': Timestamp.now(),
        'relatedId': '',
      });
    } catch (e) {
      debugPrint('Error sending booking notification: $e');
    }
  }

  Future<void> _cancelBooking(String bookingId) async {
    try {
      await _firestore.collection('bookings').doc(bookingId).delete();
      setState(() {
        _futureBookings = _fetchBookings();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking cancelled successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to cancel booking')),
      );
      debugPrint('Error cancelling booking: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookings', style: TextStyle(fontWeight: FontWeight.w600)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).colorScheme.onBackground,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: FutureBuilder<List<Booking>>(
          future: _futureBookings,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
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
            onPressed: () => setState(() => _futureBookings = _fetchBookings()),
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Retry'),
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
      onRefresh: () async => setState(() => _futureBookings = _fetchBookings()),
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
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {}, // Add booking details navigation if needed
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
              if (booking.status == BookingStatus.applied)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red[400],
                    ),
                    onPressed: () => _showCancelDialog(booking.id),
                    child: const Text('Cancel Application'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(BookingStatus status) {
    final color = status == BookingStatus.approved
        ? Colors.green
        : status == BookingStatus.applied
        ? Colors.orange
        : Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        status.toString().split('.').last,
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

  void _showCancelDialog(String bookingId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Booking?'),
        content: const Text('This action cannot be undone. Are you sure you want to cancel this booking application?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Go Back'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _cancelBooking(bookingId);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Cancel Booking'),
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

  Booking({
    required this.id,
    required this.petName,
    required this.petCategory,
    required this.requesterName,
    required this.date,
    required this.location,
    required this.status,
  });
}